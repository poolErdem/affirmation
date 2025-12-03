import 'dart:math';
import 'package:affirmation/models/reminder.dart';
import 'package:affirmation/state/app_state.dart';
import 'package:affirmation/ui/screens/premium_screen.dart';
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
  static const generalCategoryId = "general";

  late ReminderModel data;
  late AnimationController _fade;

  @override
  void initState() {
    super.initState();

    final now = TimeOfDay.now();

    data = widget.reminder ??
        ReminderModel(
          id: "r_${DateTime.now().millisecondsSinceEpoch}",
          categoryIds: {generalCategoryId},
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

  // -----------------------------------------------------------
  // CATEGORY LABEL
  // -----------------------------------------------------------
  String _categoryLabel() {
    if (data.categoryIds.contains("general")) return "General";
    return data.categoryIds.join(", ");
  }

  // -----------------------------------------------------------
  // OPEN CATEGORY SELECTION (FREE → PREMIUMSCREEN)
  // -----------------------------------------------------------
  void _openCategorySheet() async {
    final isPremium = true;
    // context.read<AppState>().preferences.premiumActive;

    // FREE USER → Premium Screen
    if (!isPremium) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PremiumScreen()),
      );
      return;
    }

    // PREMIUM USER → Bottom Sheet
    final selected = Set<String>.from(data.categoryIds);

    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryBottomSheet(
        selected: selected,
      ),
    );

    if (result != null) {
      setState(() {
        data = data.copyWith(categoryIds: result);
      });
    }
  }

  // -----------------------------------------------------------
  // MAIN UI
  // -----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<AppState>().preferences.premiumActive;

    return PopScope(
      canPop: false, // sen manual pop yapıyorsun
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xfff7f2ed), Color(0xfff2ebe5)],
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
                opacity: _fade,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                  children: [
                    _header(context),
                    const SizedBox(height: 16),

                    // GENERAL (FREE → disable görünüm)
                    _infoBox(
                      "Category",
                      _categoryLabel(),
                      onTap: _openCategorySheet,
                      isPremium: isPremium,
                    ),

                    _editBox(
                      title: "How many times",
                      trailing: _countStepper(),
                    ),
                    _editBox(
                      title: "Start at",
                      trailing: _timeStepper(
                        data.startTime,
                        () => _shiftStart(-30),
                        () => _shiftStart(30),
                      ),
                    ),
                    _editBox(
                      title: "End at",
                      trailing: _timeStepper(
                        data.endTime,
                        () => _shiftEnd(-30),
                        () => _shiftEnd(30),
                      ),
                    ),
                    _repeatDaysBox(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // HEADER
  Widget _header(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context, data),
          child: const Icon(Icons.arrow_back_ios_new,
              size: 26, color: Colors.black87),
        ),
        const SizedBox(width: 12),
        Text(
          widget.reminder == null ? "New Reminder" : "Edit Reminder",
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // CATEGORY BOX (FREE → DISABLED)
  Widget _infoBox(String title, String value,
      {VoidCallback? onTap, required bool isPremium}) {
    final isFree = !isPremium;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: _boxDecoration(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87)),
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
                if (isFree) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC9A85D),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      "Premium",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ]
              ],
            )
          ],
        ),
      ),
    );
  }

  // GENERIC EDIT BOX
  Widget _editBox({required String title, required Widget trailing}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: _boxDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87)),
          trailing,
        ],
      ),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFC9A85D), width: 1.3),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFFC9A85D).withValues(alpha: 0.18),
          blurRadius: 12,
          offset: const Offset(0, 5),
        ),
      ],
    );
  }

  // COUNT STEPPER
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
        const SizedBox(width: 10),
        Text(
          "${data.repeatCount}",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 10),
        _circleBtn("+", () {
          setState(() {
            data = data.copyWith(repeatCount: data.repeatCount + 1);
          });
        }),
      ],
    );
  }

  // TIME STEPPER
  Widget _timeStepper(TimeOfDay v, VoidCallback onMinus, VoidCallback onPlus) {
    String label =
        "${v.hour.toString().padLeft(2, '0')}:${v.minute.toString().padLeft(2, '0')}";

    return Row(
      children: [
        _circleBtn("-", onMinus),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 10),
        _circleBtn("+", onPlus),
      ],
    );
  }

  Widget _circleBtn(String t, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFF0EAE2),
        ),
        child: Text(
          t,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  // REPEAT DAYS
  Widget _repeatDaysBox() {
    const names = ["M", "T", "W", "T", "F", "S", "S"];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Repeat days",
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87)),
          const SizedBox(height: 12),
          Row(
            children: List.generate(7, (i) {
              final weekday = i + 1;
              final selected = data.repeatDays.contains(weekday);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    final s = Set<int>.from(data.repeatDays);
                    selected ? s.remove(weekday) : s.add(weekday);
                    data = data.copyWith(repeatDays: s);
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFC9A85D)
                        : const Color(0xFFF0EAE2),
                    borderRadius: BorderRadius.circular(10),
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
          ),
        ],
      ),
    );
  }

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
// PREMIUM CATEGORY BOTTOM SHEET (ONLY FOR PREMIUM USERS)
// -------------------------------------------------------------
class _CategoryBottomSheet extends StatefulWidget {
  final Set<String> selected;

  const _CategoryBottomSheet({
    required this.selected,
  });

  @override
  State<_CategoryBottomSheet> createState() => _CategoryBottomSheetState();
}

class _CategoryBottomSheetState extends State<_CategoryBottomSheet> {
  static const allCategories = [
    "general",
    "self_care",
    "sleep",
    "stress_anxiety",
    "relationships",
    "happiness",
    "positive_thinking",
    "confidence",
    "motivation",
    "mindfulness",
    "career_success"
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.40,
      maxChildSize: 0.90,
      builder: (_, controller) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            children: [
              // HANDLE
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                "Select Categories",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 18),

              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: allCategories.map((c) {
                      final isSelected = widget.selected.contains(c);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              widget.selected.remove(c);
                            } else {
                              widget.selected.add(c);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 14,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFC9A85D)
                                  : Colors.black12,
                              width: 1.5,
                            ),
                            color: isSelected
                                ? const Color(0xFFF7EFE1)
                                : Colors.white,
                          ),
                          child: Text(
                            c.replaceAll("_", " ").toUpperCase(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // DONE BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFFC9A85D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.pop(context, widget.selected);
                  },
                  child: const Text(
                    "Done",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// -------------------------------------------------------------
// Noise Background Painter
// -------------------------------------------------------------
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
      canvas.drawRect(Rect.fromLTWH(dx, dy, 1.0, 1.0), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
