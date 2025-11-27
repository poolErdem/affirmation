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

    // 🔥 AppState'i burada güvenli şekilde alırız
    final appState = Provider.of<AppState>(context, listen: false);

    // 🔥 RANDOM sayfa seçimi
    final randomIndex = Random().nextInt(appState.pageCount);

    // 🔥 PAGE CONTROLLER
    _pageController = PageController(initialPage: randomIndex);

    // 🔥 Playback index değiştiğinde PageView’ı ilerlet
    appState.playback.onIndexChanged = (newIndex) {
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          newIndex,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    };

    // 🔥 Animations
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

          // AFFIRMATIONS
          Align(
            alignment: Alignment.center,
            child: _buildAffirmationPager(appState),
          ),

          // FAVORITE + SHARE
          Align(
            alignment: const Alignment(0.90, 0.75),
            child: SlideTransition(
              position: _slideAnim,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: _buildMiddleActions(context),
              ),
            ),
          ),

          // Positioned(
          //     left: 16,
          //     bottom: 24,
          //     // Herhangi bir sayfada FloatingActionButton ekle:
          //     child: FloatingActionButton(
          //       onPressed: () {
          //         final reminderState = context.read<ReminderState>();
          //         reminderState.debugCreateSampleReminder();
          //         Future.delayed(Duration(seconds: 2), () {
          //           reminderState.debugFireFirstReminder();
          //         });
          //       },
          //       child: Icon(Icons.add_alert),
          //     )),

          //CATEGORY BUTTON
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
          final lastIndex = items.length - 1;
          if (index == lastIndex) {
            // ⭐ Son sayfadaysa → hafif delay ile başa sar
            Future.microtask(() {
              if (_pageController.hasClients) {
                _pageController.jumpToPage(0);
              }
            });
          }
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

  // FAVORITE + SHARE
  //────────────────────────────────────────
  Widget _buildMiddleActions(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 🔊 READ BUTTON — EN ÜSTTE  ⭐⭐ BU KISIM BURAYA GELİYOR ⭐⭐
        Consumer<AppState>(
          builder: (context, appState, child) {
            final enabled = appState.playback.autoReadEnabled;

            return GestureDetector(
              onTap: () {
                appState.playback.toggleAutoRead();
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: enabled
                      ? const Color(0x55FF6B6B)
                      : const Color(0x33000000),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: enabled ? Colors.redAccent : const Color(0x44FFFFFF),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  enabled ? Icons.volume_up : Icons.volume_off,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        // ❤️ FAVORİ BUTONU
        Consumer<AppState>(
          builder: (context, appState, child) {
            final current = appState.affirmationAt(appState.currentIndex);
            final isFav = current != null && appState.isFavorite(current.id);

            return GestureDetector(
              onTap: () {
                final aff = appState.affirmationAt(appState.currentIndex);
                if (aff == null) return;

                final wasFav = appState.isFavorite(aff.id);

                if (!wasFav && appState.isOverFavoriteLimit()) {
                  _showFavoriteLimitDialog(context);
                  return;
                }

                appState.toggleFavorite(aff.id);

                if (!wasFav) {
                  _runTripleStarSparkle();
                }
              },
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
            );
          },
        ),

        const SizedBox(height: 16),

        // 📤 PAYLAŞ BUTONU
        GestureDetector(
          onTapDown: (_) => setState(() => _shareScale = 0.85),
          onTapUp: (_) => setState(() => _shareScale = 1.0),
          onTapCancel: () => setState(() => _shareScale = 1.0),
          onTap: () {
            final appState = context.read<AppState>();
            final aff = appState.affirmationAt(appState.currentIndex);
            if (aff == null) return;

            Share.share(aff.text);
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
              child: const Icon(Icons.ios_share, size: 26, color: Colors.white),
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
        id: "general",
        name: "General",
        imageAsset: "assets/data/categories/general.jfif",
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
            ),
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

  //────────────────────────────────────────
  // SPARKLE EFFECT
  //────────────────────────────────────────
  void _runTripleStarSparkle() async {
    final overlay = Overlay.of(context);

    Future<void> showStar(double dx, double dy, double size) async {
      final entry = OverlayEntry(
        builder: (_) => Positioned(
          top: MediaQuery.of(context).size.height * 0.60 + dy,
          //left: MediaQuery.of(context).size.width * 0.55 + dx,
          right: MediaQuery.of(context).size.width * 0.30 - dx,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 1, end: 0),
            duration: const Duration(milliseconds: 600),
            builder: (_, value, __) {
              return Transform.scale(
                scale: 1 + (1 - value) * size,
                child: const Icon(Icons.star,
                    color: Color.fromARGB(255, 201, 174, 92), size: 28),
              );
            },
          ),
        ),
      );

      overlay.insert(entry);
      await Future.delayed(const Duration(milliseconds: 620));
      entry.remove();
    }

    // ⭐ 1 → merkez
    showStar(50, 0, 0.4);

    // ⭐ 2 → biraz sol + biraz yukarı
    await Future.delayed(const Duration(milliseconds: 90));
    showStar(30, -21, 0.5);

    // ⭐ 3 → daha sol + daha yukarı
    await Future.delayed(const Duration(milliseconds: 90));
    showStar(15, -50, 0.6);
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
    final appState = context.read<AppState>();

    final isPremium = appState.preferences.isPremiumValid;
    final freeLimit = AppState.freeFavoriteLimit;
    final premiumLimit = AppState.premiumFavoriteLimit;

    String title;
    String message;

    List<Widget> actions;

    if (!isPremium) {
      // FREE USER
      title = "Favorites Limit";
      message = "You've reached your free favorites limit ($freeLimit).\n\n"
          "Upgrade to Premium and save up to $premiumLimit favorites ✨";

      actions = [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PremiumScreen()),
            );
          },
          child: const Text("Go Premium"),
        ),
      ];
    } else {
      // PREMIUM USER
      title = "Premium Limit Reached";
      message = "You've reached your Premium favorites limit ($premiumLimit).\n"
          "You cannot add more favorites.";

      actions = [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("OK"),
        ),
      ];
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        actions: actions, // ⭐ DOĞRU YER!
      ),
    );
  }
}
