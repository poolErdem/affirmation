import 'package:affirmation/constants/constants.dart';
import 'package:affirmation/models/category.dart';
import 'package:affirmation/state/reminder_state.dart';
import 'package:affirmation/ui/screens/premium_screen.dart';
import 'package:affirmation/ui/screens/theme_screen.dart';
import 'package:affirmation/ui/screens/categories_screen.dart';
import 'package:affirmation/ui/screens/settings/settings_screen.dart';
import 'package:affirmation/models/user_preferences.dart';
import 'package:affirmation/state/app_state.dart';
import 'package:affirmation/state/my_affirmation_state.dart';

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
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;
  late PageController _pageController;

  bool _editing = false; // <-- BURADA OLMALI
  String? _editingId; // <-- BURADA OLMALI
  double _shareScale = 1.0;

  bool _panelVisible = false;
  final TextEditingController _panelController = TextEditingController();

// 🔥 YENİ: MyAffirmations için ayrı bir PageController
  PageController? _myAffPageController;

  @override
  void initState() {
    super.initState();

    _myAffPageController = PageController();

    final appState = Provider.of<AppState>(context, listen: false);
    final myState = Provider.of<MyAffirmationState>(context, listen: false);

    _pageController = PageController(initialPage: appState.currentIndex);

    // Playback limit callback
    appState.playback.onLimitReached = () {
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

    // 🔥 Auto page sync (LOOP KIRICI FLAG ile)
    appState.playback.onIndexChanged = (newIndex) {
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          newIndex,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    };

    myState.playback.onIndexChanged = (newIndex) {
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

    _slideAnim = Tween(begin: const Offset(0, -0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _actionAnim, curve: Curves.easeOut));

    _fadeAnim = CurvedAnimation(parent: _actionAnim, curve: Curves.easeInOut);

    _actionAnim.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppState>();
      final myState = context.read<MyAffirmationState>();

      appState.playback.forceStop();
      myState.playback.forceStop();
    });
  }

  @override
  void dispose() {
    _myAffPageController?.dispose();
    _pageController.dispose();
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
          // Background
          Image.asset(
            backgroundImage,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          Container(color: const Color(0x55000000)),

          _buildTopBar(context, isPremium),

          Align(
            alignment: Alignment.center,
            child: _buildAffirmationPager(appState),
          ),

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

          // 🔥 My Affirmations → Show ADD & EDIT buttons
          if (appState.activeCategoryId == Constants.myCategoryId)
            _buildMyAffButtons(),

          // 🔥 Bottom panel
          _buildMyPanel(context),
        ],
      ),
    );
  }

// --------------------------------------------------------------
// AFFIRMATION PAGER  (Custom affirmations destekli)

  Widget _buildAffirmationPager(AppState appState) {
    final myState = context.watch<MyAffirmationState>();

    // -------------------------------------------------------------
    // MY AFFIRMATIONS (User custom feed)
    // -------------------------------------------------------------
    if (appState.activeCategoryId == Constants.myCategoryId) {
      final items = myState.items;

      if (items.isEmpty) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.52,
          child: Center(
            child: Text(
              "No affirmations yet\nCreate your first one! ✨",
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

      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.52,
        child: PageView.builder(
          key: ValueKey(_myAffPageController), // 🔥 Controller değişince reset
          controller: _myAffPageController,
          scrollDirection: Axis.vertical,
          itemCount: items.length,
          onPageChanged: (index) {
            final last = items.length - 1;

            if (index == last) {
              myState.setCurrentIndex(0);
              Future.microtask(() {
                if (_pageController.hasClients) {
                  _pageController.jumpToPage(0);
                }
              });
            } else {
              myState.setCurrentIndex(index);
            }
            _actionAnim.forward(from: 0);
          },
          itemBuilder: (_, index) {
            final aff = items[index];
            return Center(
              child: AffirmationCard(
                key: ValueKey(aff.id),
                affirmation: null,
                customText: aff.text,
                isMine: true,
              ),
            );
          },
        ),
      );
    }

    // -------------------------------------------------------------
    // NORMAL (JSON) FEED
    // -------------------------------------------------------------
    final items = appState.currentFeed;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.52,
      child: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
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
        itemBuilder: (_, index) {
          final aff = items[index];
          return Center(
            child: AffirmationCard(
              key: ValueKey(aff.id),
              affirmation: aff,
            ),
          );
        },
      ),
    );
  }

// MY AFFIRMATION PANEL (ADD + EDIT)
// -------------------------------------------------------------------
  Widget _buildMyPanel(BuildContext context) {
    final myAffState = context.read<MyAffirmationState>();

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      left: 0,
      right: 0,
      bottom: _panelVisible ? 0 : -MediaQuery.of(context).size.height * 0.35,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0D0D0D),
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          border: Border(
            top: BorderSide(
              color: Color(0x44FFFFFF),
              width: 1.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 30,
              spreadRadius: 5,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          bottom: true,
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // DRAG HANDLE
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0x55FFFFFF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),

                const SizedBox(height: 20),

                // TITLE
                Text(
                  _editing ? "Edit Affirmation" : "New Affirmation",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 16),

                // INPUT FIELD
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0x22FFFFFF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0x33FFFFFF),
                      width: 1,
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _panelController,
                    maxLines: 3,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.4,
                    ),
                    decoration: const InputDecoration(
                      hintText: "Write your affirmation…",
                      hintStyle: TextStyle(
                        color: Color(0x66FFFFFF),
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // BUTTONS ROW
                Row(
                  children: [
                    // DELETE BUTTON (only when editing)
                    if (_editing) ...[
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            if (_editingId != null) {
                              final myState =
                                  context.read<MyAffirmationState>();
                              final currentIndex =
                                  _myAffPageController?.page?.round() ?? 0;

                              await myAffState.remove(_editingId!);

                              _panelController.clear();
                              if (!mounted) return;

                              setState(() {
                                _editing = false;
                                _editingId = null;
                                _panelVisible = false;
                              });

                              await Future.delayed(
                                  const Duration(milliseconds: 100));
                              if (!mounted) return;

                              if (myState.items.isNotEmpty &&
                                  _myAffPageController != null) {
                                if (_myAffPageController!.hasClients) {
                                  final newIndex =
                                      currentIndex >= myState.items.length
                                          ? myState.items.length - 1
                                          : currentIndex;

                                  _myAffPageController!.jumpToPage(newIndex);
                                }
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0x22FF4444),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0x66FF4444),
                                width: 1.5,
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Delete",
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],

                    // SAVE BUTTON
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final text = _panelController.text.trim();
                          if (text.isEmpty) return;

                          final scaffoldContext = context;
                          final wasEditing = _editing;

                          if (!wasEditing) {
                            final isOver = await myAffState.isOverLimit();

                            if (!mounted) return;
                            if (isOver) {
                              _showMyAffLimitDialog(scaffoldContext);
                              return;
                            }
                          }

                          if (wasEditing) {
                            if (_editingId != null) {
                              await myAffState.update(_editingId!, text);
                            }
                          } else {
                            await myAffState.add(text);
                          }

                          _panelController.clear();
                          if (!mounted) return;

                          setState(() {
                            _editing = false;
                            _editingId = null;
                            _panelVisible = false;
                          });

                          if (!wasEditing) {
                            await Future.delayed(
                                const Duration(milliseconds: 100));
                            if (!mounted) return;

                            final myState = context.read<MyAffirmationState>();
                            if (myState.items.isNotEmpty &&
                                _myAffPageController != null) {
                              if (_myAffPageController!.hasClients) {
                                await _myAffPageController!.animateToPage(
                                  myState.items.length - 1,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                );
                              }
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF4A4A4A),
                                Color(0xFF2A2A2A),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0x55FFFFFF),
                              width: 1.5,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x22FFFFFF),
                                blurRadius: 8,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _editing ? "Update" : "Save",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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

    // 🔥 Doğru playback seç
    final playback = isMyCategory
        ? myAffState.playback as dynamic
        : appState.playback as dynamic;

    final enabled = playback.volumeEnabled; // ✔ Çalışır
    print("ses enabled $enabled");

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            print("tiklandi, enable durumu $enabled");
            playback.toggleVolume();
          }, // ✔ Çalışır
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:
                  enabled ? const Color(0x55FF6B6B) : const Color(0x33000000),
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
        ),

        const SizedBox(height: 16),

        // ❤️ FAVORITE
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

                if (!wasFav) _runTripleStarSparkle();
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

        // 📤 SHARE
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

  Widget _buildPlayButton(BuildContext context) {
    final appState = context.watch<AppState>();
    final myAffState = context.watch<MyAffirmationState>();

    final bool isMyCategory =
        appState.activeCategoryId == Constants.myCategoryId;

    //final double? right = isMyCategory ? null : 10;

    // 🔥 Doğru playback seç
    final playback = isMyCategory
        ? myAffState.playback as dynamic
        : appState.playback as dynamic;

    final enabled = playback.autoReadEnabled; // ✔ Çalışır

    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 🔊 PLAY BUTTON (AUTO-TTS)
          GestureDetector(
            onTap: () => playback.toggleAutoRead(), // ✔ Çalışır
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    enabled ? const Color(0x55FF6B6B) : const Color(0x33000000),
                shape: BoxShape.circle,
                border: Border.all(
                  color: enabled ? Colors.redAccent : const Color(0x44FFFFFF),
                  width: 1.5,
                ),
              ),
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
        //reminderState.debugCreateSampleReminder();
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

  Widget _buildThemeButton(BuildContext context) {
    final reminderState = context.read<ReminderState>();

    return InkWell(
      onTap: () {
        reminderState.debugScheduleImmediateNotification();
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

  Widget _buildMyAffButtons() {
    return Positioned(
      bottom: 100,
      left: 0,
      right: 250,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // EDIT
          _circleButton(
            icon: Icons.edit,
            onTap: () {
              final myState = context.read<MyAffirmationState>();

              // 🔥 AKTİF SAYFA INDEX'İ (MY AFFIRMATIONS PageView)
              final index = _myAffPageController?.page?.round() ?? 0;

              if (index < 0 || index >= myState.items.length) return;

              final aff = myState.items[index];

              _editing = true;
              _editingId = aff.id;
              _panelController.text = aff.text;

              setState(() => _panelVisible = true);
            },
          ),

          const SizedBox(width: 18),

          // ADD
          _circleButton(
            icon: Icons.add,
            onTap: () {
              _editing = false;
              _editingId = null;
              _panelController.clear();
              setState(() => _panelVisible = true);
            },
          ),
        ],
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0x44000000),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0x33FFFFFF), width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: 26),
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
    final freeLimit = Constants.freeFavoriteLimit;
    final premiumLimit = Constants.premiumFavoriteLimit;

    String title;
    String message;
    List<Widget> actions;

    if (!isPremium) {
      title = "Favorites Limit";
      message =
          "You've reached your free favorites limit ($freeLimit).\n\nUpgrade to Premium and save up to $premiumLimit favorites ✨";

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
      title = "Premium Limit Reached";
      message =
          "You've reached your Premium favorites limit ($premiumLimit). You cannot add more favorites.";

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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        actions: actions,
      ),
    );
  }

  void _showMyAffLimitDialog(BuildContext context) {
    final appState = context.read<AppState>();
    final isPremium = appState.preferences.isPremiumValid;

    final freeLimit = Constants.freeMyAffLimit;
    final premiumLimit = Constants.premiumMyAffLimit;

    String title;
    String message;
    List<Widget> actions;

    if (!isPremium) {
      title = "My Affirmations Limit";
      message =
          "You've reached your free limit ($freeLimit).\n\nUpgrade to Premium and save up to $premiumLimit custom affirmations ✨";

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
      title = "Premium Limit Reached";
      message =
          "You've reached your Premium limit ($premiumLimit). You cannot add more custom affirmations.";

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
    String title = "Read Limit";
    String message =
        "Your free voice preview is finished. Go Premium to enjoy full, unlimited voice reading.✨";

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
                  color: Color.fromARGB(255, 201, 174, 92),
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

    showStar(50, 0, 0.4);

    await Future.delayed(const Duration(milliseconds: 90));
    showStar(25, -25, 0.5);

    await Future.delayed(const Duration(milliseconds: 90));
    showStar(15, -65, 0.6);

    await Future.delayed(const Duration(milliseconds: 90));
    showStar(8, -115, 0.6);
  }
}
