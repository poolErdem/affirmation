import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

/// Bu sınıf sadece ses, TTS ve auto-read’den sorumludur.
class PlaybackState extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();

  bool autoReadEnabled = false;
  bool _isReading = false;
  int currentIndex = 0;

  // Affirmation listesini dışarıdan set ediyorsun
  List<dynamic> affirmations = [];

  // TTS bekleme için completer
  Completer<void>? _ttsCompleter;

  void Function(int index)? onIndexChanged;

  PlaybackState() {
    initTts();
  }

  /// Dışarıda kategori değişince çağırırsın
  void updateAffirmations(List<dynamic> list) {
    affirmations = list;
    currentIndex = 0;
    notifyListeners();
  }

  /// Dışarıda PageView'dan index değişince çağırırsın
  void setCurrentIndex(int index) {
    currentIndex = index;

    // ⭐ CALLBACK → HomeScreen senkron çalışsın
    if (onIndexChanged != null) {
      onIndexChanged!(index);
    }

    notifyListeners();
  }

  // Auto READ
  Future<void> toggleAutoRead() async {
    autoReadEnabled = !autoReadEnabled;

    if (autoReadEnabled) {
      _startAutoRead();
    } else {
      _stopAutoRead();
    }

    notifyListeners();
  }

  void setLanguage(String code) {
    _tts.setLanguage(code);
    debugPrint("🎤 Playback language set → $code");
  }

  void initTts() {
    print("🎤 initTts()");

    _tts.setCompletionHandler(() {
      print("🎤 TTS COMPLETION EVENT RECEIVED");

      if (_ttsCompleter != null && !_ttsCompleter!.isCompleted) {
        print("🎤 Completing completer (finish)");
        _ttsCompleter!.complete();
      }
    });
  }

  Future<void> _waitTtsFinish() async {
    print("⏳ _waitTtsFinish() → new completer created");
    _ttsCompleter = Completer<void>();
    return _ttsCompleter!.future;
  }

  Future<void> _stopAutoRead() async {
    print("🛑 _stopAutoRead() called");
    _isReading = false;

    await _tts.stop();
    print("🛑 TTS stopped");

    if (_ttsCompleter != null && !_ttsCompleter!.isCompleted) {
      print("🧹 Completing pending completer");
      _ttsCompleter!.complete();
    }
  }

  Future<void> playTextToSpeech(String text) async {
    print(
        "🔊 TTS PLAY START → '${text.substring(0, text.length > 30 ? 30 : text.length)}...'");

    await _tts.stop();
    print("🔊 TTS stopped (before speaking)");

    await _tts.setSpeechRate(0.42);
    await _tts.setPitch(1.05);
    await _tts.setVolume(1.0);

    print("🔊 Speaking now...");
    await _tts.speak(text);
  }

  Future<void> _startAutoRead() async {
    if (_isReading) {
      return;
    }

    _isReading = true;

    while (autoReadEnabled && _isReading) {
      if (affirmations.isEmpty) {
        print("❌ affirmations boş");
        break;
      }
      print("🔁 LOOP → currentIndex=$currentIndex");

      if (currentIndex >= affirmations.length) {
        print("⚠ currentIndex out of range, reset → 0");
        currentIndex = 0;
      }

      final aff = affirmations[currentIndex];
      if (aff == null) {
        print("❌ aff=null → break loop");
        break;
      }

      print(
          "📖 READING → ${aff.text.substring(0, aff.text.length > 40 ? 40 : aff.text.length)}...");

      await playTextToSpeech(aff.text);

      print("⏳ Waiting TTS finish...");
      await _waitTtsFinish();
      print("✅ TTS finished");

      if (!autoReadEnabled) {
        print("⛔ autoReadEnabled=false → breaking");
        break;
      }

      print("➡ Moving to next affirmation");
      nextAffirmation();
    }

    print("🚪 Exiting AutoRead loop");
  }

  void nextAffirmation() {
    final list = affirmations;
    print("➡ nextAffirmation() called");

    if (list.isEmpty) {
      print("❌ nextAffirmation → list empty");
      return;
    }

    if (currentIndex < list.length - 1) {
      currentIndex++;
    } else {
      currentIndex = 0;
    }

    // ⭐ PageView’a haber ver
    if (onIndexChanged != null) {
      onIndexChanged!(currentIndex);
    }

    notifyListeners();
  }

  void onPageChanged(int index) {
    currentIndex = index;
    notifyListeners();
  }
}
