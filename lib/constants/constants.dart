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
  static const freeFavoriteLimit = 10;
  static const premiumFavoriteLimit = 500;
  static const freeMyAffLimit = 100;
  static const premiumMyAffLimit = 100;
  static const freeMyAffReadLimit = 10000;
  static const prefsKey = "my_affirmations";

  static const supportedLanguages = ['en', 'tr'];
  static const List<String> allContentPreferenceIds = ContentPreferences.all;

  static const String dataBasePath = "assets/data";
  static const String categoriesJson = "categories.json";
  static const String themesJson = "themes.json";

  static const List<AffirmationCategory> baseCategories = [
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
      id: myCategoryId,
      name: 'My Affirmations',
      imageAsset: 'assets/data/categories/myAffirmations.jfif',
      isPremiumLocked: false,
    ),
  ];
}
