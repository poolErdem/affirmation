import 'dart:convert';
import 'package:flutter/services.dart';

import 'package:affirmation/data/app_data_bundle.dart';
import 'package:affirmation/models/affirmation.dart';
import 'package:affirmation/models/category.dart';
import 'package:affirmation/models/theme_model.dart';

class AppRepository {
  final String languageCode;

  AppRepository({required this.languageCode});

  String get basePath => "assets/data/$languageCode";

  // -------------------------------------------------------------
  // LOAD CATEGORIES + THEMES
  // -------------------------------------------------------------
  Future<AppDataBundle> load() async {
    print("🔵 [LOAD] Başlıyor → dil: $languageCode");
    print("📁 Base path: $basePath");

    // ---------------- CATEGORIES ----------------
    final categoriesJson =
        await rootBundle.loadString("$basePath/categories.json");

    final categoriesList = json.decode(categoriesJson) as List;

    final categories =
        categoriesList.map((e) => AffirmationCategory.fromJson(e)).toList();

    print("📦 Category count = ${categories.length}");

    // ---------------- THEMES ----------------
    final themesJson =
        await rootBundle.loadString("assets/data/themes/themes.json");

    final themesList = json.decode(themesJson) as List;

    final themes = themesList.map((e) => ThemeModel.fromJson(e)).toList();

    print("🎨 Theme count = ${themes.length}");

    return AppDataBundle(
      categories: categories,
      themes: themes,
      affirmations: const [],
    );
  }

  // -------------------------------------------------------------
  // LOAD SINGLE CATEGORY JSON (new format)
  // -------------------------------------------------------------
  Future<List<Affirmation>> loadCategoryItem(String categoryId) async {
    final filePath = "$basePath/$categoryId.json";

    print("\n🔶 [LOAD-CATEGORY] $categoryId");
    print("📁 Path = $filePath");

    try {
      final jsonStr = await rootBundle.loadString(filePath);
      final decoded = json.decode(jsonStr);

      if (decoded is! Map ||
          decoded["affirmations"] is! List ||
          decoded["categoryId"] != categoryId) {
        throw Exception("⚠️ Invalid format in $categoryId.json");
      }

      final items = decoded["affirmations"] as List;

      print("📊 Affirmation count = ${items.length}");

      return items.map((e) {
        return Affirmation.fromJson({
          ...e,
          "categoryId": categoryId, // JSON içinden garanti
        });
      }).toList();
    } catch (e) {
      print("❌ loadCategoryItem($categoryId) hata: $e");
      rethrow;
    }
  }

  // -------------------------------------------------------------
  // LOAD ALL CATEGORIES ITEMS
  // -------------------------------------------------------------
  Future<List<Affirmation>> loadAllCategoriesItems() async {
    print("\n🔵 [LOAD-ALL] Tüm kategoriler yükleniyor...");

    final bundle = await load(); // category + theme load
    final List<Affirmation> result = [];

    for (final c in bundle.categories) {
      try {
        final items = await loadCategoryItem(c.id);
        result.addAll(items);
      } catch (e) {
        print("❌ Category ${c.id} yüklenemedi: $e");
      }
    }

    print("✅ [LOAD-ALL] Total affirmations = ${result.length}");
    return result;
  }
}
