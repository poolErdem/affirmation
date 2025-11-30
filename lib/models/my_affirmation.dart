import 'package:affirmation/constants/constants.dart';
import 'package:affirmation/models/affirmation.dart';

class MyAffirmation {
  final String id;
  final String text;

  const MyAffirmation({
    required this.id,
    required this.text,
  });

  MyAffirmation copyWith({
    String? id,
    String? text,
  }) {
    return MyAffirmation(
      id: id ?? this.id,
      text: text ?? this.text,
    );
  }

  factory MyAffirmation.fromJson(Map<String, dynamic> json) {
    return MyAffirmation(
      id: json['id'],
      text: json['text'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
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
