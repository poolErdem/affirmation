import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:affirmation/state/app_state.dart';
import 'package:affirmation/l10n/app_localizations.dart';

class ContentPreferencesScreen extends StatefulWidget {
  const ContentPreferencesScreen({super.key});

  @override
  State<ContentPreferencesScreen> createState() => _ContentPreferencesScreen();
}

class _ContentPreferencesScreen extends State<ContentPreferencesScreen>
    with SingleTickerProviderStateMixin {
  Set<String> selected = {};

  late AnimationController _fadeController;

  final prefs = [
    "self_care",
    "personal_growth",
    "stress_anxiety",
    "body_positivity",
    "happiness",
    "attracting_love",
    "confidence",
    "motivation",
    "mindfulness",
    "gratitude",
  ];

  @override
  void initState() {
    super.initState();

    // Load saved prefs
    final st = context.read<AppState>();
    selected = Set<String>.from(st.preferences.selectedContentPreferences);

    // Fade animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final st = context.read<AppState>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background gradient
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

          // Noise layer
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: NoisePainter(opacity: 0.06),
              ),
            ),
          ),

          // Top blur fade
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
                parent: _fadeController,
                curve: Curves.easeOut,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 28,
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

                    // Subheader
                    const Text(
                      "✨ Select what speaks to your soul",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                        height: 1.3,
                      ),
                    ),

                    const SizedBox(height: 26),

                    // GRID
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
                            onTap: () {
                              setState(() {
                                isSelected
                                    ? selected.remove(item)
                                    : selected.add(item);
                              });

                              // Save
                              st.setSelectedContentPreferences(selected);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                color: Colors.white,
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFC9A85D) // GOLD
                                      : Colors.transparent,
                                  width: isSelected ? 2.2 : 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isSelected
                                        ? const Color(0xFFC9A85D)
                                            .withValues(alpha: 0.22)
                                        : Colors.black.withValues(alpha: 0.05),
                                    blurRadius: isSelected ? 18 : 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  _formatText(item),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16.2,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: Colors.black87,
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
    );
  }

  String _formatText(String id) {
    return id
        .replaceAll("_", " ")
        .split(" ")
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(" ");
  }
}

// ------------------------------------------------------------
// NOISE PAINTER (premium grain effect)
// ------------------------------------------------------------
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
