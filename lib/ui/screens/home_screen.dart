import 'dart:math';
import 'dart:ui';
import 'package:affirmation/constants/constants.dart';
import 'package:affirmation/l10n/app_localizations.dart';
import 'package:affirmation/models/affirmation.dart';
import 'package:affirmation/models/category.dart';
import 'package:affirmation/models/my_affirmation.dart';
import 'package:affirmation/ui/screens/premium_screen.dart';
import 'package:affirmation/ui/screens/theme_screen.dart';
import 'package:affirmation/ui/screens/categories_screen.dart';
import 'package:affirmation/ui/screens/settings/settings_screen.dart';
import 'package:affirmation/models/user_preferences.dart';
import 'package:affirmation/state/app_state.dart';
import 'package:affirmation/state/my_affirmation_state.dart';
import 'package:affirmation/ui/widgets/video_bg.dart';
import 'package:affirmation/utils/utils.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../widgets/affirmation_card.dart';

class HomeScreen extends StatefulWidget {
  final String? initialCategoryId;
  final String? initialAffirmationId;

  const HomeScreen({
    super.key,
    this.initialCategoryId,
    this.initialAffirmationId,
  });

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

  late AppState appState;
  late MyAffirmationState myState;

  @override
  void initState() {
    super.initState();

    appState = Provider.of<AppState>(context, listen: false);
    myState = Provider.of<MyAffirmationState>(context, listen: false);

    _pageController = PageController(initialPage: appState.currentIndex);
    _myAffPageController = PageController(initialPage: myState.currentIndex);

    // ⭐ FAVORİDEN GELİYORSA jump yap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialId = widget.initialAffirmationId;
      if (initialId == null) return;

      final app = context.read<AppState>();
      final my = context.read<MyAffirmationState>();

      final active = app.activeCategoryId;

      // ---- FEEDİ OLUŞTUR ----
      late final List<Affirmation> feed;

      if (active == Constants.favoritesCategoryId) {
        feed = app.favoritesFeed; // Affirmation list
      } else if (active == Constants.myCategoryId) {
        feed = my.items.map((m) => m.toAffirmation()).toList();
      } else {
        return; // diğer kategorilerde jump yok
      }

      // ---- INDEX BUL ----
      final index = feed.indexWhere((a) => a.id == initialId);
      print("Jump index → $index / id=$initialId / category=$active");

      if (index != -1 && _myAffPageController.hasClients) {
        _myAffPageController.jumpToPage(index);
      }
    });

    // ⭐ Playback limit
    appState.playback.onLimitReached = () {
      if (!mounted) return;
      _showPlaybackDialog(context);
    };

    // ⭐ Pending share
    Future.microtask(() {
      final shareText = appState.pendingShareText;
      if (shareText != null && shareText.isNotEmpty) {
        appState.setPendingShareText(null);
        Share.share(shareText);
      }
    });

    appState.playback.onIndexChanged = (newIndex) {
      if (!mounted) return;

      if (_pageController.hasClients) {
        _pageController.jumpToPage(
          newIndex,
        );
      }
    };

    _actionAnim = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    )..forward();

    // Başlangıçta playback'i durdur
    WidgetsBinding.instance.addPostFrameCallback((_) {
      appState.playback.forceStop();
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
    // ⭐ Sadece isLoaded'ı izle
    final isLoaded = context.select<AppState, bool>((s) => s.isLoaded);
    final isLoaded2 =
        context.select<MyAffirmationState, bool>((s) => s.isLoaded);

    if (!isLoaded && isLoaded2) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final appState = context.read<AppState>();
    final myState = context.read<MyAffirmationState>();

    final isPremium = appState.preferences.isPremiumValid;
    final backgroundImage = appState.activeThemeImage;
    final isVideo = backgroundImage.toLowerCase().endsWith(".mp4");

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ⭐ NEW PREMIUM BACKGROUND

          Positioned.fill(
            child: Stack(
              children: [
                // ⭐ BACKGROUND (video veya image)
                isVideo
                    ? VideoBg(assetPath: backgroundImage)
                    : Image.asset(
                        backgroundImage,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),

                // ⭐ Soft dark overlay
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

                // ⭐ Noise overlay
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
            child: _buildAffirmationPager(appState, myState),
          ),

          Positioned(
            right: 16,
            bottom: 80,
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

          Positioned(
            right: 100,
            bottom: 24,
            child: _buildDebugNextDayButton(context),
          ),

          Builder(
            builder: (context) {
              final isMyCategory = context.select<AppState, bool>(
                (s) =>
                    s.activeCategoryId != Constants.myCategoryId &&
                    s.activeCategoryId != Constants.favoritesCategoryId,
              );
              return isMyCategory
                  ? _buildPlayButton(context)
                  : const SizedBox.shrink();
            },
          ),

          _buildTopBar(context, isPremium),
        ],
      ),
    );
  }

  // --- AFFIRMATION PAGER (NO CHANGE) ---
  Widget _buildAffirmationPager(AppState appState, MyAffirmationState myState) {
    final t = AppLocalizations.of(context)!;

    final isMy = appState.activeCategoryId == Constants.myCategoryId;
    final isFav = appState.activeCategoryId == Constants.favoritesCategoryId;

    // ───────────────────────────────────────────
    // 1) MY AFFIRMATIONS → MyAffirmation → Affirmation'a dönüştür
    // ───────────────────────────────────────────
    if (isMy || isFav) {
      final List<Affirmation> items = isMy
          ? myState.items.map((m) => m.toAffirmation()).toList()
          : appState.favoritesFeed; // zaten Affirmation

      if (items.isEmpty) {
        final emptyText = isMy ? t.noAff : t.favoritesEmpty;

        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.52,
          child: Center(
            child: Text(
              emptyText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "Poppins",
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
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
            physics: const FastPagePhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            itemCount: items.length,
            onPageChanged: (index) {
              print("currentIndex: $index");
              print("item: ${items[index].text}");

              if (isMy) {
                myState.setCurrentIndex(index);
              } else {
                appState.setCurrentIndex(index);
              }

              _actionAnim.forward(from: 0);
            },
            itemBuilder: (_, index) {
              final aff = items[index];
              final app = context.watch<AppState>();

              // İlk açılışta pozisyonu yükle
              WidgetsBinding.instance.addPostFrameCallback((_) {
                app.loadAffirmationPosition(aff.id);
              });

              return Center(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.52,
                  child: Stack(
                    children: [
                      // 🔹 SADECE ARKA PLAN KARTI (yazı olmadan)
                      AffirmationCard(
                        key: ValueKey(aff.id),
                        affirmation: aff,
                        isMine: isMy,
                        showText:
                            false, // ⭐ AffirmationCard'a bu parametreyi ekleyin
                      ),

                      // 🔹 SÜRÜKLENEBİLİR YAZI
                      Positioned(
                        left: app.getAffirmationPosition(aff.id).dx,
                        top: app.getAffirmationPosition(aff.id).dy,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            final currentPos =
                                app.getAffirmationPosition(aff.id);
                            final newX = currentPos.dx + details.delta.dx;
                            final newY = currentPos.dy + details.delta.dy;
                            app.saveAffirmationPosition(aff.id, newX, newY);
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width - 48,
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              aff.text,
                              textAlign: TextAlign.center,
                              style: AffirmationCard.provideTextStyle(
                                  context), // static yapın
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
      );
    }

    // ───────────────────────────────────────────
    // 2) DİĞER TÜM KATEGORİLER (Normal Affirmation feed)
    // ───────────────────────────────────────────
    final items = appState.currentFeed;

    return SizedBox.expand(
      child: PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          physics: const FastPagePhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          itemCount: items.length,
          onPageChanged: (index) {
            final last = items.length - 1;

            if (index == last) {
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
          // Widget tarafında:
          itemBuilder: (_, index) {
            final aff = items[index];
            final app = context.watch<AppState>();

            // İlk açılışta pozisyonu yükle
            WidgetsBinding.instance.addPostFrameCallback((_) {
              app.loadAffirmationPosition(aff.id);
            });

            return Center(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.52,
                child: Stack(
                  children: [
                    // 🔹 SADECE ARKA PLAN KARTI (yazı olmadan)
                    AffirmationCard(
                      key: ValueKey(aff.id),
                      affirmation: aff,
                      isMine: false,
                      showText:
                          false, // ⭐ AffirmationCard'a bu parametreyi ekleyin
                    ),

                    // 🔹 SÜRÜKLENEBİLİR YAZI
                    Positioned(
                      left: app.getAffirmationPosition(aff.id).dx,
                      top: app.getAffirmationPosition(aff.id).dy,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          final currentPos = app.getAffirmationPosition(aff.id);
                          final newX = currentPos.dx + details.delta.dx;
                          final newY = currentPos.dy + details.delta.dy;
                          app.saveAffirmationPosition(aff.id, newX, newY);
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width - 48,
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            aff.text,
                            textAlign: TextAlign.center,
                            style: AffirmationCard.provideTextStyle(
                                context), // static yapın
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
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
                  //reminderState.testScheduleSingle();
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

  // FAVORITE + SHARE + PLAY + SES +
  Widget _buildMiddleActions(BuildContext context) {
    final appState = context.read<AppState>();
    final currentIndex = context.select<AppState, int>((s) => s.currentIndex);

    final activeCategory =
        context.select<AppState, String>((s) => s.activeCategoryId);

    final currentAff = appState.affirmationAt(currentIndex);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ⭐ TEK IF — iki buton birden kontrol ediyor
        if (activeCategory != Constants.myCategoryId &&
            activeCategory != Constants.favoritesCategoryId) ...[
          Builder(
            builder: (context) {
              final isFav = currentAff != null &&
                  context.select<AppState, bool>(
                    (s) => s.isFavorite(currentAff.id),
                  );

              return GestureDetector(
                onTap: () {
                  if (currentAff == null) return;

                  final wasFav = appState.isFavorite(currentAff.id);

                  if (!wasFav &&
                      appState.isOverFavoriteLimit() &&
                      !appState.preferences.isPremiumValid) {
                    _showFavoriteLimitDialog(context);
                    return;
                  }

                  appState.toggleFavorite(currentAff.id);
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
          const SizedBox(height: 5),

          // 📤 SHARE (herkeste görünür)
          GestureDetector(
            onTapDown: (_) => setState(() => _shareScale = 0.85),
            onTapUp: (_) => setState(() => _shareScale = 1.0),
            onTapCancel: () => setState(() => _shareScale = 1.0),
            onTap: () {
              if (currentAff == null) return;
              final filtered =
                  currentAff.renderWithName(appState.userName ?? "");
              Share.share(filtered);
            },
            child: AnimatedScale(
              scale: _shareScale,
              duration: const Duration(milliseconds: 140),
              child: glassButton(
                child:
                    const Icon(Icons.ios_share, size: 26, color: Colors.white),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPlayButton(BuildContext context) {
    final appState = context.read<AppState>();
    final enabled = appState.playback.autoReadEnabled;
    final volumeEnabled = appState.playback.volumeEnabled; // varsa zaten var

    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ▶️ PLAY / PAUSE BUTTON
          GestureDetector(
            onTap: () => appState.playback.toggleAutoRead(),
            child: glassButton(
              enabled: enabled,
              child: Icon(
                enabled ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),

          const SizedBox(width: 10),

          // 🔊 VOLUME BUTTON
          GestureDetector(
            onTap: () => appState.playback.toggleVolume(),
            child: glassButton(
              enabled: volumeEnabled,
              child: Icon(
                volumeEnabled ? Icons.volume_up : Icons.volume_off,
                size: 26,
                color: Colors.white,
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
    // ⭐ Sadece activeCategoryId ve categories'i izle
    final activeCategoryId =
        context.select<AppState, String>((s) => s.activeCategoryId);
    final categories = context
        .select<AppState, List<AffirmationCategory>>((s) => s.categories);

    final t = AppLocalizations.of(context)!;

    final selectedCategory = categories.firstWhere(
      (c) => c.id == activeCategoryId,
      orElse: () => AffirmationCategory(
        id: "general",
        name: t.general,
        imageAsset: Constants.generalThemePath,
        isPremiumLocked: false,
      ),
    );

    final categoryName = localizedCategoryName(t, selectedCategory.id);

    return Transform.scale(
      scale: 0.9, // 🔥 glassButton ile aynı küçültme
      child: GestureDetector(
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
                  Icon(
                    Icons.category,
                    color: Colors.white.withValues(alpha: 0.95),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    categoryName,
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
      ),
    );
  }

  Widget _buildThemeButton(BuildContext context) {
    return Transform.scale(
      scale: 0.87, // 🔥 glassButton ile aynı küçültme
      child: GestureDetector(
        onTap: () async {
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
      ),
    );
  }

  Widget _buildDirectionButton(BuildContext context) {
    return Transform.scale(
      scale: 0.87, // 🔥 glassButton ile aynı küçültme
      child: GestureDetector(
        onTap: () async {
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
                Icons.directions_car,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
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
    return Transform.scale(
      scale: 0.87, // 🔥 %20 küçültme
      child: ClipRRect(
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
      ),
    );
  }

  // PREMIUM STATUS DIALOG
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

  /// test için
  Widget _buildDebugNextDayButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final myAff = context.read<MyAffirmationState>();

        await myAff.simulateNextDay();

        print(
            "🔥 simulateNextDay çağrıldı → Yeni challengeDay: ${myAff.todayChallengeDay}");
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          "Next Day",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
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

class FastPagePhysics extends BouncingScrollPhysics {
  const FastPagePhysics({super.parent});

  @override
  double get dragStartDistanceMotionThreshold => 3.5;

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    return offset * 1.35; // kaydırma hızını %35 artırır
  }
}
