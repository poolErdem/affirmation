import 'dart:ui';
import 'package:affirmation/constants/constants.dart';
import 'package:affirmation/ui/screens/onboarding/onboarding_theme_screen.dart';
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
  String? _localSelected;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final fromPrefs =
        ModalRoute.of(context)?.settings.arguments == "from_prefs";

    final appState = context.read<AppState>();

    if (fromPrefs) {
      _localSelected = appState.gender;
    } else {
      appState.gender = null;
      _localSelected = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final String? selectedGender = _localSelected;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              Constants.onboardingThemePath,
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
                    onTap: () => Navigator.pop(context, "prefs"),
                    child: Text(
                      t.back,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 18,
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
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      t.genderSubtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),

                  // BUTTONS
                  _buildGenderButton(
                      context, "female", t.female, selectedGender),
                  const SizedBox(height: 20),
                  _buildGenderButton(context, "male", t.male, selectedGender),
                  const SizedBox(height: 20),
                  _buildGenderButton(
                      context, "others", t.others, selectedGender),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGenderButton(BuildContext context, String rawValue,
      String displayText, String? selectedGender) {
    final bool isSelected = selectedGender == rawValue;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _localSelected = rawValue);
      },
      onTap: () async {
        final appState = context.read<AppState>();
        await appState.setGender(rawValue); // 🔥 DOĞRU
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const OnboardingThemeScreen(),
            settings: const RouteSettings(arguments: "from_gender"),
          ),
        );
      },
      child: AnimatedScale(
        scale: isSelected ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(36),
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.05),
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.white54,
                  width: isSelected ? 2.2 : 1.6,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.25),
                          blurRadius: 14,
                          spreadRadius: 1,
                        )
                      ]
                    : [],
              ),
              child: Center(
                child: Text(
                  displayText, // 🔥 artık sadece gösterim
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
