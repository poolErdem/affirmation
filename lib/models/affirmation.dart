class Affirmation {
  final String id;
  final String text;
  final String categoryId;
  final List<String> preferences; // content preferences
  final String language;
  final bool isPremium;
  final String gender;

  /// "female", "male", "any"

  Affirmation({
    required this.id,
    required this.text,
    required this.categoryId,
    required this.preferences,
    required this.language,
    required this.isPremium,
    required this.gender,
  });

  factory Affirmation.fromJson(Map<String, dynamic> json) {
    return Affirmation(
      id: json['id'] as String,
      text: json['text'] as String,
      categoryId: json['categoryId'] as String,
      preferences: List<String>.from(json['preferences'] ?? const <String>[]),
      language: json['language'] as String? ?? 'en',
      isPremium: json['isPremium'] as bool? ?? false,

      /// Eğer JSON içinde gender yoksa default: "any"
      gender: json['gender'] as String? ?? "any",
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'categoryId': categoryId,
        'preferences': preferences,
        'language': language,
        'isPremium': isPremium,
        'gender': gender,
      };

  String renderWithName(String userName) {
    if (userName.isEmpty) return text;
    return text.replaceAll("{name}", userName);
  }
}
