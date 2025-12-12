import 'package:affirmation/l10n/app_localizations.dart';
import 'package:affirmation/state/app_state.dart';
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

  @override
  void initState() {
    super.initState();

    // Yumuşak fade + scale animasyonu
    _fadeScale = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    // 3 saniye sonra ana ekrana geç
    Future.delayed(const Duration(milliseconds: 3500), () {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final t = AppLocalizations.of(context)!;
    final userName = appState.preferences.userName;

    final message =
        userName.isEmpty ? t.welcomeLast : "${t.welcomeLast}, $userName";

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ⭐ Soft Premium Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0E1621), // deep premium blue
                  Color(0xFF1C2B38), // calm midnight blue
                  Color(
                      0xFF2F4E63), // premium steel blue (soft transition middle)
                  Color(0xFF9ED7F5), // OPEN LIGHT BLUE (soft, serene, premium)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.33, 0.66, 1.0], // ⭐ çok daha yumuşak dağılım
              ),
            ),
          ),

          // ⭐ Hafif üstten aşağıya blur glow efekti
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),

          // ⭐ Main Content – Fade + Scale animasyonlu
          Positioned(
            top: MediaQuery.of(context).size.height * 0.28,
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
                    // ⭐ Gold Gradient Title
                    ShaderMask(
                      shaderCallback: (rect) {
                        return const LinearGradient(
                          colors: [
                            Color(0xFFF5E9C7),
                            Color(0xFFE4C98A),
                            Color(0xFFC9A85D),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(rect);
                      },
                    ),

                    const SizedBox(height: 90),

                    // ⭐ Sub Text
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          color: Colors.white.withValues(alpha: 0.90),
                          height: 1.45,
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
