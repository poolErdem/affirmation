import 'package:flutter/material.dart';
import '../../models/affirmation.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';

class AffirmationCard extends StatelessWidget {
  final Affirmation affirmation;

  const AffirmationCard({super.key, required this.affirmation});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final userName = appState.preferences.userName;
    final rendered = affirmation.renderWithName(userName);

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
}
