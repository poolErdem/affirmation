import 'package:affirmation/l10n/app_localizations.dart';
import 'package:affirmation/models/reminder.dart';
import 'package:affirmation/models/user_preferences.dart';
import 'package:affirmation/state/app_state.dart';
import 'package:affirmation/state/reminder_state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ReminderEditScreen extends StatefulWidget {
  final ReminderModel reminder;
  final bool isNew;

  const ReminderEditScreen({
    super.key,
    required this.reminder,
    required this.isNew,
  });

  @override
  State<ReminderEditScreen> createState() => _ReminderEditScreenState();
}

class _ReminderEditScreenState extends State<ReminderEditScreen> {
  late Set<String> _categoryIds;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late int _repeatCount;
  late Set<int> _repeatDays;
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    _categoryIds = {...widget.reminder.categoryIds};
    _startTime = widget.reminder.startTime;
    _endTime = widget.reminder.endTime;
    _repeatCount = widget.reminder.repeatCount;
    _repeatDays = {...widget.reminder.repeatDays};
    _enabled = widget.reminder.enabled;
  }

  Future<void> _pickTime({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart ? _startTime : _endTime;

    TimeOfDay? selected = initial;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SizedBox(
          height: 320,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),

              // PICKER
              SizedBox(
                height: 220,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: DateTime(
                    now.year,
                    now.month,
                    now.day,
                    initial.hour,
                    initial.minute,
                  ),
                  onDateTimeChanged: (dateTime) {
                    selected = TimeOfDay(
                      hour: dateTime.hour,
                      minute: dateTime.minute,
                    );
                  },
                ),
              ),

              // DONE BUTTON
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 12),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Done"),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      setState(() {
        if (isStart) {
          _startTime = selected!;
        } else {
          _endTime = selected!;
        }
      });
    }
  }

  void _toggleDay(int dayIndex) {
    setState(() {
      if (_repeatDays.contains(dayIndex)) {
        _repeatDays.remove(dayIndex);
      } else {
        _repeatDays.add(dayIndex);
      }
      if (_repeatDays.isEmpty) {
        // boş kalmasın
        _repeatDays.add(dayIndex);
      }
    });
  }

  String _formatTime(TimeOfDay t) {
    String two(int v) => v.toString().padLeft(2, '0');
    return "${two(t.hour)}:${two(t.minute)}";
  }

  void _save() {
    // basit validation: end, start'tan sonra mı
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("End time should be after start time."),
        ),
      );
      return;
    }

    if (_repeatCount < 1 || _repeatCount > 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Repeat count must be between 1 and 30."),
        ),
      );
      return;
    }

    final reminderState = context.read<ReminderState>();
    final updated = widget.reminder.copyWith(
      categoryIds: {"happiness"},
      startTime: _startTime,
      endTime: _endTime,
      repeatCount: _repeatCount,
      repeatDays: _repeatDays,
      enabled: _enabled,
    );

    if (widget.isNew) {
      final ok = reminderState.addReminder(updated);
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Reminder limit reached."),
          ),
        );
        return;
      }
    } else {
      reminderState.updateReminder(updated);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final appState = context.watch<AppState>();
    final reminderState = context.watch<ReminderState>();

    final isPremiumUser = appState.preferences.isPremiumValid;
    // free kullanıcı + non-premium reminder → kategori kilitli (self_care)
    final isCategoryLocked = !isPremiumUser && !widget.reminder.isPremium;

    final categories = appState.categories;

    const labels = ["M", "T", "W", "T", "F", "S", "S"];

    return Scaffold(
      backgroundColor: const Color(0xfff3ece7),
      appBar: AppBar(
        backgroundColor: const Color(0xfff3ece7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isNew ? t.addReminder : t.editReminder,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              "Save",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
        children: [
          _buildTypeSelector(t, isPremiumUser),
          const SizedBox(height: 14),
          _buildRepeatCountBox(),
          const SizedBox(height: 14),
          _buildTimeAdjustBox(
            label: "Start at",
            time: _startTime,
            onMinus: () => setState(() {
              int h = _startTime.hour;
              int m = _startTime.minute - 1;

              if (m < 0) {
                m = 59;
                h = (h - 1) % 24;
              }
              _startTime = TimeOfDay(hour: h, minute: m);
            }),
            onPlus: () => setState(() {
              int h = _startTime.hour;
              int m = _startTime.minute + 1;

              if (m > 59) {
                m = 0;
                h = (h + 1) % 24;
              }
              _startTime = TimeOfDay(hour: h, minute: m);
            }),
          ),
          const SizedBox(height: 14),
          _buildTimeAdjustBox(
            label: "End at",
            time: _endTime,
            onMinus: () {
              setState(() {
                int h = _endTime.hour;
                int m = _endTime.minute - 1;

                if (m < 0) {
                  m = 59;
                  h = (h - 1) % 24;
                }

                _endTime = TimeOfDay(hour: h, minute: m);
              });
            },
            onPlus: () {
              setState(() {
                int h = _endTime.hour;
                int m = _endTime.minute + 1;

                if (m > 59) {
                  m = 0;
                  h = (h + 1) % 24;
                }

                _endTime = TimeOfDay(hour: h, minute: m);
              });
            },
          ),
          const SizedBox(height: 14),
          _buildRepeatDays(),
          const SizedBox(height: 14),
          _buildSoundSelector(),
        ],
      ),
    );
  }

  Widget _buildTypeSelector(AppLocalizations t, bool isPremiumUser) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Type of affirmations",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          GestureDetector(
            onTap: isPremiumUser
                ? () {
                    // TODO: kategori seçme ekranına git
                  }
                : null,
            child: Row(
              children: [
                Text(
                  _categoryIds.isEmpty ? "General" : "Selected",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isPremiumUser ? Colors.black : Colors.grey.shade400,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: isPremiumUser ? Colors.black : Colors.grey.shade400,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepeatCountBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "How many",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _roundButton("-", () {
                setState(() {
                  if (_repeatCount > 1) _repeatCount--;
                });
              }),
              Text(
                "${_repeatCount}x",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              _roundButton("+", () {
                setState(() {
                  if (_repeatCount < 30) _repeatCount++;
                });
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeAdjustBox({
    required String label,
    required TimeOfDay time,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _roundButton("-", onMinus),
              Text(
                _formatTime(time),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              _roundButton("+", onPlus),
            ],
          ),
        ],
      ),
    );
  }

  Widget _roundButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildRepeatDays() {
    const labels = ["S", "M", "T", "W", "T", "F", "S"];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Repeat",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final day = i + 1;
              final selected = _repeatDays.contains(day);

              return GestureDetector(
                onTap: () => _toggleDay(day),
                child: Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xffe6c5b9) : Colors.white,
                    borderRadius: BorderRadius.circular(21),
                    border: Border.all(
                      color: selected ? Colors.transparent : Colors.black26,
                    ),
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.black : Colors.black87,
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

  Widget _buildSoundSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Sound",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          Row(
            children: const [
              Text(
                "Positive",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              SizedBox(width: 6),
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black),
            ],
          ),
        ],
      ),
    );
  }
}
