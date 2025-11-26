import 'dart:convert';
import 'package:affirmation/data/app_data_bundle.dart';
import 'package:flutter/services.dart';

import 'package:affirmation/models/affirmation.dart';
import 'package:affirmation/models/category.dart';
import 'package:affirmation/models/theme_model.dart';

class AppRepository {
  final String languageCode;

  AppRepository({required this.languageCode});

  // -------------------------------------------------------------
  // 🔥 ANA LOAD (categories + themes)
  // -------------------------------------------------------------
  Future<AppDataBundle> load() async {
    final basePath = "assets/data/$languageCode";

    print("🔵 [LOAD] Başladı → dil: $languageCode");
    print("📁 [PATH] Base path: $basePath");

    // CATEGORIES
    print("📥 [LOAD] categories.json okunuyor...");
    final categoriesJson =
        await rootBundle.loadString("$basePath/categories.json");
    print("✅ [OK] categories.json yüklendi (${categoriesJson.length} byte)");

    final categoriesList = json.decode(categoriesJson) as List;
    print("📊 [DECODE] categories list length = ${categoriesList.length}");

    final categories =
        categoriesList.map((e) => AffirmationCategory.fromJson(e)).toList();
    print("🎯 [MAP] category obj count = ${categories.length}");

    // THEMES
    print("📥 [LOAD] themes.json okunuyor...");
    final themesJson =
        await rootBundle.loadString("assets/data/themes/themes.json");
    print("✅ [OK] themes.json yüklendi (${themesJson.length} byte)");

    final themesList = json.decode(themesJson) as List;
    print("📊 [DECODE] themes list length = ${themesList.length}");

    final themes = themesList.map((e) => ThemeModel.fromJson(e)).toList();
    print("🎨 [MAP] theme obj count = ${themes.length}");

    print("🟢 [LOAD] AppDataBundle hazır");

    return AppDataBundle(
      themes: themes,
      categories: categories,
      affirmations: const [],
    );
  }

  // -------------------------------------------------------------
  // 🔥 TEK KATEGORİ LOAD
  // -------------------------------------------------------------
  Future<List<Affirmation>> loadCategoryItem(String categoryId) async {
    final basePath = "assets/data/$languageCode";
    final filePath = "$basePath/$categoryId.json";

    print("\n🔶 [LOAD-CATEGORY] Başladı → $categoryId");
    print("📁 [PATH] $filePath");

    try {
      final jsonStr = await rootBundle.loadString(filePath);
      print("📥 [OK] $categoryId.json yüklendi (${jsonStr.length} byte)");

      final decoded = json.decode(jsonStr);

      late final List rawItems;

      if (decoded is List) {
        rawItems = decoded;
      } else if (decoded is Map && decoded["items"] is List) {
        rawItems = decoded["items"];
      } else {
        throw Exception("Invalid JSON format for $categoryId");
      }

      print("📊 [DECODE] items count = ${rawItems.length}");

      return rawItems.map((e) {
        return Affirmation.fromJson({
          ...e,
          "categoryId": categoryId,
        });
      }).toList();
    } catch (e) {
      print("❌ [ERROR] loadCategoryItems($categoryId) hata: $e");
      rethrow;
    }
  }

  // -------------------------------------------------------------
  // 🔥 BÜTÜN KATEGORİLERİ LOAD
  // -------------------------------------------------------------
  Future<List<Affirmation>> loadAllCategoriesItems() async {
    print("\n🔵 [LOAD-ALL] Tüm kategoriler yükleniyor...");

    final bundle = await load(); // ❗️ önemli! await koymazsan her şey çöker
    final List<Affirmation> result = [];

    for (final c in bundle.categories) {
      try {
        final items = await loadCategoryItem(c.id);
        result.addAll(items);
      } catch (e) {
        print("❌ Category load error for ${c.id}: $e");
      }
    }

    print(
        "✅ [LOAD-ALL] Tüm affirmations yüklendi → toplam ${result.length} madde");

    return result;
  }
}
