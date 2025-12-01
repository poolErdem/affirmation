import 'dart:async';
import 'package:affirmation/constants/constants.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlaybackState extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _bgMusicPlayer = AudioPlayer();

  List<dynamic> affirmations = [];

  Completer<void>? _ttsCompleter;
  void Function(int index)? onIndexChanged;
  VoidCallback? onLimitReached;
  Timer? _limitTimer;

  bool _volumeEnabled = false;
  bool _autoReadEnabled = false;
  bool _isReading = false;

  int currentIndex = 0;

  bool get autoReadEnabled => _autoReadEnabled;
  bool get volumeEnabled => _volumeEnabled;

  PlaybackState() {
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

  Future<void> setLanguage(String code) async {
    await _tts.setLanguage(code);
    debugPrint("🎤 Language set → $code");
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

  void updateAffirmations(List<dynamic> list) {
    affirmations = list;

    if (currentIndex >= affirmations.length) {
      currentIndex = 0;
    }

    notifyListeners();
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

  Future<void> playTextToSpeech(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> _waitTts() async {
    _ttsCompleter = Completer<void>();
    return _ttsCompleter!.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {},
    );
  }

  Future<void> _startAutoRead() async {
    if (_isReading) return;

    if (_ttsCompleter != null) {
      await _ttsCompleter!.future;
    }

    _isReading = true;

    // LIMIT ONLY FOR NON-PREMIUM
    try {
      final prefs = await SharedPreferences.getInstance();
      final isPremium = prefs.getBool("premiumActive") ?? false;

      if (!isPremium) {
        _limitTimer = Timer(
          const Duration(seconds: Constants.freeMyAffReadLimit),
          () async {
            if (!_isReading) return;

            await _stopAutoRead();
            onLimitReached?.call();
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

        final userName = await _getUserNameFromPrefs();
        final text = aff.text.replaceAll("{name}", userName ?? "");

        await playTextToSpeech(text);
        await _waitTts();

        if (!_autoReadEnabled || !_isReading) break;

        await Future.delayed(const Duration(seconds: 2));

        nextAffirmation();
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
    await _bgMusicPlayer.stop();

    if (_ttsCompleter != null && !_ttsCompleter!.isCompleted) {
      _ttsCompleter!.complete();
    }

    notifyListeners();
  }

  void nextAffirmation() {
    if (affirmations.isEmpty) return;

    int next = currentIndex + 1;
    if (next >= affirmations.length) next = 0;

    setCurrentIndex(next);
  }

  @override
  void dispose() {
    _limitTimer?.cancel();
    _tts.stop();
    super.dispose();
  }

  Future<String?> _getUserNameFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("userName");
  }
}


  // ⭐ Müzik başlat
  // if (backgroundMusicEnabled) {
  //   try {
  //     await _bgMusicPlayer.play(
  //       AssetSource('audio/$selectedMusic'),
  //       volume: 0.3,
  //     );
  //     await _bgMusicPlayer.setReleaseMode(ReleaseMode.loop);
  //   } catch (e) {
  //     debugPrint("⚠️ Müzik başlatılamadı: $e");
  //   }
  // }

  // ⭐ YENİ: Müzik seçimi
  // void setBackgroundMusic(String musicFile) {
  //   selectedMusic = musicFile;

  //   // Eğer müzik çalıyorsa, yenisini başlat
  //   if (_bgMusicPlayer.state == PlayerState.playing) {
  //     _bgMusicPlayer.stop();
  //     _bgMusicPlayer.play(
  //       AssetSource('audio/$selectedMusic'),
  //       volume: 0.3,
  //     );
  //     _bgMusicPlayer.setReleaseMode(ReleaseMode.loop);
  //   }

  //   notifyListeners();
  // }

  // ⭐ YENİ: Müzik toggle
  // void toggleBackgroundMusic() {
  //   backgroundMusicEnabled = !backgroundMusicEnabled;

  //   if (!backgroundMusicEnabled &&
  //       _bgMusicPlayer.state == PlayerState.playing) {
  //     _bgMusicPlayer.stop();
  //   }

  //   notifyListeners();
  // }

