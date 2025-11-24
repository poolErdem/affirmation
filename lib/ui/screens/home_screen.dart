import 'package:affirmation/models/affirmation.dart';
import 'package:affirmation/models/category.dart';
import 'package:affirmation/ui/screens/premium_screen.dart';
import 'package:affirmation/ui/screens/theme_screen.dart';
import 'package:affirmation/ui/screens/categories_screen.dart';
import 'package:affirmation/ui/screens/settings/settings_screen.dart';
import 'package:affirmation/ui/widgets/premium_upsell_card.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../state/app_state.dart';
import '../widgets/affirmation_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _actionAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  late PageController _pageController;

  double _shareScale = 1.0; // SHARE bounce
  //────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _pageController = PageController();

    _actionAnim = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _actionAnim, curve: Curves.easeOut),
    );

    _fadeAnim = CurvedAnimation(
      parent: _actionAnim,
      curve: Curves.easeInOut,
    );

    _actionAnim.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _actionAnim.dispose();
    super.dispose();
  }

  //────────────────────────────────────────
  // SPARKLE EFFECT (Heart)
  //────────────────────────────────────────
  void _runHeartSparkle() async {
    OverlayEntry entry = OverlayEntry(
      builder: (_) => Positioned(
        top: MediaQuery.of(context).size.height * 0.43,
        right: 60,
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 600),
          tween: Tween(begin: 1, end: 0),
          builder: (_, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.scale(
                scale: 1 + (1 - value) * 0.5,
                child: const Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 26,
                ),
              ),
            );
          },
        ),
      ),
    );

    Overlay.of(context).insert(entry);
    await Future.delayed(const Duration(milliseconds: 650));
    entry.remove();
  }

  //────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    if (!appState.isLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isPremium = appState.preferences.isPremiumValid;
    final backgroundImage = appState.activeThemeImage;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // BACKGROUND IMAGE
          Image.asset(
            backgroundImage,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          // DARK OVERLAY
          Container(
            color: Colors.black.withValues(alpha: 0.40),
          ),

          // TOP BAR
          _buildTopBar(context, isPremium),

          // AFFIRMATIONS LIST
          Align(
            alignment: Alignment.center,
            child: _buildAffirmationPager(appState),
          ),

          // FAVORITE + SHARE (RIGHT SIDE)
          Align(
            alignment: const Alignment(0.90, 0.65),
            child: SlideTransition(
              position: _slideAnim,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: _buildMiddleActions(context),
              ),
            ),
          ),

          // CATEGORY BUTTON
          Positioned(
            left: 16,
            bottom: 24,
            child: _buildCategoryButton(context),
          ),

          // THEME BUTTON
          Positioned(
            right: 16,
            bottom: 24,
            child: _buildThemeButton(context),
          ),
        ],
      ),
    );
  }

  //────────────────────────────────────────
  // TOP BAR
  //────────────────────────────────────────
  Widget _buildTopBar(BuildContext context, bool isPremium) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // SETTINGS
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
                child:
                    const Icon(Icons.settings, color: Colors.white, size: 24),
              ),

              // PREMIUM ICON
              GestureDetector(
                onTap: () {
                  if (isPremium) {
                    _showPremiumStatusDialog(context);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PremiumScreen()),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: isPremium
                        ? const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color:
                        isPremium ? null : Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isPremium
                          ? Colors.amber.shade700
                          : Colors.white.withValues(alpha: 0.25),
                      width: isPremium ? 2 : 1.4,
                    ),
                    boxShadow: isPremium
                        ? [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.35),
                              blurRadius: 22,
                              spreadRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    isPremium
                        ? Icons.workspace_premium
                        : Icons.workspace_premium_outlined,
                    size: 24,
                    color: isPremium
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //────────────────────────────────────────
  // PREMIUM STATUS DIALOG
  //────────────────────────────────────────
  void _showPremiumStatusDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.amber, size: 28),
            const SizedBox(width: 8),
            const Text(
              'Premium Active',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBenefit(Icons.block, 'Ad-free experience'),
            _buildBenefit(Icons.category, 'All categories unlocked'),
            _buildBenefit(Icons.color_lens, 'All themes available'),
            _buildBenefit(Icons.favorite, 'Unlimited favorites'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefit(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.green, size: 18),
          ),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }

  //────────────────────────────────────────
  // AFFIRMATION PAGEVIEW
  //────────────────────────────────────────
  Widget _buildAffirmationPager(AppState appState) {
    final items = appState.pagedItems;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.52,
      child: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: items.length,
        onPageChanged: (index) {
          final item = items[index];
          if (item['type'] == 'affirmation') {
            final realIndex = item['realIndex'] ?? 0;
            appState.onPageChanged(realIndex);
            _actionAnim.forward(from: 0);
          }
        },
        itemBuilder: (_, index) {
          final item = items[index];

          // PREMIUM CTA
          if (item['type'] == 'cta_premium') {
            return const PremiumUpsellCard();
          }

          final affirmation = item['data'];
          if (affirmation == null || affirmation is! Affirmation) {
            return const SizedBox();
          }

          return Center(
            child: AffirmationCard(
              key: ValueKey(affirmation.id),
              affirmation: affirmation,
            ),
          );
        },
      ),
    );
  }

  //────────────────────────────────────────
  // FAVORITE + SHARE BUTTONS
  //────────────────────────────────────────
  Widget _buildMiddleActions(BuildContext context) {
    final appState = context.watch<AppState>();
    final current = appState.affirmationAt(appState.currentIndex);
    final isFav = current != null && appState.isFavorite(current.id);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ❤️ FAVORITE + sparkle
        GestureDetector(
          onTap: () {
            appState.toggleFavoriteForCurrent(context);
            _runHeartSparkle();
          },
          child: AnimatedScale(
            scale: isFav ? 1.25 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                size: 28,
                color: Colors.white,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 🔄 SHARE + bounce
        GestureDetector(
          onTapDown: (_) => setState(() => _shareScale = 0.85),
          onTapUp: (_) => setState(() => _shareScale = 1.0),
          onTapCancel: () => setState(() => _shareScale = 1.0),
          onTap: () async {
            final aff = appState.affirmationAt(appState.currentIndex);
            if (aff != null) await Share.share(aff.text);
          },
          child: AnimatedScale(
            scale: _shareScale,
            duration: const Duration(milliseconds: 140),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.share,
                size: 26,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  //────────────────────────────────────────
  // CATEGORY BUTTON
  //────────────────────────────────────────
  Widget _buildCategoryButton(BuildContext context) {
    final appState = context.watch<AppState>();

    final selectedCategory = appState.categories.firstWhere(
      (c) => c.id == appState.activeCategoryId,
      orElse: () => AffirmationCategory(
        id: "self_care",
        name: "Self Care",
        imageAsset: "assets/data/categories/self_care.jfif",
        isPremiumLocked: false,
      ),
    );

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CategoriesScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.22),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.category, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(
              selectedCategory.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            )
          ],
        ),
      ),
    );
  }

  //────────────────────────────────────────
  // THEME BUTTON
  //────────────────────────────────────────
  Widget _buildThemeButton(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ThemeScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.28),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.22),
            width: 1,
          ),
        ),
        child: const Icon(Icons.color_lens, color: Colors.white, size: 24),
      ),
    );
  }
}
