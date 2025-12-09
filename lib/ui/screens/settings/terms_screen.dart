import 'dart:ui';
import 'dart:math';
import 'package:affirmation/state/app_state.dart';
import 'package:affirmation/ui/widgets/shared_blur_background.dart';
import 'package:flutter/material.dart';
import 'package:affirmation/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
          title: Transform.translate(
            offset: const Offset(-10, 0),
            child: Text(
              t.terms,
              style: const TextStyle(
                fontFamily: "Poppins",
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
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
                  child: Container(height: 130, color: Colors.transparent),
                ),
              ),
            ),

            // ⭐ Main Content
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.30),
                            Colors.white.withValues(alpha: 0.12),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color:
                              const Color(0xFFC9A85D).withValues(alpha: 0.45),
                          width: 1.4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const _TermsContent(),
                    ),
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

class _TermsContent extends StatelessWidget {
  const _TermsContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          "Last Updated: November 2025",
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        SizedBox(height: 22),
        _Header("1. Acceptance of Terms"),
        _Body(
          "By using the Affirmation app, you agree to these Terms & Conditions. "
          "If you do not agree, please discontinue using the application.",
        ),
        _Header("2. Use of the App"),
        _Body(
          "This app is for personal and non-commercial use. You may not copy, "
          "modify, distribute, or sell any content without permission.",
        ),
        _Header("3. User Responsibilities"),
        _Body(
          "You agree not to misuse the app, attempt to disrupt service, "
          "or engage in any harmful or illegal activity while using the app.",
        ),
        _Header("4. Premium Features"),
        _Body(
          "Certain content and themes may require a Premium subscription. "
          "Payments are handled through your app store and follow their policies.",
        ),
        _Header("5. Limitation of Liability"),
        _Body(
          "We are not responsible for emotional, psychological, or health outcomes "
          "that may result from using the app. This app is for motivational purposes only.",
        ),
        _Header("6. Updates to Terms"),
        _Body(
          "We may update these Terms & Conditions from time to time. "
          "Continued use of the app means you agree to the updated terms.",
        ),
        _Header("7. Contact Us"),
        _Body(
          "If you have any questions about these Terms, feel free to contact us.",
        ),
        SizedBox(height: 10),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final String text;
  const _Body(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        height: 1.45,
        color: Colors.black87,
      ),
    );
  }
}

// ------------------------------------------------------------
// Noise Painter
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
