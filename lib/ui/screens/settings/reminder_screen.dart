import 'dart:math';
import 'package:affirmation/constants/constants.dart';
import 'package:affirmation/l10n/app_localizations.dart';
import 'package:affirmation/models/reminder.dart';
import 'package:affirmation/state/app_state.dart';
import 'package:affirmation/state/reminder_state.dart';
import 'package:affirmation/ui/screens/premium_screen.dart';
import 'package:affirmation/ui/screens/settings/reminder_edit_screen.dart';
import 'package:flutter/material.dart';
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
    // Basit varsayılanlar
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

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ⭐ TOP GRADIENT
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xfff7f2ed),
                  Color(0xfff2ebe5),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _NoisePainter(opacity: 0.06)),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: CurvedAnimation(parent: _fade, curve: Curves.easeOut),
              child: Column(
                children: [
                  // ⭐ HEADER
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.arrow_back_ios_new,
                              size: 26, color: Colors.black87),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          t.reminders,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        )
                      ],
                    ),
                  ),

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
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC9A85D),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: () {
                          if (!isPremium) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const PremiumScreen()),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("All reminders are unlocked ✨"),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        child: const Text(
                          "Unlock all reminders",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
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
    );
  }

  // ------------------------------------------------------------
  // ⭐ PREMIUM: MY AFFIRMATIONS (Card)
  // ------------------------------------------------------------
  Widget _buildMyAffirmationsCard(BuildContext context, bool isPremium) {
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
      child: _premiumBox(
        title: "My Affirmations",
        subtitle:
            isPremium ? "Custom affirmation reminders" : "Premium feature",
        rightIcon: isPremium
            ? Icons.arrow_forward_ios_rounded
            : Icons.lock_outline_rounded,
        isPremium: isPremium,
      ),
    );
  }

  // ------------------------------------------------------------
  // ⭐ SLOT CARD (2., 3., 4., 5. kutucuk)
  // ------------------------------------------------------------
  Widget _buildSlotCard({
    required BuildContext context,
    required int slotIndex,
    required bool isPremium,
    required List<ReminderModel> reminders,
  }) {
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
            // Draft'ı güncelle, id'yi slot id'sine sabitle
            _drafts[slotIndex] = edited.copyWith(
              id: _slotId(slotIndex),
              // Non-prem için kategori ~ daima general
              categoryIds: isPremium
                  ? edited.categoryIds
                  : {Constants.generalCategoryId},
              isPremium: isPremium,
              // enable durumu burada önemli değil, switch karar veriyor
            );
          });

          // Eğer hali hazırda aktif bir reminder varsa,
          // sadece değerlerini güncelle (enabled durumuna dokunma)
          if (active != null) {
            final updated = _drafts[slotIndex]!.copyWith(
              id: active.id,
              enabled: active.enabled,
            );
            await reminderState.updateReminder(updated);
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isOn ? const Color(0xFFC9A85D) : Colors.transparent,
            width: isOn ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isOn
                  ? const Color(0xFFC9A85D).withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: isOn ? 18 : 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FIRST ROW
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "General",
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6EDD8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    timeRange,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
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
                      const Icon(
                        Icons.lock_outline_rounded,
                        size: 20,
                        color: Colors.black45,
                      ),
                    Switch(
                      value: isOn,
                      activeThumbColor: const Color(0xFFC9A85D),
                      onChanged: locked
                          ? null
                          : (v) async {
                              if (v) {
                                // ENABLE → add/update + aktif hale getir
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
                                  await reminderState.addReminder(model);
                                } else {
                                  await reminderState.updateReminder(model);
                                }
                              } else {
                                // DISABLE → reminder silinsin
                                if (active != null) {
                                  await reminderState.deleteReminder(active.id);
                                }
                              }
                            },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _premiumBox({
    required String title,
    required String subtitle,
    required IconData rightIcon,
    required bool isPremium,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isPremium ? const Color(0xFFC9A85D) : Colors.transparent,
          width: isPremium ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isPremium
                ? const Color(0xFFC9A85D).withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: isPremium ? 18 : 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87)),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: isPremium ? Colors.black54 : Colors.black38,
                ),
              ),
            ],
          ),
          Icon(rightIcon, size: 22, color: Colors.black54),
        ],
      ),
    );
  }

  List<Widget> _weekdayBadges(Set<int> days) {
    const shortNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return days.map((d) {
      final label = shortNames[d - 1];
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF0EAE2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
      );
    }).toList();
  }

  String _formatTime(TimeOfDay t) {
    return "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
  }
}

// NoisePainter — aynı
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
