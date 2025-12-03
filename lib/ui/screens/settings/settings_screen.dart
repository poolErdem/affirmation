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
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../state/app_state.dart';

// ------------------------------------------------------------
// MAIN WIDGET
// ------------------------------------------------------------
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

    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // 🌟 Parçacıklar oluştur
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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final appState = context.watch<AppState>();
    final isPremium = appState.preferences.isPremiumValid;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.black, size: 26),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t.settings,
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ------------------------------------------------------------
      // BACKGROUND + NOISE + BLUR
      // ------------------------------------------------------------
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xfff7f2ed),
                  Color(0xfff2ebe5),
                ],
              ),
            ),
          ),

          // Noise layer
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: NoisePainter(opacity: 0.06),
              ),
            ),
          ),

          // Top blur transition
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 16,
                  sigmaY: 16,
                ),
                child: Container(height: 120, color: Colors.transparent),
              ),
            ),
          ),

          // CONTENT
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              children: [
                const SizedBox(height: 10),

                // 🔥 UPGRADED PREMIUM CARD
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PremiumScreen()),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 15),

                _section(t.general),

                _tile(
                  context,
                  title: t.name,
                  icon: Icons.person_outline_rounded,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NameScreen()),
                  ),
                ),

                _tile(
                  context,
                  title: t.preferences,
                  icon: Icons.tune,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ContentPreferencesScreen()),
                  ),
                ),

                _tile(
                  context,
                  title: t.language,
                  icon: Icons.language,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LanguageScreen()),
                  ),
                ),

                _tile(
                  context,
                  title: t.reminders,
                  icon: Icons.notifications_none_rounded,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ReminderListScreen()),
                  ),
                ),

                _tile(
                  context,
                  title: t.gender,
                  icon: Icons.wc,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GenderScreen()),
                  ),
                ),

                _section(t.about),

                _tile(
                  context,
                  title: t.privacyPolicy,
                  icon: Icons.description_outlined,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyScreen()),
                  ),
                ),

                _tile(
                  context,
                  title: t.terms,
                  icon: Icons.verified_user_outlined,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TermsScreen()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // 🔥 UPGRADED PREMIUM CARD V2
  // Glassmorphism + Particles + 3D Shadow + Pulse
  // ------------------------------------------------------------
  Widget _buildPremiumCardV2({
    required BuildContext context,
    required bool isPremium,
    required double shineValue,
    required double particleValue,
    required double pulseValue,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: isPremium
                ? [
                    const Color(0xFF1A1A1A),
                    const Color(0xFF2D2D2D),
                  ]
                : [
                    const Color(0xFF3D3D3D),
                    const Color(0xFF2A2A2A),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: isPremium
                  ? Colors.amber.withValues(alpha: 0.4 + pulseValue * 0.2)
                  : const Color.fromARGB(255, 83, 80, 80)
                      .withValues(alpha: 0.3),
              blurRadius: 30 + pulseValue * 10,
              spreadRadius: isPremium ? 2 : 0,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // 🌟 Background gradient overlay
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
                            const Color.fromARGB(0, 56, 53, 53),
                          ],
                  ),
                ),
              ),

              // ✨ Particle effects (only for premium)
              if (isPremium)
                ..._particles.map((particle) => _buildParticle(
                      particle,
                      particleValue,
                      Size(MediaQuery.of(context).size.width - 40, 160),
                    )),

              // 💎 Glassmorphism blur
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.05),
                        Colors.white.withValues(alpha: 0.02),
                      ],
                    ),
                    border: Border.all(
                      color: isPremium
                          ? Colors.amber.withValues(alpha: 0.6)
                          : Colors.white.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),

              // 🌈 Shine effect
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
                    stops: const [0.3, 0.5, 0.7],
                  ).createShader(rect);
                },
                child: const SizedBox.expand(),
              ),

              // 📝 Content
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Icon with pulse
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
                                      ? LinearGradient(
                                          colors: [
                                            const Color(0xFFFFD700),
                                            const Color(0xFFFFA500),
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
                                            color: Colors.amber.withValues(
                                                alpha: 0.6 + pulseValue * 0.2),
                                            blurRadius: 25,
                                            spreadRadius: 4,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Icon(
                                  Icons.workspace_premium,
                                  size: 36,
                                  color:
                                      isPremium ? Colors.white : Colors.white70,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 20),

                        // Text content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title with gradient
                              if (isPremium)
                                ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                    colors: [
                                      Color(0xFFFFD700),
                                      Color(0xFFFFA500)
                                    ],
                                  ).createShader(bounds),
                                  child: const Text(
                                    "Premium Active",
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              else
                                const Text(
                                  "Get Premium",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),

                              const SizedBox(height: 6),

                              // Subtitle
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

                        // Arrow icon
                        Icon(
                          Icons.arrow_forward_ios,
                          color: isPremium
                              ? Colors.amber.withValues(alpha: 0.8)
                              : Colors.white.withValues(alpha: 0.5),
                          size: 20,
                        ),
                      ],
                    ),

                    // Premium benefits (only show for premium users)
                    if (isPremium) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMiniFeature(Icons.block, "Ad-Free"),
                          _buildMiniFeature(Icons.favorite, "Unlimited"),
                          _buildMiniFeature(Icons.color_lens, "All Themes"),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Mini feature badge
  Widget _buildMiniFeature(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.amber),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Particle widget
  Widget _buildParticle(Particle particle, double progress, Size cardSize) {
    final pos = particle.getPosition(progress, cardSize);
    final opacity = particle.opacity(progress);

    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: particle.size,
          height: particle.size,
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
      ),
    );
  }

  // ------------------------------------------------------------
  // SECTION TITLE WITH GOLD DOT
  // ------------------------------------------------------------
  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10, top: 26),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFc9a85d),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12.8,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6A6A6A),
              letterSpacing: 1.0,
            ),
          )
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // GOLD TILES
  // ------------------------------------------------------------
  Widget _tile(
    BuildContext context, {
    required String title,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          border: Border.all(
            color: const Color(0xFFE4DCD3),
            width: 1.2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 18,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: const Color(0xFFC9A85D),
              weight: 200,
              grade: -25,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16.2,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4C4743),
                  letterSpacing: -0.2,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade500,
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// PARTICLE CLASS
// ------------------------------------------------------------
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

  double opacity(double progress) {
    return 1 - ((progress * speed) % 1);
  }
}

// ------------------------------------------------------------
// NOISE PAINTER
// ------------------------------------------------------------
class NoisePainter extends CustomPainter {
  final double opacity;
  final Random _random = Random();

  NoisePainter({this.opacity = 0.08});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: opacity);

    for (int i = 0; i < size.width * size.height / 80; i++) {
      final dx = _random.nextDouble() * size.width;
      final dy = _random.nextDouble() * size.height;
      canvas.drawRect(
        Rect.fromLTWH(dx, dy, 1.2, 1.2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant NoisePainter oldDelegate) => false;
}
