class UserPreferences {
  final Set<String> selectedContentPreferences;
  final Set<String> selectedCategoryIds;
  final String selectedThemeId;
  final Set<String> favoriteAffirmationIds;
  final String languageCode;

  final String userName;
  final double backgroundVolume;

  final Gender? gender;

  final PremiumPlan? premiumPlanId;
  final DateTime? premiumExpiresAt;
  final bool premiumActive;

  const UserPreferences({
    required this.selectedContentPreferences,
    required this.selectedCategoryIds,
    required this.selectedThemeId,
    required this.favoriteAffirmationIds,
    required this.languageCode,
    required this.userName,
    required this.backgroundVolume,
    required this.gender,
    required this.premiumPlanId,
    required this.premiumExpiresAt,
    required this.premiumActive,
  });

  factory UserPreferences.initial({
    required String defaultThemeId,
    required Set<String> allCategoryIds,
    required Set<String> allContentPreferenceIds,
  }) {
    return UserPreferences(
      selectedContentPreferences: allContentPreferenceIds,
      selectedCategoryIds: allCategoryIds,
      selectedThemeId: defaultThemeId,
      favoriteAffirmationIds: <String>{},
      languageCode: 'en',
      userName: '',
      backgroundVolume: 0.5,
      gender: Gender.none,
      premiumPlanId: null,
      premiumExpiresAt: null,
      premiumActive: false,
    );
  }

  UserPreferences copyWith({
    Set<String>? selectedContentPreferences,
    Set<String>? selectedCategoryIds,
    String? selectedThemeId,
    Set<String>? favoriteAffirmationIds,
    String? languageCode,
    String? userName,
    double? backgroundVolume,
    Gender? gender,
    PremiumPlan? premiumPlanId,
    DateTime? premiumExpiresAt,
    bool? premiumActive,
  }) {
    return UserPreferences(
      selectedContentPreferences:
          selectedContentPreferences ?? this.selectedContentPreferences,
      selectedCategoryIds: selectedCategoryIds ?? this.selectedCategoryIds,
      selectedThemeId: selectedThemeId ?? this.selectedThemeId,
      favoriteAffirmationIds:
          favoriteAffirmationIds ?? this.favoriteAffirmationIds,
      languageCode: languageCode ?? this.languageCode,
      userName: userName ?? this.userName,
      backgroundVolume: backgroundVolume ?? this.backgroundVolume,
      gender: gender ?? this.gender,
      premiumPlanId: premiumPlanId ?? this.premiumPlanId,
      premiumExpiresAt: premiumExpiresAt ?? this.premiumExpiresAt,
      premiumActive: premiumActive ?? this.premiumActive,
    );
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      selectedContentPreferences:
          Set<String>.from(json['selectedContentPreferences'] ?? const []),
      selectedCategoryIds:
          Set<String>.from(json['selectedCategoryIds'] ?? const []),
      selectedThemeId: json['selectedThemeId'] as String,
      favoriteAffirmationIds:
          Set<String>.from(json['favoriteAffirmationIds'] ?? const []),
      languageCode: json['languageCode'] as String? ?? 'en',
      userName: json['userName'] as String? ?? '',
      backgroundVolume: (json['backgroundVolume'] as num?)?.toDouble() ?? 0.5,
      gender: genderFromString(json['gender']),
      premiumPlanId: premiumPlanFromString(json['premiumPlanId']),
      premiumExpiresAt: json['premiumExpiresAt'] != null
          ? DateTime.tryParse(json['premiumExpiresAt'])
          : null,
      premiumActive: json['premiumActive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'selectedContentPreferences': selectedContentPreferences.toList(),
        'selectedCategoryIds': selectedCategoryIds.toList(),
        'selectedThemeId': selectedThemeId,
        'favoriteAffirmationIds': favoriteAffirmationIds.toList(),
        'languageCode': languageCode,
        'userName': userName,
        'backgroundVolume': backgroundVolume,
        'gender': genderToString(gender),
        'premiumPlanId': premiumPlanToString(premiumPlanId),
        'premiumExpiresAt': premiumExpiresAt?.toIso8601String(),
        'premiumActive': premiumActive,
      };
}

// GENDER ENUM + Helpers
enum Gender { male, female, other, none }

Gender? genderFromString(String? value) {
  switch (value) {
    case "male":
      return Gender.male;
    case "female":
      return Gender.female;
    case "other":
      return Gender.other;
    case "none":
      return Gender.none;
  }
  return null;
}

String? genderToString(Gender? gender) {
  if (gender == null) return null;
  return gender.name;
}

// -----------------------------
// PREMIUM PLAN ENUM + Helpers
// -----------------------------
enum PremiumPlan { monthly, yearly, lifetime }

PremiumPlan? premiumPlanFromString(String? value) {
  switch (value) {
    case "monthly":
      return PremiumPlan.monthly;
    case "yearly":
      return PremiumPlan.yearly;
    case "lifetime":
      return PremiumPlan.lifetime;
  }
  return null;
}

String? premiumPlanToString(PremiumPlan? plan) {
  if (plan == null) return null;
  return plan.name;
}
