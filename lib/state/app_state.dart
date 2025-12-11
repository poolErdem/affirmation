import 'dart:async';
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

  Map<String, int> get favoriteTimestamps {
    if (!_loaded) return const {};
    return _preferences.favoriteTimestamps;
  }

  Map<String, int> get myAffTimestamps {
    if (!_loaded) return const {};
    return _preferences.myAffTimestamps;
  }

  // Cache → key: "gender|premium|cat1,cat2"
  final Map<String, List<Affirmation>> _categoryCache = {};
  final Map<String, List<Affirmation>> _cachedAffirmations = {};

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
        allContentPreferenceIds: Constants.allCategories.toSet(),
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

    // 7️⃣ LANGUAGE PREFERENCE FALLBACK
    if (_preferences.languageCode.isEmpty) {
      _preferences = _preferences.copyWith(languageCode: _selectedLocale);
    }

    await loadAllAffirmations(_preferences.languageCode);

    _currentIndex = randomIndex(_calculateInitialCount());
    print("🎲 Random , index = $_currentIndex");

    _loaded = true;
    _generalDirty = true;
    _categoryDirty = true;
    _favoriteDirty = true;

    clearAffirmationCache();
    notifyListeners();

    print("✅ initialize() tamamlandı");
    print("📊 Final state:");
    print("   → Gender: ${_preferences.gender}");
    print("   → Content Prefs: ${_preferences.selectedContentPreferences}");
    print("   → Premium: ${_preferences.isPremiumValid}");
  }

  Future<void> loadAllAffirmations(String languageCode) async {
    // Eğer cache’de varsa → direkt kullan
    if (_cachedAffirmations.containsKey(languageCode)) {
      _allAffirmations = _cachedAffirmations[languageCode]!;
      print(
          "⚡ CACHE HIT → $languageCode affirmations RAM’den yüklendi, aff sayısı: ${_allAffirmations.length}");
      return;
    }

    print("🌀 LOAD → $languageCode affirmations JSON’dan yükleniyor...");

    final loaded = await _repository.loadAllCategoriesItems();

    _cachedAffirmations[languageCode] = loaded;
    _allAffirmations = loaded;

    print("📦 CACHE STORED → $languageCode affirmations cached");
  }

  int _calculateInitialCount() {
    final count = _allAffirmations.where((a) {
      return matchGender(a, _preferences.gender) &&
          a.categoryId == Constants.generalCategoryId &&
          _preferences.selectedContentPreferences.contains(a.actualCategory);
    }).length;

    return count;
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
      final favTimestampsRaw = prefs.getString('favoriteTimestamps');
      final myTimestampsRaw = prefs.getString('myAffTimestamps');

      final userName = prefs.getString("userName");

      final favoriteTimestamps = parseTimestampMap(favTimestampsRaw ?? "");
      final myAffTimestamps = parseTimestampMap(myTimestampsRaw ?? "");

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
              categoryIds: {"general"},
              startTime: const TimeOfDay(hour: 2, minute: 0),
              endTime: const TimeOfDay(hour: 8, minute: 0),
              repeatCount: 20,
              repeatDays: {1, 2, 3, 4, 5, 6, 7},
              enabled: true,
              isPremium: false,
            )
          ],

          // ⭐ Doğru ve güvenli timestamp map
          favoriteTimestamps: favoriteTimestamps,
          myAffTimestamps: myAffTimestamps);

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

      await prefs.setBool('premiumActive', _preferences.premiumActive);
      await prefs.setString(
        'premiumPlanId',
        premiumPlanToString(_preferences.premiumPlanId) ?? '',
      );
      await prefs.setString(
        'premiumExpiresAt',
        _preferences.premiumExpiresAt?.toIso8601String() ?? '',
      );

      // ⭐ FAVORİ IDS
      await prefs.setString(
        "favoriteAffirmationIds",
        _preferences.favoriteAffirmationIds.join(','),
      );

      // ⭐ MY AFFIRMATION IDS
      await prefs.setString(
        "myAffirmationIds",
        _preferences.myAffirmationIds.join(','),
      );

      // 🔥 FAVORITE TIMESTAMPS — nihai doğru kayıt
      await prefs.setString(
        "favoriteTimestamps",
        encodeTimestampMap(_preferences.favoriteTimestamps),
      );

      await prefs.setString(
          "myAffTimestamps", encodeTimestampMap(_preferences.myAffTimestamps));

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

    // Filtrelenmiş general listesi (full)
    final list = _allAffirmations.where((a) {
      return matchGender(a, _preferences.gender) &&
          a.categoryId == Constants.generalCategoryId &&
          _preferences.selectedContentPreferences.contains(a.actualCategory);
    }).toList();

    print('🔍 GENERAL FEED (raw) count: ${list.length}');

    return list;
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
      return a.categoryId == _activeCategoryId &&
          matchGender(a, _preferences.gender);
    }).toList();

    print('🔍 CATEGORY FEED (raw) count = ${list.length}');

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
    final favIds = _preferences.favoriteAffirmationIds;
    final stamps = _preferences.favoriteTimestamps;

    // 1) Favori listesi
    final list = _allAffirmations.where((a) => favIds.contains(a.id)).toList();

    list.sort((a, b) {
      final tA = stamps[a.id] ?? 0;
      final tB = stamps[b.id] ?? 0;
      return tB.compareTo(tA); // en yeni en üstte
    });

    return list;
  }

  List<Affirmation> get currentFeed {
    if (_activeCategoryId.isEmpty) return generalFeed;
    if (_activeCategoryId == Constants.generalCategoryId) return generalFeed;

    if (_activeCategoryId == Constants.favoritesCategoryId) {
      return favoritesFeed;
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
    print("🎲 set Current Index affirmation = ${feed[_currentIndex].text}");

    notifyListeners();
  }

  // CATEGORIES
  List<AffirmationCategory> get categories {
    final base = Constants.baseCategories;
    final cats = _categories;

    final result = <AffirmationCategory>[];

    // 0 → categories[0] (varsa)
    if (cats.isNotEmpty) {
      result.add(cats[0]);
    }

    // 1 ve 2 → base[0], base[1] (varsa)
    if (base.isNotEmpty) result.add(base[0]);
    if (base.length > 1) result.add(base[1]);

    // 3 → categories[1] ve sonrası
    if (cats.length > 1) {
      result.addAll(cats.sublist(1));
    }

    return result;
  }

  //🔥 OPTİMİZE: Kategori ID'sini günceller + dirty flag + playback
  void setActiveCategoryIdOnly(String id) {
    print("🎯 setActiveCategoryIdOnly: $id");

    if (_activeCategoryId == id) {
      print("⚠️ Zaten aktif kategori, işlem yok");
      return;
    }

    // Premium kontrolü
    if (id != Constants.favoritesCategoryId && id != Constants.myCategoryId) {
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

    if (_activeCategoryId != Constants.favoritesCategoryId) {
      assignRandomIndex();
    }

    notifyListeners();
    saveLastSettings();
  }

  bool canAccessCategory(AffirmationCategory category) {
    if (!category.isPremiumLocked) return true;
    return _preferences.isPremiumValid;
  }

  // AFFIRMATIONS
  Affirmation? affirmationAt(int index) {
    final list = currentFeed;
    if (list.isEmpty) return null;

    if (index < 0 || index >= list.length) {
      debugPrint(
          "⚠️ WARNING: affirmationAt($index) → NULL (limit = ${list.length})");
      return null;
    }

    return list[index];
  }

  String _makeCacheKey(Set<String> categories) {
    final sorted = categories.toList()..sort();
    final cats = sorted.join(",");
    final gender = _preferences.gender;
    return "$gender|$cats";
  }

  void clearAffirmationCache() {
    _categoryCache.clear();
    _generalDirty = true;
    _categoryDirty = true;
    print("🧽 [AFF-CACHE] cache cleared");
  }

  List<Affirmation> affirmationsForCategories(Set<String> categoryIds) {
    print("🎯 [AFF] allAffirmations count → ${_allAffirmations.length}");
    print("🎯 [AFF] gender → ${_preferences.gender}");
    print("🎯 [AFF] incoming categoryIds → $categoryIds");

    final effectiveCats = categoryIds.isEmpty ? {"general"} : categoryIds;

    final key = _makeCacheKey(effectiveCats);

    // 🔥 CACHE HIT
    if (_categoryCache.containsKey(key)) {
      print("⚡ [AFF-CACHE] HIT → $key (len=${_categoryCache[key]!.length})");
      return _categoryCache[key]!;
    }

    print("🐢 [AFF-CACHE] MISS → $key");

    late final List<Affirmation> list;

    //gender + category
    list = _allAffirmations.where((a) {
      final genderOk = matchGender(a, _preferences.gender);
      final matchesCategory = effectiveCats.contains(a.categoryId);
      return genderOk && matchesCategory;
    }).toList();

    print("🎯 [AFF] after filtering → ${list.length}");

    // 🔥 CACHE STORE
    _categoryCache[key] = list;

    return list;
  }

  Affirmation? getRandomAffirmation(Set<String> categoryIds) {
    print("🎲 incoming categoryIds = $categoryIds");

    var list = affirmationsForCategories(categoryIds);

    if (list.isEmpty) {
      return null;
    }

    final frandomIndex = randomIndex(list.length);
    final selected = list[frandomIndex];

    print("🎯 [AFF] random index → $frandomIndex");
    print("🎯 [AFF] selected affirmation → ${selected.text}");

    return selected;
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
    print("🎲 Random index = $_currentIndex");
    print("🎲 Random affirmation = ${feed[_currentIndex].text}");

    return;
  }

  // FAVORITES
  void toggleFabExpanded() {
    _fabExpanded = !_fabExpanded;
    notifyListeners();
  }

  void toggleFavorite(String id) {
    final favs = Set<String>.from(_preferences.favoriteAffirmationIds);
    final stamps = Map<String, int>.from(_preferences.favoriteTimestamps);

    if (favs.contains(id)) {
      favs.remove(id);
      stamps.remove(id);
    } else {
      favs.add(id);
      stamps[id] = DateTime.now().millisecondsSinceEpoch;
    }

    _preferences = _preferences.copyWith(
      favoriteAffirmationIds: favs,
      favoriteTimestamps: stamps,
    );

    _favoriteDirty = true;
    notifyListeners();
    saveLastSettings();
  }

  bool isFavorite(String id) {
    return _preferences.favoriteAffirmationIds.contains(id);
  }

  // PREFS / THEME / LANGUAGE / SOUND
  Future<void> setSelectedContentPreferences(Set<String> prefs) async {
    print("🎯 Content prefs changed → $prefs");

    _preferences = _preferences.copyWith(
      selectedContentPreferences: prefs,
    );

    _generalDirty = true;
    _categoryDirty = true;
    _favoriteDirty = true;

    notifyListeners();

    await saveLastSettings(); // 🔥 garantili yazım
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("onboarding_completed", true);
    notifyListeners();
  }

  Map<String, Offset> affirmationPositions = {};

  Offset getAffirmationPosition(String affirmationId) {
    return affirmationPositions[affirmationId] ?? const Offset(40, 200);
  }

  Future<void> saveAffirmationPosition(
      String affirmationId, double x, double y) async {
    affirmationPositions[affirmationId] = Offset(x, y);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("aff_pos_$affirmationId", "$x,$y");

    notifyListeners();
  }

// ⭐ Kaydedilmiş pozisyonu yükler
  Future<void> loadAffirmationPosition(String affirmationId) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString("aff_pos_$affirmationId");

    if (saved != null) {
      final parts = saved.split(',');
      affirmationPositions[affirmationId] = Offset(
        double.parse(parts[0]),
        double.parse(parts[1]),
      );
      notifyListeners();
    }
  }

// ⭐ (Opsiyonel) Tüm pozisyonları temizle
  Future<void> clearAllPositions() async {
    final prefs = await SharedPreferences.getInstance();

    for (var id in affirmationPositions.keys) {
      await prefs.remove("aff_pos_$id");
    }

    affirmationPositions.clear();
    notifyListeners();
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
    if (id.isEmpty) {
      _preferences =
          _preferences.copyWith(selectedThemeId: Constants.onboardingThemePath);
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

      _themes = bundle.themes;
      _categories = bundle.categories;

      await loadAllAffirmations(code);

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
    clearAffirmationCache();
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
    clearAffirmationCache();
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

  bool get activeThemeIsVideo {
    final t = activeTheme;
    return t.imageAsset.toLowerCase().endsWith(".mp4");
  }

  String get activeThemeAsset {
    final t = activeTheme;
    return t.imageAsset;
  }
}

extension ActiveThemeHelpers on AppState {
  bool get activeThemeIsVideo =>
      activeTheme.imageAsset.toLowerCase().endsWith('.mp4');

  String get activeThemeAsset => activeTheme.imageAsset;
}

extension ActiveThemeExt on AppState {
  ThemeModel? get activeTheme {
    return themes.firstWhere(
      (t) => t.id == preferences.selectedThemeId,
      orElse: () => themes.first,
    );
  }
}
