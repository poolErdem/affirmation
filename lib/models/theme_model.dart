class ThemeModel {
  final String id;
  final String imageAsset;
  final String group;
  final bool isPremiumLocked;
  final String? soundAsset; // 🔥 yeni eklendi

  ThemeModel({
    required this.id,
    required this.imageAsset,
    required this.group,
    this.isPremiumLocked = false,
    this.soundAsset,
  });

  factory ThemeModel.fromJson(Map<String, dynamic> json) {
    return ThemeModel(
      id: json['id'],
      imageAsset: json['imageAsset'],
      group: json['group'],
      isPremiumLocked: json['isPremiumLocked'] ?? false,
      soundAsset: json['soundAsset'], // 🔥 json’dan okur
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'imageAsset': imageAsset,
        'group': group,
        'isPremiumLocked': isPremiumLocked,
        'soundAsset': soundAsset,
      };
}
