import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/my_affirmation.dart';

class MyAffPlaybackState extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _bgMusicPlayer = AudioPlayer();

  bool backgroundMusicEnabled = false;
  String selectedMusic = 'nature_sounds.mp3';

  bool _autoReadEnabled = false;
  bool _isReading = false;
  bool autoScrollEnabled = true; // ⭐ YENİ: Otomatik kaydırma

  List<MyAffirmation> affirmations = [];
  int currentIndex = 0;

  Completer<void>? _ttsCompleter;
  bool _isInitialized = false;

  VoidCallback? onLimitReached;
  void Function(int index)? onIndexChanged;
  Timer? _limitTimer;

  bool get autoReadEnabled => _autoReadEnabled;

  MyAffPlaybackState() {
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
      if (_ttsCompleter != null && !_ttsCompleter!.isCompleted) {
        _ttsCompleter!.complete();
      }
    });

    _isInitialized = true;
  }

  // 🔥 MyAffirmationState buraya data gönderir
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

    while (!_isInitialized) {
      await Future.delayed(const Duration(milliseconds: 80));
    }

    _isReading = true;

    // Free limit kontrolü
    final prefs = await SharedPreferences.getInstance();
    final isPremium = prefs.getBool("premiumActive") ?? false;

    if (!isPremium) {
      _limitTimer = Timer(const Duration(seconds: 15), () async {
        await _stopAutoRead();
        onLimitReached?.call();
      });
    }

    try {
      while (_isReading && autoReadEnabled) {
        if (affirmations.isEmpty) break;

        final aff = affirmations[currentIndex];
        await play(aff.text);
        await _waitTts();

        if (!_isReading || !autoReadEnabled) break;

        await Future.delayed(const Duration(seconds: 2));

        nextMyAffirmation();
      }
    } finally {
      await _stopAutoRead();
    }
  }

  Future<void> _stopAutoRead() async {
    _isReading = false;
    _limitTimer?.cancel();
    await _tts.stop();

    if (_ttsCompleter != null && !_ttsCompleter!.isCompleted) {
      _ttsCompleter!.complete();
    }
  }

  // 🔥 MyAff için next()
  void nextMyAffirmation() {
    if (affirmations.isEmpty) return;

    currentIndex =
        (currentIndex < affirmations.length - 1) ? currentIndex + 1 : 0;

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

  @override
  void dispose() {
    _limitTimer?.cancel();
    _tts.stop();
    super.dispose();
  }
}
