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

      // -------------------------
      // PREMIUM APPBAR
      // -------------------------
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Color.fromARGB(80, 0, 0, 0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Transform.translate(
          offset: const Offset(-10, 0),
          child: Text(
            t.reminders,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              fontFamily: "Poppins",
            ),
          ),
        ),
      ),

      body: Stack(
        children: [
          // -------------------------
          // PREMIUM NOISE TEXTURE
          // -------------------------
          Positioned.fill(
            child: Opacity(
              opacity: 0.055,
              child: Image.asset(
                "assets/premium/noise.png",
                fit: BoxFit.cover,
              ),
            ),
          ),

          Column(
            children: [
              const SizedBox(height: 4),

              // -------------------------
              // REMINDER LIST
              // -------------------------
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: reminders.length,
                  itemBuilder: (context, index) {
                    final r = reminders[index];

                    final categoryName = appState.categories
                        .firstWhere(
                          (c) => r.categoryIds.contains(c.id),
                          orElse: () => appState.categories.first,
                        )
                        .name;

                    final isLockedPremiumReminder =
                        r.isPremium && !isPremiumUser;

                    return AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      opacity: 1,
                      child: ReminderCard(
                        reminder: r,
                        categoryName: categoryName,
                        locked: isLockedPremiumReminder,
                        onTap: () {
                          if (isLockedPremiumReminder) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const PremiumScreen()),
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
                      ),
                    );
                  },
                ),
              ),

              // -------------------------
              // PREMIUM BLACK "ADD" BUTTON
              // -------------------------
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 20,
                      ),
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 14,
                      shadowColor: Colors.black.withValues(alpha: 0.45),

                      // GOLD AURA
                      side: BorderSide(
                        color: const Color(0xFFC9A85D).withValues(alpha: 0.35),
                        width: 1.3,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 22),
                    label: Text(
                      reminderState.canAddReminder
                          ? t.addReminder
                          : (isPremiumUser
                              ? t.reminderLimitReached
                              : t.unlockMoreReminders),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        shadows: [
                          Shadow(
                            color: Color(0xFFC9A85D),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    onPressed: () {
                      if (!reminderState.canAddReminder) {
                        if (!isPremiumUser) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const PremiumScreen()),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Reminder limit reached.")),
                          );
                        }
                        return;
                      }

                      // Default yeni reminder
                      final newReminder = ReminderModel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        categoryIds: {"self_care"},
                        startTime: const TimeOfDay(hour: 9, minute: 0),
                        endTime: const TimeOfDay(hour: 21, minute: 0),
                        repeatCount: 3,
                        repeatDays: {1, 2, 3, 4, 5, 6, 7},
                        enabled: true,
                        isPremium: !isPremiumUser,
                      );

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReminderEditScreen(
                              reminder: newReminder, isNew: true),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
