import 'dart:math';

import 'package:affirmation/models/category.dart';
import 'package:affirmation/ui/screens/premium_screen.dart';
import 'package:affirmation/ui/screens/theme_screen.dart';
import 'package:affirmation/ui/screens/categories_screen.dart';
import 'package:affirmation/ui/screens/settings/settings_screen.dart';
import 'package:affirmation/models/user_preferences.dart';

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

  double _shareScale = 1.0;

  @override
  void initState() {
    super.initState();

    final appState = Provider.of<AppState>(context, listen: false);
    final randomIndex = Random().nextInt(appState.pageCount);

    _pageController = PageController(initialPage: randomIndex);

    appState.playback.onIndexChanged = (newIndex) {
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          newIndex,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    };

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
  // SPARKLE EFFECT
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
            return Transform.scale(
              scale: 1 + (1 - value) * 0.5,
              child: const Icon(Icons.star, color: Colors.amber, size: 26),
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
          // BACKGROUND
          Image.asset(
            backgroundImage,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          // DARK OVERLAY
          Container(color: const Color(0x55000000)),

          // TOP BAR
          _buildTopBar(context, isPremium),

          // AUTO-READ BAR
          _buildAutoReadBar(),

          // AFFIRMATIONS
          Align(
            alignment: Alignment.center,
            child: _buildAffirmationPager(appState),
          ),

          // FAVORITE + SHARE
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
            color: const Color(0x22000000), // yarı şeffaf siyah (opacity YOK)
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0x33FFFFFF), // hafif beyaz çerçeve
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ⚙️ SETTINGS BUTTON
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

              // ⭐ PREMIUM BUTTON
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
                    shape: BoxShape.circle,
                    gradient: isPremium
                        ? const LinearGradient(
                            colors: [
                              Color(0xFFFFD700),
                              Color(0xFFFFA500),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isPremium
                        ? null
                        : const Color(0x33000000), // premium değilse sade
                    border: Border.all(
                      color: isPremium
                          ? Colors.amber.shade700
                          : const Color(0x33FFFFFF),
                      width: isPremium ? 2 : 1.4,
                    ),
                    boxShadow: isPremium
                        ? [
                            BoxShadow(
                              color: Colors.amber.withAlpha(90),
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
                    color: Colors.white,
                    size: 24,
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
  // AUTO READ PANEL
  //────────────────────────────────────────
  Widget _buildAutoReadBar() {
    final appState = context.watch<AppState>();
    final playback = appState.playback; // ⭐ PlaybackState'e erişim
    final enabled = playback.autoReadEnabled;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 80,
      left: 20,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 200, // ⭐️ genişlik burada limitleniyor
        ),
        child: GestureDetector(
          onTap: () => playback.toggleAutoRead(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0x33000000),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x44FFFFFF), width: 1.3),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      enabled ? Icons.volume_up : Icons.volume_off,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      enabled ? "Auto-Read: ON" : "Auto-Read: OFF",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const Text(
                  "1x",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  //────────────────────────────────────────
  // PAGEVIEW + AUTO-READ
  //────────────────────────────────────────

  Widget _buildAffirmationPager(AppState appState) {
    final items = appState.currentFeed; // List<Affirmation>

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.52,
      child: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: items.length,
        onPageChanged: (index) {
          appState.setCurrentIndex(index);
          appState.playback.setCurrentIndex(index);
          _actionAnim.forward(from: 0);
        },
        itemBuilder: (_, index) {
          final affirmation = items[index]; // Affirmation

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
  // FAVORITE + SHARE
  //────────────────────────────────────────
  Widget _buildMiddleActions(BuildContext context) {
    final appState = context.watch<AppState>();
    final current = appState.affirmationAt(appState.currentIndex);
    final isFav = current != null && appState.isFavorite(current.id);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            final appState = context.read<AppState>();
            final aff = appState.affirmationAt(appState.currentIndex);

            if (appState.isOverFavoriteLimit()) {
              _showFavoriteLimitDialog(context);
              return;
            }

            if (aff != null) {
              appState.toggleFavorite(aff.id);
            }

            _runHeartSparkle();
          },
          child: AnimatedScale(
            scale: isFav ? 1.25 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0x33000000),
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
              decoration: const BoxDecoration(
                color: Color(0x33000000),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.share, size: 26, color: Colors.white),
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
          color: const Color(0x44000000),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: const Color(0x33FFFFFF),
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
          color: const Color(0x44000000),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0x33FFFFFF),
            width: 1,
          ),
        ),
        child: const Icon(Icons.color_lens, color: Colors.white, size: 24),
      ),
    );
  }

  //────────────────────────────────────────
// PREMIUM STATUS DIALOG
//────────────────────────────────────────
  Widget _buildPremiumBenefit(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0x3323C552), // yeşilimsi ama opacity YOK
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF23C552), size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  void _showPremiumStatusDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(
            color: Color(0x55FFD700),
            width: 1.4,
          ),
        ),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        title: Row(
          children: [
            const Icon(Icons.workspace_premium, color: Colors.amber, size: 28),
            const SizedBox(width: 10),
            const Text(
              'Premium Active',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPremiumBenefit(Icons.block, "Ad-free experience"),
            _buildPremiumBenefit(Icons.category, "All categories unlocked"),
            _buildPremiumBenefit(Icons.color_lens, "All themes available"),
            _buildPremiumBenefit(Icons.favorite, "Unlimited favorites"),
          ],
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFavoriteLimitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Favorites Limit"),
        content: const Text(
          "You've reached your free favorites limit (5).\n\nUpgrade to Premium for up to 50 favorites ✨",
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PremiumScreen()),
              );
            },
            child: const Text(
              "Upgrade",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
