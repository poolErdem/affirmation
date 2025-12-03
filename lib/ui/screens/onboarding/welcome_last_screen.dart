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
          // ⭐ Background gradient - Orta kısımda açık ton
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 83, 78, 73), // Üst koyu
                  Color(0xFFFCEFD9), // Orta açık/gold
                  Color(0xFFF7EEDD), // Alt açık
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // ⭐ Sparkle
          Positioned(
            top: 110,
            left: 0,
            right: 0,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 900),
              builder: (_, v, __) => Opacity(
                opacity: v,
                child: ShaderMask(
                  shaderCallback: (rect) {
                    return const LinearGradient(
                      colors: [
                        Colors.white,
                        Color(0xFFC9A85D),
                        Colors.white,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(rect);
                  },
                  child: const Icon(
                    Icons.star_sharp,
                    size: 42,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          // ⭐ Konfeti
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
              colors: const [
                Color(0xFFC9A85D),
                Color(0xFFE8D5A6),
                Color(0xFFFAF3D2),
              ],
              createParticlePath: _drawStar,
            ),
          ),

          // ⭐ Content
          Positioned(
            top: 285,
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
                    const Icon(
                      Icons.auto_awesome,
                      size: 50,
                      color: Color(0xFFC9A85D),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        height: 1.2,
                        fontFamily: "Georgia",
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      t.welcomeLast,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
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
