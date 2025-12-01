import 'package:affirmation/ui/screens/onboarding/welcome_last_screen.dart';
import 'package:affirmation/ui/widgets/glass_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:affirmation/state/app_state.dart';
import 'package:affirmation/ui/screens/home_screen.dart';
import 'package:affirmation/l10n/app_localizations.dart';

class OnboardingThemeScreen extends StatefulWidget {
  const OnboardingThemeScreen({super.key});

  @override
  State<OnboardingThemeScreen> createState() => _OnboardingThemeScreenState();
}

class _OnboardingThemeScreenState extends State<OnboardingThemeScreen> {
  int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final themes = appState.themes;
    final t = AppLocalizations.of(context)!;

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

          // PREMIUM GRADIENT
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
                  const SizedBox(height: 18),

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

                  const SizedBox(height: 40),

                  // TITLE
                  Center(
                    child: Text(
                      t.pickTheme,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Center(
                    child: Text(
                      t.changeLater,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // GRID
                  Expanded(
                    child: GridView.builder(
                      itemCount: themes.length,
                      padding: const EdgeInsets.only(bottom: 20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 22,
                        childAspectRatio: 0.62,
                      ),
                      itemBuilder: (context, index) {
                        final theme = themes[index];
                        final isSelected = selectedIndex == index;

                        return GestureDetector(
                          onTap: () => setState(() => selectedIndex = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.25),
                                width: isSelected ? 2.2 : 1.4,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Colors.white.withValues(
                                          alpha: 0.25,
                                        ),
                                        blurRadius: 18,
                                        spreadRadius: 2,
                                      )
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.35,
                                        ),
                                        blurRadius: 12,
                                        spreadRadius: 1,
                                      )
                                    ],
                            ),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.asset(
                                    theme.imageAsset,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),

                                // GRADIENT ON CARD
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Colors.black54,
                                        Colors.transparent,
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                  ),
                                ),

                                // SELECTED CHECK
                                if (isSelected)
                                  const Positioned(
                                    top: 8,
                                    right: 8,
                                    child: CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.white,
                                      child: Icon(Icons.check,
                                          size: 18, color: Colors.black),
                                    ),
                                  ),

                                // GROUP LABEL
                                Positioned(
                                  bottom: 10,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Text(
                                      theme.group.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black,
                                            blurRadius: 6,
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // CONTINUE BUTTON (GLASS)
                  GlassButton(
                    text: t.continueLabel,
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);

                      if (selectedIndex == null) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(t.pleaseSelectTheme),
                          ),
                        );
                        return;
                      }

                      final st = Provider.of<AppState>(context, listen: false);
                      st.onboardingThemeIndex = selectedIndex;

                      await st.saveOnboardingData();
                      if (!mounted) return;

                      navigator.pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (_) => const WelcomeLastScreen()),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
