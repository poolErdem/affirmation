import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/affirmation.dart';
import '../../state/app_state.dart';

class AffirmationCard extends StatelessWidget {
  final Affirmation? affirmation; // normal affirmation
  final String? customText; // my-affirmation text
  final bool isMine; // my-affirmation flag

  const AffirmationCard({
    super.key,
    this.affirmation,
    this.customText,
    this.isMine = false,
  });

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final userName = appState.preferences.userName;

    // ------------------------------------------
    // NORMAL Affirmation (JSON’dan gelen)
    // ------------------------------------------
    if (!isMine) {
      final rendered = affirmation!.renderWithName(userName);
      final textTheme = Theme.of(context).textTheme;

      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            rendered,
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              height: 1.4,
            ),
          ),
        ),
      );
    }

    // ------------------------------------------
    // MY AFFIRMATION (kullanıcının eklediği)
    // ------------------------------------------
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Text(
          customText ?? "",
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
