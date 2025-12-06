import 'dart:math';
import 'dart:ui';
import 'package:affirmation/constants/constants.dart';
import 'package:affirmation/l10n/app_localizations.dart';
import 'package:affirmation/models/category.dart';
import 'package:affirmation/state/reminder_state.dart';
import 'package:affirmation/ui/screens/premium_screen.dart';
import 'package:affirmation/ui/screens/theme_screen.dart';
import 'package:affirmation/ui/screens/categories_screen.dart';
import 'package:affirmation/ui/screens/settings/settings_screen.dart';
import 'package:affirmation/models/user_preferences.dart';
import 'package:affirmation/state/app_state.dart';
import 'package:affirmation/state/my_affirmation_state.dart';
import 'package:affirmation/ui/widgets/my_aff_edit_popup.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../widgets/affirmation_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _actionAnim;

  late PageController _pageController;
  late PageController _myAffPageController;

  double _shareScale = 1.0;

  final TextEditingController _panelController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final appState = Provider.of<AppState>(context, listen: false);
    final myState = Provider.of<MyAffirmationState>(context, listen: false);

    _pageController = PageController(initialPage: appState.currentIndex);
    _myAffPageController = PageController(initialPage: myState.currentIndex);

    // Playback limit callback
    appState.playback.onLimitReached = () {
      if (!mounted) return;
      _showPlaybackDialog(context);
    };

    myState.playbackMyAff.onLimitReached = () {
      if (!mounted) return;
      _showPlaybackDialog(context);
    };

    // Pending share text
    Future.microtask(() {
      final shareText = appState.pendingShareText;
      if (shareText != null && shareText.isNotEmpty) {
        appState.setPendingShareText(null);
        Share.share(shareText);
      }
    });

    // Auto page sync
    appState.playback.onIndexChanged = (newIndex) {
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          newIndex,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    };

    myState.playbackMyAff.onIndexChanged = (newIndex) {
      if (_myAffPageController.hasClients) {
        _myAffPageController.animateToPage(
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

    _actionAnim.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppState>();
      final myState = context.read<MyAffirmationState>();
      appState.playback.forceStop();
      myState.playbackMyAff.forceStop();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _myAffPageController.dispose();
    _actionAnim.dispose();
    _panelController.dispose();
    super.dispose();
  }

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
          // ⭐ NEW PREMIUM BACKGROUND
          Positioned.fill(
            child: Stack(
              children: [
                Image.asset(
                  backgroundImage,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),

                // Soft dark overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.25),
                        Colors.black.withValues(alpha: 0.45),
                      ],
                    ),
                  ),
                ),

                // Noise
                IgnorePointer(
                  child: CustomPaint(
                    painter: HomeNoisePainter(opacity: 0.04),
                  ),
                ),
              ],
            ),
          ),

          Align(
            alignment: Alignment.center,
            child: _buildAffirmationPager(appState),
          ),

          Positioned(
            right: 16,
            bottom: 92,
            child: _buildMiddleActions(context),
          ),

          Positioned(
            left: 16,
            bottom: 24,
            child: _buildCategoryButton(context),
          ),

          Positioned(
            right: 16,
            bottom: 24,
            child: _buildThemeButton(context),
          ),

          _buildPlayButton(context),

          if (appState.activeCategoryId == Constants.myCategoryId)
            _buildMyAffButtons(),

          _buildTopBar(context, isPremium),
        ],
      ),
    );
  }

  // --- AFFIRMATION PAGER (NO CHANGE) ---
  Widget _buildAffirmationPager(AppState appState) {
    final myState = context.watch<MyAffirmationState>();
    final t = AppLocalizations.of(context)!;

    if (appState.activeCategoryId == Constants.myCategoryId) {
      final items = myState.items;

      if (items.isEmpty) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.52,
          child: Center(
            child: Text(
              t.noAff,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "Poppins",
                fontSize: 16,
                color: Colors.black.withAlpha(140),
              ),
            ),
          ),
        );
      }

      return SizedBox.expand(
        child: PageView.builder(
          key: ValueKey(_myAffPageController),
          controller: _myAffPageController,
          scrollDirection: Axis.vertical,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          itemCount: items.length,
          onPageChanged: (index) {
            myState.setCurrentIndex(index);
            _actionAnim.forward(from: 0);
          },
          itemBuilder: (_, index) {
            final aff = items[index];

            return Center(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.52,
                child: AffirmationCard(
                  key: ValueKey(aff.id),
                  affirmation: null,
                  customText: aff.text,
                  isMine: true,
                ),
              ),
            );
          },
        ),
      );
    }

    final items = appState.currentFeed;

    return SizedBox.expand(
      child: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        itemCount: items.length,
        onPageChanged: (index) {
          final last = items.length - 1;

          if (index == last) {
            // Loop to start
            appState.setCurrentIndex(0);
            Future.microtask(() {
              if (_pageController.hasClients) {
                _pageController.jumpToPage(0);
              }
            });
          } else {
            appState.setCurrentIndex(index);
          }

          _actionAnim.forward(from: 0);
        },
        itemBuilder: (_, index) {
          final aff = items[index];

          return Center(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.52,
              child: AffirmationCard(
                key: ValueKey(aff.id),
                affirmation: aff,
              ),
            ),
          );
        },
      ),
    );
  }

  //────────────────────────────────────────
  // TOP BAR
  //────────────────────────────────────────
  Widget _buildTopBar(BuildContext context, bool isPremium) {
    final reminderState = context.read<ReminderState>();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0x22000000),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0x33FFFFFF),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ⚙️ SETTINGS
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  reminderState.testScheduleSingle();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child:
                      const Icon(Icons.settings, color: Colors.white, size: 24),
                ),
              ),

              // ⭐ PREMIUM BUTTON
              GestureDetector(
                behavior: HitTestBehavior.opaque,
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
                            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isPremium ? null : const Color(0x33000000),
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
  // FAVORITE + SHARE + PLAY + SES +
  //────────────────────────────────────────
  Widget _buildMiddleActions(BuildContext context) {
    final appState = context.watch<AppState>();
    final myAffState = context.watch<MyAffirmationState>();

    final bool isMyCategory =
        appState.activeCategoryId == Constants.myCategoryId;

    // doğru playback
    final playback = isMyCategory
        ? myAffState.playbackMyAff as dynamic
        : appState.playback as dynamic;

    final enabled = playback.volumeEnabled;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 🔊 VOLUME → GLOW VERSION
        GestureDetector(
          onTap: () {
            playback.toggleVolume();
          },
          child: glassButton(
            enabled: enabled, // 🔥 işte bu! Glow aktif/pasif olur
            child: Icon(
              enabled ? Icons.volume_up : Icons.volume_off,
              size: 26,
              color: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ❤️ FAVORITE (same)
        Consumer<AppState>(
          builder: (context, appState, child) {
            final current = appState.affirmationAt(appState.currentIndex);
            final isFav = current != null && appState.isFavorite(current.id);

            return GestureDetector(
              onTap: () {
                final aff = appState.affirmationAt(appState.currentIndex);
                if (aff == null) return;

                final wasFav = appState.isFavorite(aff.id);

                if (!wasFav &&
                    appState.isOverFavoriteLimit() &&
                    !appState.preferences.isPremiumValid) {
                  _showFavoriteLimitDialog(context);
                  return;
                }

                appState.toggleFavorite(aff.id);

                if (!wasFav) _runTripleStarSparkle();
              },
              child: glassButton(
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

        // 📤 SHARE (same but animated)
        GestureDetector(
          onTapDown: (_) => setState(() => _shareScale = 0.85),
          onTapUp: (_) => setState(() => _shareScale = 1.0),
          onTapCancel: () => setState(() => _shareScale = 1.0),
          onTap: () {
            final appState = context.read<AppState>();
            final aff = appState.affirmationAt(appState.currentIndex);
            if (aff == null) return;
            final filtered = aff.renderWithName(appState.userName ?? "");
            Share.share(filtered);
          },
          child: AnimatedScale(
            scale: _shareScale,
            duration: const Duration(milliseconds: 140),
            child: glassButton(
              child: const Icon(Icons.ios_share, size: 26, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayButton(BuildContext context) {
    final appState = context.watch<AppState>();
    final myAffState = context.watch<MyAffirmationState>();

    final bool isMyCategory =
        appState.activeCategoryId == Constants.myCategoryId;

    // doğru playback
    final playback = isMyCategory
        ? myAffState.playbackMyAff as dynamic
        : appState.playback as dynamic;

    final enabled = playback.autoReadEnabled;

    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => playback.toggleAutoRead(),
            child: glassButton(
              enabled: enabled, // 🔥 işte bu! Glow aktif/pasif olur
              child: Icon(
                enabled ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget glowButton({
    required bool active,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? const Color(0x55FF6B6B) : const Color(0x33000000),
          border: Border.all(
            color: active ? Colors.redAccent : const Color(0x44FFFFFF),
            width: 1.8,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.redAccent.withAlpha(120),
                    blurRadius: 22,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildCategoryButton(BuildContext context) {
    final appState = context.watch<AppState>();
    final t = AppLocalizations.of(context)!;

    final selectedCategory = appState.categories.firstWhere(
      (c) => c.id == appState.activeCategoryId,
      orElse: () => AffirmationCategory(
        id: "general",
        name: t.general,
        imageAsset: Constants.generalThemePath,
        isPremiumLocked: false,
      ),
    );

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CategoriesScreen()),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.category,
                    color: Colors.white.withValues(alpha: 0.95), size: 20),
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
        ),
      ),
    );
  }

  Widget _buildThemeButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        //await reminderState.initialize();
        //await reminderState.testScheduleSingle();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ThemeScreen()),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.20),
                width: 1.3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.color_lens,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMyAffButtons() {
    return Positioned(
      bottom: 106,
      left: 0,
      right: 270,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // EDIT
          _iconButton(
            icon: Icons.edit,
            onTap: () {
              final myState = context.read<MyAffirmationState>();

              final index = _myAffPageController.page?.round() ?? 0;

              if (index < 0 || index >= myState.items.length) return;

              final aff = myState.items[index];

              _openMyAffPopup(
                existingId: aff.id,
                existingText: aff.text,
              );
            },
          ),

          const SizedBox(width: 12),

          // ADD
          _iconButton(
            icon: Icons.add,
            onTap: () {
              _openMyAffPopup();
            },
          ),
        ],
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      child: Padding(
        padding: const EdgeInsets.all(6.0), // küçük tıklama alanı
        child: Icon(
          icon,
          size: 24,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget glassButton({
    required Widget child,
    bool enabled = false,
    EdgeInsets padding = const EdgeInsets.all(10),
    double blur = 14,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            shape: BoxShape.circle,
            border: Border.all(
              color: enabled
                  ? Colors.redAccent.withValues(alpha: 0.60)
                  : Colors.white.withValues(alpha: 0.20),
              width: 1.3,
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: Colors.redAccent.withValues(alpha: 0.50),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.20),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: child,
        ),
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
            decoration: const BoxDecoration(
              color: Color(0x3323C552),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF23C552), size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 15),
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
          children: const [
            Icon(Icons.workspace_premium, color: Colors.amber, size: 28),
            SizedBox(width: 10),
            Text(
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

  //────────────────────────────────────────
  // FAVORITES ve MY AFFS LIMIT DIALOG
  //────────────────────────────────────────
  void _showFavoriteLimitDialog(BuildContext context) {
    final appState = context.read<AppState>();
    final isPremium = appState.preferences.isPremiumValid;
    final t = AppLocalizations.of(context)!;

    if (isPremium) {
      // Premium kullanıcıya limit uyarısı göstermeyiz :)
      return;
    }

    // Buraya gelen her kullanıcı premium değil → değişkenler garanti dolacak
    final title = t.favoritesLimitTitle;
    final message = t.favoritesLimitMessage;

    final actions = [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(t.close),
      ),
      TextButton(
        onPressed: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PremiumScreen()),
          );
        },
        child: Text(t.goPremium),
      ),
    ];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        actions: actions,
      ),
    );
  }

  //────────────────────────────────────────
  // PLAYBACK LIMIT DIALOG
  //────────────────────────────────────────
  void _showPlaybackDialog(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    String title = t.readLimit;
    String message = t.voiceLimitMessage;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        actions: [
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
          right: MediaQuery.of(context).size.width * 0.30 - dx,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 1, end: 0),
            duration: const Duration(milliseconds: 600),
            builder: (_, value, __) {
              return Transform.scale(
                scale: 1 + (1 - value) * size,
                child: const Icon(
                  Icons.star,
                  color: Color.fromARGB(255, 239, 205, 91),
                  size: 28,
                ),
              );
            },
          ),
        ),
      );

      overlay.insert(entry);
      await Future.delayed(const Duration(milliseconds: 620));
      entry.remove();
    }

    showStar(45, 110, 0.4);

    await Future.delayed(const Duration(milliseconds: 90));
    showStar(25, 75, 0.5);

    await Future.delayed(const Duration(milliseconds: 90));
    showStar(13, 35, 0.6);

    await Future.delayed(const Duration(milliseconds: 90));
    showStar(8, -10, 0.6);
  }

  void _openMyAffPopup({String? existingId, String? existingText}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return MyAffEditPopup(
          editingId: existingId,
          initialText: existingText,
        );
      },
    );
  }
}

class HomeNoisePainter extends CustomPainter {
  final double opacity;
  final Random _rand = Random();

  HomeNoisePainter({this.opacity = 0.04});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: opacity);

    for (int i = 0; i < size.width * size.height / 120; i++) {
      final dx = _rand.nextDouble() * size.width;
      final dy = _rand.nextDouble() * size.height;
      canvas.drawRect(Rect.fromLTWH(dx, dy, 1, 1), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
