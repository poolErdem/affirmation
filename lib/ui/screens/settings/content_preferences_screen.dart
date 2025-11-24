import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../state/app_state.dart';

class ContentPreferencesScreen extends StatelessWidget {
  const ContentPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final selectedPrefs = appState.preferences.selectedContentPreferences;

    final allPrefs = [
      "self_care",
      "personal_growth",
      "stress_anxiety",
      "body_positivity",
      "happiness",
      "attracting_love",
      "confidence",
      "motivation",
      "mindfulness",
      "gratitude",
    ];

    return Scaffold(
      backgroundColor: const Color(0xfff3ece7),
      appBar: AppBar(
        backgroundColor: const Color(0xfff3ece7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Content Preferences",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          const SizedBox(height: 4),
          const Text(
            "What areas of your life would you like to improve?",
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
              height: 1.35,
            ),
          ),

          const SizedBox(height: 22),

          // 🔥 MODERN CHIP GRID (Category / Theme style)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: allPrefs.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 2.7,
            ),
            itemBuilder: (_, index) {
              final pref = allPrefs[index];
              final isSelected = selectedPrefs.contains(pref);
              return _modernChip(context, pref, isSelected);
            },
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------
  // MODERN CHIP (CREAMY + PREMIUM STYLE)
  // -----------------------------------------------------
  Widget _modernChip(BuildContext context, String pref, bool isSelected) {
    final appState = context.read<AppState>();

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        final updated = Set<String>.from(
          appState.preferences.selectedContentPreferences,
        );

        isSelected ? updated.remove(pref) : updated.add(pref);

        appState.setSelectedContentPreferences(updated);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: isSelected ? const Color(0xFF2E7D32) : Colors.white,
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isSelected ? const Color(0xFF1B5E20) : Colors.transparent,
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          _label(pref),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.black87,
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // LABEL
  String _label(String pref) {
    switch (pref) {
      case "self_care":
        return "Self Care";
      case "personal_growth":
        return "Personal Growth";
      case "stress_anxiety":
        return "Stress & Anxiety";
      case "body_positivity":
        return "Body Positivity";
      case "happiness":
        return "Happiness";
      case "attracting_love":
        return "Attracting Love";
      case "confidence":
        return "Confidence";
      case "motivation":
        return "Motivation";
      case "mindfulness":
        return "Mindfulness";
      case "gratitude":
        return "Gratitude";
      default:
        return pref;
    }
  }
}
