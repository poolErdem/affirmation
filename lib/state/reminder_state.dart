import 'dart:convert';
import 'package:affirmation/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/reminder.dart';

@pragma('vm:entry-point')
void _onBackgroundNotification(NotificationResponse response) {
  // Background olaylarını buraya yazabilirsin
}

class ReminderState extends ChangeNotifier {
  final AppState appState;

  ReminderState({required this.appState});

  List<ReminderModel> _reminders = [];
  bool _isPremium = false;

  // Notification plugin
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  List<ReminderModel> get reminders => List.unmodifiable(_reminders);
  bool get isPremium => _isPremium;
  int get limit => _isPremium ? 200 : 20;
  bool get canAddReminder => _reminders.length < limit;

  // -------------------------------------------------------------------------
  // INITIALIZE (AppState'ten premium durumu al + Notifications setup)
  // -------------------------------------------------------------------------
  Future<void> initialize(bool isPremium) async {
    _isPremium = isPremium;
    await _initializeNotifications();
    await _loadFromPrefs();

    //  test modu
    // assert(() {
    //   _debugAutoTest();
    //   return true;
    // }());

    // ❗❗ SADECE DEBUG İÇİN AÇ  // KALDIRACAZ
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("reminders_json");
    print("🧹 DEBUG → reminders_json temizlendi");

    await _loadFromPrefs();

    // PROD → reminder'ları schedule et
    await _scheduleAllReminders();

    notifyListeners();
  }

  void clearReminderPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("reminders_json");
    print("🧹 reminders_json TEMİZLENDİ");
  }

  Future<void> _scheduleAllReminders() async {
    debugPrint("🗓 PROD → Tüm reminder'lar schedule ediliyor...");

    if (_reminders.isEmpty) {
      debugPrint("⚠️ PROD → Schedule edilecek reminder yok.");
      return;
    }

    // Clear eski schedule'lar
    await _notificationsPlugin.cancelAll();

    // Her reminder için tekrar oluştur
    for (final r in _reminders) {
      await _scheduleReminder(r);
    }

    debugPrint("🎉 PROD → Tüm reminder schedule edildi!");
  }

  Future<void> _scheduleReminder(ReminderModel r) async {
    debugPrint("🗓 SCHEDULE → Reminder: ${r.id}");

    final now = DateTime.now();

    // Eğer repeatDays boşsa bugün için schedule et
    final days = r.repeatDays.isEmpty ? {now.weekday} : r.repeatDays;

    for (final day in days) {
      // O günün tarihi (bugün veya gelecek hafta)
      DateTime dayDate = _nextWeekday(now, day);

      // Bugünse ve saat geçmişse yarın için al
      if (dayDate.year == now.year &&
          dayDate.month == now.month &&
          dayDate.day == now.day) {
        final startDateTime = DateTime(
          dayDate.year,
          dayDate.month,
          dayDate.day,
          r.startTime.hour,
          r.startTime.minute,
        );

        if (startDateTime.isBefore(now)) {
          dayDate = dayDate.add(const Duration(days: 7));
        }
      }

      // Başlangıç ve bitiş zamanları
      DateTime start = DateTime(
        dayDate.year,
        dayDate.month,
        dayDate.day,
        r.startTime.hour,
        r.startTime.minute,
      );

      DateTime end = DateTime(
        dayDate.year,
        dayDate.month,
        dayDate.day,
        r.endTime.hour,
        r.endTime.minute,
      );

      // Gece geçişi kontrolü
      if (end.isBefore(start)) {
        end = end.add(const Duration(days: 1));
      }

      // Toplam süre
      final totalMinutes = end.difference(start).inMinutes;

      if (totalMinutes <= 0 || r.repeatCount <= 0) {
        debugPrint("⚠️ Geçersiz zaman aralığı: start=$start end=$end");
        continue;
      }

      // Her bildirim arasındaki dakika
      final intervalMinutes = (totalMinutes / r.repeatCount).floor();

      debugPrint(
        "⏱ SCHEDULE → ${r.id} → start=$start, end=$end, count=${r.repeatCount}, interval=$intervalMinutes min",
      );

      // repeatCount kadar bildirim schedule et
      for (int i = 0; i < r.repeatCount; i++) {
        final scheduledTime = start.add(Duration(minutes: intervalMinutes * i));

        // Geçmiş zamana schedule etme
        if (scheduledTime.isBefore(now)) {
          debugPrint("⏭️ Geçmiş zaman atlandı: $scheduledTime");
          continue;
        }

        await _scheduleSingleNotification(r, scheduledTime);

        debugPrint("🔔 Scheduled ${r.id} #$i → $scheduledTime");
      }
    }
  }

  Future<void> _scheduleSingleNotification(
      ReminderModel r, DateTime when) async {
    final tzTime = tz.TZDateTime.from(when, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'affirmation_reminders',
      'Affirmation Reminders',
      channelDescription: 'Daily affirmation notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();

    await _notificationsPlugin.zonedSchedule(
      when.millisecondsSinceEpoch ~/
          1000, //  when.hashCode   Benzersiz ID (saniye bazlı)
      'Affirmation Time! 🌟',
      'It’s time for your affirmation.',
      tzTime,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // ⭐ Burası
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  DateTime _nextWeekday(DateTime now, int weekday) {
    int diff = (weekday - now.weekday) % 7;
    return now.add(Duration(days: diff));
  }

  // -------------------------------------------------------------------------
  // Notification Plugin Initialize
  // -------------------------------------------------------------------------
  Future<void> _initializeNotifications() async {
    // Android ayarları
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS ayarları
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotification,
    );

// ⭐ Android notification channel oluştur
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'affirmation_reminders', // ID
      'Affirmation Reminders', // Name
      description: 'Daily affirmation notifications',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Android 13+ için izin iste
    await _requestNotificationPermission();

    // ⭐ EXACT ALARM izni iste (Android 12+)
    await _requestExactAlarmPermission();
  }

  // -------------------------------------------------------------------------
  // İzin İste (Android 13+)
  // -------------------------------------------------------------------------
  Future<void> _requestNotificationPermission() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }

  Future<void> _requestExactAlarmPermission() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // Android 12+ için exact alarm izni kontrol et
      final bool? canScheduleExact =
          await androidPlugin.canScheduleExactNotifications();

      if (canScheduleExact == false) {
        debugPrint("⚠️ Exact alarm izni yok, istek gönderiliyor...");
        await androidPlugin.requestExactAlarmsPermission();
      } else {
        debugPrint("✅ Exact alarm izni var!");
      }
    }
  }

  // -------------------------------------------------------------------------
  // Bildirime tıklandığında
  // -------------------------------------------------------------------------
  void _onNotificationTapped(NotificationResponse response) async {
    debugPrint("📱 Bildirime tıklandı → actionId: ${response.actionId}");

    // payload JSON ise decode et
    String? payload = response.payload;

    Map<String, dynamic>? data;
    if (payload != null && payload.isNotEmpty) {
      try {
        data = jsonDecode(payload);
      } catch (_) {
        data = null;
      }
    }

    final affId = data?["id"];
    final affText = data?["text"];

    if (response.actionId == 'favorite_action') {
      debugPrint("❤️ FAVORITE tıklandı");

      if (affId != null) {
        appState.setPendingShareText("");
        appState.toggleFavorite(affId);
        debugPrint("❤️ Favorite eklendi/çıkarıldı → $affId");
      }
    }

    if (response.actionId == 'share_action') {
      debugPrint("📤 SHARE tıklandı");

      if (affText != null) {
        appState.setPendingShareText(affText);
        debugPrint("📤 Paylaşılacak metin: $affText");
      }
    }

    debugPrint("📱 Notification tap payload: $payload");
  }

  // -------------------------------------------------------------------------
  // Premium durumunu güncelle (AppState değişince çağrılacak)
  // -------------------------------------------------------------------------
  void updatePremiumStatus(bool isPremium) {
    _isPremium = isPremium;
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // ADD
  // -------------------------------------------------------------------------
  bool addReminder(ReminderModel r) {
    if (!canAddReminder) return false;

    _reminders.add(r);
    _saveToPrefs();
    return true;
  }

  // -------------------------------------------------------------------------
  // UPDATE
  // -------------------------------------------------------------------------
  void updateReminder(ReminderModel updated) {
    final index = _reminders.indexWhere((r) => r.id == updated.id);
    if (index != -1) {
      _reminders[index] = updated;
      _saveToPrefs();
    }
  }

  // -------------------------------------------------------------------------
  // DELETE
  // -------------------------------------------------------------------------
  void deleteReminder(String id) {
    _reminders.removeWhere((r) => r.id == id);
    _saveToPrefs();
  }

  // -------------------------------------------------------------------------
  // SAVE → SharedPreferences'a JSON olarak kaydet
  // -------------------------------------------------------------------------
  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Debug loglar
      debugPrint(
          "💾 [SAVE] Kaydedilecek reminder sayısı = ${_reminders.length}");

      for (final r in _reminders) {
        debugPrint("🟡 Reminder toJson: ${r.toJson()}");
      }

      // JSON encode
      final list = _reminders.map((r) => r.toJson()).toList();
      final encoded = jsonEncode(list);

      debugPrint("📦 [SAVE] Encoded JSON: $encoded");

      // Kaydet
      await prefs.setString("reminders_json", encoded);

      debugPrint("✅ [SAVE] reminders_json başarıyla kaydedildi!");
      notifyListeners();
    } catch (e, stackTrace) {
      debugPrint("❌ [SAVE ERROR] $e");
      debugPrint("Stack trace: $stackTrace");
    }
  }

  // -------------------------------------------------------------------------
  // LOAD → SharedPreferences'tan yükle
  // -------------------------------------------------------------------------
  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString("reminders_json");

      debugPrint("🔵 [LOAD] RAW reminders_json: $raw");

      if (raw == null || raw.isEmpty) {
        debugPrint("⚪ [LOAD] Kaydedilmiş reminder bulunamadı.");
        _reminders = [];
        return;
      }

      final decoded = jsonDecode(raw);

      if (decoded is! List) {
        debugPrint("⚠️ [LOAD] Bozuk format (List değil) → Temizleniyor!");
        _reminders = [];
        await prefs.remove("reminders_json");
        return;
      }

      // Her item'i decode et
      _reminders = [];
      for (var json in decoded) {
        try {
          final reminder = ReminderModel.fromJson(json);
          _reminders.add(reminder);
        } catch (e) {
          debugPrint("⚠️ [LOAD] Geçersiz reminder atlandı: $json → Hata: $e");
        }
      }

      debugPrint("✅ [LOAD] Reminders yüklendi: ${_reminders.length}");
    } catch (e, stackTrace) {
      debugPrint("❌ [LOAD ERROR] $e");
      debugPrint("Stack trace: $stackTrace");
      _reminders = [];
    }
  }

  // -------------------------------------------------------------------------
  // INTERNAL FIRE → Bildirim tetikleme
  // -------------------------------------------------------------------------
  Future<void> _fireReminder(ReminderModel r) async {
    debugPrint("🔔 FIRE → Reminder çalıştı: ${r.categoryIds}");

    appState.setActiveCategories(r.categoryIds);
    final aff = appState.getRandomAffirmation();

    if (aff == null) {
      debugPrint("⚠️ FIRE → Affirmation bulunamadı.");
      return;
    }

    // Android Notification Actions
    final androidDetails = AndroidNotificationDetails(
      'affirmation_reminders',
      'Affirmation Reminders',
      channelDescription: 'Daily affirmation notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: const BigTextStyleInformation(''),
      actions: [
        AndroidNotificationAction(
          'favorite_action', // action ID
          'FAVORITE', // görünen buton
        ),
        AndroidNotificationAction(
          'share_action',
          'SHARE',
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails();

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notificationsPlugin.show(
        r.id.hashCode,
        'Affirmation',
        aff.text,
        notificationDetails,
        payload: jsonEncode({
          "id": aff.id,
          "text": aff.text,
          "category": r.categoryIds.first,
        }),
      );

      debugPrint("✅ Bildirim gönderildi (actions dahil)!");
    } catch (e) {
      debugPrint("❌ Bildirim hatası: $e");
    }
  }

  // -------------------------------------------------------------------------
  // DEBUG: Test reminder oluştur
  // -------------------------------------------------------------------------
  void debugCreateSampleReminder() {
    final now = DateTime.now();

    print("saat: ${now.hour}");

    final reminder = ReminderModel(
      id: "debug_${DateTime.now().millisecondsSinceEpoch}",
      categoryIds: {"happiness"}, // ✅ Set<String>
      startTime: TimeOfDay(hour: now.hour, minute: now.minute + 3),
      endTime:
          TimeOfDay(hour: now.hour, minute: now.minute + 6), // 3 dakika sonra
      repeatCount: 10, // 10 bildirim
      repeatDays: {now.weekday},
      enabled: true,
      isPremium: true,
    );

    if (addReminder(reminder)) {
      debugPrint(
        "🟢 DEBUG → Test reminder eklendi, kategori: ${reminder.categoryIds.first}",
      );
    } else {
      debugPrint(
        "❌ DEBUG → Reminder eklenemedi (limit: $_reminders.length/$limit)",
      );
    }
  }

  // -------------------------------------------------------------------------
  // DEBUG: İlk reminder'ı tetikle
  // -------------------------------------------------------------------------
  Future<void> debugFireFirstReminder() async {
    if (_reminders.isEmpty) {
      debugPrint("⚠️ DEBUG → Reminder yok.");
      return;
    }

    debugPrint(
        "🔥 DEBUG → Reminder tetiklendi: ${_reminders.first.categoryIds}");
    await _fireReminder(_reminders.first);
  }

  Future<void> _debugAutoTest() async {
    debugPrint("🐞 DEBUG → Auto reminder test başlıyor...");

    // 1) Bir adet test reminder oluştur
    debugCreateSampleReminder();

    // 2) 3 tane art arda bildirimi ateşle
    await Future.delayed(const Duration(seconds: 10));
    await debugFireFirstReminder();

    await Future.delayed(const Duration(seconds: 10));
    await debugFireFirstReminder();

    await Future.delayed(const Duration(seconds: 10));
    await debugFireFirstReminder();

    await Future.delayed(const Duration(seconds: 15));
    await debugFireFirstReminder();

    await Future.delayed(const Duration(seconds: 15));
    await debugFireFirstReminder();

    debugPrint("🐞 DEBUG → Auto test bitti.");
  }

  Future<void> debugScheduleImmediateNotification() async {
    final now = DateTime.now();
    final scheduledTime = now.add(const Duration(seconds: 10));

    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    debugPrint("🔔 DEBUG → Bildirim birazdan gelecek inş: $tzTime");

    const androidDetails = AndroidNotificationDetails(
      'affirmation_reminders',
      'Affirmation Reminders',
      channelDescription: 'Daily affirmation notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();

    await _notificationsPlugin.zonedSchedule(
      999, // Test ID
      'TEST Affirmation 🧪',
      'Bu bir test bildirimidir.',
      tzTime,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    debugPrint("✅ Test bildirimi schedule edildi!");
  }
}
