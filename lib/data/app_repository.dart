import 'dart:convert';
import 'package:affirmation/data/app_data_bundle.dart';
import 'package:flutter/services.dart';

import 'package:affirmation/models/affirmation.dart';
import 'package:affirmation/models/category.dart';
import 'package:affirmation/models/theme_model.dart';

class AppRepository {
  final String languageCode;

  AppRepository({required this.languageCode});

  // 🔥 Ana load
  Future<AppDataBundle> load() async {
    final basePath = "assets/data/$languageCode";

    print("🔵 [LOAD] Başladı → dil: $languageCode");
    print("📁 [PATH] Base path: $basePath");

    // categories.json
    print("📥 [LOAD] categories.json okunuyor...");
    final categoriesJson =
        await rootBundle.loadString("$basePath/categories.json");
    print("✅ [OK] categories.json yüklendi (${categoriesJson.length} byte)");

    final categoriesList = json.decode(categoriesJson) as List;
    print("📊 [DECODE] categories list length = ${categoriesList.length}");

    final categories =
        categoriesList.map((e) => AffirmationCategory.fromJson(e)).toList();
    print("🎯 [MAP] category obj count = ${categories.length}");

    // themes.json
    print("📥 [LOAD] themes.json okunuyor...");
    final themesJson =
        await rootBundle.loadString("assets/data/themes/themes.json");
    print("✅ [OK] themes.json yüklendi (${themesJson.length} byte)");

    final themesList = json.decode(themesJson) as List;
    print("📊 [DECODE] themes list length = ${themesList.length}");

    final themes = themesList.map((e) => ThemeModel.fromJson(e)).toList();
    print("🎨 [MAP] theme obj count = ${themes.length}");

    print("🟢 [LOAD] AppDataBundle hazır (affirmations = empty)");
    return AppDataBundle(
      themes: themes,
      categories: categories,
      affirmations: const [],
    );
  }

  // 🔥 Kategori seçilince çağrılacak
  Future<List<Affirmation>> loadCategoryItems(String categoryId) async {
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
        // Yeni format → direkt liste
        rawItems = decoded;
      } else if (decoded is Map && decoded["items"] is List) {
        // Eski format → items içinde liste
        rawItems = decoded["items"];
      } else {
        throw Exception("Invalid JSON format for $categoryId");
      }

      print("📊 [DECODE] items count = ${rawItems.length}");

      return rawItems.map((e) {
        print("👉 Affirmation yükleniyor: ${e["text"]}");
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
}
