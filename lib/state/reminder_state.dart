import 'dart:convert';
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

  bool _loaded = false;
  List<ReminderModel> _reminders = [];
  bool _isPremium = false;

  bool get isLoaded => _loaded;
  List<ReminderModel> get reminders => List.unmodifiable(_reminders);
  bool get isPremium => _isPremium;
  int get limit => _isPremium ? 200 : 20;
  bool get canAddReminder => _reminders.length < limit;

  // --------------------------------------------------------
  // INITIALIZE
  // --------------------------------------------------------
  Future<void> initialize(bool premium) async {
    print("🚀 [REM] initialize() başlıyor...");
    print("   • premium = $premium");

    _isPremium = premium;

    print("🔔 [REM] _initNotifications() çağrılıyor...");
    await _initNotifications();
    print("✔ [REM] _initNotifications tamam.");

    print("📥 [REM] _loadFromPrefs() çağrılıyor...");
    await _loadFromPrefs();
    print("📚 [REM] Yüklenen reminder sayısı: ${_reminders.length}");

    print("⏰ [REM] _scheduleAll() başlıyor... (existing=${_reminders.length})");
    final sw = Stopwatch()..start();

    await _scheduleAll();

    sw.stop();
    print(
        "✔ [REM] _scheduleAll tamamlandı → süre: ${sw.elapsedMilliseconds} ms");

    _loaded = true;
    notifyListeners();

    print("🏁 [REM] initialize() tamam! Sistem hazır 🎉\n");
  }

// --------------------------------------------------------
// ADD
// --------------------------------------------------------
  Future<bool> addReminder(ReminderModel r) async {
    print("➕ [REM] addReminder() çağrıldı");
    print("   • id          = ${r.id}");
    print("   • enabled     = ${r.enabled}");
    print("   • startTime   = ${r.startTime}");
    print("   • endTime     = ${r.endTime}");
    print("   • repeatCount = ${r.repeatCount}");
    print("   • repeatDays  = ${r.repeatDays}");
    print("   • categories  = ${r.categoryIds}");
    print(
        "   • canAdd?     = $canAddReminder (limit=$limit, current=${_reminders.length})");

    if (!canAddReminder) {
      print("❌ [REM] addReminder → limit aşıldı, eklenmedi.");
      return false;
    }

    _reminders.add(r);
    print(
        "✅ [REM] Reminder listeye eklendi. Yeni length = ${_reminders.length}");

    await _savePrefs();
    print("💾 [REM] _savePrefs tamam.");

    await _scheduleReminder(r);
    print("⏰ [REM] _scheduleReminder tamamlandı (id=${r.id}).");

    notifyListeners();
    print("📢 [REM] notifyListeners() çağrıldı (addReminder).");

    return true;
  }

// --------------------------------------------------------
// UPDATE
// --------------------------------------------------------
  Future<void> updateReminder(ReminderModel r) async {
    print("📝 [REM] updateReminder() çağrıldı");
    print("   • id          = ${r.id}");
    print("   • enabled     = ${r.enabled}");
    print("   • startTime   = ${r.startTime}");
    print("   • endTime     = ${r.endTime}");
    print("   • repeatCount = ${r.repeatCount}");
    print("   • repeatDays  = ${r.repeatDays}");
    print("   • categories  = ${r.categoryIds}");

    final index = _reminders.indexWhere((x) => x.id == r.id);
    print("   • bulunan index = $index");

    if (index == -1) {
      print("❌ [REM] updateReminder → id bulunamadı, hiçbir şey yapılmadı.");
      return;
    }

    _reminders[index] = r;
    print("✅ [REM] Reminder listede güncellendi (index=$index).");

    await _savePrefs();
    print("💾 [REM] _savePrefs tamam (update).");

    await cancelReminder(r.id);
    print("🗑️ [REM] cancelReminder çağrıldı (id=${r.id}).");

    await _scheduleReminder(r);
    print("⏰ [REM] _scheduleReminder tamamlandı (update, id=${r.id}).");

    notifyListeners();
    print("📢 [REM] notifyListeners() çağrıldı (updateReminder).");
  }

// --------------------------------------------------------
// DELETE
// --------------------------------------------------------
  Future<void> deleteReminder(String id) async {
    print("🗑️ [REM] deleteReminder() çağrıldı → id=$id");
    final before = _reminders.length;

    _reminders.removeWhere((r) => r.id == id);

    final after = _reminders.length;
    print("   • önce length = $before, sonra length = $after");

    await _savePrefs();
    print("💾 [REM] _savePrefs tamam (delete).");

    await cancelReminder(id);
    print("🧹 [REM] cancelReminder çağrıldı (id=$id).");

    notifyListeners();
    print("📢 [REM] notifyListeners() çağrıldı (deleteReminder).");
  }

  Future<void> cancelReminder(String id) async {
    final notifId = id.hashCode;
    print("🚫 [REM] cancelReminder() → id=$id, notifId=$notifId");
    await _notifications.cancel(notifId);
    print("✔ [REM] Notification cancel tamam (notifId=$notifId).");
  }

  // --------------------------------------------------------
  // SAVE / LOAD
  // --------------------------------------------------------
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

  // --------------------------------------------------------
  // NOTIFICATIONS INIT
  // --------------------------------------------------------
  Future<void> _initNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();

    await _notifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onTap,
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

    // Notification permission
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Exact alarm permission
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      final can = await androidPlugin.canScheduleExactNotifications();
      if (can == false) {
        await androidPlugin.requestExactAlarmsPermission();
      }
    }
  }

  void _onTap(NotificationResponse response) {}

  // --------------------------------------------------------
  // SCHEDULE ALL
  // --------------------------------------------------------
  Future<void> _scheduleAll() async {
    await _notifications.cancelAll();

    for (final r in _reminders) {
      if (r.enabled) {
        await _scheduleReminder(r);
      }
    }
  }

  // --------------------------------------------------------
  // SCHEDULE SINGLE REMINDER
  // --------------------------------------------------------

  DateTime _computeBaseDay(DateTime now, int weekday, TimeOfDay startTime) {
    // Bugünkü gün mü?
    if (weekday == now.weekday) {
      final todayStart = DateTime(
        now.year,
        now.month,
        now.day,
        startTime.hour,
        startTime.minute,
      );

      // Eğer bugünün saati geçmişse → yarın
      if (todayStart.isBefore(now)) {
        return now.add(const Duration(days: 1));
      }

      // Saat geçmemiş → bugün
      return now;
    }

    // Farklı gün → gelecek ilk o gün
    int diff = (weekday - now.weekday) % 7;
    return now.add(Duration(days: diff));
  }

  Future<void> _scheduleReminder(ReminderModel r) async {
    final now = DateTime.now();

    // Eğer tekrar günleri boşsa → sadece bugünün weekday’i
    final days = r.repeatDays.isEmpty ? {now.weekday} : r.repeatDays;

    for (final day in days) {
      // 🔥 Yeni FIX: Bugün + saat + önümüzdeki gün hesaplaması
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

      // Her tekrar için aralık
      final interval = (total / r.repeatCount).floor();

      for (int i = 0; i < r.repeatCount; i++) {
        final t = start.add(Duration(minutes: interval * i));

        // Ön geçmiş zamanları atla
        if (t.isBefore(now)) continue;

        await _scheduleSingle(r, t);
      }
    }
  }

  Future<void> _scheduleSingle(ReminderModel r, DateTime time) async {
    print("🔔 [_scheduleSingle] START for reminder: ${r.id}");
    print("➡ categoryIds: ${r.categoryIds}");

    // Category fallback
    final categorySet = r.categoryIds.isEmpty ? {"general"} : r.categoryIds;

    // Random affirmation
    final aff = appState.getRandomAffirmation(categorySet);
    final rendered = aff?.renderWithName(appState.preferences.userName) ??
        "Your affirmation is ready.";

    // 🚀 Doğru time: her zaman tz.local üzerinden
    final tzTime = buildNextInstance(time);

    final notifId = tzTime.millisecondsSinceEpoch ~/ 1000;

    print("📅 Scheduling notification:");
    print("   • ID: $notifId");
    print("   • Time: $tzTime");
    print("   • Body: $rendered");

    await _notifications.zonedSchedule(
      notifId,
      'Affirmation Time 🌟',
      rendered,
      tzTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'affirmation_reminders',
          'Affirmation Reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    print("✔ Notification scheduled.\n");
  }

  tz.TZDateTime buildNextInstance(DateTime time) {
    final now = tz.TZDateTime.now(tz.local);

    var scheduled = tz.TZDateTime(
      tz.local,
      time.year,
      time.month,
      time.day,
      time.hour,
      time.minute,
      time.second,
    );

    // Geçmişse → yarına kaydır
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    print("⏰ NOW: $now");
    print("⏰ SCHEDULED: $scheduled");

    return scheduled;
  }
}
