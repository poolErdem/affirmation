import 'dart:math';
import 'dart:ui';
import 'package:affirmation/l10n/app_localizations.dart';
import 'package:affirmation/models/user_preferences.dart';
import 'package:affirmation/ui/screens/settings/content_preferences_screen.dart';
import 'package:affirmation/ui/screens/settings/gender_screen.dart';
import 'package:affirmation/ui/screens/settings/language_screen.dart';
import 'package:affirmation/ui/screens/settings/name_screen.dart';
import 'package:affirmation/ui/screens/premium_screen.dart';
import 'package:affirmation/ui/screens/settings/privacy_policy_screen.dart';
import 'package:affirmation/ui/screens/settings/reminder_screen.dart';
import 'package:affirmation/ui/screens/settings/terms_screen.dart';
import 'package:affirmation/ui/widgets/premium_tile.dart';
import 'package:affirmation/ui/widgets/shared_blur_background.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../state/app_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _shineController;
  late AnimationController _particleController;
  late AnimationController _pulseController;

  final List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();

    _shineController =
        AnimationController(vsync: this, duration: const Duration(seconds: 6))
          ..repeat();

    _particleController =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    for (int i = 0; i < 12; i++) {
      _particles.add(Particle());
    }
  }

  @override
  void dispose() {
    _shineController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _instantGo(Widget page) {
    Navigator.of(context).push(PageRouteBuilder(
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (_, __, ___) => page,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final appState = context.watch<AppState>();
    final isPremium = appState.preferences.isPremiumValid;
    final bg = appState.activeThemeImage;

    return SharedBlurBackground(
      imageAsset: bg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leadingWidth: 32, // 🔥 soldaki boşluğu azaltır
          leading: Padding(
            padding:
                const EdgeInsets.only(left: 6), // 🔥 istediğin kadar kaydır
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 22,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: Text(
            t.settings,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: NoisePainter(opacity: 0.06),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(height: 120, color: Colors.transparent),
                ),
              ),
            ),
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                children: [
                  const SizedBox(height: 10),
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _shineController,
                      _particleController,
                      _pulseController,
                    ]),
                    builder: (context, child) {
                      return _buildPremiumCardV2(
                        context: context,
                        isPremium: isPremium,
                        shineValue: _shineController.value,
                        particleValue: _particleController.value,
                        pulseValue: _pulseController.value,
                        onTap: () => _instantGo(const PremiumScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 25),
                  PremiumTile(
                    title: t.name,
                    icon: Icons.person_outline_rounded,
                    onTap: () => _instantGo(const NameScreen()),
                  ),
                  PremiumTile(
                    title: t.preferences,
                    icon: Icons.tune,
                    onTap: () => _instantGo(const ContentPreferencesScreen()),
                  ),
                  PremiumTile(
                    title: t.language,
                    icon: Icons.language,
                    onTap: () => _instantGo(const LanguageScreen()),
                  ),
                  PremiumTile(
                    title: t.reminders,
                    icon: Icons.notifications_none_rounded,
                    onTap: () => _instantGo(const ReminderListScreen()),
                  ),
                  PremiumTile(
                    title: t.gender,
                    icon: Icons.wc,
                    onTap: () => _instantGo(const GenderScreen()),
                  ),
                  _section(t.about),
                  PremiumTile(
                    title: t.privacyPolicy,
                    icon: Icons.description_outlined,
                    onTap: () => _instantGo(const PrivacyPolicyScreen()),
                  ),
                  PremiumTile(
                    title: t.terms,
                    icon: Icons.verified_user_outlined,
                    onTap: () => _instantGo(const TermsScreen()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10, top: 26),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFFC9A85D),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6A6A6A),
            ),
          ),
        ],
      ),
    );
  }

  // PREMIUM CARD ----------------------------------------------------
  Widget _buildPremiumCardV2({
    required BuildContext context,
    required bool isPremium,
    required double shineValue,
    required double particleValue,
    required double pulseValue,
    required VoidCallback onTap,
  }) {
    final t = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: isPremium
                ? [const Color(0xFF1A1A1A), const Color(0xFF2D2D2D)]
                : [
                    const Color(0xFF3D3D3D),
                    const Color.fromARGB(255, 104, 102, 102)
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: isPremium
                  ? Colors.amber.withValues(alpha: 0.4 + pulseValue * 0.2)
                  : Colors.black.withValues(alpha: 0.25),
              blurRadius: 30 + pulseValue * 10,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isPremium
                        ? [
                            Colors.amber.withValues(alpha: 0.15),
                            Colors.orange.withValues(alpha: 0.08),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.05),
                            Colors.transparent,
                          ],
                  ),
                ),
              ),
              if (isPremium)
                ..._particles.map(
                  (p) => _buildParticle(
                    p,
                    particleValue,
                    Size(MediaQuery.of(context).size.width - 40, 160),
                  ),
                ),
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isPremium
                          ? Colors.amber.withValues(alpha: 0.6)
                          : Colors.white.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              ShaderMask(
                blendMode: BlendMode.srcATop,
                shaderCallback: (rect) {
                  return LinearGradient(
                    begin: Alignment(-1 + shineValue * 2, 0),
                    end: Alignment(1 + shineValue * 2, 0),
                    colors: [
                      Colors.white.withValues(alpha: 0),
                      Colors.white.withValues(alpha: isPremium ? 0.3 : 0.1),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ).createShader(rect);
                },
                child: const SizedBox.expand(),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1 + pulseValue * 0.15,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: isPremium
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFFFFD700),
                                        Color(0xFFFFA500),
                                      ],
                                    )
                                  : LinearGradient(
                                      colors: [
                                        Colors.white.withValues(alpha: 0.2),
                                        Colors.white.withValues(alpha: 0.1),
                                      ],
                                    ),
                              boxShadow: isPremium
                                  ? [
                                      BoxShadow(
                                        color:
                                            Colors.amber.withValues(alpha: 0.5),
                                        blurRadius: 25,
                                      )
                                    ]
                                  : null,
                            ),
                            child: Icon(
                              Icons.workspace_premium,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 25),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment:
                            MainAxisAlignment.center, // 🔥 yazıyı aşağı indirir

                        children: [
                          Text(
                            isPremium ? t.premiumActive : t.getPremium,
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w500,
                              color: isPremium ? Colors.amber : Colors.white,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            isPremium
                                ? "All features unlocked ✨"
                                : "Unlock unlimited access",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // PARTICLES -------------------------------------------------------
  Widget _buildParticle(Particle p, double progress, Size size) {
    final pos = p.getPosition(progress, size);
    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: Container(
        width: p.size,
        height: p.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.amber.withValues(alpha: 0.8),
              Colors.amber.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

// PARTICLE CLASS ---------------------------------------------------
class Particle {
  final double startX = Random().nextDouble();
  final double startY = Random().nextDouble();
  final double speed = Random().nextDouble() * 0.5 + 0.3;
  final double size = Random().nextDouble() * 3 + 2;
  final double angle = Random().nextDouble() * 2 * pi;

  Offset getPosition(double progress, Size size) {
    final x = startX * size.width + sin(progress * 2 * pi + angle) * 20;
    final y =
        startY * size.height - (progress * speed * size.height) % size.height;
    return Offset(x, y);
  }
}

// NOISE ------------------------------------------------------------
class NoisePainter extends CustomPainter {
  final double opacity;
  final Random _random = Random();

  NoisePainter({this.opacity = 0.08});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: opacity);
    for (int i = 0; i < size.width * size.height / 80; i++) {
      canvas.drawRect(
        Rect.fromLTWH(
          _random.nextDouble() * size.width,
          _random.nextDouble() * size.height,
          1.2,
          1.2,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant NoisePainter oldDelegate) => false;
}
