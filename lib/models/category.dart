class AffirmationCategory {
  final String id;
  final String name;
  final String imageAsset;
  final bool isPremiumLocked;

  const AffirmationCategory({
    required this.id,
    required this.name,
    required this.imageAsset,
    required this.isPremiumLocked,
  });

  factory AffirmationCategory.fromJson(Map<String, dynamic> json) {
    return AffirmationCategory(
      id: json["id"],
      name: json["name"],
      imageAsset: json["imageAsset"],
      isPremiumLocked: json["isPremiumLocked"] ?? false,
    );
  }
}
