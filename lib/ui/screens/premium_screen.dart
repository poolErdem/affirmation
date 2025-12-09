import 'dart:ui';
import 'dart:math';

import 'package:affirmation/models/user_preferences.dart';
import 'package:affirmation/ui/widgets/shared_blur_background.dart';
import 'package:affirmation/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen>
    with SingleTickerProviderStateMixin {
  String _selectedPlan = "yearly";
  final bool _loading = false;

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
    final isPremium = appState.preferences.isPremiumValid;
    final purchase = appState.purchaseState;

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
                  painter: _NoisePainter(opacity: 0.055),
                ),
              ),
            ),

            // ⭐ Top Glow
            Positioned(
              top: -80,
              left: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFF2C0),
                ),
              ),
            ),

            // ⭐ Bottom Glow
            Positioned(
              bottom: -110,
              right: -70,
              child: Container(
                width: 200,
                height: 200,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFD18F),
                ),
              ),
            ),

            // ⭐ FULL SCREEN BLUR SOFTENER
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                child: Container(color: Colors.transparent),
              ),
            ),

            SafeArea(
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _fade,
                  curve: Curves.easeOut,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),

                      // ⭐ Premium Badge (Glass Orb)
                      _premiumBadge(),

                      const SizedBox(height: 24),

                      // ⭐ TITLE
                      Text(
                        isPremium ? "${t.youarePremium} ✨" : t.goPremium,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        isPremium
                            ? "Enjoy unlimited access forever."
                            : "Unlock all content. No ads. Total freedom.",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 15,
                          height: 1.35,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 26),

                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _benefit("All Categories & Themes"),
                              _benefit("Unlimited Favorites"),
                              _benefit("My Affirmations"),
                              _benefit("Premium Backgrounds"),
                              const SizedBox(height: 28),
                              if (!isPremium) ...[
                                _planTile(
                                  id: "monthly",
                                  title: "Monthly",
                                  price: purchase.monthlyPriceLabel,
                                ),
                                _planTile(
                                  id: "yearly",
                                  title: "Yearly • Best Value",
                                  price: purchase.yearlyPriceLabel,
                                  highlight: true,
                                ),
                                const SizedBox(height: 20),
                                _buyButton(),
                                const SizedBox(height: 12),
                                _restoreButton(purchase),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ⭐ Close Button
            Positioned(
              top: 50,
              right: 22,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent, // ⭐ TIKLAMA GARANTİSİ
                onTap: () {
                  print("❌ Close tapped");
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
              ),
            ),

            // ⭐ Loading Overlay
            if (_loading)
              Container(
                color: Colors.black.withValues(alpha: 0.55),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  //───────────────────────────────────────────────────────────────
  // ⭐ GLASS PREMIUM BADGE
  Widget _premiumBadge() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 118,
          height: 118,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFFFF0C6),
          ),
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            width: 118,
            height: 118,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFFF3C1),
                  Color(0xFFFFCE80),
                ],
              ),
            ),
          ),
        ),
        const Icon(Icons.workspace_premium, size: 48, color: Colors.white),
      ],
    );
  }

  //───────────────────────────────────────────────────────────────
  // ⭐ BENEFIT LINE
  Widget _benefit(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFFFFE08F), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  //───────────────────────────────────────────────────────────────
  // ⭐ PLAN TILE
  Widget _planTile({
    required String id,
    required String title,
    required String price,
    bool highlight = false,
  }) {
    final selected = _selectedPlan == id;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: highlight
              ? LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.22),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                )
              : null,
          color: highlight ? null : Colors.white.withValues(alpha: 0.09),
          border: Border.all(
            color: selected
                ? const Color(0xFFFFE08F)
                : Colors.white.withValues(alpha: 0.20),
            width: selected ? 2 : 1.2,
          ),
          boxShadow: selected
              ? [
                  const BoxShadow(
                    color: Color(0x33FFD27A),
                    blurRadius: 22,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected
                  ? const Color(0xFF4A3D2F)
                  : Colors.white.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: selected ? const Color(0xFF3A2E20) : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Text(
              price,
              style: TextStyle(
                color: selected
                    ? const Color(0xFF3A2E20)
                    : Colors.white.withValues(alpha: 0.85),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  //───────────────────────────────────────────────────────────────
  // ⭐ BUY BUTTON
  Widget _buyButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFF3C1),
            Color(0xFFFFCE80),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: _loading
            ? null
            : () async {
                // backend purchase logic...
              },
        child: const Text(
          "Continue",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3A2E20),
          ),
        ),
      ),
    );
  }

  //───────────────────────────────────────────────────────────────
  // ⭐ RESTORE BUTTON
  Widget _restoreButton(purchase) {
    return TextButton(
      onPressed: () => purchase.restorePurchases(),
      child: Text(
        "Restore Purchases",
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.75),
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

//──────────────────────────────────────────────────────────────────
// ⭐ NOISE PAINTER
class _NoisePainter extends CustomPainter {
  final double opacity;
  final Random _rand = Random();

  _NoisePainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: opacity);

    for (int i = 0; i < size.width * size.height / 70; i++) {
      final dx = _rand.nextDouble() * size.width;
      final dy = _rand.nextDouble() * size.height;
      canvas.drawRect(Rect.fromLTWH(dx, dy, 1.2, 1.2), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
