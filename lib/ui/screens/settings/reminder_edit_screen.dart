import 'dart:math';
import 'dart:ui';
import 'package:affirmation/constants/constants.dart';
import 'package:affirmation/l10n/app_localizations.dart';
import 'package:affirmation/models/reminder.dart';
import 'package:affirmation/state/app_state.dart';
import 'package:affirmation/ui/screens/premium_screen.dart';
import 'package:affirmation/ui/widgets/shared_blur_background.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ReminderEditScreen extends StatefulWidget {
  final ReminderModel? reminder;

  const ReminderEditScreen({super.key, this.reminder});

  @override
  State<ReminderEditScreen> createState() => _ReminderEditScreenState();
}

class _ReminderEditScreenState extends State<ReminderEditScreen>
    with SingleTickerProviderStateMixin {
  late ReminderModel data;
  late AnimationController _fade;

  @override
  void initState() {
    super.initState();

    final now = TimeOfDay.now();

    data = widget.reminder ??
        ReminderModel(
          id: "r_${DateTime.now().millisecondsSinceEpoch}",
          categoryIds: {Constants.generalCategoryId},
          startTime: now,
          endTime: TimeOfDay(hour: now.hour, minute: (now.minute + 30) % 60),
          repeatCount: 3,
          repeatDays: {DateTime.now().weekday},
          enabled: false,
          isPremium: false,
        );

    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final appState = context.watch<AppState>();
    final bg = appState.activeThemeImage;

    final isPremium = appState.preferences.premiumActive;

    return SharedBlurBackground(
      imageAsset: bg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            // NOISE
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _NoisePainter(0.055),
                ),
              ),
            ),

            SafeArea(
              child: FadeTransition(
                opacity: _fade,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  children: [
                    _header(context),
                    const SizedBox(height: 26),

                    // CATEGORY
                    _glassInfoBox(
                      title: t.category,
                      value: _categoryLabel(t),
                      isPremium: isPremium,
                      onTap: _openCategorySheet,
                    ),

                    _glassEditBox(
                      title: t.howMany,
                      trailing: _countStepper(),
                    ),

                    _glassEditBox(
                      title: t.startAt,
                      trailing: _timeStepper(
                        data.startTime,
                        () => _shiftStart(-30),
                        () => _shiftStart(30),
                      ),
                    ),

                    _glassEditBox(
                      title: t.endAt,
                      trailing: _timeStepper(
                        data.endTime,
                        () => _shiftEnd(-30),
                        () => _shiftEnd(30),
                      ),
                    ),

                    _repeatDaysGlassBox(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // HEADER
  // -------------------------------------------------------------
  Widget _header(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context, data),
          child: const Icon(Icons.arrow_back_ios_new,
              size: 22, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Text(
          t.editReminder,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // CATEGORY LABEL
  // -------------------------------------------------------------
  String _categoryLabel(AppLocalizations t) {
    if (data.categoryIds.contains("general")) return "General";
    return data.categoryIds.join(", ");
  }

  // -------------------------------------------------------------
  // CATEGORY SELECTION SHEET
  // -------------------------------------------------------------
  void _openCategorySheet() async {
    final isPremium = context.read<AppState>().preferences.premiumActive;

    if (!isPremium) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PremiumScreen()),
      );
      return;
    }

    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CategoryBottomSheet(selected: data.categoryIds.toSet()),
    );

    if (result != null) {
      setState(() {
        data = data.copyWith(categoryIds: result);
      });
    }
  }

  // -------------------------------------------------------------
  // GLASS BOX DECORATION
  // -------------------------------------------------------------
  BoxDecoration _glassDeco() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: const Color(0x55C9A85D),
        width: 1.2,
      ),
      gradient: LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.22),
          Colors.white.withValues(alpha: 0.08),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.18),
          blurRadius: 14,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // GLASS INFO BOX
  // -------------------------------------------------------------
  Widget _glassInfoBox({
    required String title,
    required String value,
    required bool isPremium,
    VoidCallback? onTap,
  }) {
    final isFree = !isPremium;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            margin: const EdgeInsets.only(bottom: 18),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: _glassDeco(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                Row(
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isFree ? Colors.black26 : Colors.black87,
                      ),
                    ),
                    if (isFree)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC9A85D),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          "Premium",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
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

  // -------------------------------------------------------------
  // EDIT BOX
  // -------------------------------------------------------------
  Widget _glassEditBox({required String title, required Widget trailing}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 18),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: _glassDeco(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
              trailing,
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // COUNT STEPPER
  // -------------------------------------------------------------
  Widget _countStepper() {
    return Row(
      children: [
        _circleBtn("-", () {
          if (data.repeatCount > 1) {
            setState(() {
              data = data.copyWith(repeatCount: data.repeatCount - 1);
            });
          }
        }),
        const SizedBox(width: 12),
        Text("${data.repeatCount}",
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(width: 12),
        _circleBtn("+", () {
          setState(() {
            data = data.copyWith(repeatCount: data.repeatCount + 1);
          });
        }),
      ],
    );
  }

  // -------------------------------------------------------------
  // TIME STEPPER
  // -------------------------------------------------------------
  Widget _timeStepper(TimeOfDay v, VoidCallback minus, VoidCallback plus) {
    final label =
        "${v.hour.toString().padLeft(2, '0')}:${v.minute.toString().padLeft(2, '0')}";

    return Row(
      children: [
        _circleBtn("-", minus),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 12),
        _circleBtn("+", plus),
      ],
    );
  }

  Widget _circleBtn(String t, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.25),
          border: Border.all(
            color: const Color(0x55C9A85D),
            width: 1.2,
          ),
        ),
        child: Text(
          t,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // REPEAT DAYS
  // -------------------------------------------------------------
  Widget _repeatDaysGlassBox() {
    final t = AppLocalizations.of(context)!;
    const names = ["M", "T", "W", "T", "F", "S", "S"];

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: _glassDeco(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.repeatDays,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
              const SizedBox(height: 12),
              Row(
                children: List.generate(7, (i) {
                  final w = i + 1;
                  final selected = data.repeatDays.contains(w);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        final s = Set<int>.from(data.repeatDays);
                        selected ? s.remove(w) : s.add(w);
                        data = data.copyWith(repeatDays: s);
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: selected
                            ? const Color(0xFFAEE5FF) // 🔵 SERENE BLUE
                            : Colors.white.withValues(alpha: 0.25),
                      ),
                      child: Text(
                        names[i],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  );
                }),
              )
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  void _shiftStart(int minutes) {
    final dt = DateTime(2020, 1, 1, data.startTime.hour, data.startTime.minute)
        .add(Duration(minutes: minutes));
    setState(() {
      data = data.copyWith(
        startTime: TimeOfDay(hour: dt.hour, minute: dt.minute),
      );
    });
  }

  void _shiftEnd(int minutes) {
    final dt = DateTime(2020, 1, 1, data.endTime.hour, data.endTime.minute)
        .add(Duration(minutes: minutes));
    setState(() {
      data = data.copyWith(
        endTime: TimeOfDay(hour: dt.hour, minute: dt.minute),
      );
    });
  }
}

// -------------------------------------------------------------
// CATEGORY SHEET
// -------------------------------------------------------------
class _CategoryBottomSheet extends StatefulWidget {
  final Set<String> selected;

  const _CategoryBottomSheet({required this.selected});

  @override
  State<_CategoryBottomSheet> createState() => _CategoryBottomSheetState();
}

class _CategoryBottomSheetState extends State<_CategoryBottomSheet> {
  static const all = Constants.allCategories;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.35),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            border: Border.all(
              color: const Color(0x55C9A85D),
              width: 1.3,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.black.withAlpha(80),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                "Select Categories",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: all.map((id) {
                      final sel = widget.selected.contains(id);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            sel
                                ? widget.selected.remove(id)
                                : widget.selected.add(id);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: sel
                                  ? const Color(0xFFC9A85D)
                                  : Colors.black26,
                              width: 1.3,
                            ),
                            color: sel
                                ? const Color(0xFFF6EEDC)
                                : Colors.white.withValues(alpha: 0.25),
                          ),
                          child: Text(
                            id.replaceAll("_", " ").toUpperCase(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, widget.selected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC9A85D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    "Done",
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// NOISE PAINTER
// -------------------------------------------------------------
class _NoisePainter extends CustomPainter {
  final double opacity;
  final Random _rand = Random();

  _NoisePainter(this.opacity);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: opacity);
    for (int i = 0; i < size.width * size.height / 70; i++) {
      final dx = _rand.nextDouble() * size.width;
      final dy = _rand.nextDouble() * size.height;
      canvas.drawRect(Rect.fromLTWH(dx, dy, 1.1, 1.1), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
