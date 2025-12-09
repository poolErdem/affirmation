import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/affirmation.dart';
import '../../state/app_state.dart';

class AffirmationCard extends StatelessWidget {
  final Affirmation? affirmation;
  final String? customText;
  final bool isMine;
  final bool showText; // ⭐ YENİ - yazıyı göster/gizle

  const AffirmationCard({
    super.key,
    this.affirmation,
    this.customText,
    this.isMine = false,
    this.showText = true, // ⭐ YENİ - varsayılan göster
  });

  /// ⭐ Kartın eski stilini %100 koruyan ortak style (artık static)
  static TextStyle provideTextStyle(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return textTheme.headlineSmall?.copyWith(
          color: Colors.white,
          height: 1.4,
        ) ??
        const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          height: 1.4,
        );
  }

  @override
  Widget build(BuildContext context) {
    final userName = context.select<AppState, String>(
      (s) => s.preferences.userName,
    );

    // ---- TEXT SEÇİMİ ----
    final String finalText = isMine
        ? (customText ?? "")
        : (affirmation?.renderWithName(userName) ?? customText ?? "");

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: showText // ⭐ YENİ - şartlı gösterim
            ? Text(
                finalText,
                textAlign: TextAlign.center,
                style: provideTextStyle(context),
              )
            : const SizedBox.shrink(), // Gizliyken boş widget
      ),
    );
  }
}
