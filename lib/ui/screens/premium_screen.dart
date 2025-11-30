import 'dart:ui';
import 'package:affirmation/models/user_preferences.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  String _selectedPlan = "yearly";
  final bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isPremium = appState.preferences.isPremiumValid;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Stack(
        children: [
          // BACKGROUND GRADIENT (Soft charcoal)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0E0E0E),
                  Color(0xFF141414),
                  Color(0xFF0D0D0D),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // GOLD GLOW TOP
          Positioned(
            top: -120,
            left: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFE7B0),
              ),
            ),
          ),

          // GOLD GLOW BOTTOM RIGHT
          Positioned(
            bottom: -100,
            right: -70,
            child: Container(
              width: 260,
              height: 260,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFD9A0),
              ),
            ),
          ),

          // BLUR to soften the glow
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 140, sigmaY: 140),
              child: Container(color: Colors.transparent),
            ),
          ),

          // MAIN CONTENT
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                children: [
                  const SizedBox(height: 60),

                  // PREMIUM BADGE (Soft gold + blur circle)
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFFF3C1),
                          ),
                        ),
                        BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFFFF2C0),
                                  Color(0xFFFFCE80),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const Icon(Icons.workspace_premium,
                            color: Colors.white, size: 44),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // TITLE
                  Text(
                    isPremium ? "You're Premium ✨" : "Go Premium",
                    style: const TextStyle(
                      color: Color(0xFFEAEAEA),
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    isPremium
                        ? "Enjoy full access forever."
                        : "Unlock all content, no ads.",
                    style: const TextStyle(
                      color: Color(0xFFBDBDBD),
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 36),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _benefit("All Categories and Themes"),
                          _benefit("Unlimited Favorites"),
                          _benefit("Voice Affirmations"),
                          const SizedBox(height: 30),
                          if (!isPremium) ...[
                            _buildPlan("monthly", "Monthly", "₺99.99"),
                            _buildPlan(
                                "yearly", "Yearly (Best Deal)", "₺549.99"),
                            const SizedBox(height: 20),
                            _buyButton(),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: () {
                                context
                                    .read<AppState>()
                                    .purchaseState
                                    .restorePurchases();
                              },
                              child: const Text(
                                "Restore Purchases",
                                style: TextStyle(
                                  color: Color(0xFFCECECE),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // CLOSE BUTTON - Stack'in en üstünde, SafeArea içinde
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 10, right: 22),
              child: Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xAA000000),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Color(0xFFFFFFFF),
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // LOADING OVERLAY
          if (_loading)
            Container(
              color: const Color(0x88000000),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  //─────────────────────────────── BENEFIT ITEM
  Widget _benefit(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.check_rounded, color: Color(0xFFFFD27A), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFEFEFEF),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  //─────────────────────────────── PLAN CARD
  Widget _buildPlan(String id, String title, String price) {
    final selected = (_selectedPlan == id);

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: selected ? const Color(0xFFFFE8B5) : const Color(0x11FFFFFF),
          border: Border.all(
            color: selected ? const Color(0xFFFFD27A) : const Color(0x22FFFFFF),
            width: 1.3,
          ),
          boxShadow: selected
              ? [
                  const BoxShadow(
                    color: Color(0x44FFC978),
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
              color:
                  selected ? const Color(0xFF4A3D2F) : const Color(0xFFCCCCCC),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: selected
                      ? const Color(0xFF3A2E20)
                      : const Color(0xFFEAEAEA),
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
                    : const Color(0xFFEAEAEA),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  //─────────────────────────────── BUY BUTTON
  Widget _buyButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFF2C0),
            Color(0xFFFFCE80),
          ],
        ),
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
        onPressed: _loading ? null : () {},
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
}
