import 'package:affirmation/l10n/app_localizations.dart';
import 'package:affirmation/models/reminder.dart';
import 'package:affirmation/models/user_preferences.dart';
import 'package:affirmation/state/app_state.dart';
import 'package:affirmation/state/reminder_state.dart';
import 'package:affirmation/ui/screens/premium_screen.dart';
import 'package:affirmation/ui/screens/settings/reminder_edit_screen.dart';
import 'package:affirmation/ui/widgets/reminder_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final appState = context.watch<AppState>();
    final reminderState = context.watch<ReminderState>();

    final isPremiumUser = appState.preferences.isPremiumValid;
    final reminders = reminderState.reminders;

    return Scaffold(
      backgroundColor: const Color(0xfff3ece7),
      appBar: AppBar(
        backgroundColor: const Color(0xfff3ece7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Transform.translate(
          offset: const Offset(-14, 0),
          child: Text(
            t.settings,
            style: const TextStyle(
              fontFamily: "Poppins",
              color: Colors.black,
              fontSize: 21,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: reminders.length,
              itemBuilder: (context, index) {
                final r = reminders[index];

                final categoryName = appState.categories
                    .firstWhere(
                      // ignore: unrelated_type_equality_checks
                      (c) => c.id == r.categoryIds,
                      orElse: () => appState.categories.first,
                    )
                    .name;

                final isLockedPremiumReminder =
                    r.isPremium && !isPremiumUser; // görünür ama kilitli

                return ReminderCard(
                  reminder: r,
                  categoryName: categoryName,
                  locked: isLockedPremiumReminder,
                  onTap: () {
                    // Kilitliyse Premium’a yönlendir
                    if (isLockedPremiumReminder) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PremiumScreen(),
                        ),
                      );
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ReminderEditScreen(reminder: r, isNew: false),
                      ),
                    );
                  },
                  onToggleEnabled: (value) {
                    if (isLockedPremiumReminder) return;
                    final updated = r.copyWith(enabled: value);
                    context.read<ReminderState>().updateReminder(updated);
                  },
                );
              },
            ),
          ),

          // ADD BUTTON
          Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 24,
              top: 4,
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: Text(
                  reminderState.canAddReminder
                      ? t.addReminder
                      : (isPremiumUser
                          ? t.reminderLimitReached
                          : t.unlockMoreReminders),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () {
                  if (!reminderState.canAddReminder) {
                    if (!isPremiumUser) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PremiumScreen(),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Reminder limit reached."),
                        ),
                      );
                    }
                    return;
                  }

                  // Yeni reminder (default self_care)
                  final newReminder = ReminderModel(
                    id: DateTime.now()
                        .millisecondsSinceEpoch
                        .toString(), // basit id
                    categoryIds: {"self_care"},
                    startTime: const TimeOfDay(hour: 9, minute: 0),
                    endTime: const TimeOfDay(hour: 21, minute: 0),
                    repeatCount: 3,
                    repeatDays: {1, 2, 3, 4, 5, 6, 7},
                    enabled: true,
                    isPremium:
                        !isPremiumUser, // free user için bile premium flag önemli değil aslında
                  );

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReminderEditScreen(
                        reminder: newReminder,
                        isNew: true,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
