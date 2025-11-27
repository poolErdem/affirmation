import 'dart:async';
import 'package:affirmation/data/preferences.dart';
import 'package:affirmation/models/reminder.dart';
import 'package:affirmation/state/playback_state.dart';
import 'package:affirmation/state/purchase_state.dart';
import 'package:affirmation/utils/affirmation_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

import '../data/app_repository.dart';
import '../models/affirmation.dart';
import '../models/category.dart';
import '../models/theme_model.dart';
import '../models/user_preferences.dart';

class AppState extends ChangeNotifier {
  // Premium product IDs (tek doğru yer)
  static const String kMonthly = "premium_monthly";
  static const String kYearly = "premium_yearly";
  static const String kLifetime = "premium_lifetime";

  static const String favoritesCategoryId = 'favorites';
  static const String generalCategoryId = 'general';
  static const String myCategoryId = 'myaffirmations';

  static const int freeFavoriteLimit = 5;
  static const int premiumFavoriteLimit = 500;

  List<Affirmation> _cachedGeneral = [];
  bool _generalDirty = true;

  late AppRepository _repository;

  String _selectedLocale = "en";
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

  Set<String> _activeCategoryIds = {};
  Set<String> get activeCategoryIds => _activeCategoryIds;

  final AudioPlayer _audioPlayer = AudioPlayer();

  static const List<String> allContentPreferenceIds = ContentPreferences.all;

  bool onboardingCompleted = false;
  String? onboardingGender;
  Set<String> onboardingContentPrefs = {};
  int? onboardingThemeIndex;
  String? onboardingName;

  static const supportedLanguages = ['en', 'tr'];

  //final playback = PlaybackState();
  late PlaybackState _playback;

  late PurchaseState purchaseState;

  AppState() {
    _playback = PlaybackState();
    // ⭐ PlaybackState değiştiğinde AppState'i de güncelle
    _playback.addListener(() {
      notifyListeners();
    });

    purchaseState = PurchaseState(this);
  }

  PlaybackState get playback => _playback;
  bool get isLoaded => _loaded;

  @override
  void dispose() {
    _playback.dispose();
    purchaseState.dispose(); // dispose async olduğu için await edemiyoruz
    super.dispose();
  }

  // INITIALIZE
  Future<void> initialize() async {
    print("🔥 initialize()");

    final prefs = await SharedPreferences.getInstance();
    print(
        "📌 PREFS = ${prefs.getKeys().map((k) => "$k=${prefs.get(k)}").join(" | ")}");

    // 1️⃣ LANGUAGE RESOLUTION (saved → device → fallback)
    final savedLang = prefs.getString("lastLanguage");
    final deviceLang = PlatformDispatcher.instance.locale.languageCode;

    String resolvedLang;

    if (savedLang != null && savedLang.isNotEmpty) {
      resolvedLang = savedLang;
    } else if (supportedLanguages.contains(deviceLang)) {
      resolvedLang = deviceLang;
    } else {
      resolvedLang = "en";
    }

    _selectedLocale = resolvedLang;
    playback.setLanguage(_selectedLocale);

    print("🌐 Dil: → $resolvedLang");

    // 2️⃣ REPOSITORY LOAD (categories + themes + affirmations)
    _repository = AppRepository(languageCode: resolvedLang);

    final bundle = await _repository.load();
    _categories = bundle.categories;
    _themes = bundle.themes;

    _allAffirmations = await _repository.loadAllCategoriesItems();
    print(
        "🟢 ALL data loaded. Category count= ${_categories.length} , Affirmation count=${_allAffirmations.length}");

    // 3️⃣ ONBOARDING & OLD PREFS LOAD
    onboardingCompleted = prefs.getBool("onboarding_completed") ?? false;

    if (onboardingCompleted) {
      await loadLastSettings();
    } else if (_hasValidPrefs(prefs)) {
      await loadLastSettings();
    } else {
      _preferences = UserPreferences.initial(
        defaultThemeId: _themes.isNotEmpty ? _themes.first.id : "",
        allCategoryIds: _categories.map((c) => c.id).toSet(),
        allContentPreferenceIds: allContentPreferenceIds.toSet(),
      );
    }

    // 4️⃣ PREMIUM OVERRIDE (prefs içindeki premium değerlerini okuyup uygula)
    final premiumActive = prefs.getBool('premiumActive');
    final premiumPlanId = prefs.getString('premiumPlanId');
    final premiumExpiresAtStr = prefs.getString('premiumExpiresAt');

    DateTime? premiumExpiresAt =
        premiumExpiresAtStr != null && premiumExpiresAtStr.isNotEmpty
            ? DateTime.tryParse(premiumExpiresAtStr)
            : null;

    _preferences = _preferences.copyWith(
      premiumActive: premiumActive ?? _preferences.premiumActive,
      premiumPlanId: (premiumPlanId != null && premiumPlanId.isNotEmpty)
          ? premiumPlanFromString(premiumPlanId)
          : _preferences.premiumPlanId,
      premiumExpiresAt: premiumExpiresAt ?? _preferences.premiumExpiresAt,
    );

    // 5️⃣ CATEGORY VALIDATION & PREMIUM FALLBACK
    if (_activeCategoryId.isEmpty && _categories.isNotEmpty) {
      _activeCategoryId = _categories.first.id;
    }

    final activeCategory = _categories.firstWhere(
      (c) => c.id == _activeCategoryId,
      orElse: () => _categories.first,
    );

    if (activeCategory.isPremiumLocked && !_preferences.isPremiumValid) {
      final fallback = _categories.firstWhere(
        (c) => !c.isPremiumLocked,
        orElse: () => _categories.first,
      );
      _activeCategoryId = fallback.id;
    }

    // 6️⃣ THEME VALIDATION & PREMIUM FALLBACK
    ThemeModel? activeTheme;
    if (_preferences.selectedThemeId.isNotEmpty) {
      activeTheme = _themes.firstWhere(
        (t) => t.id == _preferences.selectedThemeId,
        orElse: () => _themes.first,
      );
    } else if (_themes.isNotEmpty) {
      activeTheme = _themes.first;
    }

    if (activeTheme != null &&
        activeTheme.isPremiumLocked &&
        !_preferences.isPremiumValid) {
      final freeTheme = _themes.firstWhere(
        (t) => !t.isPremiumLocked,
        orElse: () => _themes.first,
      );
      _preferences = _preferences.copyWith(selectedThemeId: freeTheme.id);
    }

    // 7️⃣ LANGUAGE PREFERENCE FALLBACK
    if (_preferences.languageCode.isEmpty) {
      _preferences = _preferences.copyWith(languageCode: _selectedLocale);
    }

    // 8️⃣ PLAYBACK
    playback.updateAffirmations(currentFeed);
    playback.setCurrentIndex(_currentIndex);

    await purchaseState.initialize();
    await purchaseState.fetchProducts();

    _loaded = true;
    _generalDirty = true;

    notifyListeners();

    print("✅ initialize() tamamlandı");
    print("📊 Final state:");
    print("   → Aktif Category: $_activeCategoryId");
    print("   → Gender: ${_preferences.gender}");
    print("   → Content Prefs: ${_preferences.selectedContentPreferences}");
    print("   → Premium: ${_preferences.isPremiumValid}");
  }

// ===============================
  // PREMIUM UPDATE FROM PURCHASESTATE
  // ===============================

  void updatePremium({
    required bool active,
    required PremiumPlan plan,
    required DateTime? expiry,
  }) async {
    _preferences = _preferences.copyWith(
      premiumActive: active,
      premiumPlanId: plan,
      premiumExpiresAt: expiry,
    );

    // storage
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool("premiumActive", false);
    prefs.setString("premiumPlanId", plan.name);
    prefs.setString("premiumExpiresAt", expiry?.toIso8601String() ?? "");

    notifyListeners();
  }

  bool _hasValidPrefs(SharedPreferences prefs) {
    return prefs.containsKey("selectedThemeId") ||
        prefs.containsKey("gender") ||
        prefs.containsKey("selectedContentPreferences") ||
        prefs.containsKey("premiumActive");
  }

  List<Affirmation> get generalFeed {
    if (_generalDirty) {
      _cachedGeneral = _calculateGeneralFeed();
      _generalDirty = false;
    }
    return _cachedGeneral;
  }

  // Genel feed = tüm kategoriler + gender + seçilen kategoriler filtresi
  List<Affirmation> _calculateGeneralFeed() {
    print('📌 [GENERAL FEED] Başladı');
    print('➡ Gender: ${_preferences.gender}');
    print('➡ Selected categories: ${_preferences.selectedContentPreferences}');

    // Kullanıcının seçtiği kategoriler + gender
    final list = _allAffirmations.where((a) {
      final genderOk = matchGender(a, _preferences.gender);

      final categoryOk =
          _preferences.selectedContentPreferences.contains(a.categoryId);

      return genderOk && categoryOk;
    }).toList();

    if (!_preferences.premiumActive && list.length > 200) {
      print('✅ GENERAL FEED (200 sınırı) toplam: ${list.length}');
      return list.take(200).toList();
    }

    print('✅ GENERAL FEED toplam: ${list.length}');

    return list;
  }

  // Aktif kategoriye ve gender a göre feed
  List<Affirmation> get categoryFeed {
    print('📌 [CATEGORY FEED] Başladı → $_activeCategoryId');

    final list = _allAffirmations.where((a) {
      return a.categoryId == _activeCategoryId &&
          matchGender(a, _preferences.gender);
    }).toList();

    print('✅ CATEGORY FEED toplam: ${list.length}');
    return list;
  }

  // Favoriler feed
  List<Affirmation> get favoritesFeed {
    print('📌 [FAVORITE FEED] Başladı');

    final list = _allAffirmations.where((a) {
      return _preferences.favoriteAffirmationIds.contains(a.id);
    }).toList();

    print('✅ FOVORITE FEED toplam: ${list.length}');
    return list;
  }

  // Kendi feed lerim
  List<Affirmation> get myFeed {
    print('📌 [MY FEED] Başladı');

    final list = _allAffirmations.where((a) {
      return _preferences.myAffirmationIds.contains(a.id);
    }).toList();
    print('✅ MY FEED toplam: ${list.length}');

    return list;
  }

  // Şu an gösterilecek gerçek feed
  List<Affirmation> get currentFeed {
    // GENERAL boş veya unset → general
    if (_activeCategoryId.isEmpty) return generalFeed;
    if (_activeCategoryId == generalCategoryId) return generalFeed;

    // FAVORITES
    if (_activeCategoryId == favoritesCategoryId) {
      final fav = favoritesFeed;

      if (fav.isEmpty) {
        return [
          Affirmation(
            id: "empty_fav",
            text: "Your favorites are empty.",
            categoryId: favoritesCategoryId,
            gender: "none",
            preferences: const [],
            isPremium: false,
            language: selectedLocale,
          ),
        ];
      }

      return fav;
    }

    // MY AFFIRMATIONS
    if (_activeCategoryId == myCategoryId) {
      final mine = myFeed;

      if (mine.isEmpty) {
        return [
          Affirmation(
            id: "empty_my",
            text: "You haven't added any custom affirmations yet.",
            categoryId: myCategoryId,
            gender: "none",
            preferences: const [],
            isPremium: false,
            language: selectedLocale,
          ),
        ];
      }

      return mine;
    }

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
  // CATEGORIES + THEMES
  List<AffirmationCategory> get categories {
    // Özel kategoriler
    final base = [
      const AffirmationCategory(
        id: generalCategoryId,
        name: 'General',
        imageAsset: 'assets/data/categories/general.jfif',
        isPremiumLocked: false,
      ),
      const AffirmationCategory(
        id: favoritesCategoryId,
        name: 'My Favorites',
        imageAsset: 'assets/data/categories/favorites.jfif',
        isPremiumLocked: false,
      ),
      const AffirmationCategory(
        id: myCategoryId,
        name: 'My Affirmations',
        imageAsset: 'assets/data/categories/myAffirmations.jfif',
        isPremiumLocked: false,
      ),
    ];

    // Değiştirilebilir liste oluştur
    final result = List<AffirmationCategory>.from(base);

    // _categories'i index 3'ten başlayarak ekle
    result.addAll(_categories);

    return result;
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

      await prefs.setBool('premiumActive', false);
      await prefs.setString('premiumPlanId',
          premiumPlanToString(_preferences.premiumPlanId) ?? '');
      await prefs.setString(
        'premiumExpiresAt',
        _preferences.premiumExpiresAt?.toIso8601String() ?? '',
      );

      prefs.setString(
        "favoriteAffirmationIds",
        _preferences.favoriteAffirmationIds.join(','),
      );
      prefs.setString(
        "myAffirmationIds",
        _preferences.myAffirmationIds.join(','),
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

      onboardingCompleted = prefs.getBool("onboarding_completed") ?? false;
      onboardingGender = prefs.getString("onboard_gender");
      onboardingContentPrefs =
          (prefs.getStringList("onboard_prefs") ?? []).toSet();
      onboardingThemeIndex = prefs.getInt("onboard_theme");

      final lastTheme = prefs.getString('lastTheme');
      final lastLanguage = prefs.getString('lastLanguage');
      final lastContentPrefs = prefs.getString('lastContentPreferences');
      final lastIndex = prefs.getInt('lastAffirmationIndex');

      final premiumActive = prefs.getBool('premiumActive');
      final premiumPlanId = prefs.getString('premiumPlanId');
      final premiumExpiresAtStr = prefs.getString('premiumExpiresAt');
      final myList = prefs.getString("myAffirmationIds");
      final favIds = prefs.getString("favoriteAffirmationIds");

      final userName = prefs.getString("userName");
      // --------------------------------------------------------
      // 🟦 1) _preferences TEK SEFERDE OLUŞUYOR
      // --------------------------------------------------------
      _preferences = UserPreferences(
        selectedContentPreferences: lastContentPrefs != null
            ? Set<String>.from(lastContentPrefs.split(","))
            : <String>{},
        selectedThemeId: lastTheme ?? "",
        favoriteAffirmationIds:
            favIds != null ? Set<String>.from(favIds.split(",")) : <String>{},
        myAffirmationIds:
            myList != null ? Set<String>.from(myList.split(",")) : <String>{},
        languageCode: lastLanguage ?? "en",
        userName: userName ?? "",
        backgroundVolume: 0.5, // ⭐ REQUIRED
        gender: genderFromString(onboardingGender ?? "none"),

        premiumPlanId: premiumPlanId != null && premiumPlanId.isNotEmpty
            ? premiumPlanFromString(premiumPlanId)
            : null,
        premiumExpiresAt: premiumExpiresAtStr != null
            ? DateTime.tryParse(premiumExpiresAtStr)
            : null,
        premiumActive: premiumActive ?? false,
        reminders: [
          ReminderModel(
            id: "free_default",
            categoryIds: {"self_care"},
            startTime: const TimeOfDay(hour: 9, minute: 0),
            endTime: const TimeOfDay(hour: 21, minute: 0),
            repeatCount: 3,
            repeatDays: {1, 2, 3, 4, 5, 6, 7},
            enabled: true,
            isPremium: false,
          )
        ],
      );

      // --------------------------------------------------------
      // 🟧 2) KATEGORİ
      // --------------------------------------------------------
      _activeCategoryId = generalCategoryId;
      // --------------------------------------------------------
      // 🟨 3) INDEX
      // --------------------------------------------------------
      _currentIndex = lastIndex ?? 0;
      playback.setCurrentIndex(_currentIndex);

      // --------------------------------------------------------
      // 🟩 4) DİL (AppState’in kendi dili)
      // --------------------------------------------------------
      if (lastLanguage != null && lastLanguage.isNotEmpty) {
        _selectedLocale = lastLanguage;
      }
    } catch (e) {
      print("❌ LOAD ERROR: $e");
    }
  }

  // PAGE + AFFIRMATION
  int get pageCount => currentFeed.isEmpty ? 1 : currentFeed.length;

  Affirmation? affirmationAt(int index) {
    final list = currentFeed;
    if (list.isEmpty) return null;
    if (index < 0 || index >= list.length) {
      print(
          "⚠️ WARNING: affirmationAt($index) → NULL (limit = ${currentFeed.length})");

      return null;
    }
    print("📌 affirmationAt($index)  (limit = ${currentFeed.length})");
    return list[index];
  }

  // CATEGORY CHANGE
  Future<void> setActiveCategory(String id) async {
    print("📌 Category selected: $id");
    print(
        "⛔ Uygulama kategori listesindeki ilk kategori: ${_categories.first.id} ");

    if (_activeCategoryId == id) {
      assignRandomIndex();
      return;
    }

    if (id != favoritesCategoryId &&
        id != generalCategoryId &&
        id != myCategoryId) {
      final category = _categories.firstWhere(
        (c) => c.id == id,
        orElse: () => _categories.first,
      );

      if (!canAccessCategory(category)) {
        print("⛔ Premium değil → kategori kilitli");
        return;
      }
      _activeCategoryId = category.id;
    }

    _activeCategoryId = id;

    print("📌 Category changed: $_activeCategoryId");
    playback.updateAffirmations(currentFeed);

    assignRandomIndex();
    notifyListeners();
    saveLastSettings();
  }

  List<Affirmation> get affirmationsForActiveCategories {
    return allAffirmations.where((a) {
      final genderOk = matchGender(a, _preferences.gender);
      final matchesCategory = _activeCategoryIds.contains(a.categoryId);
      return genderOk && matchesCategory;
    }).toList();
  }

  void setActiveCategories(Set<String> categoryIds) {
    _activeCategoryIds = categoryIds;
    notifyListeners();
  }

  Affirmation? getRandomAffirmation() {
    final list = affirmationsForActiveCategories;
    if (list.isEmpty) return null;

    final frandomIndex = randomIndex(list.length);
    return list[frandomIndex];
  }

  // RANDOM INDEX
  void assignRandomIndex() {
    final feed = currentFeed; // mevcut cache'den alır
    if (_allAffirmations.isEmpty) {
      _currentIndex = 0;
      playback.setCurrentIndex(0);
      return;
    }

    final frandomIndex = randomIndex(feed.length);
    print(
        "Seçilen kategori: ${feed.first.categoryId} ve aff sayısı= ${feed.length} 🎲 Random index = $frandomIndex");

    _currentIndex = frandomIndex;
    playback.setCurrentIndex(frandomIndex);
  }

  // UI STATE
  void toggleFabExpanded() {
    _fabExpanded = !_fabExpanded;
    notifyListeners();
  }

// FAVORITES
  bool isOverFavoriteLimit() {
    final isPremium = _preferences.isPremiumValid;
    final currentCount = _preferences.favoriteAffirmationIds.length;

    final limit = isPremium ? premiumFavoriteLimit : freeFavoriteLimit;

    return currentCount >= limit;
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

  // PREFS / THEME / LANGUAGE / PREMIUM
  void setSelectedContentPreferences(Set<String> prefs) {
    print("🎯 Content prefs changed → $prefs");
    _preferences = _preferences.copyWith(selectedContentPreferences: prefs);
    _generalDirty = true;
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

    _generalDirty = true;

    notifyListeners();
    playback.updateAffirmations(currentFeed);
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

  // PAGE ITEMS (AFFIRMATION + CTA)

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
