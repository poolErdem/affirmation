import 'dart:ui';
import 'package:affirmation/ui/screens/onboarding/preferences_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:affirmation/state/app_state.dart';
import 'package:affirmation/l10n/app_localizations.dart';

class OnboardingGenderScreen extends StatefulWidget {
  const OnboardingGenderScreen({super.key});

  @override
  State<OnboardingGenderScreen> createState() => _OnboardingGenderScreenState();
}

class _OnboardingGenderScreenState extends State<OnboardingGenderScreen> {
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final appState = context.watch<AppState>();

    // AppState’ten seçili gender
    final String? selectedGender = appState.gender;
    print("Onboarding gender: $selectedGender");

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              "assets/data/themes/a1.jfif",
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black87,
                    Colors.black54,
                    Colors.black26,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      t.back,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 70),
                  Center(
                    child: Text(
                      t.identifyGender,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      t.genderSubtitle,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                  _buildGenderButton(context, "female", selectedGender),
                  const SizedBox(height: 20),
                  _buildGenderButton(context, "male", selectedGender),
                  const SizedBox(height: 20),
                  _buildGenderButton(context, "other", selectedGender),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGenderButton(
      BuildContext context, String genderKey, String? selectedGender) {
    final bool isSelected = selectedGender == genderKey;

    final displayText = genderKey[0].toUpperCase() + genderKey.substring(1);

    return GestureDetector(
      onTap: () {
        final appState = context.read<AppState>();
        appState.gender = genderKey; // kaydet
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const PreferencesScreen(),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              color: isSelected
                  ? const Color.fromARGB(60, 255, 255, 255)
                  : const Color.fromARGB(38, 255, 255, 255),
              border: Border.all(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.45),
                width: isSelected ? 2.6 : 1.8,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.25),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: Center(
              child: Text(
                displayText,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  shadows: isSelected
                      ? [
                          const Shadow(
                            color: Colors.black54,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          )
                        ]
                      : [],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
