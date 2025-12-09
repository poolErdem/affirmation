import 'package:affirmation/constants/constants.dart';
import 'package:affirmation/models/affirmation.dart';

class MyAffirmation {
  final String id;
  final String text;
  final int createdAt; // 🔥 ekledik

  String get displayText => text;

  const MyAffirmation({
    required this.id,
    required this.text,
    required this.createdAt,
  });

  MyAffirmation copyWith({
    String? id,
    String? text,
    int? createdAt,
  }) {
    return MyAffirmation(
      id: id ?? this.id,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory MyAffirmation.fromJson(Map<String, dynamic> json) {
    return MyAffirmation(
      id: json['id'],
      text: json['text'],
      createdAt: json['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'createdAt': createdAt,
    };
  }
}

// 🚨 DİKKAT: extension sınıfın DIŞINDA olmalı
extension MyAffToAffirmation on MyAffirmation {
  Affirmation toAffirmation() {
    return Affirmation(
      id: id,
      text: text,
      categoryId: Constants.myCategoryId,
      gender: "any", // Projendeki modele göre "all" kullanıyorsan onu yaz
      language: "en", // İstersen burada appState.selectedLocale da verilebilir
    );
  }
}
