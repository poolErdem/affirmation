import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlaybackState extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _bgMusicPlayer = AudioPlayer();

  bool backgroundMusicEnabled = false;
  String selectedMusic = 'nature_sounds.mp3';

  bool autoScrollEnabled = true; // ⭐ YENİ: Otomatik kaydırma

  bool _autoReadEnabled = false;
  bool _isReading = false;
  int currentIndex = 0;

  List<dynamic> affirmations = [];
  Completer<void>? _ttsCompleter;
  void Function(int index)? onIndexChanged;

  bool _isInitialized = false;
  bool get autoReadEnabled => _autoReadEnabled;

  VoidCallback? onLimitReached;
  Timer? _limitTimer; // ⭐ Class seviyesinde ekle

  PlaybackState() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setSpeechRate(0.42);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _tts.setVoice({"name": "Yelda", "locale": "tr-TR"});
    }

    _tts.setCompletionHandler(() {
      print("✅ TTS COMPLETED"); // ⭐ Bu log görünmeli

      if (_ttsCompleter != null && !_ttsCompleter!.isCompleted) {
        _ttsCompleter!.complete();
      }
    });

    _isInitialized = true;
    print("✅ TTS initialized");
  }

  void updateAffirmations(List<dynamic> list) {
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

  // ⭐ YENİ: Müzik toggle
  void toggleBackgroundMusic() {
    backgroundMusicEnabled = !backgroundMusicEnabled;

    if (!backgroundMusicEnabled &&
        _bgMusicPlayer.state == PlayerState.playing) {
      _bgMusicPlayer.stop();
    }

    notifyListeners();
  }

  // ⭐ YENİ: Müzik seçimi
  void setBackgroundMusic(String musicFile) {
    selectedMusic = musicFile;

    // Eğer müzik çalıyorsa, yenisini başlat
    if (_bgMusicPlayer.state == PlayerState.playing) {
      _bgMusicPlayer.stop();
      _bgMusicPlayer.play(
        AssetSource('audio/$selectedMusic'),
        volume: 0.3,
      );
      _bgMusicPlayer.setReleaseMode(ReleaseMode.loop);
    }

    notifyListeners();
  }

  // ⭐ YENİ: Otomatik kaydırma toggle
  void toggleAutoScroll() {
    autoScrollEnabled = !autoScrollEnabled;
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

    // ⭐ TTS hazır olana kadar bekle
    while (!_isInitialized) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    _isReading = true;

    // ⭐ Müzik başlat
    if (backgroundMusicEnabled) {
      try {
        await _bgMusicPlayer.play(
          AssetSource('audio/$selectedMusic'),
          volume: 0.3,
        );
        await _bgMusicPlayer.setReleaseMode(ReleaseMode.loop);
      } catch (e) {
        debugPrint("⚠️ Müzik başlatılamadı: $e");
      }
    }

    // 🔥 FREE USER LIMIT TIMER
    try {
      final prefs = await SharedPreferences.getInstance();
      final isPremium = prefs.getBool("premiumActive") ?? false;

      if (!isPremium) {
        _limitTimer = Timer(const Duration(seconds: 15), () async {
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

    // 🔄 ANA TTS DÖNGÜSÜ
    try {
      while (autoReadEnabled && _isReading) {
        if (affirmations.isEmpty) break;

        if (currentIndex >= affirmations.length) {
          currentIndex = 0;
        }

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

        if (!autoReadEnabled || !_isReading) break;

        await Future.delayed(const Duration(seconds: 2));

        if (!_isReading) break; // ⭐ Ekstra güvenlik

        nextAffirmation();
      }
    } catch (e) {
      debugPrint("⚠️ AutoRead döngüsünde hata: $e");
    } finally {
      // ⭐ Döngü bittiğinde temizlik
      if (_isReading) {
        await _stopAutoRead();
      }
    }
  }

  Future<void> _stopAutoRead() async {
    _isReading = false;

    // ⭐ Timer'ı iptal et
    _limitTimer?.cancel();
    _limitTimer = null;

    await _tts.stop();
    await _bgMusicPlayer.stop();

    if (_ttsCompleter != null && !_ttsCompleter!.isCompleted) {
      _ttsCompleter!.complete();
    }
  }

  void nextAffirmation() {
    if (affirmations.isEmpty) return;

    if (currentIndex < affirmations.length - 1) {
      currentIndex++;
    } else {
      currentIndex = 0;
    }

    if (onIndexChanged != null) {
      onIndexChanged!(currentIndex);
    }

    notifyListeners();
  }

  void onPageChanged(int index) {
    currentIndex = index;
    notifyListeners();
  }

  // ⭐ dispose() metodunda da temizlik yap
  @override
  void dispose() {
    _limitTimer?.cancel();
    _bgMusicPlayer.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<String?> _getUserNameFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("userName");
  }
}
