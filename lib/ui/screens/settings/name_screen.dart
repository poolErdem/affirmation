import 'dart:math';
import 'dart:ui';
import 'package:affirmation/l10n/app_localizations.dart';
import 'package:affirmation/ui/widgets/shared_blur_background.dart';
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

    // mevcut isim
    if (appState.onboardingName?.trim().isNotEmpty == true) {
      _controller.text = appState.onboardingName!;
    } else if (appState.preferences.userName.isNotEmpty) {
      _controller.text = appState.preferences.userName;
    }

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
            // ⭐ Noise
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _NoisePainter(0.055),
                ),
              ),
            ),

            // ⭐ Üst hafif blur glow
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
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ⭐ HEADER
                      Row(
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
                            t.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
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
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ⭐ GLASS INPUT BOX
                      ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.22),
                                  Colors.white.withValues(alpha: 0.08),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: const Color(0x55C9A85D),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
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
                                fontSize: 16,
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ⭐ SAVE BUTTON
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _fade,
                  curve: Curves.easeOut,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFC9A85D),
                            Color(0xFFE4C98A),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF87652B),
                          width: 1.4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFC9A85D).withValues(alpha: 0.40),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () async {
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
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: Text(
                                "Save",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                  shadows: [
                                    Shadow(
                                      color: Color(0xFFC9A85D),
                                      offset: Offset(0, 0),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// Premium Noise Painter
// ------------------------------------------------------------
class _NoisePainter extends CustomPainter {
  final double opacity;
  final Random _r = Random();

  _NoisePainter(this.opacity);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.black.withValues(alpha: opacity);
    for (int i = 0; i < size.width * size.height / 75; i++) {
      final dx = _r.nextDouble() * size.width;
      final dy = _r.nextDouble() * size.height;
      canvas.drawRect(Rect.fromLTWH(dx, dy, 1.2, 1.2), p);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
