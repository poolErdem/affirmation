import 'dart:ui';
import 'package:affirmation/ui/screens/onboarding/onboarding_gender_screen.dart';
import 'package:affirmation/ui/widgets/glass_button.dart';
import 'package:affirmation/ui/widgets/press_effect.dart';
import 'package:flutter/material.dart';

import 'package:affirmation/l10n/app_localizations.dart';

class OnboardingNameScreen extends StatefulWidget {
  const OnboardingNameScreen({super.key});

  @override
  State<OnboardingNameScreen> createState() => _OnboardingNameScreenState();
}

class _OnboardingNameScreenState extends State<OnboardingNameScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          // BACKGROUND
          Positioned.fill(
            child: Image.asset(
              "assets/data/themes/c20.jpg",
              fit: BoxFit.cover,
            ),
          ),

          // PREMIUM GRADIENT OVERLAY
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
                      t.back,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 70),

                  // TITLE
                  Center(
                    child: Text(
                      t.nameQuestion,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Center(
                    child: Text(
                      t.personalize,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),

                  // GLASSY TEXT FIELD
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                            width: 1.4,
                          ),
                        ),
                        child: TextField(
                          controller: _controller,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: t.hitname,
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // CONTINUE BUTTON (glassy like onboarding theme)
                  Pressable(
                    child: GlassButton(
                      text: t.continueLabel,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const OnboardingGenderScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
