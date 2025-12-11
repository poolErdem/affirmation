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
import 'package:video_player/video_player.dart';

class ThemeScreen extends StatefulWidget {
  const ThemeScreen({super.key});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  String selectedGroup = "All";

  final groups = ["All", "Colorful", "Live", "Dark", "Abstract"];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final t = AppLocalizations.of(context)!;

    final themes = appState.themes;

    final filteredThemes = selectedGroup == "All"
        ? themes
        : themes.where((th) => th.group == selectedGroup).toList();

    final bg = context.select<AppState, String>((s) => s.activeThemeImage);

    return SharedBlurBackground(
      imageAsset: bg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leadingWidth: 32,
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
          title: Text(
            t.themes,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),

        // BODY
        body: Stack(
          children: [
            // Noise layer
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: NoisePainter(opacity: 0.05)),
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
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ----------------------------------------------------
                  // GROUP FILTER TABS (Glass + Soft Blue Accent)
                  // ----------------------------------------------------
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
                                filter:
                                    ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFFAEE5FF)
                                          : Colors.white.withValues(alpha: 0.3),
                                      width: 1.6,
                                    ),
                                    gradient: LinearGradient(
                                      colors: isSelected
                                          ? [
                                              Colors.white
                                                  .withValues(alpha: 0.18),
                                              Colors.white
                                                  .withValues(alpha: 0.05),
                                            ]
                                          : [
                                              Colors.white
                                                  .withValues(alpha: 0.12),
                                              Colors.white
                                                  .withValues(alpha: 0.04),
                                            ],
                                    ),
                                  ),
                                  child: Text(
                                    g,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: isSelected
                                          ? const Color(0xFFAEE5FF)
                                          : Colors.white,
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

                  // THEMES GRID
                  Expanded(child: _buildGrid(filteredThemes, appState)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // THEMES GRID
  // ----------------------------------------------------
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

                // Soft-blue accent border instead of gold
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFAEE5FF)
                      : Colors.white.withValues(alpha: 0.18),
                  width: isSelected ? 2.3 : 1.3,
                ),

                // Soft glow
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color:
                              const Color(0xFFAEE5FF).withValues(alpha: 0.40),
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
                    // Photo / Video preview
                    Positioned.fill(
                      child: item.isVideo
                          ? _VideoPreview(assetPath: item.imageAsset)
                          : Image.asset(item.imageAsset, fit: BoxFit.cover),
                    ),

                    // Softer gradient top-bottom
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

                    // LOCK ICON (soft blue)
                    if (isLocked)
                      const Positioned(
                        top: 8,
                        right: 8,
                        child: Icon(
                          Icons.lock_outline_rounded,
                          color: Color(0xFFAEE5FF),
                          size: 22,
                        ),
                      ),

                    // CHECKMARK (white — good contrast)
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

// -----------------------------------------------------------
// NOISE LAYER
// -----------------------------------------------------------
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

// -----------------------------------------------------------
// VIDEO PREVIEW (loop, muted)
// -----------------------------------------------------------
class _VideoPreview extends StatefulWidget {
  final String assetPath;
  const _VideoPreview({required this.assetPath});

  @override
  State<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.assetPath)
      ..setLooping(true)
      ..setVolume(0)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _controller.play();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller.value.size.width,
              height: _controller.value.size.height,
              child: VideoPlayer(_controller),
            ),
          )
        : Container(color: Colors.black);
  }
}
