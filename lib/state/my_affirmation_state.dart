import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/my_affirmation.dart';
import '../constants/constants.dart';
import 'my_aff_playback_state.dart';

class MyAffirmationState extends ChangeNotifier {
  List<MyAffirmation> _items = [];
  List<MyAffirmation> get items => _items;

  late MyAffPlaybackState playbackMyAff;
  MyAffPlaybackState get playback => playbackMyAff;

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  MyAffirmationState() {
    playbackMyAff = MyAffPlaybackState();

    playbackMyAff.addListener(() {
      // playback dışarıda değiştiğinde MyAffirmationState’i de yenile
      _currentIndex = playback.currentIndex;
      notifyListeners();
    });
  }

  bool _loaded = false;
  bool get isLoaded => _loaded;

  Future<void> initialize() async {
    await loadPrefs();
    _loaded = true;

    playback.updateAffirmations(_items);

    _currentIndex = 0;
    playback.setCurrentIndex(0); // 🔥 LOCAL + PLAYBACK SENKRON

    notifyListeners();
  }

  Future<void> loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(Constants.prefsKey);

    if (data != null) {
      final list = jsonDecode(data) as List;
      _items = list.map((e) => MyAffirmation.fromJson(e)).toList();
    } else {
      _items = [];
    }
  }

  Future<void> savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = jsonEncode(_items.map((e) => e.toJson()).toList());
    await prefs.setString(Constants.prefsKey, jsonList);
  }

  Future<void> _commit() async {
    await savePrefs();
  }

  // -----------------------------------------------------
  // ADD
  // -----------------------------------------------------
  Future<void> add(String text) async {
    final id = "my_${DateTime.now().millisecondsSinceEpoch}";
    _items.add(MyAffirmation(id: id, text: text));
    await _commit();

    playback.updateAffirmations(_items);

    final newIndex = _items.length - 1;

    _currentIndex = newIndex; // 🔥 LOCAL
    playback.setCurrentIndex(newIndex); // 🔥 PLAYBACK

    notifyListeners();
  }

  // -----------------------------------------------------
  // UPDATE
  // -----------------------------------------------------
  Future<void> update(String id, String newText) async {
    final index = _items.indexWhere((x) => x.id == id);
    if (index == -1) return;

    _items[index] = _items[index].copyWith(text: newText);
    await _commit();

    playback.updateAffirmations(_items);

    _currentIndex = index; // 🔥 LOCAL
    playback.setCurrentIndex(index); // 🔥 PLAYBACK

    notifyListeners();
  }

  // -----------------------------------------------------
  // REMOVE
  // -----------------------------------------------------
  Future<void> remove(String id) async {
    final oldIndex = _items.indexWhere((e) => e.id == id);

    _items.removeWhere((x) => x.id == id);
    await _commit();

    playback.updateAffirmations(_items);

    if (_items.isEmpty) {
      _currentIndex = 0;
      playback.setCurrentIndex(0);
    } else {
      final safeIndex = oldIndex.clamp(0, _items.length - 1);
      _currentIndex = safeIndex; // 🔥 LOCAL
      playback.setCurrentIndex(safeIndex); // 🔥 PLAYBACK
    }

    notifyListeners();
  }

  // -----------------------------------------------------
  // MANUAL SETTER
  // -----------------------------------------------------
  void setCurrentIndex(int index) {
    _currentIndex = index;
    playback.setCurrentIndex(index); // 🔥 İkisini birden güncelle
    notifyListeners();
  }

  Future<bool> isOverLimit() async {
    final prefs = await SharedPreferences.getInstance();
    final premiumActive = prefs.getBool('premiumActive') ?? false;
    final maxAllowed =
        premiumActive ? Constants.premiumMyAffLimit : Constants.freeMyAffLimit;
    return _items.length >= maxAllowed;
  }
}
