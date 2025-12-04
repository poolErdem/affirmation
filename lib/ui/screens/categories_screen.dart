import 'dart:math';
import 'package:affirmation/constants/constants.dart';
import 'package:affirmation/models/user_preferences.dart';
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
    final categories = appState.categories;
    final activeId = appState.activeCategoryId;
    final t = AppLocalizations.of(context)!;
    final bg = appState.activeThemeImage;

    return SharedBlurBackground(
      imageAsset: bg,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,

        // ------------------------------------------------------------
        // APPBAR (şeffaf)
        // ------------------------------------------------------------
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black,
              size: 26,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Transform.translate(
            offset: const Offset(-8, 0),
            child: Text(
              t.categories,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
          ),
        ),

        // ------------------------------------------------------------
        // BODY → PREMIUM BACKDROP + NOISE
        // ------------------------------------------------------------
        body: Stack(
          children: [
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
                      "✨ ${t.categoryTitle}",
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.black.withAlpha(140),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ------------------------------------------------------------
                  // GRID (premium style)
                  // ------------------------------------------------------------
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
                        mainAxisSpacing: 18,
                        crossAxisSpacing: 18,
                        childAspectRatio: 0.78,
                      ),
                      itemBuilder: (_, index) {
                        final category = categories[index];

                        final isSelected = category.id == activeId;
                        final isPremiumLocked = category.isPremiumLocked &&
                            !appState.preferences.isPremiumValid;

                        return GestureDetector(
                          onTap: () {
                            if (isPremiumLocked) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PremiumScreen(),
                                ),
                              );
                              return;
                            }

                            appState.setActiveCategoryIdOnly(category.id);
                            Navigator.pop(context);
                          },
                          child: AnimatedScale(
                            scale: isSelected ? 1.06 : 1.0,
                            duration: const Duration(milliseconds: 160),
                            curve: Curves.easeOut,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFD4AF37)
                                      : Colors.white.withValues(alpha: 0.18),
                                  width: isSelected ? 2.2 : 1.2,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFFD4AF37)
                                              .withValues(
                                            alpha: 0.45,
                                          ),
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

                                    // Gradient overlay
                                    Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Color(0x00000000),
                                            Color(0x66000000),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // LOCK icon (premium style)
                                    if (isPremiumLocked)
                                      const Positioned(
                                        top: 10,
                                        right: 10,
                                        child: Icon(
                                          Icons.lock_outline,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ),

                                    // LIMITED badge
                                    if ((category.id ==
                                                Constants.generalCategoryId ||
                                            category.id ==
                                                Constants.favoritesCategoryId ||
                                            category.id ==
                                                Constants.myCategoryId ||
                                            category.id == "self_care") &&
                                        !appState.preferences.isPremiumValid)
                                      Positioned(
                                        top: 10,
                                        left: 10,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade700,
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          child: Text(
                                            t.limited,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),

                                    // CATEGORY NAME
                                    Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                            bottom: 12, left: 8, right: 8),
                                        child: Text(
                                          _titleCase(
                                            localizedCategoryName(
                                                t, category.id),
                                          ),
                                          maxLines: 2,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            shadows: [
                                              Shadow(
                                                blurRadius: 12,
                                                color: Colors.black,
                                                offset: Offset(0, 3),
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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

/// NoisePainter — premium glossy efekt için
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
