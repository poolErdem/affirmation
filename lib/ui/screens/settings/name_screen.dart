import 'dart:math';
import 'dart:ui';
import 'package:affirmation/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../state/app_state.dart';

class NameScreen extends StatefulWidget {
  const NameScreen({super.key});

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  late AnimationController _fade;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();

    // Eski isim yükleme
    if (appState.onboardingName != null &&
        appState.onboardingName!.trim().isNotEmpty) {
      _controller.text = appState.onboardingName!;
    } else if (appState.preferences.userName.isNotEmpty) {
      _controller.text = appState.preferences.userName;
    }

    // Animasyon
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

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ⭐ Premium Gradient
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
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
                          t.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Text(
                      t.nameDescription,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        color: Colors.black.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ⭐ Premium Input Box
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color:
                              const Color(0xFFC9A85D).withValues(alpha: 0.35),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFC9A85D)
                                .withValues(alpha: 0.18), // Gold-ish shadow
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        cursorColor: const Color(0xFFC9A85D),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Type your name...",
                          hintStyle: TextStyle(color: Colors.black38),
                        ),
                        style: const TextStyle(
                          fontSize: 17,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ⭐ Save Button (Floating Bottom)
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: _fade,
                curve: Curves.easeOut,
              ),
              child: ElevatedButton(
                onPressed: () async {
                  final name = _controller.text.trim();

                  context.read<AppState>().setUserName(name);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Name saved"),
                      duration: Duration(milliseconds: 900),
                    ),
                  );

                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.black, // MAT SİYAH
                  foregroundColor: Colors.white,
                  elevation: 10,
                  shadowColor: Colors.black.withValues(alpha: 0.45),

                  // GOLD OUTLINE SOFT EFFECT
                  side: BorderSide(
                    color: const Color(0xFFC9A85D)
                        .withValues(alpha: 0.35), // gold tint
                    width: 1.2,
                  ),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  "Save",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    shadows: [
                      Shadow(
                        color: Color(0xFFC9A85D), // gold light glow
                        offset: Offset(0, 0),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// Noise Painter (Aynı premium görünüm için)
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
