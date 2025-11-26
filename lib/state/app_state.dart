import 'dart:async';
import 'package:affirmation/data/preferences.dart';
import 'package:affirmation/state/playback_state.dart';
import 'package:affirmation/utils/affirmation_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import '../data/app_repository.dart';
import '../models/affirmation.dart';
import '../models/category.dart';
import '../models/theme_model.dart';
import '../models/user_preferences.dart';

class AppState extends ChangeNotifier {
  static const String favoritesCategoryId = 'favorites';
  static const String generalCategoryId = 'general';
  static const String myownaffirmations = 'myownaffirmations';

  late AppRepository _repository;

  String _selectedLocale = "en"; // default
  String get selectedLocale => _selectedLocale;

  List<Affirmation> _allAffirmations = [];

  List<AffirmationCategory> _categories = [];
  List<ThemeModel> _themes = [];
  late UserPreferences _preferences;

  String _activeCategoryId = '';
  int _currentIndex = 0;
  bool _fabExpanded = false;
  bool _loaded = false;
  bool isSoundEnabled = true;
  bool favoriteLimitReached = false;

  final AudioPlayer _audioPlayer = AudioPlayer();
  static const List<String> allContentPreferenceIds = ContentPreferences.all;

  bool onboardingCompleted = false;
  String? onboardingGender;
  Set<String> onboardingContentPrefs = {};
  int? onboardingThemeIndex;
  String? onboardingName;

  static const int freeFavoriteLimit = 5;
  static const int premiumFavoriteLimit = 50;
  static const supportedLanguages = ['en', 'tr']; // şu an için

  final playback = PlaybackState();

  AppState();

  bool get isLoaded => _loaded;

  //────────────────────────────────────────
  // INITIALIZE
  //────────────────────────────────────────

  Future<void> initialize() async {
    print("🔥 initialize()");

    final prefs = await SharedPreferences.getInstance();
    print(
        "📌 PREFS = ${prefs.getKeys().map((k) => "$k=${prefs.get(k)}").join(" | ")}");

    String? savedLang = prefs.getString("lastLanguage");

    // Cihaz dili
    final deviceLocale = PlatformDispatcher.instance.locale;
    String deviceLang = deviceLocale.languageCode;

    String resolvedLang;

    if (savedLang != null && savedLang.isNotEmpty) {
      resolvedLang = savedLang;
      print("🌐 Dil: Kullanıcı tercihi bulundu → $resolvedLang");
    } else {
      // İlk açılış → cihaz dilini kontrol et
      if (supportedLanguages.contains(deviceLang)) {
        resolvedLang = deviceLang;
        print("🌐 Dil: Cihaz dili destekleniyor → $resolvedLang");
      } else {
        resolvedLang = "en"; // fallback
        print("🌐 Dil: Cihaz dili desteklenmiyor → fallback = en");
      }
    }

    _selectedLocale = resolvedLang;
    playback.setLanguage(_selectedLocale);

    _repository = AppRepository(languageCode: resolvedLang);

    // 1) Categories & themes
    final bundle = await _repository.load();
    _categories = bundle.categories;
    _themes = bundle.themes;

    // 2) Tüm kategorileri tek seferde yükle
    _allAffirmations = await _repository.loadAllCategoriesItems();

    print("🟢 ALL data loaded. Total = ${_allAffirmations.length}");

    _preferences = UserPreferences.initial(
      defaultThemeId: _themes.first.id,
      allCategoryIds: _categories.map((c) => c.id).toSet(),
      allContentPreferenceIds: allContentPreferenceIds.toSet(),
    );

    onboardingCompleted = prefs.getBool("onboarding_completed") ?? false;
    onboardingGender = prefs.getString("onboard_gender");
    onboardingContentPrefs =
        (prefs.getStringList("onboard_prefs") ?? []).toSet();
    onboardingThemeIndex = prefs.getInt("onboard_theme");

    print("🔥 ONBOARDING STATUS:");
    print("➡ completed = $onboardingCompleted");
    print("➡ gender = $onboardingGender");
    print("➡ prefs = $onboardingContentPrefs");
    print("➡ themeIndex = $onboardingThemeIndex");

    // Premium bilgileri
    final premiumActive = prefs.getBool('premiumActive');
    final premiumPlanId = prefs.getString('premiumPlanId');
    final premiumExpiresAtStr = prefs.getString('premiumExpiresAt');
    DateTime? premiumExpiresAt;
    if (premiumExpiresAtStr != null && premiumExpiresAtStr.isNotEmpty) {
      premiumExpiresAt = DateTime.tryParse(premiumExpiresAtStr);
    }

    // SENARYO 1: ONBOARDING TAMAMLANMIŞ
    if (onboardingCompleted) {
      print("✅ Onboarding tamamlanmış → kullanıcı ayarları yükleniyor");
      await loadLastSettings();
    } else {
      // ESKİ KULLANICI (backward compatibility)
      final hasOldData = prefs.getString('lastCategory') != null ||
          prefs.getString('lastContentPreferences') != null;

      if (hasOldData) {
        print("⚠️ Onboarding yok AMA eski data var → eski ayarlar yükleniyor");
        await loadLastSettings();

        if (_preferences.selectedContentPreferences.isEmpty) {
          print("🔓 Fallback: Tüm content preferences aktif");
          _preferences = _preferences.copyWith(
            selectedContentPreferences: Set.from(allContentPreferenceIds),
          );
        }
      } else {
        print("🆕 İlk açılış (veya crash recovery) → varsayılan ayarlar");

        _preferences = _preferences.copyWith(
          selectedContentPreferences: Set.from(allContentPreferenceIds),
          gender: Gender.none,
        );
      }
    }

    // 4️⃣ CATEGORY + THEME VALIDATION (ESKİ KODUN)
    if (_activeCategoryId.isEmpty && _categories.isNotEmpty) {
      _activeCategoryId = _categories.first.id;
    }

    // Premium kategori → fallback
    final activeCategory = _categories
        .where((c) => c.id == _activeCategoryId)
        .cast<AffirmationCategory?>()
        .firstWhere((c) => c != null, orElse: () => null);

    if (activeCategory != null &&
        activeCategory.isPremiumLocked &&
        !_preferences.isPremiumValid) {
      final fallback = _categories.firstWhere(
        (c) => !c.isPremiumLocked,
        orElse: () => _categories.first,
      );

      _activeCategoryId = fallback.id;
      print("🔒 Premium kategori → fallback: ${fallback.id}");
    }

    // Tema kontrolü
    if (_preferences.selectedThemeId.isEmpty && _themes.isNotEmpty) {
      _preferences = _preferences.copyWith(
        selectedThemeId: _themes.first.id,
      );
    }

    // Premium tema → fallback
    final activeTheme = _themes
        .where((t) => t.id == _preferences.selectedThemeId)
        .cast<ThemeModel?>()
        .firstWhere((t) => t != null, orElse: () => null);

    if (activeTheme != null &&
        activeTheme.isPremiumLocked &&
        !_preferences.isPremiumValid) {
      final fallbackTheme = _themes.firstWhere(
        (t) => !t.isPremiumLocked,
        orElse: () => _themes.first,
      );
      _preferences = _preferences.copyWith(selectedThemeId: fallbackTheme.id);
      print("🔒 Premium tema → fallback: ${fallbackTheme.id}");
    }

    // Dil kontrolü (biz artık _selectedLocale ile zaten çözdük)
    if (_preferences.languageCode.isEmpty) {
      _preferences = _preferences.copyWith(languageCode: _selectedLocale);
    }

    // Premium durumunu uygula
    _preferences = _preferences.copyWith(
      premiumActive: premiumActive ?? _preferences.premiumActive,
      premiumPlanId: (premiumPlanId != null && premiumPlanId.isNotEmpty)
          ? premiumPlanFromString(premiumPlanId)
          : _preferences.premiumPlanId,
      premiumExpiresAt: premiumExpiresAt ?? _preferences.premiumExpiresAt,
    );

    playback.updateAffirmations(currentFeed);
    playback.setCurrentIndex(_currentIndex); // ⭐ önemli

    _loaded = true;
    notifyListeners();

    print("✅ initialize() tamamlandı");
    print("📊 Final state:");
    print("   → Language: $_selectedLocale");
    print("   → Category: $_activeCategoryId");
    print("   → Theme: ${_preferences.selectedThemeId}");
    print("   → Gender: ${_preferences.gender}");
    print("   → Content Prefs: ${_preferences.selectedContentPreferences}");
    print("   → Premium: ${_preferences.isPremiumValid}");
  }

  // Genel feed = tüm kategoriler + gender filtresi
  List<Affirmation> get generalFeed => _allAffirmations
      .where((a) => matchGender(a, _preferences.gender))
      .toList();

  // Aktif kategoriye göre feed
  List<Affirmation> get categoryFeed => _allAffirmations
      .where((a) =>
          a.categoryId == _activeCategoryId &&
          matchGender(a, _preferences.gender))
      .toList();

  // Favoriler feed
  List<Affirmation> get favoritesFeed => _allAffirmations
      .where((a) =>
          _preferences.favoriteAffirmationIds.contains(a.id) &&
          matchGender(a, _preferences.gender))
      .toList();

  // Eski kodda varsa diye bıraktım, generalFeed'e delege ettim
  List<Affirmation> get homeFeed => generalFeed;

  // Şu an gösterilecek gerçek feed
  List<Affirmation> get currentFeed {
    if (_activeCategoryId.isEmpty) return generalFeed;
    if (_activeCategoryId == generalCategoryId) return generalFeed;
    if (_activeCategoryId == favoritesCategoryId) return favoritesFeed;
    return categoryFeed;
  }

  void setLocale(String code) {
    _selectedLocale = code;
    notifyListeners();
  }

  void setCurrentIndex(int index) {
    _currentIndex = index;
  }

  Future<void> playThemeSound() async {
    final theme = activeTheme;
    if (!isSoundEnabled || theme.soundAsset == null) {
      await _audioPlayer.stop();
      return;
    }

    await _audioPlayer.stop();
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource(theme.soundAsset!));
  }

  void toggleSound() {
    isSoundEnabled = !isSoundEnabled;
    playThemeSound();
    notifyListeners();
  }

  void setVolume(double v) {
    _audioPlayer.setVolume(v);
    print("🔊 Volume updated → $v");
    notifyListeners();
  }

  // CATEGORIES + THEMES
  //────────────────────────────────────────

  List<AffirmationCategory> get categories {
    // orijinal listeyi kopyala
    final base = List<AffirmationCategory>.from(_categories);

    // Eklemek istediğin özel kategoriler
    const extraCategories = [
      AffirmationCategory(
        id: generalCategoryId,
        name: 'General',
        imageAsset: 'assets/data/categories/general.jfif',
        isPremiumLocked: false,
      ),
      AffirmationCategory(
        id: favoritesCategoryId,
        name: 'My Favorites',
        imageAsset: 'assets/data/categories/favorites.jfif',
        isPremiumLocked: false,
      ),
      AffirmationCategory(
        id: favoritesCategoryId,
        name: 'My Own Affirmations',
        imageAsset: 'assets/data/categories/favorites.jfif',
        isPremiumLocked: false,
      ),
    ];

    // 🔥 TEK SEFERDE ekle (her çağrıda kopya listeye ekleniyor, orijinali bozmuyor)
    base.insertAll(1, extraCategories);

    return base;
  }

  List<ThemeModel> get themes => _themes;
  UserPreferences get preferences => _preferences;
  String get activeCategoryId => _activeCategoryId;
  int get currentIndex => _currentIndex;
  bool get isFabExpanded => _fabExpanded;
  List<Affirmation> get allAffirmations => _allAffirmations;

  void setUserName(String name) async {
    _preferences = _preferences.copyWith(userName: name);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    prefs.setString("userName", name);
  }

  String get activeThemeImage {
    final theme = _themes.firstWhere(
      (t) => t.id == _preferences.selectedThemeId,
      orElse: () => _themes.first,
    );
    return theme.imageAsset;
  }

  ThemeModel get activeTheme {
    return _themes.firstWhere(
      (t) => t.id == _preferences.selectedThemeId,
      orElse: () => _themes.first,
    );
  }

  bool canAccessCategory(AffirmationCategory category) {
    if (!category.isPremiumLocked) return true;
    return _preferences.isPremiumValid;
  }

  bool canAccessTheme(ThemeModel theme) {
    if (!theme.isPremiumLocked) return true;
    return _preferences.isPremiumValid;
  }

  // SAVE / LOAD
  //────────────────────────────────────────

  Future<void> saveLastSettings() async {
    print("💾 saveLastSettings()");

    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('lastCategory', _activeCategoryId);
      await prefs.setString('lastTheme', _preferences.selectedThemeId);
      await prefs.setString('lastLanguage', _preferences.languageCode);
      await prefs.setString(
        'lastContentPreferences',
        _preferences.selectedContentPreferences.join(','),
      );
      await prefs.setInt('lastAffirmationIndex', _currentIndex);

      await prefs.setBool('premiumActive', _preferences.premiumActive);
      await prefs.setString('premiumPlanId',
          premiumPlanToString(_preferences.premiumPlanId) ?? '');
      await prefs.setString(
        'premiumExpiresAt',
        _preferences.premiumExpiresAt?.toIso8601String() ?? '',
      );

      print(
          "✔ Kaydedildi → category=$_activeCategoryId | theme=${_preferences.selectedThemeId} | prefs=${_preferences.selectedContentPreferences}");
    } catch (e) {
      print("❌ SAVE ERROR: $e");
    }
  }

  Future<void> saveOnboardingData() async {
    print("🔥 saveOnboardingData()");

    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool("onboarding_completed", true);
    await prefs.setString("onboard_gender", onboardingGender ?? "");
    await prefs.setStringList("onboard_prefs", onboardingContentPrefs.toList());
    await prefs.setInt("onboard_theme", onboardingThemeIndex ?? 0);
    await prefs.setString("onboard_name", onboardingName ?? "");
    await prefs.setInt('lastAffirmationIndex', 0);

    await prefs.remove('lastContentPreferences');

    // Gender
    if (onboardingGender != null && onboardingGender!.isNotEmpty) {
      _preferences = _preferences.copyWith(
        gender: genderFromString(onboardingGender!),
      );
    }

    // Content preferences
    _preferences = _preferences.copyWith(
      selectedContentPreferences: onboardingContentPrefs,
    );

    await prefs.setString(
      'lastContentPreferences',
      onboardingContentPrefs.join(','),
    );

    // Theme
    if (onboardingThemeIndex != null &&
        onboardingThemeIndex! < _themes.length) {
      final themeId = _themes[onboardingThemeIndex!].id;
      _preferences = _preferences.copyWith(selectedThemeId: themeId);
      await prefs.setString('lastTheme', themeId);
      print("🎨 Saved theme → $themeId");
    }

    // Active category
    if (_categories.isNotEmpty) {
      _activeCategoryId = _categories.first.id;
      await prefs.setString('lastCategory', _activeCategoryId);
    }

    _currentIndex = 0;

    onboardingCompleted = true;

    notifyListeners();

    print("✅ Onboarding data saved successfully!");
  }

  Future<void> loadLastSettings() async {
    print("📥 loadLastSettings()");

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();

      print("🔥 HOME prefs:");
      print("➡ lastCategory = ${prefs.getString('lastCategory')}");
      print("➡ lastTheme = ${prefs.getString('lastTheme')}");
      print("➡ lastLanguage = ${prefs.getString('lastLanguage')}");
      print(
          "➡ lastContentPrefs = ${prefs.getString('lastContentPreferences')}");
      print("➡ lastIndex = ${prefs.getInt('lastAffirmationIndex')}");

      onboardingCompleted = prefs.getBool("onboarding_completed") ?? false;
      onboardingGender = prefs.getString("onboard_gender");
      onboardingContentPrefs =
          (prefs.getStringList("onboard_prefs") ?? []).toSet();
      onboardingThemeIndex = prefs.getInt("onboard_theme");

      print("🔥 ONBOARDING prefs:");
      print("➡ completed = $onboardingCompleted");
      print("➡ gender = $onboardingGender");
      print("➡ prefs = $onboardingContentPrefs");
      print("➡ themeIndex = $onboardingThemeIndex");

      final lastCategory = prefs.getString('lastCategory');
      final lastTheme = prefs.getString('lastTheme');
      final lastLanguage = prefs.getString('lastLanguage');
      final lastContentPrefs = prefs.getString('lastContentPreferences');
      final lastIndex = prefs.getInt('lastAffirmationIndex');

      final premiumActive = prefs.getBool('premiumActive');
      final premiumPlanId = prefs.getString('premiumPlanId');
      final premiumExpiresAtStr = prefs.getString('premiumExpiresAt');
      DateTime? premiumExpiresAt;
      if (premiumExpiresAtStr != null && premiumExpiresAtStr.isNotEmpty) {
        premiumExpiresAt = DateTime.tryParse(premiumExpiresAtStr);
      }

      if (onboardingGender != null && onboardingGender!.isNotEmpty) {
        _preferences = _preferences.copyWith(
          gender: genderFromString(onboardingGender!),
        );
      }

      if (lastCategory != null && lastCategory.isNotEmpty) {
        _activeCategoryId = lastCategory;
      }

      if (lastTheme != null && lastTheme.isNotEmpty) {
        _preferences = _preferences.copyWith(selectedThemeId: lastTheme);
      }

      if (lastLanguage != null && lastLanguage.isNotEmpty) {
        _preferences = _preferences.copyWith(languageCode: lastLanguage);
        _selectedLocale = lastLanguage;
      }

      if (lastContentPrefs != null && lastContentPrefs.isNotEmpty) {
        _preferences = _preferences.copyWith(
          selectedContentPreferences:
              Set<String>.from(lastContentPrefs.split(',')),
        );
      }

      if (lastIndex != null) {
        _currentIndex = lastIndex;
      } else {
        _currentIndex = 0;
      }

      playback.setCurrentIndex(_currentIndex);

      _preferences = _preferences.copyWith(
        premiumActive: premiumActive ?? _preferences.premiumActive,
        premiumPlanId: (premiumPlanId != null && premiumPlanId.isNotEmpty)
            ? premiumPlanFromString(premiumPlanId)
            : _preferences.premiumPlanId,
        premiumExpiresAt: premiumExpiresAt ?? _preferences.premiumExpiresAt,
      );
    } catch (e) {
      print("❌ LOAD ERROR: $e");
    }
  }

  // PAGE + AFFIRMATION
  //────────────────────────────────────────

  int get pageCount => currentFeed.isEmpty ? 1 : currentFeed.length;

  Affirmation? affirmationAt(int index) {
    final list = currentFeed;
    if (list.isEmpty) return null;
    if (index < 0 || index >= list.length) {
      print(
          "⚠️ WARNING: affirmationAt($index) → NULL (limit = ${currentFeed.length})");

      return null;
    }
    return list[index];
  }

  // CATEGORY CHANGE
  //────────────────────────────────────────

  Future<void> setActiveCategory(String id) async {
    print("📌 Category changed: $id");

    if (_activeCategoryId == id) {
      assignRandomIndex();
      return;
    }

    if (id != favoritesCategoryId) {
      final category = _categories.firstWhere(
        (c) => c.id == id,
        orElse: () => _categories.first,
      );

      if (!canAccessCategory(category)) {
        print("⛔ Premium değil → kategori kilitli");
        return;
      }
    }

    _activeCategoryId = id;
    _currentIndex = 0;

    assignRandomIndex();

    notifyListeners();
    saveLastSettings();

    playback.updateAffirmations(currentFeed);
  }

  // Eski kodda da kalmış, generalFeed ile uyumlu hale getirdik
  List<Affirmation> get homeFeedRaw {
    final gender = preferences.gender;

    return _allAffirmations.where((a) {
      if (a.gender == "any") return true;
      if (gender == Gender.none) return true;
      if (gender == Gender.male) return a.gender == "male";
      if (gender == Gender.female) return a.gender == "female";
      return true;
    }).toList();
  }

  //────────────────────────────────────────
  // RANDOM INDEX
  //────────────────────────────────────────

  void assignRandomIndex() {
    if (_allAffirmations.isEmpty) {
      _currentIndex = 0;
      playback.setCurrentIndex(0);
      return;
    }

    final frandomIndex = randomIndex(_allAffirmations.length);
    print("🎲 Random index = $frandomIndex");

    _currentIndex = frandomIndex;
    playback.setCurrentIndex(frandomIndex);
  }

  //────────────────────────────────────────
  // UI STATE
  //────────────────────────────────────────

  void toggleFabExpanded() {
    _fabExpanded = !_fabExpanded;
    notifyListeners();
  }

  //────────────────────────────────────────
  // FAVORITES
  //────────────────────────────────────────

  bool isOverFavoriteLimit() {
    final isPremium = preferences.isPremiumValid;
    final currentCount = _preferences.favoriteAffirmationIds.length;
    return !isPremium && currentCount >= 5;
  }

  void toggleFavorite(String id) {
    final favs = Set<String>.from(_preferences.favoriteAffirmationIds);

    if (favs.contains(id)) {
      favs.remove(id);
    } else {
      favs.add(id);
    }

    _preferences = _preferences.copyWith(
      favoriteAffirmationIds: favs,
    );

    notifyListeners();
    saveLastSettings();
  }

  bool isFavorite(String id) {
    return _preferences.favoriteAffirmationIds.contains(id);
  }

  //────────────────────────────────────────
  // PREFS / THEME / LANGUAGE / PREMIUM
  //────────────────────────────────────────

  void setSelectedContentPreferences(Set<String> prefs) {
    print("🎯 Content prefs changed → $prefs");
    _preferences = _preferences.copyWith(selectedContentPreferences: prefs);
    notifyListeners();
    saveLastSettings();

    playback.updateAffirmations(currentFeed);
  }

  Future<void> setSelectedTheme(String id) async {
    final theme =
        _themes.firstWhere((t) => t.id == id, orElse: () => _themes.first);

    if (!canAccessTheme(theme)) {
      print("⛔ Premium değil → tema kilitli");
      return;
    }

    print("🎨 Theme changed → $id");

    _preferences = _preferences.copyWith(selectedThemeId: id);

    await playThemeSound();

    notifyListeners();

    await saveLastSettings();
  }

  Future<void> setLanguage(String code) async {
    print("🟥 AppState.setLanguage() CALLED → $code");

    _selectedLocale = code;
    _preferences = _preferences.copyWith(languageCode: code);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("lastLanguage", code);

    print("🟥 Language saved to SharedPreferences");

    _repository = AppRepository(languageCode: code);

    try {
      print("🟥 Loading JSON for language = $code");

      final bundle = await _repository.load();
      print("🟩 JSON LOADED SUCCESSFULLY");

      _themes = bundle.themes;
      _categories = bundle.categories;

      // Aktif kategori yeni listede yoksa fallback
      if (_categories.isNotEmpty &&
          !_categories.any((c) => c.id == _activeCategoryId)) {
        _activeCategoryId = _categories.first.id;
      }
    } catch (e) {
      print("❌ JSON LOAD ERROR: $e");
    }

    print("🟥 Calling notifyListeners()");
    notifyListeners();
  }

  Future<void> updatePremiumStatus({
    required bool active,
    PremiumPlan? planId,
    DateTime? expiresAt,
  }) async {
    _preferences = _preferences.copyWith(
      premiumActive: active,
      premiumPlanId: planId,
      premiumExpiresAt: expiresAt,
    );

    notifyListeners();
    await saveLastSettings();

    print(
        "💎 Premium güncellendi → active=$active, plan=$planId, expiresAt=$expiresAt");
  }

  //────────────────────────────────────────
  // PAGE ITEMS (AFFIRMATION + CTA)
  //────────────────────────────────────────

  List<Map<String, dynamic>> get pagedItems {
    return _buildPagedItems(
      affirmations: currentFeed,
      isPremium: _preferences.isPremiumValid,
    );
  }

  List<Map<String, dynamic>> _buildPagedItems({
    required List<Affirmation> affirmations,
    required bool isPremium,
  }) {
    final List<Map<String, dynamic>> items = [];

    for (int i = 0; i < affirmations.length; i++) {
      items.add({
        "type": "affirmation",
        "data": affirmations[i],
        "realIndex": i,
      });
    }

    // FREE kullanıcı → en sona CTA kartı
    // if (!isPremium) {
    //   items.add({"type": "cta_premium"});
    // }

    return items;
  }
}
