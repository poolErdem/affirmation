class Affirmation {
  final String id;
  final String text;
  final String categoryId;
  final String language;
  final String gender;

  /// "female", "male", "any"

  Affirmation({
    required this.id,
    required this.text,
    required this.categoryId,
    required this.language,
    required this.gender,
  });

  factory Affirmation.fromJson(Map<String, dynamic> json) {
    return Affirmation(
      id: json['id'] as String,
      text: json['text'] as String,
      categoryId: json['categoryId'] as String,
      language: json['language'] as String? ?? 'en',

      /// Eğer JSON içinde gender yoksa default: "any"
      gender: json['gender'] as String? ?? "any",
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'categoryId': categoryId,
        'language': language,
        'gender': gender
      };

  String renderWithName(String userName) {
    if (userName.isEmpty) return text.replaceAll(", {name}", "");

    return text.replaceAll("{name}", userName);
  }
}
