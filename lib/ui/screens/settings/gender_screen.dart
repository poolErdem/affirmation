import 'dart:math';
import 'dart:ui';
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

    // -------------------------------------------------------------
    // Gender seçenekleri
    // -------------------------------------------------------------
    final genders = [
      {
        "code": "female",
        "label": "Female",
        "icon": Icons.female_rounded,
        "color": const Color(0xffFF6FAF), // pink
      },
      {
        "code": "male",
        "label": "Male",
        "icon": Icons.male_rounded,
        "color": const Color(0xff4A7AFF), // blue
      },
      {
        "code": "none",
        "label": "Any",
        "icon": Icons.auto_awesome_rounded,
        "color": const Color.fromARGB(255, 53, 128, 79), // soft green
      },
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ⭐ Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xfff7f2ed),
                  Color(0xfff2ebe5),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // ⭐ Noise Texture
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: NoisePainter(opacity: 0.06),
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
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
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
                  // ⭐ HEADER
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 26,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          t.gender,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ⭐ AÇIKLAMA (Doğru Yer)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Text(
                      t.genderDescription,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                        height: 1.35,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ⭐ GENDER LIST
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
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
                            print("👤 GenderScreen → $code seçildi");
                            await context.read<AppState>().setGender(code);

                            await Future.delayed(
                                const Duration(milliseconds: 350));

                            if (context.mounted) Navigator.pop(context);
                          },
                          child: AnimatedScale(
                            scale: isSelected ? 1.02 : 1.0,
                            duration: const Duration(milliseconds: 160),
                            curve: Curves.easeOut,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 240),
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.symmetric(
                                vertical: 20,
                                horizontal: 22,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFC9A85D)
                                      : Colors.transparent,
                                  width: isSelected ? 2.2 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isSelected
                                        ? const Color(0xFFC9A85D)
                                            .withValues(alpha: 0.28)
                                        : Colors.black.withValues(alpha: 0.07),
                                    blurRadius: isSelected ? 20 : 12,
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
                                      Icon(
                                        icon,
                                        size: 28,
                                        color: color,
                                      ),
                                      const SizedBox(width: 14),
                                      Text(
                                        label,
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: Colors.black87,
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
    );
  }
}

// -------------------------------------------------------------------
// NoisePainter – aynı
// -------------------------------------------------------------------
class NoisePainter extends CustomPainter {
  final double opacity;
  final Random _random = Random();

  NoisePainter({this.opacity = 0.06});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: opacity);

    for (int i = 0; i < size.width * size.height / 80; i++) {
      final dx = _random.nextDouble() * size.width;
      final dy = _random.nextDouble() * size.height;
      canvas.drawRect(Rect.fromLTWH(dx, dy, 1.0, 1.0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant NoisePainter oldDelegate) => false;
}
