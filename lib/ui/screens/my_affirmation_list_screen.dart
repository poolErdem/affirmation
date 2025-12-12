import 'dart:math';
import 'package:affirmation/constants/constants.dart';
import 'package:affirmation/l10n/app_localizations.dart';
import 'package:affirmation/models/my_affirmation.dart';
import 'package:affirmation/models/user_preferences.dart';
import 'package:affirmation/ui/screens/home_screen.dart';
import 'package:affirmation/ui/screens/premium_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:affirmation/state/app_state.dart';
import 'package:affirmation/state/my_affirmation_state.dart';
import 'package:affirmation/ui/widgets/shared_blur_background.dart';
import 'package:share_plus/share_plus.dart';
import 'package:affirmation/ui/widgets/my_aff_edit_popup.dart';

class MyAffirmationListScreen extends StatefulWidget {
  const MyAffirmationListScreen({super.key});

  @override
  State<MyAffirmationListScreen> createState() =>
      _MyAffirmationListScreenState();
}

class _MyAffirmationListScreenState extends State<MyAffirmationListScreen> {
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final myState = context.watch<MyAffirmationState>();
    final appState = context.watch<AppState>();

    final items = myState.items.reversed.toList();
    final bg = appState.activeThemeImage;

    final grouped = groupByDate(items);

    return SharedBlurBackground(
      imageAsset: bg,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFFAEE5FF), // 🔵 Serene Blue
          foregroundColor: Colors.black,
          onPressed: _onAddPressed,
          child: const Icon(Icons.add, size: 30),
        ),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leadingWidth: 40,
          leading: Padding(
            padding: const EdgeInsets.only(left: 6),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 22),
              onPressed: () {
                final app = context.read<AppState>();
                app.setActiveCategoryIdOnly(Constants.myCategoryId);

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HomeScreen(
                      initialCategoryId: Constants.myCategoryId,
                    ),
                  ),
                  (route) => false,
                );
              },
            ),
          ),
          title: Text(
            t.myAff,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: NoisePainter(opacity: 0.06),
                ),
              ),
            ),

            SafeArea(
              child: items.isEmpty
                  ? const _EmptyMyAffs()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
                      children: grouped.entries.map((entry) {
                        final dateStr = entry.key;
                        final affList = entry.value;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                dateStr,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            ...affList.map(
                              (aff) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _MyAffRow(
                                  aff: aff,
                                  onEdit: () => _openMyAffPopup(
                                    existingId: aff.id,
                                    existingText: aff.text,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
            ),

            /// ⭐ TEST BUTONU — SAĞ ALT KÖŞE
            Positioned(
              left: 16,
              bottom: 16,
              child: _buildDebugNextDayButton(context),
            ),
          ],
        ),
      ),
    );
  }

  /// test için
  Widget _buildDebugNextDayButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final myAff = context.read<MyAffirmationState>();

        await myAff.simulateNextDay();

        final appState = context.read<AppState>();

        if (!appState.preferences.premiumActive) {
          appState.purchaseState.updatePremium(
            active: true,
            plan: PremiumPlan.monthly,
            expiry: DateTime.now().add(const Duration(days: 30)),
          );
        } else {
          appState.purchaseState.updatePremium(
            active: false,
            plan: PremiumPlan.monthly,
            expiry: DateTime.now().add(const Duration(days: 30)),
          );
        }

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

  void _showMyAffLimitDialog() {
    final t = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t.myAfflimitTitle),
        content: Text(t.myAfflimitMessage),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        actions: [
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
        ],
      ),
    );
  }

  void _onAddPressed() {
    final myState = context.read<MyAffirmationState>();
    final appState = context.read<AppState>();

    final isPremium = appState.preferences.isPremiumValid;
    final count = myState.items.length;

    if (!isPremium && count >= Constants.freeMyAffLimit) {
      _showMyAffLimitDialog();
      return;
    }

    _openMyAffPopup();
  }
}

// EMPTY VIEW
class _EmptyMyAffs extends StatelessWidget {
  const _EmptyMyAffs();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Center(
      child: Text(
        t.noAff,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white70,
        ),
      ),
    );
  }
}

// ROW – PREMIUM EDITION
class _MyAffRow extends StatefulWidget {
  final MyAffirmation aff;
  final VoidCallback onEdit;

  const _MyAffRow({
    required this.aff,
    required this.onEdit,
  });

  @override
  State<_MyAffRow> createState() => _MyAffRowState();
}

class _MyAffRowState extends State<_MyAffRow>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final aff = widget.aff;
    final myState = context.read<MyAffirmationState>();
    final app = context.read<AppState>();

    final dt = DateTime.fromMillisecondsSinceEpoch(aff.createdAt);

    final formatted =
        "${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} "
        "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        app.setActiveCategoryIdOnly(Constants.myCategoryId);

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              initialCategoryId: Constants.myCategoryId,
              initialAffirmationId: aff.id,
            ),
          ),
          (route) => false,
        );
      },
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 1.2,
            ),

            // 🔵 soft-blue glow hover
            boxShadow: _pressed
                ? [
                    BoxShadow(
                      color: const Color(0xFFAEE5FF).withValues(alpha: 0.35),
                      blurRadius: 17,
                      offset: const Offset(0, 6),
                    )
                  ]
                : [],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TEXT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      aff.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.35,
                        fontFamily: "Poppins",
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatted,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Share
              GestureDetector(
                onTap: () => Share.share(aff.text),
                child: const Icon(Icons.ios_share,
                    color: Color(0xFFAEE5FF), size: 22), // 🔵 serene blue
              ),
              const SizedBox(width: 14),

              // EDIT
              GestureDetector(
                onTap: widget.onEdit,
                child: const Icon(
                  Icons.edit,
                  color: Color(0xFFAEE5FF), // 🔵 premium edit
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // DELETE
              GestureDetector(
                onTap: () => myState.remove(aff.id),
                child: Icon(
                  Icons.delete,
                  color: Colors.redAccent.shade100, // pastel delete
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// GROUP BY DATE
Map<String, List<MyAffirmation>> groupByDate(List<MyAffirmation> items) {
  final Map<String, List<MyAffirmation>> groups = {};

  for (var aff in items) {
    final dt = DateTime.fromMillisecondsSinceEpoch(aff.createdAt);
    final key = "${dt.year}-${dt.month}-${dt.day}";
    groups.putIfAbsent(key, () => []);
    groups[key]!.add(aff);
  }
  return groups;
}

// NOISE
class NoisePainter extends CustomPainter {
  final double opacity;
  final Random _rand = Random();

  NoisePainter({this.opacity = 0.04});

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
