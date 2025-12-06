import 'package:affirmation/data/preferences.dart';
import 'package:affirmation/models/category.dart';

class Constants {
  // Product IDs
  static const monthly = "premium_monthly";
  static const yearly = "premium_yearly";
  static const lifetime = "premium_lifetime";

  // Category IDs
  static const favoritesCategoryId = 'favorites';
  static const generalCategoryId = 'general';
  static const myCategoryId = 'myaffirmations';

  // Limits
  static const freeGeneralLimit = 100;
  static const freeCategoryLimit = 100;
  static const freeFavoriteLimit = 20;
  static const freeMyAffLimit = 100;
  static const premiumMyAffLimit = 1000;
  static const freeMyAffReadLimit = 10000;
  static const prefsKey = "my_affirmations";

  static const supportedLanguages = ['en', 'tr'];
  static const List<String> allContentPreferenceIds = ContentPreferences.all;

  static const String dataBasePath = "assets/data";
  static const String categoriesJson = "categories.json";
  static const String themesJson = "themes.json";
  static const String onboardingThemePath = "assets/data/themes/l4.jpg";
  static const String generalThemePath = "assets/data/categories/general.jpg";
  static const String favoriteThemePath =
      "assets/data/categories/favorites.jpg";
  static const String myAffirmationsThemePath =
      "assets/data/categories/myAffirmations.jpg";

  static const List<String> allCategories = [
    "self_care",
    "sleep",
    "stress_anxiety",
    "relationships",
    "happiness",
    "positive_thinking",
    "confidence",
    "motivation",
    "mindfulness",
    "career_success",
    "gratitude"
  ];

  static const localizedLanguageNames = {
    "en": {
      "en": "English",
      "es": "Spanish",
      "tr": "Turkish",
      "de": "German",
    },
    "es": {
      "en": "Inglés",
      "es": "Español",
      "tr": "Turco",
      "de": "Alemán",
    },
    "tr": {
      "en": "İngilizce",
      "es": "İspanyolca",
      "tr": "Türkçe",
      "de": "Almanca",
    },
    "de": {
      "en": "Englisch",
      "es": "Spanisch",
      "tr": "Türkisch",
      "de": "Deutsch",
    },
  };

  static const List<AffirmationCategory> baseCategories = [
    AffirmationCategory(
      id: favoritesCategoryId,
      name: 'My Favorites',
      imageAsset: favoriteThemePath,
      isPremiumLocked: false,
    ),
    AffirmationCategory(
      id: myCategoryId,
      name: 'My Affirmations',
      imageAsset: myAffirmationsThemePath,
      isPremiumLocked: false,
    ),
  ];
}
