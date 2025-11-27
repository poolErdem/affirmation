import 'package:flutter/material.dart';

class ReminderModel {
  final String id;
  final Set<String> categoryIds;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final int repeatCount;
  final Set<int> repeatDays;
  final bool enabled;
  final bool isPremium;

  ReminderModel({
    required this.id,
    required this.categoryIds,
    required this.startTime,
    required this.endTime,
    required this.repeatCount,
    required this.repeatDays,
    required this.enabled,
    required this.isPremium,
  });

  ReminderModel copyWith({
    String? id,
    Set<String>? categoryIds,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    int? repeatCount,
    Set<int>? repeatDays,
    bool? enabled,
    bool? isPremium,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      categoryIds: categoryIds ?? this.categoryIds,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      repeatCount: repeatCount ?? this.repeatCount,
      repeatDays: repeatDays ?? this.repeatDays,
      enabled: enabled ?? this.enabled,
      isPremium: isPremium ?? this.isPremium,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryIds': categoryIds.toList(),
        'startHour': startTime.hour,
        'startMinute': startTime.minute,
        'endHour': endTime.hour,
        'endMinute': endTime.minute,
        'repeatCount': repeatCount,
        'repeatDays': repeatDays.toList(),
        'enabled': enabled,
        'isPremium': isPremium,
      };

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      id: json['id'] as String,
      categoryIds: Set<String>.from(json['categoryIds'] ?? const []),
      startTime: TimeOfDay(
        hour: json['startHour'] as int,
        minute: json['startMinute'] as int,
      ),
      endTime: TimeOfDay(
        hour: json['endHour'] as int,
        minute: json['endMinute'] as int,
      ),
      repeatCount: json['repeatCount'] as int,
      repeatDays: Set<int>.from(json['repeatDays'] ?? const []),
      enabled: json['enabled'] as bool? ?? true,
      isPremium: json['isPremium'] as bool? ?? false,
    );
  }
}
