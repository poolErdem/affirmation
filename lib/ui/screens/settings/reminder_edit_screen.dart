import 'package:affirmation/l10n/app_localizations.dart';
import 'package:affirmation/models/reminder.dart';
import 'package:affirmation/models/user_preferences.dart';
import 'package:affirmation/state/app_state.dart';
import 'package:affirmation/state/reminder_state.dart';
import 'package:affirmation/ui/widgets/time_box.dart';
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
  late String _categoryId;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late int _repeatCount;
  late Set<int> _repeatDays;
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.reminder.categoryId;
    _startTime = widget.reminder.startTime;
    _endTime = widget.reminder.endTime;
    _repeatCount = widget.reminder.repeatCount;
    _repeatDays = {...widget.reminder.repeatDays};
    _enabled = widget.reminder.enabled;
  }

  Future<void> _pickTime({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart ? _startTime : _endTime;
    TimeOfDay? selected;

    await showCupertinoModalPopup(
      context: context,
      builder: (ctx) {
        return Container(
          height: 260,
          color: Colors.white,
          child: Column(
            children: [
              SizedBox(
                height: 210,
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
              CupertinoButton(
                child: const Text(
                  "Done",
                  style: TextStyle(color: Colors.black),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                },
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
      categoryId: _categoryId,
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

    const dayLabels = ["M", "T", "W", "T", "F", "S", "S"];

    return Scaffold(
      backgroundColor: const Color(0xfff3ece7),
      appBar: AppBar(
        backgroundColor: const Color(0xfff3ece7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
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
          // CATEGORY
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Affirmation Category",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _categoryId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0x33000000)),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: categories
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        ),
                      )
                      .toList(),
                  onChanged: isCategoryLocked
                      ? null
                      : (val) {
                          if (val == null) return;
                          setState(() {
                            _categoryId = val;
                          });
                        },
                ),
                if (isCategoryLocked) ...[
                  const SizedBox(height: 6),
                  const Text(
                    "Free reminder uses Self Care. Unlock Premium to choose any category.",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 14),

          // TIME RANGE
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Time Range",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TimeBox(
                        label: "Start",
                        value: _formatTime(_startTime),
                        onTap: () => _pickTime(isStart: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TimeBox(
                        label: "End",
                        value: _formatTime(_endTime),
                        onTap: () => _pickTime(isStart: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "We’ll spread your affirmations between these hours.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // REPEAT COUNT
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "How many times per day?",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$_repeatCount times",
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
                Slider(
                  value: _repeatCount.toDouble(),
                  min: 1,
                  max: 30,
                  divisions: 29,
                  onChanged: (v) {
                    setState(() {
                      _repeatCount = v.round();
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // DAYS
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Repeat on",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (index) {
                    final day = index + 1; // 1..7
                    final selected = _repeatDays.contains(day);

                    return GestureDetector(
                      onTap: () => _toggleDay(day),
                      child: Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color:
                              selected ? Colors.black : const Color(0xFFE0D6CE),
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: Text(
                          dayLabels[index],
                          style: TextStyle(
                            color: selected ? Colors.white : Colors.black,
                            fontSize: 13,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ENABLE TOGGLE
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                "Enabled",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              value: _enabled,
              onChanged: (v) {
                setState(() {
                  _enabled = v;
                });
              },
            ),
          ),

          if (!reminderState.canAddReminder && widget.isNew) ...[
            const SizedBox(height: 10),
            const Text(
              "Tip: Premium users can create up to 5 reminders.",
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
