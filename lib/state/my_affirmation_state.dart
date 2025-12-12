import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/my_affirmation.dart';
import '../constants/constants.dart';

class MyAffirmationState extends ChangeNotifier {
  // Affirmations
  List<MyAffirmation> _items = [];
  final Map<String, int> myTimestamps = {}; // id -> millis

  int _currentIndex = 0;

  /// Challenge 1. günün gerçek takvim tarihi
  int? challengeStart;

  /// Simülasyon için gün kaydırma
  int _simOffset = 0;

  bool _loaded = false;
  bool get isLoaded => _loaded;

  List<MyAffirmation> get items => _items;
  int get currentIndex => _currentIndex;

  bool get isTodayCompleted => writtenCountToday >= requiredToday;
  bool _lastAddTriggeredReset = false;
  bool get lastAddTriggeredReset => _lastAddTriggeredReset;
  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime get virtualToday =>
      _dateOnly(DateTime.now()).add(Duration(days: _simOffset));
  DateTime? get startDate => challengeStart == null
      ? null
      : _dateOnly(DateTime.fromMillisecondsSinceEpoch(challengeStart!));

  // INIT
  Future<void> initialize() async {
    await loadPrefs();
    _loaded = true;
    notifyListeners();
  }

  // CHALLENGE DAY LOGIC
  int get challengeDay {
    if (startDate == null) return 1;

    int diff = virtualToday.difference(startDate!).inDays + 1;
    return diff.clamp(1, 21);
  }

  int get todayChallengeDay => challengeDay.clamp(1, 21);

  int requiredForDay(int day) {
    if (day <= 7) return 1;
    if (day <= 14) return 2;
    return 3;
  }

  int get requiredToday => requiredForDay(todayChallengeDay);

  int get writtenCountToday => writtenCountForDay(todayChallengeDay);

  int writtenCountForDay(int day) {
    if (startDate == null) return 0;

    final targetDate = startDate!.add(Duration(days: day - 1));
    final key = "${targetDate.year}-${targetDate.month}-${targetDate.day}";

    int c = 0;
    myTimestamps.forEach((_, ts) {
      if (_dayKey(ts) == key) {
        c++;
      }
    });
    return c;
  }

  int get realDaysPassed {
    if (startDate == null) return 0;
    return _dateOnly(DateTime.now()).difference(startDate!).inDays;
  }

  set lastAddTriggeredReset(bool value) {
    _lastAddTriggeredReset = value;
    notifyListeners();
  }

  String _dayKey(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return "${d.year}-${d.month}-${d.day}";
  }

  // START CHALLENGE
  void startChallengeIfNeeded() {
    if (challengeStart == null) {
      challengeStart = _dateOnly(DateTime.now()).millisecondsSinceEpoch;
      _simOffset = 0;
      savePrefs();
    }
  }

  // SIMULATE
  Future<void> simulateNextDay() async {
    if (challengeStart == null) return;

    if (!isTodayCompleted) {
      _resetChallenge();
      notifyListeners();
      print("⚠️ GÜN TAMAMLANMADI → RESET");
      return;
    }

    if (challengeDay >= 21) {
      _resetChallenge();
      notifyListeners();
      print("🔄 21. günden sonra RESET");
      return;
    }

    _simOffset += 1;

    await savePrefs();
    notifyListeners();

    print("🔥 simulateNextDay → yeni sanal gün: $challengeDay");
  }

  // RESET
  void _resetChallenge() {
    final today = _dateOnly(DateTime.now());

    challengeStart = today.millisecondsSinceEpoch;
    _simOffset = 0;

    myTimestamps.clear();

    _lastAddTriggeredReset = true;

    savePrefs();

    print("🔄 Challenge sıfırlandı → Gün 1");
  }

  // ADD
  Future<void> add(String text) async {
    startChallengeIfNeeded();

    final int today = challengeDay;

    int lastWrittenDay = 0;

    for (int d = 1; d <= 21; d++) {
      if (writtenCountForDay(d) > 0) {
        lastWrittenDay = d;
      }
    }

    //    Örn: Son gün 1 → Bugün 3 → reset
    if (lastWrittenDay > 0 && today > lastWrittenDay + 1) {
      _resetChallenge();
      notifyListeners();
      return Future.error("reset");
    }

    // 3) Sadece DÜN eksikse (geçiş günü) yine reset
    if (today > 1 && realDaysPassed > 0) {
      final yesterday = today - 1;

      if (writtenCountForDay(yesterday) < requiredForDay(yesterday)) {
        _resetChallenge();
        notifyListeners();
        return Future.error("reset");
      }
    }

    // 4) Buraya geldiysek → her şey temiz, ekleme yapılabilir
    final now = DateTime.now();
    final id = "my_${now.millisecondsSinceEpoch}";

    // Affirmation timestamp’i → challenge gününün gerçekteki tarihine göre
    final targetDate = startDate!.add(Duration(days: today - 1));
    final ts = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      now.hour,
      now.minute,
      now.second,
    ).millisecondsSinceEpoch;

    _items.add(MyAffirmation(id: id, text: text, createdAt: ts));
    myTimestamps[id] = ts;

    _lastAddTriggeredReset = false;

    await savePrefs();

    _currentIndex = _items.length - 1;

    notifyListeners();

    print("💾 ADD OK → gün:$today  writtenToday:$writtenCountToday");
  }

  // UPDATE
  Future<void> update(String id, String newText) async {
    final index = _items.indexWhere((x) => x.id == id);
    if (index == -1) return;

    _items[index] = _items[index].copyWith(text: newText);

    await savePrefs();
    notifyListeners();
  }

  // REMOVE
  Future<void> remove(String id) async {
    _items.removeWhere((x) => x.id == id);
    myTimestamps.remove(id);

    await savePrefs();
    notifyListeners();
  }

  // MANUAL INDEX SETTER (home vs. diğer sayfalar)
  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  /// Limit kontrolü (Free / Premium myAff sınırı)
  Future<bool> isOverLimit() async {
    final prefs = await SharedPreferences.getInstance();
    final premiumActive = prefs.getBool('premiumActive') ?? false;
    final maxAllowed =
        premiumActive ? Constants.premiumMyAffLimit : Constants.freeMyAffLimit;
    return _items.length >= maxAllowed;
  }

  // PREFS
  Future<void> loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // Items
    final data = prefs.getString(Constants.prefsKey);
    if (data != null) {
      final list = jsonDecode(data) as List;
      _items = list.map((e) => MyAffirmation.fromJson(e)).toList();
    }

    // Timestamps
    final tsRaw = prefs.getString("myAffTimestamps");
    if (tsRaw != null) {
      myTimestamps.addAll(
        Map<String, int>.from(jsonDecode(tsRaw)),
      );
    }

    // Challenge start
    challengeStart = prefs.getInt("challengeStart");

    // Offset
    _simOffset = prefs.getInt("simOffset") ?? 0;

    _lastAddTriggeredReset = prefs.getBool("lastAddTriggeredReset") ?? false;
  }

  Future<void> savePrefs() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      Constants.prefsKey,
      jsonEncode(_items.map((e) => e.toJson()).toList()),
    );

    await prefs.setString(
      "myAffTimestamps",
      jsonEncode(myTimestamps),
    );

    if (challengeStart != null) {
      await prefs.setInt("challengeStart", challengeStart!);
    }

    await prefs.setInt("simOffset", _simOffset);

    await prefs.setBool("lastAddTriggeredReset", _lastAddTriggeredReset);
  }

  // İstersen ileride dışarıdan kullanırsın diye bıraktım
  String encodeTimestampMap(Map<String, int> map) {
    return jsonEncode(map);
  }

  Map<String, int> decodeTimestampMap(String raw) {
    final decoded = jsonDecode(raw);
    return Map<String, int>.from(decoded);
  }

  // MyAffirmationState içine ekle
  DateTime? getCreatedAt(String id) {
    final ts = myTimestamps[id];
    if (ts == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ts);
  }

  bool get isChallengeCompleted {
    if (challengeStart == null) return false;

    // 1'den 21'e kadar her günün tamamlanmış olması gerekir
    for (int day = 1; day <= 21; day++) {
      if (writtenCountForDay(day) < requiredForDay(day)) {
        return false;
      }
    }

    return true; // 🎉 Challenge başarıyla tamamlandı
  }
}
