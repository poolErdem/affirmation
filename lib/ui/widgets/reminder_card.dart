import 'package:affirmation/models/reminder.dart';
import 'package:flutter/material.dart';

class ReminderCard extends StatelessWidget {
  final ReminderModel reminder;
  final String categoryName;
  final bool locked;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggleEnabled;

  const ReminderCard({
    super.key,
    required this.reminder,
    required this.categoryName,
    required this.locked,
    required this.onTap,
    required this.onToggleEnabled,
  });

  String _formatTimeRange() {
    String two(int v) => v.toString().padLeft(2, '0');
    final s =
        "${two(reminder.startTime.hour)}:${two(reminder.startTime.minute)}";
    final e = "${two(reminder.endTime.hour)}:${two(reminder.endTime.minute)}";
    return "$s – $e";
  }

  String _formatDays() {
    const labels = ["M", "T", "W", "T", "F", "S", "S"];

    if (reminder.repeatDays.length == 7) return "Every day";

    final list = reminder.repeatDays.toList()..sort();
    return list.map((d) => labels[d - 1]).join(" ");
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: locked ? const Color(0xFFE0C36B) : const Color(0x11000000),
            width: locked ? 1.3 : 1.0,
          ),
        ),
        child: Row(
          children: [
            // LEFT SIDE
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.notifications_active_outlined,
                        size: 20,
                        color: Colors.black,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        categoryName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (locked) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.lock,
                          size: 16,
                          color: Color(0xFFE0C36B),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTimeRange(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${reminder.repeatCount}× • ${_formatDays()}",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            // RIGHT SIDE: SWITCH
            Switch(
              value: reminder.enabled,
              onChanged: locked ? null : onToggleEnabled,
            ),
          ],
        ),
      ),
    );
  }
}
