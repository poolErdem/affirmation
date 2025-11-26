import 'dart:math';
import 'package:affirmation/models/user_preferences.dart';

import '../models/affirmation.dart';

/// ------------------------------------------------------
/// GENDER MATCH
/// ------------------------------------------------------
bool matchGender(Affirmation a, Gender? g) {
  if (a.gender == "any") return true;

  if (g == null || g == Gender.none) return true;

  if (g == Gender.male) return a.gender == "male";
  if (g == Gender.female) return a.gender == "female";

  return true;
}

/// ------------------------------------------------------
/// FILTER BY GENDER
/// ------------------------------------------------------
List<Affirmation> filterByGender(
  List<Affirmation> list,
  Gender userGender,
) {
  return list.where((a) => matchGender(a, userGender)).toList();
}

/// ------------------------------------------------------
/// FILTER BY CATEGORY
/// ------------------------------------------------------
List<Affirmation> filterByCategory(
  List<Affirmation> list,
  String categoryId,
) {
  return list.where((a) => a.categoryId == categoryId).toList();
}

/// ------------------------------------------------------
/// RANDOM INDEX (0..total-1)
/// ------------------------------------------------------
int randomIndex(int total) {
  if (total <= 0) return 0;
  return Random().nextInt(total);
}
