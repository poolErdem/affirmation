import 'dart:math';
import 'package:affirmation/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../home_screen.dart';

class WelcomeLastScreen extends StatefulWidget {
  const WelcomeLastScreen({super.key});

  @override
  State<WelcomeLastScreen> createState() => _WelcomeLastScreen();
}

class _WelcomeLastScreen extends State<WelcomeLastScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fade;

  @override
  void initState() {
    super.initState();

    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    // 🔥 1.2 saniye sonra home'a geç
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final userName = appState.preferences.userName;

    // ⭐ Kullanıcı adı varsa kişisel karşılama
    final title = userName.isEmpty ? "Welcome" : "Welcome, $userName";

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ⭐ Premium tema uyumlu gradient (gold dokunuşlu)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xfffaf5ef), // soft warm
                  Color(0xfff7e9d9), // soft peach
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // ⭐ Hafif noise
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _NoisePainter(opacity: 0.04),
              ),
            ),
          ),

          // ⭐ Altın ışık efekti (bloom glow)
          Positioned(
            top: 120,
            left: 0,
            right: 0,
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFC9A85D)
                        .withValues(alpha: 0.35), // altın glow
                    Colors.transparent,
                  ],
                  radius: 0.85,
                ),
              ),
            ),
          ),

          // ⭐ Yazılar
          SafeArea(
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: _fade,
                curve: Curves.easeOut,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ✨ SPARKLE ICON
                    Icon(
                      Icons.auto_awesome,
                      size: 46,
                      color: const Color(0xFFC9A85D),
                    ),
                    const SizedBox(height: 20),

                    // ⭐ Başlık
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ⭐ Alt açıklama
                    const Text(
                      "Your personalized affirmations are ready.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// Noise painter
// ------------------------------------------------------------
class _NoisePainter extends CustomPainter {
  final double opacity;
  final Random _rand = Random();

  _NoisePainter({this.opacity = 0.04});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: opacity);

    for (int i = 0; i < size.width * size.height / 90; i++) {
      final dx = _rand.nextDouble() * size.width;
      final dy = _rand.nextDouble() * size.height;
      canvas.drawRect(Rect.fromLTWH(dx, dy, 1.2, 1.2), paint);
    }
  }

  @override
  bool shouldRepaint(_NoisePainter oldDelegate) => false;
}
