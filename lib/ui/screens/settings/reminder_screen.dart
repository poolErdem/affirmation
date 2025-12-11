import 'dart:math';
import 'dart:ui';

import 'package:affirmation/constants/constants.dart';
import 'package:affirmation/l10n/app_localizations.dart';
import 'package:affirmation/models/reminder.dart';
import 'package:affirmation/state/app_state.dart';
import 'package:affirmation/state/reminder_state.dart';
import 'package:affirmation/ui/screens/premium_screen.dart';
import 'package:affirmation/ui/screens/settings/reminder_edit_screen.dart';
import 'package:affirmation/ui/widgets/shared_blur_background.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class ReminderListScreen extends StatefulWidget {
  const ReminderListScreen({super.key});

  @override
  State<ReminderListScreen> createState() => _ReminderListScreenState();
}

class _ReminderListScreenState extends State<ReminderListScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fade;

  // 4 general/preset slot
  static const int _slotCount = 4;

  // Edit ekranından gelen, henüz aktif edilmemiş (enable edilmemiş) taslaklar
  final Map<int, ReminderModel> _drafts = {};

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  String _slotId(int index) => 'slot_${index + 1}';

  ReminderModel _defaultTemplate(int index, bool isPremium) {
    const start = TimeOfDay(hour: 10, minute: 0);
    const end = TimeOfDay(hour: 14, minute: 0);

    return ReminderModel(
      id: _slotId(index),
      categoryIds: {Constants.generalCategoryId},
      startTime: start,
      endTime: end,
      repeatCount: 3,
      repeatDays: {1, 3, 5}, // Mon, Wed, Fri
      enabled: false,
      isPremium: isPremium,
    );
  }

  ReminderModel? _findActiveForSlot(List<ReminderModel> list, int slotIndex) {
    final id = _slotId(slotIndex);
    for (final r in list) {
      if (r.id == id) return r;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final reminderState = context.watch<ReminderState>();
    final appState = context.watch<AppState>();
    final isPremium = appState.preferences.premiumActive;
    final t = AppLocalizations.of(context)!;
    final reminders = reminderState.reminders;
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
            t.reminders,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        body: Stack(
          children: [
            // Noise overlay (blur arka plan üstüne film)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _NoisePainter(opacity: 0.06),
                ),
              ),
            ),

            // Üstte hafif ek blur bandı
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    height: 120,
                    color: Colors.transparent,
                  ),
                ),
              ),
            ),

            SafeArea(
              child: FadeTransition(
                opacity: CurvedAnimation(parent: _fade, curve: Curves.easeOut),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // İçerik
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        children: [
                          // 1) My Affirmations kartı
                          _buildMyAffirmationsCard(context, isPremium),
                          const SizedBox(height: 20),

                          // 2) 4 adet reminder slot kartı
                          for (int i = 0; i < _slotCount; i++)
                            Padding(
                              padding: EdgeInsets.only(
                                  bottom: i == _slotCount - 1 ? 0 : 18),
                              child: _buildSlotCard(
                                context: context,
                                slotIndex: i,
                                isPremium: isPremium,
                                reminders: reminders,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // ⭐ UNLOCK ALL REMINDERS BUTTON
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFC9A85D),
                                  Color(0xFFE4C98A),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF87652B),
                                width: 1.4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFC9A85D)
                                      .withValues(alpha: 0.40),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  if (!isPremium) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const PremiumScreen(),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            "All reminders are unlocked ✨"),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  child: Center(
                                    child: Text(
                                      "Unlock all reminders",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // ⭐ PREMIUM: MY AFFIRMATIONS (Glass Card)
  // ------------------------------------------------------------
  Widget _buildMyAffirmationsCard(BuildContext context, bool isPremium) {
    final t = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () {
        if (!isPremium) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PremiumScreen()),
          );
          return;
        }

        final template = ReminderModel(
          id: "my_affirmations_${DateTime.now().millisecondsSinceEpoch}",
          categoryIds: {"my_affirmations"},
          startTime: const TimeOfDay(hour: 10, minute: 0),
          endTime: const TimeOfDay(hour: 14, minute: 0),
          repeatCount: 3,
          repeatDays: {1, 3, 5},
          enabled: true,
          isPremium: true,
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReminderEditScreen(reminder: template),
          ),
        );
      },
      child: _glassCard(
        highlight: isPremium,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left text
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.myAff,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isPremium
                      ? "Custom affirmation reminders"
                      : "Premium feature",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),

            // Right icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isPremium
                      ? const Color(0xFFC9A85D)
                      : Colors.white.withValues(alpha: 0.40),
                  width: 1.2,
                ),
              ),
              child: Icon(
                isPremium
                    ? Icons.arrow_forward_ios_rounded
                    : Icons.lock_outline_rounded,
                size: 18,
                color: isPremium
                    ? const Color(0xFFC9A85D)
                    : Colors.white.withValues(alpha: 0.80),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // ⭐ SLOT CARD (4 slot için glass panel)
  // ------------------------------------------------------------
  Widget _buildSlotCard({
    required BuildContext context,
    required int slotIndex,
    required bool isPremium,
    required List<ReminderModel> reminders,
  }) {
    final t = AppLocalizations.of(context)!;
    final reminderState = context.read<ReminderState>();

    final active = _findActiveForSlot(reminders, slotIndex);

    // UI için gösterilecek model:
    final uiModel =
        active ?? _drafts[slotIndex] ?? _defaultTemplate(slotIndex, isPremium);

    final timeRange =
        "${_formatTime(uiModel.startTime)} – ${_formatTime(uiModel.endTime)}";

    // non-prem kullanıcı için:
    // slotIndex == 0 → serbest
    // slotIndex 1,2,3 → kilitli
    final locked = !isPremium && slotIndex > 0;

    final isOn = active != null && active.enabled;

    return GestureDetector(
      onTap: () async {
        if (locked) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PremiumScreen()),
          );
          return;
        }

        // Edit ekranına mevcut uiModel ile git
        final edited = await Navigator.push<ReminderModel?>(
          context,
          MaterialPageRoute(
            builder: (_) => ReminderEditScreen(reminder: uiModel),
          ),
        );

        if (edited != null) {
          setState(() {
            _drafts[slotIndex] = edited.copyWith(
              id: _slotId(slotIndex),
              categoryIds: isPremium
                  ? edited.categoryIds
                  : {Constants.generalCategoryId},
              isPremium: isPremium,
            );
          });

          if (active != null) {
            final updated = _drafts[slotIndex]!.copyWith(
              id: active.id,
              enabled: active.enabled,
            );
            await reminderState.updateReminder(updated, t);
          }
        }
      },
      child: _glassCard(
        highlight: isOn,
        locked: locked,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FIRST ROW
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  t.general,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    timeRange,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                )
              ],
            ),

            const SizedBox(height: 12),

            // SECOND ROW
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Wrap(
                  spacing: 6,
                  children: _weekdayBadges(uiModel.repeatDays),
                ),
                Row(
                  children: [
                    if (locked)
                      Icon(Icons.lock_outline_rounded,
                          size: 20,
                          color: Colors.white.withValues(alpha: 0.85)),
                    Switch(
                        value: isOn,
                        activeThumbColor: const Color(0xFFAEE5FF), // soft blue
                        activeTrackColor:
                            const Color(0xFFAEE5FF).withValues(alpha: 0.50),
                        inactiveThumbColor:
                            Colors.white.withValues(alpha: 0.90),
                        inactiveTrackColor:
                            Colors.white.withValues(alpha: 0.25),
                        onChanged: (v) async {
                          if (v) {
                            // 🔥 BURADA İZİN İSTE
                            final status =
                                await Permission.notification.request();
                            if (!status.isGranted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        "Please allow notification permission.")),
                              );
                              return;
                            }

                            final draft = _drafts[slotIndex] ??
                                _defaultTemplate(slotIndex, isPremium);

                            final model = (active ?? draft).copyWith(
                              id: _slotId(slotIndex),
                              enabled: true,
                              categoryIds: isPremium
                                  ? (draft.categoryIds.isEmpty
                                      ? {Constants.generalCategoryId}
                                      : draft.categoryIds)
                                  : {Constants.generalCategoryId},
                              isPremium: isPremium,
                            );

                            if (active == null) {
                              await reminderState.addReminder(model, t);
                            } else {
                              await reminderState.updateReminder(model, t);
                            }
                          } else {
                            if (active != null) {
                              await reminderState.deleteReminder(active.id);
                            }
                          }
                        }),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // Ortak GLASS CARD
  // ------------------------------------------------------------
  Widget _glassCard({
    required Widget child,
    bool highlight = false,
    bool locked = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: highlight
                ? const Color(0xFFC9A85D).withValues(alpha: 0.38)
                : Colors.black.withValues(alpha: 0.22),
            blurRadius: highlight ? 22 : 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 22,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.20),
                  Colors.white.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: highlight
                    ? const Color(0xFFC9A85D)
                    : locked
                        ? Colors.white.withValues(alpha: 0.45)
                        : Colors.white.withValues(alpha: 0.35),
                width: highlight ? 1.8 : 1.3,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  List<Widget> _weekdayBadges(Set<int> days) {
    final t = AppLocalizations.of(context)!;
    final shortNames = [t.mon, t.tue, t.wed, t.thu, t.fri, t.sat, t.sun];

    return days.map((d) {
      final label = shortNames[d - 1];
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      );
    }).toList();
  }

  String _formatTime(TimeOfDay t) {
    return "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
  }
}

// ------------------------------------------------------------------
// NoisePainter — diğer ekranlarla aynı premium grain efekti
// ------------------------------------------------------------------
class _NoisePainter extends CustomPainter {
  final double opacity;
  final Random _rand = Random();

  _NoisePainter({this.opacity = 0.06});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: opacity);
    for (int i = 0; i < size.width * size.height / 80; i++) {
      final dx = _rand.nextDouble() * size.width;
      final dy = _rand.nextDouble() * size.height;
      canvas.drawRect(Rect.fromLTWH(dx, dy, 1, 1), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
