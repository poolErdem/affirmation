import 'dart:math';
import 'package:affirmation/l10n/app_localizations.dart';
import 'package:affirmation/models/user_preferences.dart';
import 'package:affirmation/models/theme_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/affirmation.dart';

// ---------------------------------------------------------
// 🔥 GENDER MATCH
// ---------------------------------------------------------
bool matchGender(Affirmation a, Gender? g) {
  if (a.gender == "any") return true;
  if (g == null || g == Gender.none) return true;

  if (g == Gender.male) return a.gender == "male";
  if (g == Gender.female) return a.gender == "female";

  return true;
}

bool hasValidPrefs(SharedPreferences prefs) {
  return prefs.containsKey("selectedThemeId") ||
      prefs.containsKey("gender") ||
      prefs.containsKey("selectedContentPreferences") ||
      prefs.containsKey("premiumActive");
}

List<Affirmation> filterByGender(
  List<Affirmation> list,
  Gender userGender,
) {
  return list.where((a) => matchGender(a, userGender)).toList();
}

List<Affirmation> filterByCategory(
  List<Affirmation> list,
  String categoryId,
) {
  return list.where((a) => a.categoryId == categoryId).toList();
}

// ---------------------------------------------------------
// 🔥 RANDOM INDEX
// ---------------------------------------------------------
int randomIndex(int total) {
  if (total <= 0) return 0;
  return Random().nextInt(total);
}

// ===================================================================
// ⭐ LANGUAGE UTILS
// ===================================================================

/// Dil belirleme (saved → device → fallback)
String resolveLanguage({
  required String? savedLang,
  required String deviceLang,
  required List<String> supported,
  String fallback = "en",
}) {
  if (savedLang != null && savedLang.isNotEmpty) {
    return savedLang;
  }

  if (supported.contains(deviceLang)) {
    return deviceLang;
  }

  return fallback;
}

/// Locale helper — basitçe Locale oluşturman gerekirse
LocaleCode toLocaleCode(String lang) {
  // UI tarafında Locale(lang) kullanıyorsun, burada string döndürebilir.
  return LocaleCode(lang);
}

String normalizeTimeZone(String input) {
  print("🧭 NORMALIZE → Input TZ: $input");

  switch (input) {
    case 'GMT+03:00':
    case 'MSK':
      print("🧭 NORMALIZE → Europe/Istanbul seçildi.");
      return 'Europe/Istanbul';

    case 'GMT+02:00':
      print("🧭 NORMALIZE → Europe/Sofia seçildi.");
      return 'Europe/Sofia';

    case 'GMT+01:00':
      print("🧭 NORMALIZE → Europe/Berlin seçildi.");
      return 'Europe/Berlin';

    case 'GMT+00:00':
      print("🧭 NORMALIZE → Europe/London seçildi.");
      return 'Europe/London';

    default:
      print("🧭 NORMALIZE → Bilinmeyen timezone → UTC seçildi.");
      return 'UTC';
  }
}

String localizedCategoryName(AppLocalizations t, String key) {
  switch (key) {
    case "self_care":
      return t.selfCare;
    case "sleep":
      return t.sleep;
    case "stress_anxiety":
      return t.stressAnxiety;
    case "positive_thinking":
      return t.positiveThinking;
    case "happiness":
      return t.happiness;
    case "relationships":
      return t.relationships;
    case "confidence":
      return t.confidence;
    case "motivation":
      return t.motivation;
    case "mindfulness":
      return t.mindfulness;
    case "gratitude":
      return t.gratitude;
    case "career_success":
      return t.careerSucces;
    default:
      return key;
  }
}

/// Basit Locale wrapper — UI’ya karışmaması için minimal
class LocaleCode {
  final String code;
  const LocaleCode(this.code);

  @override
  String toString() => code;
}

// ===================================================================
// ⭐ THEME UTILS
// ===================================================================

/// ✔ Aktif tema ID’ye göre bulunur (yoksa fallback)
ThemeModel resolveActiveTheme({
  required List<ThemeModel> themes,
  required String? themeId,
}) {
  if (themes.isEmpty) {
    return ThemeModel(
      id: "default_theme",
      imageAsset: "assets/data/themes/c20.jpg",
      soundAsset: null,
      isPremiumLocked: false,
      group: 'Abstract',
    );
  }

  if (themeId != null && themeId.isNotEmpty) {
    return themes.firstWhere(
      (t) => t.id == themeId,
      orElse: () => themes.first,
    );
  }

  return themes.first;
}

/// ✔ Premium kilit kontrolü ve fallback free theme
ThemeModel applyPremiumThemeFallback({
  required ThemeModel activeTheme,
  required List<ThemeModel> themes,
  required bool isPremium,
}) {
  // Premium değilse ve tema kilitliyse → free temaya düş
  if (activeTheme.isPremiumLocked && !isPremium) {
    return themes.firstWhere(
      (t) => !t.isPremiumLocked,
      orElse: () => themes.first,
    );
  }

  return activeTheme;
}

/// ✔ Tema erişilebilir mi?
bool canAccessTheme(ThemeModel theme, bool isPremium) {
  if (!theme.isPremiumLocked) return true;
  return isPremium;
}
