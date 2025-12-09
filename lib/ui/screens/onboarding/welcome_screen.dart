import 'package:affirmation/constants/constants.dart';
import 'package:affirmation/state/app_state.dart';
import 'package:affirmation/ui/screens/onboarding/onboarding_name_screen.dart';
import 'package:affirmation/ui/widgets/glass_button.dart';
import 'package:affirmation/ui/widgets/press_effect.dart';
import 'package:flutter/material.dart';
import 'package:affirmation/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

// ==========================================================
//   WELCOME SCREEN
// ==========================================================
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();

    // Onboarding RESET – doğru yer burası
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppState>();
      appState.gender = null;
      appState.onboardingContentPrefs = {};
      appState.onboardingName = null;
      appState.onboardingThemeIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          // BACKGROUND IMAGE
          Positioned.fill(
            child: Image.asset(
              Constants.onboardingThemePath,
              fit: BoxFit.cover,
            ),
          ),

          // DARK CINEMATIC GRADIENT
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

          // CONTENT
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(),

                  // TITLE
                  Text(
                    t.welcomeTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 15),

                  Text(
                    t.welcomeSubtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 50),

                  // ⭐️⭐️⭐️ PREMIUM GLASS BUTTON + PRESS EFFECT ⭐️⭐️⭐️
                  Pressable(
                    child: GlassButton(
                      text: t.startButton,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const OnboardingNameScreen()),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // PRIVACY / TERMS TEXT
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      text: t.continueAgree,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(
                          text: t.privacyPolicy,
                          style: const TextStyle(
                            decoration: TextDecoration.underline,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(text: " ${t.and} "),
                        TextSpan(
                          text: t.termsOfUse,
                          style: const TextStyle(
                            decoration: TextDecoration.underline,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
