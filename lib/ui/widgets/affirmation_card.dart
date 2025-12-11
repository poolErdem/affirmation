import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/affirmation.dart';
import '../../state/app_state.dart';

class AffirmationCard extends StatelessWidget {
  final Affirmation? affirmation;

  const AffirmationCard({
    super.key,
    this.affirmation,
  });

  @override
  Widget build(BuildContext context) {
    final userName = context.select<AppState, String>(
      (s) => s.preferences.userName,
    );

    // ---- TEXT SEÇİMİ ----
    final String finalText = affirmation?.renderWithName(userName) ?? "";

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Text(
          finalText,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    height: 1.4,
                  ) ??
              const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
        ),
      ),
    );
  }
}
