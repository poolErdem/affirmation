import 'dart:async';
import 'package:affirmation/constants/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/my_affirmation.dart';

class MyAffPlaybackState extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();
  //final AudioPlayer _bgMusicPlayer = AudioPlayer();

  List<MyAffirmation> affirmations = [];

  //String selectedMusic = 'nature_sounds.mp3';

  //bool backgroundMusicEnabled = false;
  bool _volumeEnabled = false;
  bool _autoReadEnabled = false; // buton görüntüsü
  bool _isReading = false; // okuma anında kullanır
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

    if (_volumeEnabled) {
      await _tts.setVolume(1.0);
    } else {
      await _tts.setVolume(0.0);
    }
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
    currentIndex = 0;
    notifyListeners();
  }

  void setCurrentIndex(int index) {
    currentIndex = index;
    if (onIndexChanged != null) {
      onIndexChanged!(index);
    }
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

    // ⭐ TTS hazır olana kadar bekle
    if (_ttsCompleter != null) {
      await _ttsCompleter!.future;
    }

    _isReading = true;

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

    // 🔥 FREE USER LIMIT TIMER
    try {
      final prefs = await SharedPreferences.getInstance();
      final isPremium = prefs.getBool("premiumActive") ?? false;

      if (!isPremium) {
        _limitTimer = Timer(
            const Duration(seconds: Constants.freeMyAffReadLimit), () async {
          if (!_isReading) return; // Double-check

          debugPrint("⏰ Free user 10 saniye limiti doldu");

          await _stopAutoRead(); // ⭐ Mevcut fonksiyonunu kullan

          if (onLimitReached != null) {
            onLimitReached!.call();
          }
        });
      }
    } catch (e) {
      debugPrint("⚠️ Premium kontrolü başarısız: $e");
    }

    try {
      while (_isReading && autoReadEnabled) {
        if (affirmations.isEmpty) break;

        if (currentIndex < 0 || currentIndex >= affirmations.length) {
          break;
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

  // 🔥 MyAff için next()
  void nextMyAffirmation() {
    if (affirmations.isEmpty) return;

    currentIndex =
        (currentIndex < affirmations.length - 1) ? currentIndex + 1 : 0;

    notifyListeners();
  }

  @override
  void dispose() {
    _limitTimer?.cancel();
    _tts.stop();
    super.dispose();
  }
}

   // ⭐ YENİ: Müzik toggle
  // void toggleBackgroundMusic() {
  //   backgroundMusicEnabled = !backgroundMusicEnabled;

  //   if (!backgroundMusicEnabled &&
  //       _bgMusicPlayer.state == PlayerState.playing) {
  //     _bgMusicPlayer.stop();
  //   }

  //   notifyListeners();
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


