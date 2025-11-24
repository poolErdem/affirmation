import 'package:affirmation/data/preferences.dart';
import 'package:affirmation/ui/screens/premium_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_html/html.dart' as html;
import 'package:audioplayers/audioplayers.dart';

import '../data/app_repository.dart';
import '../models/affirmation.dart';
import '../models/category.dart';
import '../models/theme_model.dart';
import '../models/user_preferences.dart';

class AppState extends ChangeNotifier {
  static const String favoritesCategoryId = 'favorites';

  late AppRepository _repository;

  String _selectedLocale = "en"; // default
  String get selectedLocale => _selectedLocale;

  /// Tüm diller & kategoriler için yüklenen affirmations (aktif dil için)
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

  AppState();

  bool get isLoaded => _loaded;

  void setLocale(String code) {
    _selectedLocale = code;
    notifyListeners();
  }

  void initializePurchaseListener() {
    InAppPurchase.instance.purchaseStream.listen((purchases) {
      for (final p in purchases) {
        if (p.status == PurchaseStatus.purchased ||
            p.status == PurchaseStatus.restored) {
          updatePremiumStatus(
            active: true,
            planId: premiumPlanFromString(p.productID),
            expiresAt: DateTime.now().add(const Duration(days: 365)),
          );

          InAppPurchase.instance.completePurchase(p);

          print("💎 Premium aktif edildi → ${p.productID}");
        }

        if (p.status == PurchaseStatus.error) {
          print("❌ Purchase error: ${p.error}");
        }
      }
    });
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

  List<AffirmationCategory> get categories {
    // orijinal listeyi kopyala
    final base = List<AffirmationCategory>.from(_categories);

    // Favorites kategorisi
    const fav = AffirmationCategory(
      id: favoritesCategoryId,
      name: 'My Favorites',
      imageAsset: 'assets/data/categories/favorites.jfif',
      isPremiumLocked: false,
    );

    // 🔥 2. sıraya koy (index=1)
    base.insert(1, fav);

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

  Future<void> saveLastSettings() async {
    print("💾 saveLastSettings()");

    try {
      if (kIsWeb) {
        html.window.localStorage['lastCategory'] = _activeCategoryId;
        html.window.localStorage['lastTheme'] = _preferences.selectedThemeId;
        html.window.localStorage['lastLanguage'] = _preferences.languageCode;
        html.window.localStorage['lastContentPreferences'] =
            _preferences.selectedContentPreferences.join(',');
        html.window.localStorage['lastAffirmationIndex'] =
            _currentIndex.toString();
      } else {
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
      }

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

    // ‼️ EKSİK OLAN KESİNLİKLE BUYDİ
    //await _preferences.save();

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

  /// Yeni JSON mimarisi (her kategori ayrı dosya) ile
  /// tüm kategoriler için affirmations'ı tek listeye doldurur.
  Future<void> _reloadAllAffirmationsForLanguage() async {
    print("📚 _reloadAllAffirmationsForLanguage()");

    final List<Affirmation> result = [];

    for (final c in _categories) {
      if (c.id == favoritesCategoryId) continue;
      try {
        final items = await _repository.loadCategoryItems(c.id);
        result.addAll(items);
      } catch (e) {
        print("❌ Category load error for ${c.id}: $e");
      }
    }

    _allAffirmations = result;
    print(
        "✅ All affirmations loaded for language=$_selectedLocale → ${_allAffirmations.length} items");
  }

  List<Affirmation> get _filteredAffirmations {
    print("🔥 FILTER START");
    print("➡ Category              = $_activeCategoryId");
    print("➡ Gender                = ${_preferences.gender}");
    print(
        "➡ Prefs (new)           = ${_preferences.selectedContentPreferences}");
    print("➡ Onboarding prefs      = $onboardingContentPrefs");

    final prefsSet = _preferences.selectedContentPreferences;
    String? userGender = genderToString(_preferences.gender);

    // FAVORITES MODE → fallback yok!
    if (_activeCategoryId == favoritesCategoryId) {
      final favIds = _preferences.favoriteAffirmationIds;

      final favList =
          _allAffirmations.where((a) => favIds.contains(a.id)).toList();

      print("⭐ FAVORITES MODE: ${favList.length} items (fallback kapalı!)");
      return favList;
    }

    bool matchesGender(Affirmation a) {
      if (a.gender == "any") return true;
      if (userGender == "none") return true;
      return a.gender == userGender;
    }

    bool matchesPrefs(Affirmation a) {
      if (prefsSet.isEmpty) return true;
      return a.preferences.any((p) => prefsSet.contains(p));
    }

    // F1: CATEGORY + GENDER + PREFS
    final f1 = _allAffirmations
        .where((a) =>
            a.categoryId == _activeCategoryId &&
            matchesGender(a) &&
            matchesPrefs(a))
        .toList();

    print("🔍 F1 (category + gender + prefs) = ${f1.length}");
    if (f1.isNotEmpty) {
      print("✅ F1 kullanıldı (full match)");
      return f1;
    }

    // F2: CATEGORY + GENDER
    final f2 = _allAffirmations
        .where((a) => a.categoryId == _activeCategoryId && matchesGender(a))
        .toList();

    print("🔍 F2 (category + gender) = ${f2.length}");
    if (f2.isNotEmpty) {
      print("⚠️ F1 boş → F2 kullanıldı (prefs ignore)");
      return f2;
    }

    // F3: GENDER ONLY
    final f3 = _allAffirmations.where((a) => matchesGender(a)).toList();
    print("🔍 F3 (gender only) = ${f3.length}");
    if (f3.isNotEmpty) {
      print("⚠️ F2 boş → F3 kullanıldı (category fallback)");
      return f3;
    }

    // F4: EVERYTHING
    print("⚠️ No match → FULL fallback (çok nadir)");
    return _allAffirmations;
  }

  int get pageCount =>
      _filteredAffirmations.isEmpty ? 1 : _filteredAffirmations.length;

  Affirmation? affirmationAt(int index) {
    final list = _filteredAffirmations;
    if (list.isEmpty) return null;
    if (index < 0 || index >= list.length) {
      print(
          "⚠️ WARNING: affirmationAt($index) → NULL (limit = ${_filteredAffirmations.length})");

      return null;
    }
    return list[index];
  }

  // UYGULAMA BAŞLATMA - 3 SENARYO
  Future<void> initialize() async {
    print("🔥 initialize()");

    final prefs = await SharedPreferences.getInstance();
    print(
        "📌 PREFS = ${prefs.getKeys().map((k) => "$k=${prefs.get(k)}").join(" | ")}");

    String lang = prefs.getString("lastLanguage") ?? "en";
    _selectedLocale = lang;
    _repository = AppRepository(languageCode: lang);

    final bundle = await _repository.load();

    _themes = bundle.themes;
    _categories = bundle.categories;

    // Eski mimari ile kompat: Eğer repository affirmations döndürüyorsa al,
    // döndürmüyorsa yeni mimariye göre tüm kategorileri tek tek yükle.
    _allAffirmations = bundle.affirmations;
    if (_allAffirmations.isEmpty) {
      await _reloadAllAffirmationsForLanguage();
    }

    _preferences = UserPreferences.initial(
      defaultThemeId: _themes.first.id,
      allCategoryIds: _categories.map((c) => c.id).toSet(),
      allContentPreferenceIds: allContentPreferenceIds.toSet(),
    );

    // Onboarding durumunu kontrol et
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

    // Premium bilgilerini yükle
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

    // Kategori kontrolü
    if (_activeCategoryId.isEmpty && _categories.isNotEmpty) {
      _activeCategoryId = _categories.first.id;
    }

    // Premium kilitli kategorideyse → free kategoriye geç
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

    // Premium kilitli temadaysa → free temaya geç
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

    // Dil kontrolü
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

    _loaded = true;
    notifyListeners();

    initializePurchaseListener();

    print("✅ initialize() tamamlandı");
    print("📊 Final state:");
    print("   → Category: $_activeCategoryId");
    print("   → Theme: ${_preferences.selectedThemeId}");
    print("   → Gender: ${_preferences.gender}");
    print("   → Content Prefs: ${_preferences.selectedContentPreferences}");
    print("   → Premium: ${_preferences.isPremiumValid}");
  }

  Future<void> setActiveCategory(String id) async {
    print("📌 Category changed: $id");

    if (_activeCategoryId == id) return;

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
    notifyListeners();
    saveLastSettings();
  }

  void onPageChanged(int index) {
    _currentIndex = index;
    notifyListeners();
    saveLastSettings();
  }

  void toggleFabExpanded() {
    _fabExpanded = !_fabExpanded;
    notifyListeners();
  }

// FAVORITE TOGGLE (limit + dialog + save)
  void toggleFavoriteForCurrent(BuildContext context) {
    final aff = affirmationAt(currentIndex);
    if (aff == null) return;

    final isPremium = preferences.isPremiumValid;
    final currentCount = _preferences.favoriteAffirmationIds.length;

    // Limit kontrolü (FREE için 5)
    if (!isPremium && currentCount >= 5) {
      _showFavoriteLimitDialog(context, isPremium);
      return;
    }

    toggleFavorite(aff.id);
  }

// TEK FAVORİ EKLE/SİL
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

  void _showFavoriteLimitDialog(BuildContext context, bool isPremium) {
    final limit = isPremium ? 50 : 5;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Favorites Limit"),
        content: Text(
          isPremium
              ? "You've reached the maximum favorites limit ($limit)."
              : "You've reached your free favorites limit ($limit).\n\nUpgrade to Premium for up to 50 favorites ✨",
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
          if (!isPremium)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PremiumScreen()),
                );
              },
              child: const Text(
                "Upgrade",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  void setSelectedContentPreferences(Set<String> prefs) {
    print("🎯 Content prefs changed → $prefs");
    _preferences = _preferences.copyWith(selectedContentPreferences: prefs);
    _currentIndex = 0;
    notifyListeners();
    saveLastSettings();
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

    // ✨ Ses değişimi ASYNC → beklemelisin
    await playThemeSound();

    notifyListeners();

    // ✨ Settings kaydı ASYNC → beklemelisin
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

      _allAffirmations = bundle.affirmations;
      if (_allAffirmations.isEmpty) {
        await _reloadAllAffirmationsForLanguage();
      }

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

  bool isFavorite(String id) {
    return _preferences.favoriteAffirmationIds.contains(id);
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

// 🔥 PageView için final item listesi
  List<Map<String, dynamic>> get pagedItems {
    return _buildPagedItems(
      affirmations: _filteredAffirmations, // ✔ sende var
      isPremium: _preferences.isPremiumValid, // ✔ sende var
    );
  }

// 🔥 İç mantık (affirmation + CTA kartı)
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
    if (!isPremium) {
      items.add({"type": "cta_premium"});
    }

    return items;
  }
}

// PREMIUM CHECK EXTENSION
extension UserPremiumExt on UserPreferences {
  bool get isPremiumValid {
    if (!premiumActive) return false;
    if (premiumExpiresAt == null) return true;
    return premiumExpiresAt!.isAfter(DateTime.now());
  }
}
