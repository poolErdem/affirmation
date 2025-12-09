class Affirmation {
  final String id;
  final String text;
  final String categoryId; // general veya normal kategori
  final String? actualCategory; // sadece general için
  final String language;
  final String gender; // "female", "male", "any"

  String get displayText => text;

  Affirmation({
    required this.id,
    required this.text,
    required this.categoryId,
    required this.language,
    required this.gender,
    this.actualCategory, // opsiyonel
  });

  factory Affirmation.fromJson(Map<String, dynamic> json) {
    return Affirmation(
      id: json['id'] as String,
      text: json['text'] as String,
      categoryId: json['categoryId'] as String,
      actualCategory:
          json['actualCategory'] as String?, // general için okunacak
      language: json['language'] as String? ?? 'en',
      gender: json['gender'] as String? ?? "any",
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'categoryId': categoryId,
        'actualCategory': actualCategory, // general için yazacağız
        'language': language,
        'gender': gender,
      };

  String renderWithName(String userName) {
    if (userName.isEmpty) return text.replaceAll(", {name}", "");
    return text.replaceAll("{name}", userName);
  }
}
