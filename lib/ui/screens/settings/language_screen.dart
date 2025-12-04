import 'dart:math';
import 'dart:ui';
import 'package:affirmation/constants/constants.dart';
import 'package:affirmation/l10n/app_localizations.dart';
import 'package:affirmation/ui/widgets/shared_blur_background.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../state/app_state.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen>
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
    final selected = appState.preferences.languageCode;
    final t = AppLocalizations.of(context)!;

    final currentLocale = selected;
    final languages = Constants.localizedLanguageNames[currentLocale]!;

    final bg = appState.activeThemeImage;

    return SharedBlurBackground(
      imageAsset: bg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            // ⭐ Noise Layer
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _NoisePainter(0.055),
                ),
              ),
            ),

            // ⭐ Top Glow Blur
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    height: 120,
                    color: Colors.transparent,
                  ),
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
                            t.language,
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

                    // ⭐ Description
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Text(
                        t.languageDescription,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.32,
                          color: Colors.black.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ⭐ LANGUAGE LIST (Glass Tiles)
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        children: languages.entries.map((item) {
                          final code = item.key;
                          final title = item.value;
                          final isSelected = code == selected;

                          return GestureDetector(
                            onTap: () async {
                              await context.read<AppState>().setLanguage(code);

                              await Future.delayed(
                                  const Duration(milliseconds: 320));

                              if (context.mounted) Navigator.pop(context);
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 18, horizontal: 22),
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
                                      Text(
                                        title,
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_circle,
                                          color: Color(0xFFC9A85D),
                                          size: 26,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
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
// Noise Painter (Premium Grain)
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
