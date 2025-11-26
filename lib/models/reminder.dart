import 'package:flutter/material.dart';

class ReminderModel {
  final String id; // unique id
  final String categoryId; // self_care, motivation, etc.
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final int repeatCount; // kaç kere
  final Set<int> repeatDays; // 1=Mon ... 7=Sun
  final bool enabled; // aktif/pasif
  final bool isPremium; // premium reminder mı

  ReminderModel({
    required this.id,
    required this.categoryId,
    required this.startTime,
    required this.endTime,
    required this.repeatCount,
    required this.repeatDays,
    required this.enabled,
    required this.isPremium,
  });

  ReminderModel copyWith({
    String? id,
    String? categoryId,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    int? repeatCount,
    Set<int>? repeatDays,
    bool? enabled,
    bool? isPremium,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
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
        'categoryId': categoryId,
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
      categoryId: json['categoryId'] as String,
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
