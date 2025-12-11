import 'dart:math';
import 'package:affirmation/constants/constants.dart';
import 'package:affirmation/state/app_state.dart';
import 'package:affirmation/ui/screens/onboarding/welcome_last_screen.dart';
import 'package:affirmation/ui/widgets/glass_button.dart';
import 'package:affirmation/ui/widgets/press_effect.dart';
import 'package:flutter/material.dart';
import 'package:affirmation/l10n/app_localizations.dart';
import 'package:affirmation/utils/utils.dart';
import 'package:provider/provider.dart';

class OnboardingPreferencesScreen extends StatefulWidget {
  const OnboardingPreferencesScreen({super.key});

  @override
  State<OnboardingPreferencesScreen> createState() =>
      _OnboardingPreferencesScreenState();
}

class _OnboardingPreferencesScreenState
    extends State<OnboardingPreferencesScreen>
    with SingleTickerProviderStateMixin {
  final Set<String> selected = {};

  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _triggerCuteShake() {
    _shakeController.forward(from: 0);
  }

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

          // GRADIENT
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

                  // BACK
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

                  const SizedBox(height: 30),

                  Center(
                    child: Text(
                      t.choosePreferences,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Center(
                    child: Text(
                      t.youCanChangeLater,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                  ),

                  const SizedBox(height: 39),

                  // ⭐ CUTE SHAKE GRID ⭐
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _shakeController,
                      builder: (context, _) {
                        final progress = Curves.easeInOutCubic
                            .transform(_shakeController.value);

                        return GridView.builder(
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
                            final item = prefs[index];
                            final isSelected = selected.contains(item);
                            final text = localizedCategoryName(t, item);

                            // 🍬 Sevimli micro-bounce amplitüdü
                            const double amp = 1.1;

                            // Her kutu farklı fazla oynuyor → doğal görünüm
                            final double phase = index * 0.9;

                            // X ve Y mikro hareket
                            final dx = sin(progress * 22 + phase) * amp;
                            final dy = cos(progress * 26 + phase) * amp;

                            return Transform.translate(
                              offset: _shakeController.isAnimating
                                  ? Offset(dx, dy)
                                  : Offset.zero,
                              child: GestureDetector(
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
                                          : Colors.white
                                              .withValues(alpha: 0.55),
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
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // CONTINUE BUTTON
                  Pressable(
                    child: GlassButton(
                      text: t.continueLabel,
                      onTap: () async {
                        final st = context.read<AppState>();

                        if (selected.isEmpty) {
                          _triggerCuteShake();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(t.selectThemeWarning),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );

                          return;
                        }

                        await st.setSelectedContentPreferences(selected);
                        await st.completeOnboarding();

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const WelcomeLastScreen()),
                        );
                      },
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
