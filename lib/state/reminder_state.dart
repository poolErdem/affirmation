import 'dart:convert';
import 'dart:io';
import 'package:affirmation/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
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
    removePrefs();

    await _initNotifications();

    await _loadFromPrefs();

    print("📚 [REM] Yüklenen reminder sayısı: ${_reminders.length}");
    print("⏰ [REM] _scheduleAll() başlıyor... (existing=${_reminders.length})");

    final sw = Stopwatch()..start();

    await _scheduleAll();

    sw.stop();

    _loaded = true;
    notifyListeners();

    print("🏁 [REM] initialize() tamam! Sistem hazır 🎉\n");
  }

// ADD
  Future<bool> addReminder(ReminderModel r) async {
    if (_adding) {
      print("⛔ [REM] addReminder İPTAL — zaten çalışıyor.");
      return false;
    }

    _adding = true;
    print("➕ [REM] addReminder() BAŞLADI — safe mode");

    try {
      //if (!canAddReminder) {
      //print("❌ [REM] addReminder → limit dolu.");
      //return false;
      //}

      _reminders.add(r);
      print("✅ Reminder listeye eklendi (len=${_reminders.length})");

      await _savePrefs();
      print("💾 prefs kaydedildi.");

      await _scheduleReminder(r);
      print("⏰ reminder schedule edildi.");

      notifyListeners();
      print("📢 notifyListeners çağrıldı (addReminder)");

      return true;
    } finally {
      _adding = false;
      print("🔓 [REM] addReminder kilidi AÇILDI.");
    }
  }

// --------------------------------------------------------
// UPDATE
// --------------------------------------------------------
  Future<void> updateReminder(ReminderModel r) async {
    // Eğer zaten update ediliyorsa — direkt çık
    if (_updating) {
      print("⛔ [REM] updateReminder İPTAL — zaten çalışıyor.");
      return;
    }

    _updating = true;
    print("📝 [REM] updateReminder() BAŞLADI — safe mode");

    try {
      final index = _reminders.indexWhere((x) => x.id == r.id);
      if (index == -1) {
        print("❌ [REM] updateReminder → id yok, çıkıyorum.");
        return;
      }

      _reminders[index] = r;
      print("✅ [REM] reminder listede güncellendi.");

      await _savePrefs();
      print("💾 prefs kaydedildi.");

      await cancelReminder(r.id);
      print("🗑️ eski reminder iptal edildi.");

      await _scheduleReminder(r);
      print("⏰ yeni reminder schedule edildi.");

      notifyListeners();
      print("📢 notifyListeners çağrıldı (update).");
    } finally {
      _updating = false;
      print("🔓 [REM] updateReminder() kilidi AÇILDI.");
    }
  }

// --------------------------------------------------------
// DELETE
// --------------------------------------------------------
  Future<void> deleteReminder(String id) async {
    if (_deleting) {
      print("⛔ [REM] deleteReminder İPTAL — zaten çalışıyor.");
      return;
    }

    _deleting = true;
    try {
      final before = _reminders.length;

      _reminders.removeWhere((r) => r.id == id);

      final after = _reminders.length;
      print("   • önce length = $before, sonra = $after");

      await _savePrefs();
      print("💾 prefs kaydedildi (delete).");

      await cancelReminder(id);
      print("🧹 eski notification iptal edildi.");

      notifyListeners();
      print("📢 notifyListeners çağrıldı (delete).");
    } finally {
      _deleting = false;
      print("🔓 [REM] deleteReminder kilidi AÇILDI.");
    }
  }

  Future<void> cancelReminder(String id) async {
    final notifId = id.hashCode;
    print("🚫 [REM] cancelReminder() → id=$id, notifId=$notifId");
    await _notifications.cancel(notifId);
    print("✔ [REM] Notification cancel tamam (notifId=$notifId).");
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

  Future<void> removePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final removed = await prefs.remove('reminders_json');

    if (removed) {
      print("✔ [REM] reminders_json SharedPrefs'ten silindi.");
    } else {
      print("⚠ [REM] reminders_json bulunamadı veya silinemedi.");
    }

    // State'i sıfırla
    _reminders.clear();

    // Tüm eski bildirimleri iptal et
    await _notifications.cancelAll();

    notifyListeners();
  }

  // NOTIFICATIONS INIT
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

    _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();

    // Notification permission
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Exact alarm permission
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    final enabled = await androidPlugin?.areNotificationsEnabled();
    print("enabled : $enabled");

    if (androidPlugin != null) {
      // Battery optimization kontrolü
      final can = await androidPlugin.canScheduleExactNotifications();
      print("CAN EXACT? $can");

      if (can == false) {
        await androidPlugin.requestExactAlarmsPermission();
      }
    }
  }

  void _onTap(NotificationResponse response) {}

  // SCHEDULE ALL
  Future<void> _scheduleAll() async {
    await _notifications.cancelAll();

    for (final r in _reminders) {
      if (r.enabled) {
        await _scheduleReminder(r);
      }
    }
  }

  // SCHEDULE SINGLE REMINDER
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

  Future<void> checkPendingNotifications() async {
    final pending = await _notifications.pendingNotificationRequests();
    print("📋 Bekleyen notification sayısı: ${pending.length}");
    for (var p in pending) {
      print("   • ID: ${p.id}, Title: ${p.title}, Body: ${p.body}");
    }
  }

  Future<void> testScheduleSingle() async {
    print("🔔 [TEST] START for reminder:");

    // 1. Permission Handler ile izin iste
    final permissionStatus = await Permission.notification.request();
    print("📱 Permission status: $permissionStatus");

    if (permissionStatus.isDenied || permissionStatus.isPermanentlyDenied) {
      print("❌ Notification permission NOT granted!");

      if (permissionStatus.isPermanentlyDenied) {
        // Kullanıcıyı ayarlara yönlendir
        print("⚠️ Opening app settings...");
        await openAppSettings();
      }
      return;
    }

    // 2. Exact alarm izni (Android 12+)
    if (await Permission.scheduleExactAlarm.isDenied) {
      final exactAlarmStatus = await Permission.scheduleExactAlarm.request();
      print("⏰ Exact alarm permission: $exactAlarmStatus");
    }

    // 3. Test bildirimi zamanla
    final now = tz.TZDateTime.now(tz.local);
    final testTime = now.add(const Duration(seconds: 10));
    print("⏰ Current time: $now");
    print("⏰ Test time: $testTime");

    await _notifications.zonedSchedule(
      9999,
      '🌟 Affirmation Time',
      "yeah babe",
      testTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'affirmation_reminders',
          'Affirmation Reminders',
          channelDescription: 'Daily affirmation reminders',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher', // App ikonunuz
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    print("✔ Notification scheduled for ID: 9999\n");

    // 4. Pending notifications kontrolü
    final pending = await _notifications.pendingNotificationRequests();
    print("📋 Pending notifications: ${pending.length}");
    for (var p in pending) {
      print("  - ID: ${p.id}, Title: ${p.title}");
    }
  }

// Hemen bildirim testi
  Future<void> testImmediateNotification() async {
    print("🔔 [TEST] Sending immediate notification...");

    final permissionStatus = await Permission.notification.request();
    if (!permissionStatus.isGranted) {
      print("❌ Permission denied!");
      return;
    }

    await _notifications.show(
      9998,
      '🌟 Test Notification',
      'If you see this, notifications work!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'affirmation_reminders',
          'Affirmation Reminders',
          channelDescription: 'Test channel',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );

    print("✔ Immediate notification sent!");
  }

  Future<bool> checkNotificationPermissions() async {
    final notification = await Permission.notification.status;
    final exactAlarm = await Permission.scheduleExactAlarm.status;

    print("🔔 Notification permission: $notification");
    print("⏰ Exact alarm permission: $exactAlarm");

    return notification.isGranted;
  }

  Future<void> requestNotificationPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      print("🔔 Notification permission status: $status");

      if (status.isDenied) {
        print("❌ Notification permission denied!");
      }
    }
  }

  Future<void> _scheduleSingle(ReminderModel r, DateTime time) async {
    print("🔔 [_scheduleSingle] START for reminder: ${r.id}");
    print("➡ categoryIds: ${r.categoryIds}");

    final now = tz.TZDateTime.now(tz.local);
    final testTime = now.add(const Duration(seconds: 10)); // 10 saniye sonra
    print("now $testTime");
    // Category fallback
    final categorySet = r.categoryIds.isEmpty ? {"general"} : r.categoryIds;

    // Random affirmation
    final aff = appState.getRandomAffirmation(categorySet);
    final rendered = aff?.renderWithName(appState.preferences.userName) ??
        "Your affirmation is ready.";

    // 🚀 Doğru time: her zaman tz.local üzerinden
    final tzTime = buildNextInstance(time);

// Daha güvenli ID oluşturma
    final notifId =
        (r.id.hashCode ^ time.millisecondsSinceEpoch ^ time.weekday) &
            0x7fffffff;

    print("📅 Scheduling notification:");
    print("   • ID: $notifId");
    print("   • Time: $tzTime");
    print("   • Body: $rendered");

    await _notifications.zonedSchedule(
      notifId,
      '🌟 Affirmation Time',
      rendered,
      testTime,
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
