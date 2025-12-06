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
    final myAff = context.read<MyAffirmationState>();
    final t = AppLocalizations.of(context)!;
    final isEditing = widget.editingId != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF1B1B1B),
                  Color(0xFF111111),
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
                  color: Colors.black.withValues(alpha: 0.4),
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
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: t.writeAff,
                      border: InputBorder.none,
                      hintStyle: const TextStyle(
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                Row(
                  children: [
                    if (isEditing)
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            await myAff.remove(widget.editingId!);
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color:
                                      Colors.redAccent.withValues(alpha: 0.6)),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0x33FF4444),
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
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final text = controller.text.trim();
                          if (text.isEmpty) return;

                          // Eğer yeni ekleme yapılıyorsa → limit kontrol et
                          if (!isEditing) {
                            final over = await myAff.isOverLimit();
                            if (over) {
                              Navigator.pop(context); // popup kapansın
                              showMyAffLimitDialog(
                                  context); // limit dialog açılsın
                              return;
                            }
                          }

                          if (isEditing) {
                            await myAff.update(widget.editingId!, text);
                          } else {
                            await myAff.add(text);
                          }

                          Navigator.pop(context);

                          // Ekledikten sonra son elemana scroll etmek istersen:
                          // _myAffPageController.animateToPage(...)
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFC9A85D),
                                Color(0xFFE4C98A),
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
                                    fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
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
