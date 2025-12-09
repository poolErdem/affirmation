import 'dart:math';
import 'dart:ui';
import 'package:affirmation/ui/widgets/shared_blur_background.dart';
import 'package:affirmation/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../state/app_state.dart';

class GenderScreen extends StatefulWidget {
  const GenderScreen({super.key});

  @override
  State<GenderScreen> createState() => _GenderScreenState();
}

class _GenderScreenState extends State<GenderScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fade;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final t = AppLocalizations.of(context)!;

    final selected = appState.preferences.gender;
    final bg = appState.activeThemeImage;

    // -------------------------------------------------------------
    // Gender seçenekleri
    // -------------------------------------------------------------
    final genders = [
      {
        "code": "female",
        "label": t.female,
        "icon": Icons.female_rounded,
        "color": const Color(0xffFF6FAF),
      },
      {
        "code": "male",
        "label": t.male,
        "icon": Icons.male_rounded,
        "color": const Color(0xff4A7AFF),
      },
      {
        "code": "none",
        "label": "Any",
        "icon": Icons.auto_awesome_rounded,
        "color": const Color(0xff35804F),
      },
    ];

    return SharedBlurBackground(
      imageAsset: bg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            // ⭐ Noise
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _NoisePainter(0.055),
                ),
              ),
            ),

            // ⭐ Top Blur Glow
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
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _fade,
                  curve: Curves.easeOut,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ⭐ Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              size: 22,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            t.gender,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ⭐ Açıklama
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Text(
                        t.genderDescription,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.32,
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ⭐ Gender List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        itemCount: genders.length,
                        itemBuilder: (context, i) {
                          final item = genders[i];
                          final code = item["code"] as String;
                          final label = item["label"] as String;
                          final icon = item["icon"] as IconData;
                          final color = item["color"] as Color;

                          final isSelected = selected?.name == code;

                          return GestureDetector(
                            onTap: () async {
                              await context.read<AppState>().setGender(code);

                              await Future.delayed(
                                  const Duration(milliseconds: 320));

                              if (context.mounted) Navigator.pop(context);
                            },
                            child: AnimatedScale(
                              scale: isSelected ? 1.025 : 1.0,
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOut,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: BackdropFilter(
                                  filter:
                                      ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 240),
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 20, horizontal: 22),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(22),
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withValues(
                                              alpha: isSelected ? 0.28 : 0.18),
                                          Colors.white.withValues(
                                              alpha: isSelected ? 0.12 : 0.07),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFFC9A85D)
                                                .withValues(alpha: 0.65)
                                            : Colors.white
                                                .withValues(alpha: 0.28),
                                        width: isSelected ? 2 : 1.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: isSelected
                                              ? const Color(0xFFC9A85D)
                                                  .withValues(alpha: 0.32)
                                              : Colors.black
                                                  .withValues(alpha: 0.10),
                                          blurRadius: isSelected ? 22 : 14,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(icon, size: 30, color: color),
                                            const SizedBox(width: 14),
                                            Text(
                                              label,
                                              style: TextStyle(
                                                fontSize: 17,
                                                fontWeight: isSelected
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (isSelected)
                                          const Icon(
                                            Icons.check_circle,
                                            color: Color(0xFFC9A85D),
                                            size: 28,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// NOISE PAINTER (Premium Grain)
// ------------------------------------------------------------
class _NoisePainter extends CustomPainter {
  final double opacity;
  final Random _rand = Random();

  _NoisePainter(this.opacity);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: opacity);

    for (int i = 0; i < size.width * size.height / 75; i++) {
      final dx = _rand.nextDouble() * size.width;
      final dy = _rand.nextDouble() * size.height;
      canvas.drawRect(Rect.fromLTWH(dx, dy, 1.2, 1.2), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
