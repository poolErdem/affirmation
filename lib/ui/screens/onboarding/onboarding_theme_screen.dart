import 'package:affirmation/constants/constants.dart';
import 'package:affirmation/ui/screens/onboarding/onboarding_preferences_screen.dart';
import 'package:affirmation/ui/widgets/glass_button.dart';
import 'package:affirmation/ui/widgets/press_effect.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:affirmation/state/app_state.dart';
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
          // BACKGROUND IMAGE
          Positioned.fill(
            child: Image.asset(
              Constants.onboardingThemePath,
              fit: BoxFit.cover,
            ),
          ),

          // PREMIUM DARK GRADIENT
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

                  // BACK BUTTON
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      t.back,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // TITLE
                  Center(
                    child: Text(
                      t.pickTheme,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),

                  Center(
                    child: Text(
                      t.changeLater,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 15,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // THEMES GRID
                  Expanded(
                    child: GridView.builder(
                      itemCount: themes.length,

                      // 🔥 Boşluk oluşturan kritik kısım
                      padding: const EdgeInsets.only(bottom: 60),

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
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),

                              // Soft-blue selection border
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFAEE5FF)
                                    : Colors.white.withValues(alpha: 0.25),
                                width: isSelected ? 2.4 : 1.3,
                              ),

                              // Glow
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFFAEE5FF)
                                            .withValues(alpha: 0.45),
                                        blurRadius: 18,
                                        spreadRadius: 2,
                                      )
                                    ]
                                  : [],
                            ),
                            child: Stack(
                              children: [
                                // Theme Image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.asset(
                                    theme.imageAsset,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),

                                // SOFT GRADIENT
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0x55000000),
                                        Color(0x00000000),
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                  ),
                                ),

                                // SELECT CHECKMARK
                                if (isSelected)
                                  const Positioned(
                                    top: 8,
                                    right: 8,
                                    child: CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Color(0xFFAEE5FF),
                                      child: Icon(
                                        Icons.check,
                                        size: 18,
                                        color: Colors.black,
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

                  // ⭐ CONTINUE BUTTON — artık nefes alıyor
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Pressable(
                      child: GlassButton(
                        text: t.continueLabel,
                        onTap: () async {
                          final st = context.read<AppState>();

                          if (selectedIndex == null) {
                            await st.setSelectedTheme("c2");
                          } else {
                            final selectedTheme = st.themes[selectedIndex!];
                            await st.setSelectedTheme(selectedTheme.id);
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const OnboardingPreferencesScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 42),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
