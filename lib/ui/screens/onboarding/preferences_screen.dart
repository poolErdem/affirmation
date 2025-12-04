import 'package:affirmation/constants/constants.dart';
import 'package:affirmation/state/app_state.dart';
import 'package:affirmation/ui/screens/onboarding/welcome_last_screen.dart';
import 'package:affirmation/ui/widgets/glass_button.dart';
import 'package:affirmation/ui/widgets/press_effect.dart';
import 'package:flutter/material.dart';
import 'package:affirmation/l10n/app_localizations.dart';
import 'package:affirmation/utils/utils.dart';
import 'package:provider/provider.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final Set<String> selected = {};

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final prefs = Constants.allCategories;

    return Scaffold(
      body: Stack(
        children: [
          // BACKGROUND
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
                    Colors.black45,
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
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  // Back
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

                  const SizedBox(height: 35),

                  // TITLE
                  Center(
                    child: Text(
                      t.choosePreferences,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      t.youCanChangeLater,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // GRID
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.only(bottom: 95),
                      itemCount: prefs.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 20,
                        childAspectRatio: 2.9,
                      ),
                      itemBuilder: (context, index) {
                        final item = prefs[index]; // "self_care"
                        final isSelected =
                            selected.contains(item); // doğru selection kontrolü
                        final text =
                            localizedCategoryName(t, item); // localized label

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              isSelected
                                  ? selected.remove(item)
                                  : selected.add(item);
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOut,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.55),
                                width: isSelected ? 2.2 : 1.6,
                              ),
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : Colors.white.withValues(alpha: 0.05),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Colors.white
                                            .withValues(alpha: 0.25),
                                        blurRadius: 14,
                                        spreadRadius: 1,
                                      )
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: Text(
                                text,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // ⭐️⭐️⭐️ PREMIUM GLASS BUTTON + PRESS EFFECT ⭐️⭐️⭐️
                  Pressable(
                    child: GlassButton(
                      text: t.continueLabel,
                      onTap: () async {
                        final st = context.read<AppState>();

                        await st.setSelectedContentPreferences(selected);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const WelcomeLastScreen()),
                        );
                      },
                    ),
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
