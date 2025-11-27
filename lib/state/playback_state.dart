import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

class PlaybackState extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _bgMusicPlayer = AudioPlayer();

  bool backgroundMusicEnabled = false;
  String selectedMusic = 'nature_sounds.mp3';

  bool autoScrollEnabled = true; // ⭐ YENİ: Otomatik kaydırma

  bool autoReadEnabled = false;
  bool _isReading = false;
  int currentIndex = 0;

  List<dynamic> affirmations = [];
  Completer<void>? _ttsCompleter;
  void Function(int index)? onIndexChanged;

  bool _isInitialized = false;

  PlaybackState() {
    _initTts();
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
    autoReadEnabled = !autoReadEnabled;

    if (autoReadEnabled) {
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

  Future<void> _waitTtsFinish() async {
    _ttsCompleter = Completer<void>();

    return _ttsCompleter!.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        debugPrint("⚠️ TTS timeout, moving to next");
      },
    );
  }

  Future<void> _stopAutoRead() async {
    _isReading = false;
    await _tts.stop();
    await _bgMusicPlayer.stop();

    if (_ttsCompleter != null && !_ttsCompleter!.isCompleted) {
      _ttsCompleter!.complete();
    }
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
        // Müzik hata verirse devam et
      }
    }

    while (autoReadEnabled && _isReading) {
      if (affirmations.isEmpty) break;

      if (currentIndex >= affirmations.length) {
        currentIndex = 0;
      }

      final aff = affirmations[currentIndex];
      if (aff == null) break;

      await playTextToSpeech(aff.text);
      await _waitTtsFinish();

      await Future.delayed(const Duration(seconds: 2));

      if (!autoReadEnabled) break;

      nextAffirmation();
    }

    _isReading = false;
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

  @override
  void dispose() {
    _bgMusicPlayer.dispose(); // ⭐ dispose ile değiştir
    _tts.stop();
    super.dispose();
  }
}
