import 'dart:ui';
import 'package:affirmation/ui/screens/onboarding/preferences_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:affirmation/state/app_state.dart';

class OnboardingGenderScreen extends StatelessWidget {
  const OnboardingGenderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // BACKGROUND
          Positioned.fill(
            child: Image.asset(
              "assets/data/themes/a1.jfif",
              fit: BoxFit.cover,
            ),
          ),

          // PREMIUM OVERLAY
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
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // BACK
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      "Back",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 70),

                  // TITLE
                  const Center(
                    child: Text(
                      "Identify your gender",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Center(
                    child: Text(
                      "This helps personalize your journey",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),

                  _buildGenderButton(context, "Female"),
                  const SizedBox(height: 20),

                  _buildGenderButton(context, "Male"),
                  const SizedBox(height: 20),

                  _buildGenderButton(context, "Other"),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGenderButton(BuildContext context, String text) {
    return GestureDetector(
      onTap: () {
        final appState = context.read<AppState>();
        appState.onboardingGender = text.toLowerCase();

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
              color: Colors.white.withValues(alpha: 0.15),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.45),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 12,
                )
              ],
            ),
            child: Center(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
