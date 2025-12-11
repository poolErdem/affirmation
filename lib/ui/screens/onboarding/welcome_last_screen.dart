import 'dart:math';
import 'package:affirmation/l10n/app_localizations.dart';
import 'package:affirmation/state/app_state.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../home_screen.dart';

class WelcomeLastScreen extends StatefulWidget {
  const WelcomeLastScreen({super.key});

  @override
  State<WelcomeLastScreen> createState() => _WelcomeLastScreenState();
}

class _WelcomeLastScreenState extends State<WelcomeLastScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeScale;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();

    // ⭐ Daha hızlı, daha temiz giriş animasyonu
    _fadeScale = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    // ⭐ Confetti
    _confettiController =
        ConfettiController(duration: const Duration(milliseconds: 2200));

    // ⭐ Confetti 1sn sonra başlasın
    Future.delayed(const Duration(milliseconds: 1000), () {
      _confettiController.play();
    });

    // ⭐ HomeScreen’e daha hızlı geçiş (4s)
    Future.delayed(const Duration(milliseconds: 4000), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    });
  }

  @override
  void dispose() {
    _fadeScale.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final userName = appState.preferences.userName;
    final t = AppLocalizations.of(context)!;

    final title =
        userName.isEmpty ? t.welcomeTitle : "${t.welcomeTitle}, $userName";

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ⭐ Blue + Gold Premium Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0E1621), // dark premium blue
                  Color(0xFF26384A), // deep blue
                  Color(0xFFE4C98A), // soft gold
                  Color(0xFFF3EFE7), // light champagne
                ],
                stops: [0.0, 0.35, 0.72, 1.0],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // ⭐ Brand Confetti — Blue + Gold
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.18,
              numberOfParticles: 26,
              maxBlastForce: 22,
              minBlastForce: 8,
              gravity: 0.20,
              colors: [
                Color(0xFFC9A85D), // gold
                Color(0xFF4C98FF), // blue
                Color(0xFF8AA4C2), // soft blue
                Color(0xFFF3EFE7), // champagne white
                Color(0xFF1A1D1F), // dark accent
              ],
              createParticlePath: _drawStar,
            ),
          ),

          // ⭐ Main Content
          Positioned(
            top: MediaQuery.of(context).size.height * 0.26,
            left: 0,
            right: 0,
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: _fadeScale,
                curve: Curves.easeOutBack,
              ),
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _fadeScale,
                  curve: Curves.easeOut,
                ),
                child: Column(
                  children: [
                    // ⭐ Gradient Gold Title
                    ShaderMask(
                      shaderCallback: (rect) {
                        return const LinearGradient(
                          colors: [
                            Color(0xFFF9EDD0),
                            Color(0xFFE4C98A),
                            Color(0xFFC9A85D),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(rect);
                      },
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ⭐ Sub text — daha soft premium
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        t.welcomeLast,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          color: Colors.white.withValues(alpha: 0.88),
                          height: 1.45,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
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

// ⭐ Star particles for confetti
Path _drawStar(Size size) {
  const numberOfPoints = 5;
  final halfWidth = size.width / 2;
  final externalRadius = halfWidth;
  final internalRadius = halfWidth / 2.5;
  final degreesPerStep = pi / numberOfPoints;
  final halfDegreesPerStep = degreesPerStep / 2;
  final path = Path()..moveTo(size.width, halfWidth);

  for (double step = 0; step < pi * 2; step += degreesPerStep) {
    path.lineTo(
      halfWidth + externalRadius * cos(step),
      halfWidth + externalRadius * sin(step),
    );
    path.lineTo(
      halfWidth + internalRadius * cos(step + halfDegreesPerStep),
      halfWidth + internalRadius * sin(step + halfDegreesPerStep),
    );
  }

  path.close();
  return path;
}
