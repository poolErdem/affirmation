import 'dart:async';
import 'package:affirmation/constants/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/my_affirmation.dart';

class MyAffPlaybackState extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();

  List<MyAffirmation> affirmations = [];

  bool _volumeEnabled = false;
  bool _autoReadEnabled = false;
  bool _isReading = false;
  bool autoScrollEnabled = true;

  int currentIndex = 0;

  Completer<void>? _ttsCompleter;
  VoidCallback? onLimitReached;
  void Function(int index)? onIndexChanged;
  Timer? _limitTimer;

  bool get autoReadEnabled => _autoReadEnabled;
  bool get volumeEnabled => _volumeEnabled;

  MyAffPlaybackState() {
    _initTts();
  }

  Future<void> toggleVolume() async {
    _volumeEnabled = !_volumeEnabled;
    await _tts.setVolume(_volumeEnabled ? 1.0 : 0.0);
    notifyListeners();
  }

  void forceStop() {
    _isReading = false;
    _autoReadEnabled = false;
    _limitTimer?.cancel();
    _tts.stop();
    notifyListeners();
  }

  Future<void> _initTts() async {
    await _tts.setSpeechRate(0.42);
    await _tts.setPitch(1.0);
    await _tts.setVolume(0.0);

    _tts.setCompletionHandler(() {
      if (_ttsCompleter != null && !_ttsCompleter!.isCompleted) {
        _ttsCompleter!.complete();
      }
    });
  }

  void updateAffirmations(List<MyAffirmation> list) {
    affirmations = list;

    // mevcut index yoksa başa sar
    if (currentIndex >= affirmations.length) {
      currentIndex = 0;
    }

    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    await _tts.setLanguage(code);
    debugPrint("🎤 Language set → $code");
  }

  void setCurrentIndex(int index) {
    currentIndex = index;
    onIndexChanged?.call(index);
    notifyListeners();
  }

  Future<void> toggleAutoRead() async {
    _autoReadEnabled = !_autoReadEnabled;

    if (_autoReadEnabled) {
      _startAutoRead();
    } else {
      await _stopAutoRead();
    }

    notifyListeners();
  }

  Future<void> play(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> _waitTts() async {
    _ttsCompleter = Completer<void>();
    return _ttsCompleter!.future.timeout(
      const Duration(seconds: 25),
      onTimeout: () => debugPrint("TTS timeout"),
    );
  }

  Future<void> _startAutoRead() async {
    if (_isReading) return;
    if (_ttsCompleter != null) {
      await _ttsCompleter!.future;
    }

    _isReading = true;

    // FREE USER LIMIT
    try {
      final prefs = await SharedPreferences.getInstance();
      final isPremium = prefs.getBool("premiumActive") ?? false;

      if (!isPremium) {
        _limitTimer = Timer(
          const Duration(seconds: Constants.freeMyAffReadLimit),
          () async {
            if (!_isReading) return;

            await _stopAutoRead();

            if (onLimitReached != null) {
              onLimitReached!.call();
            }
          },
        );
      }
    } catch (_) {}

    try {
      while (_isReading && _autoReadEnabled) {
        if (affirmations.isEmpty) break;

        if (currentIndex >= affirmations.length) {
          currentIndex = 0;
        }

        final aff = affirmations[currentIndex];

        await play(aff.text);
        await _waitTts();

        if (!_isReading || !_autoReadEnabled) break;

        await Future.delayed(const Duration(seconds: 2));

        nextMyAffirmation();
      }
    } finally {
      if (_isReading) {
        await _stopAutoRead();
      }
    }
  }

  Future<void> _stopAutoRead() async {
    _isReading = false;
    _autoReadEnabled = false;
    _limitTimer?.cancel();
    await _tts.stop();

    if (_ttsCompleter != null && !_ttsCompleter!.isCompleted) {
      _ttsCompleter!.complete();
    }

    notifyListeners();
  }

  void nextMyAffirmation() {
    if (affirmations.isEmpty) return;

    int next = currentIndex + 1;

    if (next >= affirmations.length) {
      next = 0;
    }

    currentIndex = next;
    onIndexChanged?.call(currentIndex);
    notifyListeners();
  }

  @override
  void dispose() {
    _limitTimer?.cancel();
    _tts.stop();
    super.dispose();
  }
}
