import 'dart:convert';
import 'package:affirmation/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/reminder.dart';

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
  int get limit => _isPremium ? 200 : 10;
  bool get canAddReminder => _reminders.length < limit;

  // -------------------------------------------------------------------------
  // INITIALIZE (AppState'ten premium durumu al + Notifications setup)
  // -------------------------------------------------------------------------
  Future<void> initialize(bool isPremium) async {
    _isPremium = isPremium;
    await _initializeNotifications();
    await _loadFromPrefs();
    notifyListeners();
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
    );

    // Android 13+ için izin iste
    await _requestNotificationPermission();
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

  // -------------------------------------------------------------------------
  // Bildirime tıklandığında
  // -------------------------------------------------------------------------
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint("📱 Bildirime tıklandı: ${response.payload}");
    // Uygulamayı affirmation sayfasına yönlendir
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
      final list = _reminders.map((r) => r.toJson()).toList();
      await prefs.setString("reminders_json", jsonEncode(list));
      notifyListeners();
    } catch (e) {
      debugPrint("❌ ReminderState save error: $e");
    }
  }

  // -------------------------------------------------------------------------
  // LOAD → SharedPreferences'tan yükle
  // -------------------------------------------------------------------------
  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString("reminders_json");

      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw);
        _reminders =
            decoded.map((json) => ReminderModel.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint("❌ ReminderState load error: $e");
    }
  }

  // -------------------------------------------------------------------------
  // DEBUG: Test reminder oluştur
  // -------------------------------------------------------------------------
  void debugCreateSampleReminder() {
    final now = DateTime.now();

    final reminder = ReminderModel(
      id: "debug_${DateTime.now().millisecondsSinceEpoch}",
      categoryIds: {"happiness"},
      startTime: TimeOfDay(hour: now.hour, minute: (now.minute + 1) % 60),
      endTime: TimeOfDay(hour: now.hour, minute: (now.minute + 3) % 60),
      repeatCount: 15,
      repeatDays: {now.weekday},
      enabled: true,
      isPremium: false,
    );

    if (addReminder(reminder)) {
      debugPrint("🟢 DEBUG → Test reminder eklendi: ${reminder.id}");
    } else {
      debugPrint(
          "❌ DEBUG → Reminder limit sebebiyle eklenemedi (${_reminders.length}/$limit)");
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

  // -------------------------------------------------------------------------
  // INTERNAL FIRE → Bildirim tetikleme
  // -------------------------------------------------------------------------
  Future<void> _fireReminder(ReminderModel r) async {
    debugPrint("🔔 FIRE → Reminder çalıştı: ${r.categoryIds}");

    appState.setActiveCategories(r.categoryIds);
    final aff = appState.getRandomAffirmation();

    // Notification details
    const androidDetails = AndroidNotificationDetails(
      'affirmation_reminders', // channel ID
      'Affirmation Reminders', // channel name
      channelDescription: 'Daily affirmation notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notificationsPlugin.show(
        r.id.hashCode,
        'Affirmation Time! 🌟',
        '${aff?.text}',
        notificationDetails,
        payload: "",
      );
      debugPrint("✅ Bildirim gönderildi!");
    } catch (e) {
      debugPrint("❌ Bildirim hatası: $e");
    }
  }
}
