import 'dart:ui';
import 'package:affirmation/models/user_preferences.dart';
import 'package:affirmation/state/my_affirmation_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../ui/screens/premium_screen.dart';
import '../../l10n/app_localizations.dart';

class MyAffEditPopup extends StatefulWidget {
  final String? editingId;
  final String? initialText;

  const MyAffEditPopup({
    super.key,
    this.editingId,
    this.initialText,
  });

  @override
  State<MyAffEditPopup> createState() => _MyAffEditPopupState();
}

class _MyAffEditPopupState extends State<MyAffEditPopup> {
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialText ?? "");
  }

  @override
  Widget build(BuildContext context) {
    final myAff = context.watch<MyAffirmationState>();
    final t = AppLocalizations.of(context)!;
    final isEditing = widget.editingId != null;

    // Gün bilgisi
    final currentDay = myAff.todayChallengeDay;
    final required = myAff.requiredForDay(currentDay);
    final written = myAff.writtenCountForDay(currentDay);

    bool missedAnyPreviousDay = false;

    // 1) En son yazılan günü bul
    int lastWrittenDay = 0;
    for (int d = 1; d <= 21; d++) {
      if (myAff.writtenCountForDay(d) > 0) {
        lastWrittenDay = d;
      }
    }

    // 2) Eğer en son yazdığı gün ile bugün arasında boş gün varsa → skip var
    if (lastWrittenDay > 0 && currentDay > lastWrittenDay + 1) {
      missedAnyPreviousDay = true;
    }

    // 3) Dün eksik mi? (eski kontrol de dursun)
    bool missedYesterday = false;
    if (!isEditing && currentDay > 1) {
      if (myAff.realDaysPassed > 0) {
        final y = currentDay - 1;
        final reqY = myAff.requiredForDay(y);
        final wY = myAff.writtenCountForDay(y);
        missedYesterday = wY < reqY;
      }
    }

    print(
        "currentday: $currentDay, missedYesterday: $missedYesterday, missedAnyPreviousDay: $missedAnyPreviousDay");
    print(
        "written: $written, required: $required, missedAnyPreviousDay: $missedAnyPreviousDay");

    //final bool missed = (!missedYesterday && !missedAnyPreviousDay);
    final bool todayCompleted = written >= required;

    var text = "";
    if (currentDay == 1) {
      text = "Your 21-day journey has restarted today.";
    }

    if (currentDay == 1 && myAff.lastAddTriggeredReset) {
      text =
          "⚠️ You missed challenge. Your 21-day journey has restarted today.";
    }

    print(
        "isediting $isEditing lastAddTriggeredReset: ${myAff.lastAddTriggeredReset}");

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 60), // 🔼 yukarı alma ayarı
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromARGB(255, 51, 50, 50),
                      Color.fromARGB(255, 109, 105, 105),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: const Color(0x88C9A85D),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // TITLE
                    Text(
                      isEditing ? t.editAff : t.newAff,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ---------- RESET MESSAGE ----------
                    if (!isEditing && currentDay == 1)
                      Container(
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.45),
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          text,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            height: 1.4,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                    // ---------- CHALLENGE INFO ----------
                    if (!isEditing)
                      Container(
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.20),
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          todayCompleted
                              ? "🎉 You have completed today's task! ($written / $required)"
                              : "Day $currentDay — Today you must write $required affirmations. Progress: $written / $required",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ),

                    // INPUT
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: TextField(
                        controller: controller,
                        maxLines: 3,
                        maxLength: 150,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: t.writeAff,
                          border: InputBorder.none,
                          hintStyle: const TextStyle(color: Colors.white54),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        // DELETE
                        if (isEditing)
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                await myAff.remove(widget.editingId!);
                                Navigator.pop(context);
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color:
                                        Colors.redAccent.withValues(alpha: 0.6),
                                  ),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color.fromARGB(51, 217, 100, 100),
                                      Color(0x22FF4444),
                                    ],
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.delete,
                                        color: Colors.redAccent),
                                    const SizedBox(width: 8),
                                    Text(
                                      t.delete,
                                      style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        if (isEditing) const SizedBox(width: 12),

                        // SAVE
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final value = controller.text.trim();
                              if (value.isEmpty) return;

                              if (!isEditing) {
                                final over = await myAff.isOverLimit();
                                if (over) {
                                  Navigator.pop(context);
                                  showMyAffLimitDialog(context);
                                  return;
                                }
                              }

                              if (isEditing) {
                                await myAff.update(widget.editingId!, value);
                                Navigator.pop(context);
                              } else {
                                try {
                                  await myAff.add(value);
                                  Navigator.pop(context);

                                  if (myAff.isChallengeCompleted) {
                                    _showChallengeCelebration(context);
                                  }
                                } catch (e) {
                                  if (e.toString() == "reset") {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "⚠️ Challenge reset! You missed yesterday's task.",
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color.fromARGB(255, 204, 179, 122),
                                    Color.fromARGB(255, 212, 192, 146),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF87652B),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    isEditing ? t.update : t.save,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showChallengeCelebration(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black.withValues(alpha: 0.85),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "🎉 Challenge Completed!",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "You successfully completed your 21-day affirmation challenge!",
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ),
    );
  }

  void showMyAffLimitDialog(BuildContext context) {
    final appState = context.read<AppState>();
    final isPremium = appState.preferences.isPremiumValid;
    final t = AppLocalizations.of(context)!;

    String title;
    String message;
    List<Widget> actions;

    if (!isPremium) {
      title = t.myAffLimitTitle;
      message = t.myAffLimit;
      actions = [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PremiumScreen()),
            );
          },
          child: const Text("Go Premium"),
        ),
      ];
    } else {
      title = "Premium Limit Reached";
      message =
          "You've reached your Premium limit (1000). You cannot add more custom affirmations.";
      actions = [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("OK"),
        ),
      ];
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        actions: actions,
      ),
    );
  }
}
