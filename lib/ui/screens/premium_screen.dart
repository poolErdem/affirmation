import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../models/user_preferences.dart';

const String kMonthly = "premium_monthly";
const String kYearly = "premium_yearly";
const String kLifetime = "premium_lifetime";

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  String _selectedPlan = "yearly";
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _initStore();
  }

  Future<void> _initStore() async {
    final available = await InAppPurchase.instance.isAvailable();
    if (!available) print("❌ Store unavailable");
  }

  //────────────────────────────────────────
  // DEBUG PURCHASE (fake)
  //────────────────────────────────────────
  Future<void> _simulatePurchase() async {
    setState(() => _loading = true);

    // ödeme simülasyonu
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return; // <-- KURTARICI

    final appState = context.read<AppState>();

    PremiumPlan? planId;
    DateTime? expiresAt;

    switch (_selectedPlan) {
      case "monthly":
        planId = PremiumPlan.monthly;
        expiresAt = DateTime.now().add(const Duration(days: 30));
        break;
      case "yearly":
        planId = PremiumPlan.yearly;
        expiresAt = DateTime.now().add(const Duration(days: 365));
        break;
      case "lifetime":
        planId = PremiumPlan.lifetime;
        expiresAt = null;
        break;
    }

    await appState.updatePremiumStatus(
      active: true,
      planId: planId,
      expiresAt: expiresAt,
    );

    if (!mounted) return; // yine güvenliyiz
    setState(() => _loading = false);

    // Başarı mesajı
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 Premium Activated! (${_selectedPlan.toUpperCase()})'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _startPurchase() async {
    if (kDebugMode) {
      await _simulatePurchase();
      return;
    }
  }

  //────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isPremium = appState.preferences.isPremiumValid;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black,
                  const Color(0xFF1A1A1A),
                  const Color(0xFF000000),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Glow layers
          Positioned(
            top: -80,
            left: -40,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.amber.withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            right: -40,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.orange.withValues(alpha: 0.12),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Close button
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close,
                          color: Colors.white, size: 28),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Premium Badge
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.5),
                            blurRadius: 30,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.workspace_premium,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Title
                  Center(
                    child: Text(
                      isPremium ? "You're Premium ✨" : "Go Premium",
                      style: const TextStyle(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Center(
                    child: Text(
                      isPremium
                          ? "Enjoy everything without limits."
                          : "Unlock all features. No ads. All themes.",
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 16),
                    ),
                  ),

                  const SizedBox(height: 32),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // BENEFITS LIST
                          _benefit(
                              "All Premium Themes and Categories unlocked"),
                          _benefit("Unlimited Favorites"),
                          _benefit("Remove Ads"),
                          _benefit("Voice Affirmations"),
                          _benefit("Early Access to New Features"),

                          const SizedBox(height: 30),

                          if (!isPremium) ...[
                            _buildPlan("monthly", "Monthly", "₺99.99 / month"),
                            _buildPlan("yearly", "Yearly (Best Deal)",
                                "₺549.99 / year"),
                            _buildPlan("lifetime", "Lifetime Access",
                                "₺999.99 one-time"),
                            const SizedBox(height: 20),

                            // BUY BUTTON
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFD700),
                                    Color(0xFFFFA500)
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber.withValues(alpha: 0.4),
                                    blurRadius: 18,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: _loading ? null : _startPurchase,
                                child: _loading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white)
                                    : const Text(
                                        "Continue",
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            TextButton(
                              onPressed: () {
                                InAppPurchase.instance.restorePurchases();
                              },
                              child: Text(
                                "Restore Purchases",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),

          if (_loading) _loadingOverlay(),
        ],
      ),
    );
  }

  //────────────────────────────────────────

  Widget _benefit(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.amber, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlan(
    String id,
    String title,
    String price, {
    bool highlight = false,
  }) {
    final bool selected = (_selectedPlan == id);

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: highlight
              ? const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                )
              : null,
          color: highlight ? null : Colors.white.withValues(alpha: 0.07),
          border: Border.all(
              color: selected ? Colors.amber : Colors.white12, width: 1.4),
          boxShadow: highlight
              ? [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.4),
                    blurRadius: 22,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? Colors.white : Colors.white70,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Text(
              price,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _loadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.4),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}
