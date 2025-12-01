import 'dart:async';
import 'package:affirmation/constants/affirmation_defaults.dart';
import 'package:affirmation/constants/constants.dart';
import 'package:affirmation/models/reminder.dart';
import 'package:affirmation/state/playback_state.dart';
import 'package:affirmation/state/purchase_state.dart';
import 'package:affirmation/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/app_repository.dart';
import '../models/affirmation.dart';
import '../models/category.dart';
import '../models/theme_model.dart';
import '../models/user_preferences.dart';

class AppState extends ChangeNotifier {
  //final AudioPlayer _audioPlayer = AudioPlayer();

  String _selectedLocale = "en";
  String get selectedLocale => _selectedLocale;

  List<Affirmation> _allAffirmations = [];
  List<AffirmationCategory> _categories = [];
  List<ThemeModel> _themes = [];
  List<Affirmation> _cachedGeneral = [];
  List<Affirmation> _cachedCategoryFeed = [];
  List<Affirmation> _cachedFavoriteFeed = [];

  Set<String> onboardingContentPrefs = {};

  bool _fabExpanded = false;
  bool _loaded = false;
  bool isSoundEnabled = true;
  bool favoriteLimitReached = false;
  bool _generalDirty = true;
  bool _categoryDirty = true;
  bool _favoriteDirty = true;
  bool onboardingCompleted = false;

  String _activeCategoryId = '';
  String? onboardingName;
  String? gender;
  String? _pendingShareText;

  int? onboardingThemeIndex;
  int _currentIndex = 0;

  final PlaybackState _playback;
  PurchaseState? _purchaseState;
  late UserPreferences _preferences;
  late AppRepository _repository;

  UserPreferences get preferences => _preferences;
  PlaybackState get playback => _playback;

  bool get isLoaded => _loaded;
  int get currentIndex => _currentIndex;
  List<ThemeModel> get themes => _themes;
  String? get pendingShareText => _pendingShareText;
  String? get userName => preferences.userName;
  String get activeCategoryId => _activeCategoryId;

  // Lazy getter
  PurchaseState get purchaseState {
    _purchaseState ??= PurchaseState(this);
    return _purchaseState!;
  }

  AppState({
    PlaybackState? playback,
    PurchaseState? testPurchase,
  })  : _playback = playback ?? PlaybackState(),
        _purchaseState = testPurchase {
    _playback.addListener(notifyListeners);
  }

  @override
  void dispose() {
    _playback.dispose();
    purchaseState.dispose();
    super.dispose();
  }

  void setPendingShareText(String? text) {
    _pendingShareText = text;
    notifyListeners();
  }

  // INITIALIZE
  Future<void> initialize() async {
    print("🔥 initialize()");
    await purchaseState.initialize();

    final prefs = await SharedPreferences.getInstance();
    print(
        "📌 PREFS = ${prefs.getKeys().map((k) => "$k=${prefs.get(k)}").join(" | ")}");

    final savedLang = prefs.getString("lastLanguage");
    final deviceLang = PlatformDispatcher.instance.locale.languageCode;

    _selectedLocale = resolveLanguage(
      savedLang: savedLang,
      deviceLang: deviceLang,
      supported: Constants.supportedLanguages,
    );

    playback.setLanguage(_selectedLocale);

    print("🌐 Dil: → $_selectedLocale");

    _repository = AppRepository(languageCode: _selectedLocale);

    final bundle = await _repository.load();
    _categories = bundle.categories;
    _themes = bundle.themes;

    print(
        "🟢 ALL data loaded. Category count= ${_categories.length} , Affirmation count=${_allAffirmations.length}");

    onboardingCompleted = prefs.getBool("onboarding_completed") ?? false;

    if (onboardingCompleted) {
      await loadLastSettings();
    } else if (hasValidPrefs(prefs)) {
      await loadLastSettings();
    } else {
      _preferences = UserPreferences.initial(
        defaultThemeId: _themes.isNotEmpty ? _themes.first.id : "",
        allCategoryIds: _categories.map((c) => c.id).toSet(),
        allContentPreferenceIds: Constants.allContentPreferenceIds.toSet(),
      );
    }

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

    _activeCategoryId = Constants.generalCategoryId;

    // 6️⃣ THEME VALIDATION & PREMIUM FALLBACK
    ThemeModel? activeTheme;
    activeTheme = resolveActiveTheme(
      themes: _themes,
      themeId: _preferences.selectedThemeId,
    );

    if (activeTheme.isPremiumLocked && !_preferences.isPremiumValid) {
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

    _allAffirmations =
        await _repository.loadAllCategoriesItems(_preferences.premiumActive);

    // random index aşmaması için, _currentIndex
    _currentIndex = 0;

    _loaded = true;
    _generalDirty = true;
    _categoryDirty = true;
    _favoriteDirty = true;

    notifyListeners();

    print("✅ initialize() tamamlandı");
    print("📊 Final state:");
    print("   → Gender: ${_preferences.gender}");
    print("   → Content Prefs: ${_preferences.selectedContentPreferences}");
    print("   → Premium: ${_preferences.isPremiumValid}");
  }

  int _calculateInitialCount() {
    if (_preferences.premiumActive) {
      return _allAffirmations
          .where(
            (a) =>
                matchGender(a, _preferences.gender) &&
                _preferences.selectedContentPreferences.contains(a.categoryId),
          )
          .length;
    } else {
      return _allAffirmations
          .where(
            (a) => matchGender(a, _preferences.gender),
          )
          .length;
    }
  }

  // SAVE / LOAD
  Future<void> loadLastSettings() async {
    print("📥 loadLastSettings()");

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();

      onboardingCompleted = prefs.getBool("onboarding_completed") ?? false;
      gender = prefs.getString("gender");
      onboardingContentPrefs =
          (prefs.getStringList("onboard_prefs") ?? []).toSet();
      onboardingThemeIndex = prefs.getInt("onboard_theme");

      final lastTheme = prefs.getString('lastTheme');
      final lastLanguage = prefs.getString('lastLanguage');
      final lastContentPrefs = prefs.getString('lastContentPreferences');

      final premiumActive = prefs.getBool('premiumActive');
      final premiumPlanId = prefs.getString('premiumPlanId');
      final premiumExpiresAtStr = prefs.getString('premiumExpiresAt');
      final myList = prefs.getString("myAffirmationIds");
      final favIds = prefs.getString("favoriteAffirmationIds");

      final userName = prefs.getString("userName");

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
        gender: genderFromString(gender ?? "none"),
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
            startTime: const TimeOfDay(hour: 2, minute: 0),
            endTime: const TimeOfDay(hour: 2, minute: 30),
            repeatCount: 30,
            repeatDays: {1, 2, 3, 4, 5, 6, 7},
            enabled: true,
            isPremium: false,
          )
        ],
      );

      _activeCategoryId = Constants.generalCategoryId;

      if (lastLanguage != null && lastLanguage.isNotEmpty) {
        _selectedLocale = lastLanguage;
      }
    } catch (e) {
      print("❌ LOAD ERROR: $e");
    }
  }

  Future<void> saveLastSettings() async {
    print("💾 saveLastSettings()");

    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('lastTheme', _preferences.selectedThemeId);
      await prefs.setString('lastLanguage', _preferences.languageCode);
      await prefs.setString(
        'lastContentPreferences',
        _preferences.selectedContentPreferences.join(','),
      );

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
    await prefs.setString("gender", "none");
    await prefs.setStringList("onboard_prefs", onboardingContentPrefs.toList());
    await prefs.setInt("onboard_theme", onboardingThemeIndex ?? 0);
    await prefs.setString("onboard_name", onboardingName ?? "");

    await prefs.remove('lastContentPreferences');

    _preferences = _preferences.copyWith(
      gender: Gender.none,
    );

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

    _activeCategoryId = Constants.generalCategoryId;

    onboardingCompleted = true;

    notifyListeners();

    print("✅ Onboarding data saved successfully!");
  }

  // FEEDS
  List<Affirmation> get generalFeed {
    if (_generalDirty) {
      _cachedGeneral = _calculateGeneralFeed();
      _generalDirty = false;
    }
    return _cachedGeneral;
  }

  List<Affirmation> _calculateGeneralFeed() {
    print('📌 [GENERAL FEED] Başladı');
    print('➡ Gender: ${_preferences.gender}');
    print('➡ Premium: ${_preferences.premiumActive}');
    print('➡ Selected categories: ${_preferences.selectedContentPreferences}');

    late final List<Affirmation> list;

    if (_preferences.premiumActive) {
      list = _allAffirmations.where((a) {
        final genderOk = matchGender(a, _preferences.gender);
        final categoryOk =
            _preferences.selectedContentPreferences.contains(a.categoryId);
        return genderOk && categoryOk;
      }).toList();
    } else {
      // zaten 2 kategoriden geliyor, seçimlere göre süzmeyelim :)
      list = _allAffirmations.where((a) {
        final genderOk = matchGender(a, _preferences.gender);
        return genderOk;
      }).toList();
    }

    print('✅ GENERAL FEED toplam: ${list.length}');
    return list.take(5).toList();
  }

  List<Affirmation> get categoryFeed {
    if (_categoryDirty) {
      _cachedCategoryFeed = _calculateCategoryFeed();
      _categoryDirty = false;
    }
    return _cachedCategoryFeed;
  }

  List<Affirmation> _calculateCategoryFeed() {
    print('📌 [CATEGORY FEED] Başladı → $_activeCategoryId');
    print('📊 [CATEGORY FEED] Tüm affirmations: ${_allAffirmations.length}');

    final list = _allAffirmations.where((a) {
      final match = a.categoryId == _activeCategoryId &&
          matchGender(a, _preferences.gender);

      return match;
    }).toList();

    print(
        '✅ CATEGORY FEED toplam: ${list.length} (kategori: $_activeCategoryId)');

    if (list.isEmpty) {
      _allAffirmations.take(3).forEach((a) {});
    }

    return list;
  }

  List<Affirmation> get favoritesFeed {
    if (_favoriteDirty) {
      _cachedFavoriteFeed = _calculateFavoriteFeed();
      _favoriteDirty = false;
    }
    return _cachedFavoriteFeed;
  }

  List<Affirmation> _calculateFavoriteFeed() {
    print('📌 [FAVORITE FEED] Başladı');

    final list = _allAffirmations.where((a) {
      return _preferences.favoriteAffirmationIds.contains(a.id);
    }).toList();

    print('✅ FOVORITE FEED toplam: ${list.length}');

    return list;
  }

  List<Affirmation> get currentFeed {
    // GENERAL boş veya unset → general
    if (_activeCategoryId.isEmpty) return generalFeed;
    if (_activeCategoryId == Constants.generalCategoryId) return generalFeed;

    // FAVORITES
    if (_activeCategoryId == Constants.favoritesCategoryId) {
      final fav = favoritesFeed;

      if (fav.isEmpty) {
        return [AffirmationDefaults.emptyFavorites(selectedLocale)];
      }
      return fav;
    }

    return categoryFeed;
  }

  void setLocale(String code) {
    _selectedLocale = code;
    notifyListeners();
  }

  void setUserName(String name) async {
    _preferences = _preferences.copyWith(userName: name);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    prefs.setString("userName", name);
  }

  void setCurrentIndex(int index) {
    final feed = currentFeed;

    _currentIndex = index;
    playback.setCurrentIndex(index);

    if (feed.isNotEmpty) playback.updateAffirmations(feed);

    notifyListeners();
  }

  // CATEGORIES
  List<AffirmationCategory> get categories {
    // Özel kategoriler
    final base = Constants.baseCategories;
    final result = List<AffirmationCategory>.from(base);

    // _categories'i index 3'ten başlayarak ekle
    result.addAll(_categories);
    return result;
  }

  //🔥 OPTİMİZE: Kategori ID'sini günceller + dirty flag + playback
  void setActiveCategoryIdOnly(String id, {bool keepIndex = false}) {
    print("🎯 setActiveCategoryIdOnly: $id");

    if (_activeCategoryId == id) {
      print("⚠️ Zaten aktif kategori, işlem yok");
      return;
    }

    // Premium kontrolü
    if (id != Constants.favoritesCategoryId &&
        id != Constants.generalCategoryId &&
        id != Constants.myCategoryId) {
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

    if (_activeCategoryId == Constants.myCategoryId) {
      print("📝 My Affirmations → playback/feed güncelleme YOK");
      notifyListeners();
      saveLastSettings();
      return;
    }

    _generalDirty = true;
    _categoryDirty = true;
    _favoriteDirty = true;

    if (!keepIndex) {
      assignRandomIndex();
    }

    notifyListeners();
    saveLastSettings();
  }

  void setActiveCategories(Set<String> categoryIds) {
    //_activeCategoryIds = categoryIds;
    notifyListeners();
  }

  bool canAccessCategory(AffirmationCategory category) {
    if (!category.isPremiumLocked) return true;
    return _preferences.isPremiumValid;
  }

  // AFFIRMATIONS
  List<Affirmation> affirmationsForActiveCategories() {
    print("🎯 notf allAffirmations count → ${_allAffirmations.length}");
    print("🎯 notf gender → ${_preferences.gender}");
    print(
        "🎯 notf seçilen kategori sayısı → ${preferences.selectedContentPreferences.length}");

    return _allAffirmations.where((a) {
      final genderOk = matchGender(a, _preferences.gender);
      final matchesCategory =
          preferences.selectedContentPreferences.contains(a.categoryId);
      return genderOk && matchesCategory;
    }).toList();
  }

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

  Affirmation? getRandomAffirmation() {
    final list = affirmationsForActiveCategories();
    print("🎯 notf affirmation count → ${list.length}");

    if (list.isEmpty) return null;

    final frandomIndex = randomIndex(list.length);
    print(
        "🎯 random index: $frandomIndex ve  affirmation → ${list[frandomIndex].text}");

    return list[frandomIndex];
  }

  // RANDOM INDEX
  void assignRandomIndex() {
    final feed = currentFeed;

    if (_allAffirmations.isEmpty) {
      playback.setCurrentIndex(0);
      return;
    }

    final frandomIndex = randomIndex(feed.length);
    print("🎲 Random index = $frandomIndex");

    _currentIndex = frandomIndex;

    playback.updateAffirmations(feed);
    playback.setCurrentIndex(_currentIndex);
    return;
  }

  // FAVORITES
  void toggleFabExpanded() {
    _fabExpanded = !_fabExpanded;
    notifyListeners();
  }

  bool isOverFavoriteLimit() {
    final isPremium = _preferences.isPremiumValid;
    final currentCount = _preferences.favoriteAffirmationIds.length;

    final limit = isPremium
        ? Constants.premiumFavoriteLimit
        : Constants.freeFavoriteLimit;

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

  // PREFS / THEME / LANGUAGE / SOUND
  void setSelectedContentPreferences(Set<String> prefs) {
    print("🎯 Content prefs changed → $prefs");
    _preferences = _preferences.copyWith(selectedContentPreferences: prefs);
    _generalDirty = true;
    _categoryDirty = true;
    _favoriteDirty = true;
    notifyListeners();
    saveLastSettings();
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

  Future<void> setSelectedTheme(String id) async {
    final theme =
        _themes.firstWhere((t) => t.id == id, orElse: () => _themes.first);

    if (!canAccessTheme(theme)) {
      print("⛔ Premium değil → tema kilitli");
      return;
    }

    _preferences = _preferences.copyWith(selectedThemeId: id);

    //await playThemeSound();
    notifyListeners();
    await saveLastSettings();
  }

  Future<void> playThemeSound() async {
    // final theme = activeTheme;
    // if (!isSoundEnabled || theme.soundAsset == null) {
    //   await _audioPlayer.stop();
    //   return;
    // }

    // await _audioPlayer.stop();
    // await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    // await _audioPlayer.play(AssetSource(theme.soundAsset!));
  }

  void toggleSound() {
    //isSoundEnabled = !isSoundEnabled;
    //playThemeSound();
    //notifyListeners();
  }

  void setVolume(double v) {
    //_audioPlayer.setVolume(v);
    //print("🔊 Volume updated → $v");
    //notifyListeners();
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

      _allAffirmations =
          await _repository.loadAllCategoriesItems(_preferences.premiumActive);

      print("🟩 All Affirmations count: ${_allAffirmations.length}");

      if (_categories.isNotEmpty &&
          !_categories.any((c) => c.id == _activeCategoryId)) {
        _activeCategoryId = Constants.generalCategoryId;
      }
    } catch (e) {
      print("❌ JSON LOAD ERROR: $e");
    }

    print("🟥 Calling notifyListeners()");

    _generalDirty = true;
    _categoryDirty = true;
    _favoriteDirty = true;
    notifyListeners();
  }

  Future<void> setGender(String gender) async {
    print("🟥 AppState.setGender() CALLED → $gender");

    Gender? selectedGender = gender == "male"
        ? Gender.male
        : gender == "female"
            ? Gender.female
            : Gender.none;

    _preferences = _preferences.copyWith(gender: selectedGender);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("gender", gender);

    print("🟥 Gender saved to SharedPreferences");

    _generalDirty = true;
    _categoryDirty = true;
    _favoriteDirty = true;
    notifyListeners();
  }

  bool canAccessTheme(ThemeModel theme) {
    if (!theme.isPremiumLocked) return true;
    return _preferences.isPremiumValid;
  }

  // Preferences
  void updatePreferences(UserPreferences newPrefs) {
    _preferences = newPrefs;
    notifyListeners();
  }
}
