import 'dart:math';
import 'dart:ui';
import 'package:affirmation/constants/constants.dart';
import 'package:affirmation/utils/utils.dart';
import 'package:affirmation/ui/widgets/shared_blur_background.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:affirmation/state/app_state.dart';
import 'package:affirmation/l10n/app_localizations.dart';

class ContentPreferencesScreen extends StatefulWidget {
  const ContentPreferencesScreen({super.key});

  @override
  State<ContentPreferencesScreen> createState() =>
      _ContentPreferencesScreenState();
}

class _ContentPreferencesScreenState extends State<ContentPreferencesScreen>
    with SingleTickerProviderStateMixin {
  Set<String> selected = {};
  late AnimationController _fade;

  final prefs = Constants.allCategories;

  @override
  void initState() {
    super.initState();

    final st = context.read<AppState>();
    selected = Set<String>.from(st.preferences.selectedContentPreferences);

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
    final t = AppLocalizations.of(context)!;
    final appState = context.watch<AppState>();
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
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ⭐ Header
                      Row(
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
                            t.preferences,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // ⭐ Description
                      Text(
                        t.prefChoose,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.35,
                          color: Colors.black.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ⭐ GRID
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.only(bottom: 12),
                          itemCount: prefs.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 18,
                            childAspectRatio: 2.8,
                          ),
                          itemBuilder: (_, index) {
                            final item = prefs[index];
                            final isSelected = selected.contains(item);

                            return GestureDetector(
                              onTap: () async {
                                setState(() {
                                  isSelected
                                      ? selected.remove(item)
                                      : selected.add(item);
                                });

                                await context
                                    .read<AppState>()
                                    .setSelectedContentPreferences(selected);
                              },
                              child: AnimatedScale(
                                scale: isSelected ? 1.03 : 1.0,
                                duration: const Duration(milliseconds: 160),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(22),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                        sigmaX: 12, sigmaY: 12),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14, horizontal: 10),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(22),
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.white.withValues(
                                                alpha:
                                                    isSelected ? 0.30 : 0.16),
                                            Colors.white.withValues(
                                                alpha:
                                                    isSelected ? 0.13 : 0.07),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFFC9A85D)
                                                  .withValues(alpha: 0.65)
                                              : Colors.white
                                                  .withValues(alpha: 0.25),
                                          width: isSelected ? 2.0 : 1.3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isSelected
                                                ? const Color(0xFFC9A85D)
                                                    .withValues(alpha: 0.28)
                                                : Colors.black
                                                    .withValues(alpha: 0.10),
                                            blurRadius: isSelected ? 20 : 12,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          localizedCategoryName(t, item),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 16.5,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
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
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// PREMIUM Noise Painter
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
