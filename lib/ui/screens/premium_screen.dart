import 'dart:ui';
import 'dart:math';

import 'package:affirmation/models/user_preferences.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:affirmation/state/app_state.dart';
import 'package:affirmation/l10n/app_localizations.dart';
import 'package:affirmation/ui/widgets/shared_blur_background.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen>
    with SingleTickerProviderStateMixin {
  String _selectedPlan = "yearly";
  bool _loading = false;

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
            Positioned.fill(child: CustomPaint(painter: _NoisePainter())),

            // Gold Glow
            Positioned(
              top: -80,
              left: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x33FFF3C1),
                ),
              ),
            ),

            Positioned(
              bottom: -110,
              right: -70,
              child: Container(
                width: 200,
                height: 200,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x33FFCE80),
                ),
              ),
            ),

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
                      _premiumBadge(),
                      const SizedBox(height: 24),
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
                            : "Unlock All Features",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFECECEC),
                          fontSize: 15,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 38),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _comparisonTable(),
                              const SizedBox(height: 32),
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
                                _planTile(
                                  id: "lifetime",
                                  title: "Lifetime Access",
                                  price: purchase.lifeTimePriceLabel,
                                ),
                                const SizedBox(height: 12),
                                _buyButton(purchase),
                                const SizedBox(height: 10),
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

            Positioned(
              top: 50,
              right: 22,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0x55000000),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //───────────────────────────────────────────────────────────────
  // Comparison Table
  Widget _comparisonTable() {
    return Column(
      children: [
        Row(
          children: const [
            Expanded(child: SizedBox()),
            SizedBox(
              width: 60,
              child: Text(
                "Premium",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFFFE08F),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(width: 12),
            SizedBox(
              width: 60,
              child: Text(
                "Basic",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFE0E0E0),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _featureRow("Favorites", premium: true, basic: true),
        _featureRow("All Categories & Themes", premium: true, basic: false),
        _featureRow("Unlimited My Affirmations", premium: true, basic: false),
        _featureRow("Voice Affirmations", premium: true, basic: false),
      ],
    );
  }

  Widget _featureRow(String text,
      {required bool premium, required bool basic}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
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
          SizedBox(
            width: 60,
            child: Icon(
              premium ? Icons.check : Icons.remove,
              color: premium ? Colors.white : Color(0x55FFFFFF),
            ),
          ),
          SizedBox(
            width: 60,
            child: Icon(
              basic ? Icons.check : Icons.remove,
              color: basic ? Colors.white : Color(0x33FFFFFF),
            ),
          ),
        ],
      ),
    );
  }

  //───────────────────────────────────────────────────────────────
  // Premium Badge
  Widget _premiumBadge() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55FFD27A),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: const Icon(
        Icons.workspace_premium,
        size: 48,
        color: Colors.white,
      ),
    );
  }

  //───────────────────────────────────────────────────────────────
  // Plan Tile
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
        duration: const Duration(milliseconds: 170),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0x14141414),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.white : const Color(0x40FFFFFF),
            width: selected ? 2.2 : 1.2,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x40FFFFFF),
                    blurRadius: 20,
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              price,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  //───────────────────────────────────────────────────────────────
  //───────────────────────────────────────────────────────────────
  // BUY BUTTON
  Widget _buyButton(purchase) {
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
        ),
        onPressed: _loading
            ? null
            : () async {
                setState(() => _loading = true);

                final ps = context.read<AppState>().purchaseState;
                await ps.buyPlan(_selectedPlan);

                setState(() => _loading = false);
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
  Widget _restoreButton(purchase) {
    return TextButton(
      onPressed: () => purchase.restorePurchases(),
      child: const Text(
        "Restore Purchases",
        style: TextStyle(
          color: Colors.white,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

//──────────────────────────────────────────────────────────────────
// Noise Painter
class _NoisePainter extends CustomPainter {
  final Random _rand = Random();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF1A1A1A);

    for (int i = 0; i < size.width * size.height / 70; i++) {
      final dx = _rand.nextDouble() * size.width;
      final dy = _rand.nextDouble() * size.height;
      canvas.drawRect(Rect.fromLTWH(dx, dy, 1.2, 1.2), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
