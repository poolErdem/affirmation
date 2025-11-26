import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reminder.dart';
import '../models/user_preferences.dart';

class ReminderState extends ChangeNotifier {
  List<ReminderModel> _reminders = [];
  UserPreferences? _userPrefs;

  List<ReminderModel> get reminders => List.unmodifiable(_reminders);

  // -------------------------------------------------------------------------
  // UserPreferences bağla (AppState yüklemesi tamamlanınca çağırılacak)
  // -------------------------------------------------------------------------
  void bindUserPreferences(UserPreferences prefs) {
    _userPrefs = prefs;

    // prefs’ten mevcut reminder’ları al
    _reminders = List<ReminderModel>.from(prefs.reminders);

    notifyListeners();
  }

  bool get isPremium {
    return _userPrefs?.isPremiumValid ?? false;
  }

  int get limit => isPremium ? 5 : 1;

  bool get canAddReminder => _reminders.length < limit;

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
  // SAVE → SharedPrefs + UserPreferences
  // -------------------------------------------------------------------------
  Future<void> _saveToPrefs() async {
    if (_userPrefs == null) return;

    final prefs = await SharedPreferences.getInstance();

    // UserPreferences’ı güncelle
    _userPrefs = _userPrefs!.copyWith(
      reminders: List<ReminderModel>.from(_reminders),
    );

    // JSON olarak yaz
    final list = _reminders.map((r) => r.toJson()).toList();
    await prefs.setString("reminders_json", jsonEncode(list));

    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // LOAD
  // -------------------------------------------------------------------------
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString("reminders_json");

    if (raw != null && raw.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(raw);
        _reminders =
            decoded.map((json) => ReminderModel.fromJson(json)).toList();
      } catch (e) {
        debugPrint("ReminderState load error $e");
      }
    }

    notifyListeners();
  }
}
