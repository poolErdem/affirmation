import 'package:affirmation/models/affirmation.dart';
import 'package:affirmation/constants/constants.dart';

class AffirmationDefaults {
  AffirmationDefaults._();

  static Affirmation emptyFavorites(String language) {
    return Affirmation(
      id: "empty_fav",
      text: "Your favorites are empty.",
      categoryId: Constants.favoritesCategoryId,
      gender: "none",
      language: language,
    );
  }

  static Affirmation emptyMyAffirmations(String language) {
    return Affirmation(
      id: "empty_my",
      text: "You haven't added any custom affirmations yet.",
      categoryId: Constants.myCategoryId,
      gender: "none",
      language: language,
    );
  }
}
