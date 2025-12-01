import 'package:affirmation/models/reminder.dart';
import 'package:flutter/material.dart';

class UserPreferences {
  final Set<String> selectedContentPreferences;
  final String selectedThemeId;
  final Set<String> favoriteAffirmationIds;
  final Set<String> myAffirmationIds;
  final String languageCode;
  final String userName;
  final Gender? gender;
  final PremiumPlan? premiumPlanId;
  final DateTime? premiumExpiresAt;
  final bool premiumActive;
  final List<ReminderModel> reminders; // ⭐

  const UserPreferences({
    required this.selectedContentPreferences,
    required this.selectedThemeId,
    required this.favoriteAffirmationIds,
    required this.myAffirmationIds,
    required this.languageCode,
    required this.userName,
    required this.gender,
    required this.premiumPlanId,
    required this.premiumExpiresAt,
    required this.premiumActive,
    required this.reminders,
  });

  factory UserPreferences.initial({
    required String defaultThemeId,
    required Set<String> allCategoryIds,
    required Set<String> allContentPreferenceIds,
  }) {
    return UserPreferences(
      selectedContentPreferences: allContentPreferenceIds,
      selectedThemeId: defaultThemeId,
      favoriteAffirmationIds: <String>{},
      myAffirmationIds: <String>{},
      languageCode: 'en',
      userName: '',
      gender: Gender.none,
      premiumPlanId: null,
      premiumExpiresAt: null,
      premiumActive: false,
      reminders: [
        ReminderModel(
          id: "free_default",
          categoryIds: {"self_care"},
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 21, minute: 0),
          repeatCount: 3,
          repeatDays: {1, 2, 3, 4, 5, 6, 7},
          enabled: true,
          isPremium: false,
        )
      ],
    );
  }

  UserPreferences copyWith({
    Set<String>? selectedContentPreferences,
    String? selectedThemeId,
    Set<String>? favoriteAffirmationIds,
    Set<String>? myAffirmationIds,
    String? languageCode,
    String? userName,
    Gender? gender,
    PremiumPlan? premiumPlanId,
    DateTime? premiumExpiresAt,
    bool? premiumActive,
    List<ReminderModel>? reminders,
  }) {
    return UserPreferences(
      selectedContentPreferences:
          selectedContentPreferences ?? this.selectedContentPreferences,
      selectedThemeId: selectedThemeId ?? this.selectedThemeId,
      favoriteAffirmationIds:
          favoriteAffirmationIds ?? this.favoriteAffirmationIds, // ✅ DÜZELTİLDİ
      myAffirmationIds:
          myAffirmationIds ?? this.myAffirmationIds, // ✅ DÜZELTİLDİ
      languageCode: languageCode ?? this.languageCode,
      userName: userName ?? this.userName,
      gender: gender ?? this.gender,
      premiumPlanId: premiumPlanId ?? this.premiumPlanId,
      premiumExpiresAt: premiumExpiresAt ?? this.premiumExpiresAt,
      premiumActive: premiumActive ?? this.premiumActive,
      reminders: reminders != null
          ? List<ReminderModel>.from(reminders)
          : List<ReminderModel>.from(this.reminders), // ⭐ kopya
    );
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      selectedContentPreferences:
          Set<String>.from(json['selectedContentPreferences'] ?? const []),
      selectedThemeId: json['selectedThemeId'] as String,
      favoriteAffirmationIds:
          Set<String>.from(json['favoriteAffirmationIds'] ?? const []),
      myAffirmationIds: Set<String>.from(json['myAffirmationIds'] ?? const []),
      languageCode: json['languageCode'] as String? ?? 'en',
      userName: json['userName'] as String? ?? '',
      gender: genderFromString(json['gender']),
      premiumPlanId: premiumPlanFromString(json['premiumPlanId']),
      premiumExpiresAt: json['premiumExpiresAt'] != null
          ? DateTime.tryParse(json['premiumExpiresAt'])
          : null,
      premiumActive: json['premiumActive'] as bool? ?? false,
      reminders: (json['reminders'] as List<dynamic>? ?? [])
          .map((e) => ReminderModel.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'selectedContentPreferences': selectedContentPreferences.toList(),
        'selectedThemeId': selectedThemeId,
        'favoriteAffirmationIds': favoriteAffirmationIds.toList(),
        'myAffirmationIds': myAffirmationIds.toList(),
        'languageCode': languageCode,
        'userName': userName,
        'gender': genderToString(gender),
        'premiumPlanId': premiumPlanToString(premiumPlanId),
        'premiumExpiresAt': premiumExpiresAt?.toIso8601String(),
        'premiumActive': premiumActive,
        'reminders': reminders.map((r) => r.toJson()).toList(), // ⭐ EKLENDİ
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

// PREMIUM CHECK EXTENSION
extension UserPremiumExt on UserPreferences {
  bool get isPremiumValid {
    if (!premiumActive) return false;
    if (premiumExpiresAt == null) return true;
    return premiumExpiresAt!.isAfter(DateTime.now());
  }
}
