import 'dart:convert';
import 'package:affirmation/l10n/app_localizations.dart';
import 'package:affirmation/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/reminder.dart';

@pragma('vm:entry-point')
void _onBackgroundNotification(NotificationResponse response) {}

class ReminderState extends ChangeNotifier {
  final AppState appState;

  ReminderState({required this.appState});

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  List<ReminderModel> _reminders = [];

  bool _loaded = false;
  bool _adding = false;
  bool _updating = false;
  bool _deleting = false;

  List<ReminderModel> get reminders => List.unmodifiable(_reminders);
  bool get isLoaded => _loaded;

  // INITIALIZE
  Future<void> initialize() async {
    print("🚀 [REM] initialize() başlıyor...");

    await _initNotifications();
    await _loadFromPrefs();

    print("📚 [REM] Yüklenen reminder sayısı: ${_reminders.length}");
    print("⏰ [REM] _scheduleAll() başlıyor...");

    await _scheduleAll(); // ← LOCALIZATION YOK, DEFAULT BAŞLIK KULLANACAK

    _loaded = true;
    notifyListeners();

    print("🏁 [REM] initialize() tamam! Sistem hazır 🎉\n");
  }

  // ADD
  Future<bool> addReminder(ReminderModel r, AppLocalizations t) async {
    if (_adding) {
      print("⛔ [REM] addReminder İPTAL — zaten çalışıyor.");
      return false;
    }

    _adding = true;
    print("➕ [REM] addReminder() BAŞLADI");

    try {
      _reminders.add(r);
      print("✅ Reminder listeye eklendi.");

      await _savePrefs();
      print("💾 prefs kaydedildi.");

      await _scheduleReminderLocalized(r, t);
      print("⏰ reminder schedule edildi.");

      notifyListeners();

      return true;
    } finally {
      _adding = false;
      print("🔓 [REM] addReminder kilidi AÇILDI.");
    }
  }

  // UPDATE
  Future<void> updateReminder(ReminderModel r, AppLocalizations t) async {
    if (_updating) {
      print("⛔ updateReminder İPTAL — zaten çalışıyor.");
      return;
    }

    _updating = true;
    print("📝 [REM] updateReminder() BAŞLADI");

    try {
      final index = _reminders.indexWhere((x) => x.id == r.id);
      if (index == -1) return;

      _reminders[index] = r;

      await _savePrefs();

      await cancelReminder(r.id);
      await _scheduleReminderLocalized(r, t);

      notifyListeners();
    } finally {
      _updating = false;
      print("🔓 [REM] updateReminder kilidi açıldı.");
    }
  }

  // DELETE
  Future<void> deleteReminder(String id) async {
    if (_deleting) return;

    _deleting = true;

    try {
      _reminders.removeWhere((r) => r.id == id);

      await _savePrefs();
      await cancelReminder(id);

      notifyListeners();
    } finally {
      _deleting = false;
    }
  }

  Future<void> cancelReminder(String id) async {
    await _notifications.cancel(id.hashCode);
  }

  // SAVE / LOAD
  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _reminders.map((r) => r.toJson()).toList();
    await prefs.setString('reminders_json', jsonEncode(jsonList));
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('reminders_json');

    if (raw == null || raw.isEmpty) {
      _reminders = [];
      return;
    }

    final decoded = jsonDecode(raw);
    _reminders =
        decoded.map<ReminderModel>((j) => ReminderModel.fromJson(j)).toList();
  }

  // NOTIFICATIONS INIT
  Future<void> _initNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();

    await _notifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onBackgroundNotification,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotification,
    );

    const channel = AndroidNotificationChannel(
      'affirmation_reminders',
      'Affirmation Reminders',
      description: 'Daily Reminders',
      importance: Importance.high,
      playSound: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // SCHEDULE ALL → DEFAULT BAŞLIK
  Future<void> _scheduleAll() async {
    await _notifications.cancelAll();

    for (final r in _reminders) {
      if (r.enabled) {
        await _scheduleReminderDefault(r);
      }
    }
  }

  // --- DATE HELPERS ---
  DateTime _computeBaseDay(DateTime now, int weekday, TimeOfDay startTime) {
    if (weekday == now.weekday) {
      final todayStart = DateTime(
        now.year,
        now.month,
        now.day,
        startTime.hour,
        startTime.minute,
      );

      if (todayStart.isBefore(now)) {
        return now.add(const Duration(days: 1));
      }
      return now;
    }

    final diff = (weekday - now.weekday) % 7;
    return now.add(Duration(days: diff));
  }

  // LOCALIZED SCHEDULING (UI'den gelen bildirimler)
  Future<void> _scheduleReminderLocalized(
      ReminderModel r, AppLocalizations t) async {
    await _scheduleReminderInternal(
      r,
      localizedTitle: t.affTime, // ← Başlık
    );
  }

  // DEFAULT SCHEDULING (background / initialize)
  Future<void> _scheduleReminderDefault(ReminderModel r) async {
    await _scheduleReminderInternal(
      r,
      localizedTitle: "🌟 Affirmation Time", // ← Default İngilizce
    );
  }

  // INTERNAL SHARED SCHEDULER
  Future<void> _scheduleReminderInternal(
    ReminderModel r, {
    required String localizedTitle,
  }) async {
    final now = DateTime.now();
    final days = r.repeatDays.isEmpty ? {now.weekday} : r.repeatDays;

    for (final day in days) {
      final base = _computeBaseDay(now, day, r.startTime);

      final start = DateTime(
        base.year,
        base.month,
        base.day,
        r.startTime.hour,
        r.startTime.minute,
      );

      final end = DateTime(
        base.year,
        base.month,
        base.day,
        r.endTime.hour,
        r.endTime.minute,
      );

      final total = end.difference(start).inMinutes;
      if (total <= 0) continue;

      final interval = (total / r.repeatCount).floor();

      for (int i = 0; i < r.repeatCount; i++) {
        final t = start.add(Duration(minutes: interval * i));
        if (t.isBefore(now)) continue;

        await _scheduleSingleInternal(
          r,
          t,
          localizedTitle,
        );
      }
    }
  }

  // SHARED SINGLE SCHEDULER
  Future<void> _scheduleSingleInternal(
      ReminderModel r, DateTime time, String title) async {
    final tzTime = tz.TZDateTime.from(time, tz.local);

    final aff = appState.getRandomAffirmation(r.categoryIds);
    final rendered = aff?.renderWithName(appState.preferences.userName) ??
        "Your affirmation is ready.";

    final notifId = _generateSafeNotificationId(r, time);

    await _notifications.zonedSchedule(
      notifId,
      title,
      rendered,
      tzTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'affirmation_reminders',
          'Affirmation Reminders',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_notification',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  int _generateSafeNotificationId(ReminderModel r, DateTime time) {
    int value = r.id.hashCode ^
        time.millisecondsSinceEpoch.hashCode ^
        (time.day << 8) ^
        (time.hour << 16) ^
        (time.minute << 24);

    return value & 0x7FFFFFFF; // 32-bit signed positive
  }
}
