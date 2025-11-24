import 'package:affirmation/models/affirmation.dart';
import 'package:affirmation/models/category.dart';
import 'package:affirmation/models/theme_model.dart';

class AppDataBundle {
  final List<ThemeModel> themes;
  final List<AffirmationCategory> categories;
  final List<Affirmation> affirmations;

  AppDataBundle({
    required this.themes,
    required this.categories,
    required this.affirmations,
  });
}
