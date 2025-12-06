import 'dart:math';
import 'dart:ui';
import 'package:affirmation/models/user_preferences.dart';
import 'package:affirmation/ui/screens/premium_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:affirmation/state/app_state.dart';
import 'package:affirmation/models/theme_model.dart';
import 'package:affirmation/l10n/app_localizations.dart';
import 'package:affirmation/ui/widgets/shared_blur_background.dart';

class ThemeScreen extends StatefulWidget {
  const ThemeScreen({super.key});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  String selectedGroup = "All";

  final groups = ["All", "Light", "Dark", "Colorful", "Abstract"];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final t = AppLocalizations.of(context)!;

    final themes = appState.themes;

    final filteredThemes = selectedGroup == "All"
        ? themes
        : themes.where((th) => th.group == selectedGroup).toList();

    final bg = appState.activeThemeImage;

    return SharedBlurBackground(
      imageAsset: bg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leadingWidth: 32, // 🔥 soldaki boşluğu azaltır
          leading: Padding(
            padding:
                const EdgeInsets.only(left: 6), // 🔥 istediğin kadar kaydır
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 22,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          title: Text(
            t.themes,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
        body: Stack(
          children: [
            // Hafif premium noise efekti
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
                  // Subtitle
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    child: Text(
                      t.themeTitle,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ------------------------------------------------------------
                  // GROUP TABS — cam panel
                  // ------------------------------------------------------------
                  SizedBox(
                    height: 46,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      scrollDirection: Axis.horizontal,
                      itemCount: groups.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) {
                        final g = groups[i];
                        final isSelected = g == selectedGroup;

                        return GestureDetector(
                          onTap: () => setState(() => selectedGroup = g),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 10,
                                  sigmaY: 10,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFFD4AF37)
                                          : Colors.white.withValues(alpha: 0.3),
                                      width: 1.5,
                                    ),
                                    gradient: LinearGradient(
                                      colors: isSelected
                                          ? [
                                              Colors.white
                                                  .withValues(alpha: 0.20),
                                              Colors.white
                                                  .withValues(alpha: 0.05),
                                            ]
                                          : [
                                              Colors.white
                                                  .withValues(alpha: 0.15),
                                              Colors.white
                                                  .withValues(alpha: 0.04),
                                            ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: Text(
                                    g,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isSelected
                                          ? const Color(0xFFD4AF37)
                                          : Colors.white,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 18),

                  // GRID
                  Expanded(child: _buildGrid(filteredThemes, appState)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // GRID BUILDER (cam panel + premium glow + gold seçili tema)
  // ------------------------------------------------------------
  Widget _buildGrid(List<ThemeModel> list, AppState appState) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.70,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemBuilder: (_, index) {
        final item = list[index];
        final isLocked =
            item.isPremiumLocked && !appState.preferences.isPremiumValid;
        final isSelected = item.id == appState.preferences.selectedThemeId;

        return GestureDetector(
          onTap: () {
            if (isLocked) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PremiumScreen()),
              );
              return;
            }

            appState.setSelectedTheme(item.id);
            Navigator.pop(context);
          },
          child: AnimatedScale(
            scale: isSelected ? 1.06 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.18),
                  width: isSelected ? 2.2 : 1.3,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color:
                              const Color(0xFFD4AF37).withValues(alpha: 0.45),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  children: [
                    // FOTO
                    Positioned.fill(
                      child: Image.asset(
                        item.imageAsset,
                        fit: BoxFit.cover,
                      ),
                    ),

                    // Üst + alt koyultma
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0x33000000),
                            Color(0x66000000),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),

                    // KİLİT — premium tarz
                    if (isLocked)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Icon(
                          Icons.lock_outline,
                          color: Colors.white,
                          size: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                    // SEÇİLİ CHECK MARK (premium gold)
                    if (isSelected)
                      const Positioned(
                        top: 8,
                        right: 8,
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),

                    // ALT METİN — grup adı
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          item.group,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 6,
                                color: Colors.black,
                                offset: Offset(0, 2),
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
    );
  }
}

// ------------------------------------------------------------
// NOISE PAINTER — premium hissi için
// ------------------------------------------------------------
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
