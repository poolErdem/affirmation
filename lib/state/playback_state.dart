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
  bool autoScrollEnabled = true;

  int currentIndex = 0;

  bool get autoReadEnabled => _autoReadEnabled;
  bool get volumeEnabled => _volumeEnabled;

  PlaybackState() {
    _initTts();
  }

  Future<void> toggleVolume() async {
    _volumeEnabled = !_volumeEnabled;

    final v = _tts.getDefaultVoice.toString();
    print("🔊 Volume → $v");

    if (_ttsCompleter != null) {
      await _ttsCompleter!.future;
    }

    if (_volumeEnabled) {
      await _tts.setVolume(1.0);
    } else {
      await _tts.setVolume(0.0);
    }

    final vi = _tts.getDefaultVoice.toString();
    print("🔊 Volume changed → $vi");

    notifyListeners();
  }

  Future<void> _initTts() async {
    await _tts.setSpeechRate(0.42);
    await _tts.setPitch(1.0);
    await _tts.setVolume(0.0);

    final vi = _tts.getDefaultVoice.toString();
    print("🔊 Initial Volume  → $vi");

    _tts.setCompletionHandler(() {
      print("✅ TTS COMPLETED");

      if (_ttsCompleter != null && !_ttsCompleter!.isCompleted) {
        _ttsCompleter!.complete();
      }
    });

    print("✅ TTS initialized");
  }

  void updateAffirmations(List<dynamic> list) {
    affirmations = list;

    print("📚 Affirmation count → ${affirmations.length}");
    print("📍 Current index → $currentIndex");

    notifyListeners();
  }

  void setCurrentIndex(int index) {
    currentIndex = index;

    print("📍 Current index changed → $currentIndex / ${affirmations.length}");

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

  Future<void> setLanguage(String code) async {
    await _tts.setLanguage(code);
    debugPrint("🎤 Language set → $code");
  }

  Future<void> _waitTtsFinish() async {
    _ttsCompleter = Completer<void>();

    return _ttsCompleter!.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        debugPrint("⚠️ TTS timeout, moving to next");
      },
    );
  }

  Future<void> playTextToSpeech(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> _startAutoRead() async {
    if (_isReading) return;

    if (_ttsCompleter != null) {
      await _ttsCompleter!.future;
    }

    _isReading = true;

    print("▶️ AutoRead started");
    print("🔢 Affirmation count → ${affirmations.length}");
    print("📍 Starting index → $currentIndex");

    try {
      final prefs = await SharedPreferences.getInstance();
      final isPremium = prefs.getBool("premiumActive") ?? false;

      if (isPremium) {
        _limitTimer = Timer(
            const Duration(seconds: Constants.freeMyAffReadLimit), () async {
          if (!_isReading) return;

          await _stopAutoRead();

          if (onLimitReached != null) {
            onLimitReached!.call();
          }
        });
      }
    } catch (e) {
      debugPrint("⚠️ Premium kontrolü başarısız: $e");
    }

    try {
      while (_isReading) {
        if (affirmations.isEmpty) break;

        if (currentIndex >= affirmations.length) {
          currentIndex = 0;
        }

        print("📖 Reading index → $currentIndex / ${affirmations.length}");

        final aff = affirmations[currentIndex];
        if (aff == null) break;

        final userName = await _getUserNameFromPrefs();
        final rendered = aff.text.replaceAll("{name}", userName ?? "");

        try {
          await playTextToSpeech(rendered);
          await _waitTtsFinish();
        } catch (e) {
          debugPrint("⚠️ TTS oynatılamadı: $e");
          break;
        }

        if (!_autoReadEnabled || !_isReading) break;

        await Future.delayed(const Duration(seconds: 2));

        nextAffirmation();
      }
    } catch (e) {
      debugPrint("⚠️ AutoRead döngüsünde hata: $e");
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
    _limitTimer = null;

    await _tts.stop();
    await _bgMusicPlayer.stop();

    if (_ttsCompleter != null && !_ttsCompleter!.isCompleted) {
      _ttsCompleter!.complete();
    }

    print("⏹ AutoRead stopped");

    notifyListeners();
  }

  void nextAffirmation() {
    if (affirmations.isEmpty) return;

    if (currentIndex < affirmations.length - 1) {
      currentIndex++;
    } else {
      currentIndex = 0;
    }

    print("➡️ Next index → $currentIndex / ${affirmations.length}");

    if (onIndexChanged != null) {
      onIndexChanged!(currentIndex);
    }

    notifyListeners();
  }

  void onPageChanged(int index) {
    currentIndex = index;

    print("📄 Page changed → $currentIndex / ${affirmations.length}");

    notifyListeners();
  }

  @override
  void dispose() {
    _limitTimer?.cancel();
    //_bgMusicPlayer.dispose();
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

