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
  static const freeCategoryLimit = 100;
  static const freeMyAffLimit = 100;
  static const premiumMyAffLimit = 1000;
  static const freeMyAffReadLimit = 10000;
  static const prefsKey = "my_affirmations";
  static const supportedLanguages = ['en', 'tr', 'de', 'es'];
  static const String dataBasePath = "assets/data";
  static const String categoriesJson = "categories.json";
  static const String themesJson = "themes.json";
  static const favoriteTimestampsKey = "favorite_timestamps";
  static const String onboardingThemePath = "assets/data/themes/c2.jpg";
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
    "gratitude",
    "general"
  ];

  static const localizedLanguageNames = {
    "en": {
      "en": "English",
      "es": "Spanish",
      "tr": "Turkish",
      "de": "German",
      "fr": "French",
      "it": "Italian",
      "pt": "Portuguese",
      "ru": "Russian",
    },
    "es": {
      "en": "Inglés",
      "es": "Español",
      "tr": "Turco",
      "de": "Alemán",
      "fr": "Francés",
      "it": "Italiano",
      "pt": "Portugués",
      "ru": "Ruso",
    },
    "tr": {
      "en": "İngilizce",
      "es": "İspanyolca",
      "tr": "Türkçe",
      "de": "Almanca",
      "fr": "Fransızca",
      "it": "İtalyanca",
      "pt": "Portekizce",
      "ru": "Rusça",
    },
    "de": {
      "en": "Englisch",
      "es": "Spanisch",
      "tr": "Türkisch",
      "de": "Deutsch",
      "fr": "Französisch",
      "it": "Italienisch",
      "pt": "Portugiesisch",
      "ru": "Russisch",
    },
    "fr": {
      "en": "Anglais",
      "es": "Espagnol",
      "tr": "Turc",
      "de": "Allemand",
      "fr": "Français",
      "it": "Italien",
      "pt": "Portugais",
      "ru": "Russe",
    },
    "it": {
      "en": "Inglese",
      "es": "Spagnolo",
      "tr": "Turco",
      "de": "Tedesco",
      "fr": "Francese",
      "it": "Italiano",
      "pt": "Portoghese",
      "ru": "Russo",
    },
    "pt": {
      "en": "Inglês",
      "es": "Espanhol",
      "tr": "Turco",
      "de": "Alemão",
      "fr": "Francês",
      "it": "Italiano",
      "pt": "Português",
      "ru": "Russo",
    },
    "ru": {
      "en": "Английский",
      "es": "Испанский",
      "tr": "Турецкий",
      "de": "Немецкий",
      "fr": "Французский",
      "it": "Итальянский",
      "pt": "Португальский",
      "ru": "Русский",
    },
  };

  static const List<String> months = [
    "",
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec"
  ];

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
