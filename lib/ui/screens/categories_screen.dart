import 'dart:math';
import 'package:affirmation/constants/constants.dart';
import 'package:affirmation/models/user_preferences.dart';
import 'package:affirmation/ui/screens/favorites_list_screen.dart';
import 'package:affirmation/ui/screens/my_affirmation_list_screen.dart';
import 'package:affirmation/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:affirmation/state/app_state.dart';
import 'package:affirmation/l10n/app_localizations.dart';
import 'package:affirmation/ui/screens/premium_screen.dart';
import 'package:affirmation/ui/widgets/shared_blur_background.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    if (!appState.isLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final categories = appState.categories;
    final activeId = appState.activeCategoryId;
    final t = AppLocalizations.of(context)!;
    final bg = appState.activeThemeImage;

    return SharedBlurBackground(
      imageAsset: bg,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,

        // ---------------------------------------------------------
        // APPBAR
        // ---------------------------------------------------------
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leadingWidth: 40,
          leading: Padding(
            padding: const EdgeInsets.only(left: 6),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 22,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: Transform.translate(
            offset: const Offset(-8, 0),
            child: Text(
              t.categories,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ),

        // ---------------------------------------------------------
        // BODY
        // ---------------------------------------------------------
        body: Stack(
          children: [
            // Premium noise overlay
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: NoisePainter(opacity: 0.05),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),

                  // Subtitle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Text(
                      t.categoryTitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.80),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ---------------------------------------------------------
                  // GRID
                  // ---------------------------------------------------------
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      itemCount: categories.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 24,
                        crossAxisSpacing: 24,
                        childAspectRatio: 0.78,
                      ),
                      itemBuilder: (_, index) {
                        final category = categories[index];
                        final isSelected = category.id == activeId;
                        final isPremiumLocked = category.isPremiumLocked &&
                            !appState.preferences.isPremiumValid;

                        // ---------------------------------------------------
                        // TAP HANDLER
                        // ---------------------------------------------------
                        return GestureDetector(
                          onTap: () {
                            if (isPremiumLocked) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const PremiumScreen()),
                              );
                              return;
                            }

                            if (category.id == Constants.favoritesCategoryId) {
                              appState.setActiveCategoryIdOnly(
                                  Constants.favoritesCategoryId);
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const FavoritesListScreen()),
                              );
                              return;
                            }

                            if (category.id == Constants.myCategoryId) {
                              appState.setActiveCategoryIdOnly(
                                  Constants.myCategoryId);
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const MyAffirmationListScreen()),
                              );
                              return;
                            }

                            appState.setActiveCategoryIdOnly(category.id);
                            Navigator.pop(context);
                          },

                          // ---------------------------------------------------
                          // CATEGORY CARD
                          // ---------------------------------------------------
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AspectRatio(
                                aspectRatio: 1,
                                child: AnimatedScale(
                                  scale: isSelected ? 1.06 : 1.0,
                                  duration: const Duration(milliseconds: 160),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),

                                      // UPDATED: modern soft-blue border & glow
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFFAEE5FF)
                                            : Colors.white
                                                .withValues(alpha: 0.18),
                                        width: isSelected ? 2.4 : 1.2,
                                      ),

                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFFAEE5FF)
                                                    .withValues(alpha: 0.45),
                                                blurRadius: 18,
                                                spreadRadius: 2,
                                              ),
                                            ]
                                          : [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.15),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Stack(
                                        children: [
                                          // IMAGE
                                          Positioned.fill(
                                            child: Image.asset(
                                              category.imageAsset,
                                              fit: BoxFit.cover,
                                            ),
                                          ),

                                          // Softer gradient overlay
                                          Container(
                                            decoration: const BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Color(0x00000000),
                                                  Color(0x44000000),
                                                ],
                                              ),
                                            ),
                                          ),

                                          // LOCK ICON (updated: serene blue)
                                          if (isPremiumLocked)
                                            const Positioned(
                                              top: 10,
                                              right: 10,
                                              child: Icon(
                                                Icons.lock_outline_rounded,
                                                color: Color(0xFFAEE5FF),
                                                size: 22,
                                              ),
                                            ),

                                          // CHECKMARK (keep white — good contrast)
                                          if (isSelected)
                                            const Positioned(
                                              top: 10,
                                              right: 10,
                                              child: Icon(
                                                Icons.check_circle,
                                                color: Colors.white,
                                                size: 28,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),

                              // CATEGORY TITLE
                              Text(
                                _titleCase(
                                    localizedCategoryName(t, category.id)),
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.95),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _titleCase(String text) {
    if (text.isEmpty) return text;
    return text
        .split(" ")
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(" ");
  }
}

// ---------------------------------------------------------
// NoisePainter
// ---------------------------------------------------------
class NoisePainter extends CustomPainter {
  final double opacity;
  NoisePainter({this.opacity = 0.06});

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random();
    final paint = Paint()..color = Colors.black.withValues(alpha: opacity);

    for (int i = 0; i < size.width * size.height / 80; i++) {
      canvas.drawRect(
        Rect.fromLTWH(
          rnd.nextDouble() * size.width,
          rnd.nextDouble() * size.height,
          1.1,
          1.1,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
