import 'dart:math';
import 'package:affirmation/l10n/app_localizations.dart';
import 'package:affirmation/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
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

    _fadeScale = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _confettiController =
        ConfettiController(duration: const Duration(milliseconds: 1400));

    Future.delayed(const Duration(milliseconds: 200), () {
      _confettiController.play();
    });

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
          // 🌟 PREMIUM GOLD BACKGROUND
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0D0C0A), // üst koyu luxury black
                  Color(0xFF2C2418), // deep brown gold
                  Color(0xFFC9A85D), // soft gold
                  Color(0xFFF5E9C7), // premium light gold
                ],
                stops: [0.0, 0.35, 0.72, 1.0],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // 🌟 CONFETTI (değişmiyor)
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.2,
              numberOfParticles: 40,
              maxBlastForce: 30,
              minBlastForce: 10,
              gravity: 0.25,
              colors: [
                const Color(0xFFC9A85D),
                const Color.fromARGB(255, 80, 118, 156),
                const Color.fromARGB(255, 193, 108, 108),
                const Color.fromARGB(255, 106, 184, 100),
                const Color.fromARGB(255, 202, 194, 194),
              ],
              createParticlePath: _drawStar,
            ),
          ),

          // 🌟 MAIN CONTENT (Premium Typography)
          Positioned(
            top: 280,
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // main icon
                    ShaderMask(
                      shaderCallback: (rect) {
                        return const LinearGradient(
                          colors: [
                            Color(0xFFF8E7B7),
                            Color(0xFFC9A85D),
                            Color(0xFFE4C98A),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(rect);
                      },
                      child: const Icon(
                        Icons.auto_awesome,
                        size: 58,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ⭐ TITLE (gold gradient)
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

                    // ⭐ Sub text
                    Text(
                      t.welcomeLast,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.white.withValues(alpha: 0.88),
                        height: 1.45,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.40),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
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

// ⭐ Star Path
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
