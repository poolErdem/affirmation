import 'package:affirmation/ui/screens/onboarding/preferences_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:affirmation/state/app_state.dart';
import 'package:affirmation/l10n/app_localizations.dart';

class GenderScreen extends StatelessWidget {
  const GenderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          // ---- Background ----
          Positioned.fill(
            child: Image.asset(
              "assets/data/themes/a1.jfif",
              fit: BoxFit.cover,
            ),
          ),

          // ---- Premium Gradient ----
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xCC000000),
                    Color(0x66000000),
                    Color(0x22000000),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ),

          // ---- Content ----
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  // BACK BUTTON (icon)
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_ios_new,
                            color: Colors.white.withValues(alpha: 0.8),
                            size: 20),
                        Text(
                          "Back",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 80),

                  // TITLE
                  Center(
                    child: Text(
                      t.identifyGender,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Center(
                    child: Text(
                      "Start your journey to a more aligned you.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),

                  // ---- Buttons ----
                  _genderButton(context, "Female"),
                  const SizedBox(height: 22),

                  _genderButton(context, "Male"),
                  const SizedBox(height: 22),

                  _genderButton(context, "Non-binary / Any"),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // -----------------------------------------------------
  // PREMIUM BUTTON
  // -----------------------------------------------------
  Widget _genderButton(BuildContext context, String text) {
    return GestureDetector(
      onTap: () {
        final appState = context.read<AppState>();

        String gender = text.toLowerCase();
        if (gender.contains("non")) gender = "any";

        appState.onboardingGender = gender;

        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PreferencesScreen()),
        );
      },
      child: AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.7),
              width: 2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x55000000),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
            color: Colors.white.withValues(alpha: 0.08),
          ),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
