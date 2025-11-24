import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:affirmation/state/app_state.dart';
import 'package:affirmation/ui/screens/premium_screen.dart';
import 'package:affirmation/models/theme_model.dart';
import 'package:affirmation/l10n/app_localizations.dart';

class ThemeScreen extends StatefulWidget {
  const ThemeScreen({super.key});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  String selectedGroup = "All";

  final groups = ["All", "Light", "Dark", "Colorful", "Abstract"];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final themes = appState.themes;
    final t = AppLocalizations.of(context)!;

    final filteredThemes = selectedGroup == "All"
        ? themes
        : themes.where((th) => th.group == selectedGroup).toList();

    return Scaffold(
      backgroundColor: const Color(0xfff3ece7),
      appBar: AppBar(
        backgroundColor: const Color(0xfff3ece7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Transform.translate(
          offset: const Offset(-14, 0),
          child: Text(
            t.themes,
            style: const TextStyle(
              fontFamily: "Poppins",
              color: Colors.black,
              fontSize: 21,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),

      /// BODY
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TAGLINE
          Padding(
            padding: const EdgeInsets.only(left: 18, right: 18, top: 4),
            child: Text(
              "✨ Customize the mood of your experience",
              style: TextStyle(
                fontFamily: "Poppins",
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: Colors.black.withValues(alpha: 0.55),
              ),
            ),
          ),

          const SizedBox(height: 16),

          /// GROUP TABS
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: groups.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final g = groups[i];
                final isSelected = g == selectedGroup;

                return GestureDetector(
                  onTap: () => setState(() => selectedGroup = g),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.green
                          : Colors.white.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.10),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : null,
                    ),
                    child: Text(
                      g,
                      style: TextStyle(
                        fontFamily: "Poppins",
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 14),

          /// THEMES GRID
          Expanded(child: _buildGrid(filteredThemes, appState)),
        ],
      ),
    );
  }

  Widget _buildGrid(List<ThemeModel> list, AppState appState) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.70,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemBuilder: (_, index) {
        final item = list[index];
        final isPremium =
            item.isPremiumLocked && !appState.preferences.isPremiumValid;
        final isSelected = item.id == appState.preferences.selectedThemeId;

        return GestureDetector(
          onTap: () {
            if (isPremium) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PremiumScreen()),
              );
              return;
            }

            appState.setSelectedTheme(item.id);
            Navigator.pop(context);
          },
          child: AnimatedScale(
            scale: isSelected ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 160),
            child: Stack(
              children: [
                /// CARD BACKGROUND
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? Colors.green
                          : isPremium
                              ? Colors.amber.shade600
                              : Colors.transparent,
                      width: isSelected || isPremium ? 2 : 0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.07),
                        blurRadius: 12,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    image: DecorationImage(
                      image: AssetImage(item.imageAsset),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0x00000000),
                          Color(0x33000000),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),

                /// PREMIUM LOCK
                if (isPremium)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(
                      Icons.lock,
                      color: Colors.amber.shade600,
                      size: 22,
                    ),
                  ),

                /// SELECTED CHECK
                if (isSelected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 22,
                      ),
                    ),
                  ),

                /// GROUP LABEL
                Center(
                  child: Text(
                    item.group,
                    style: const TextStyle(
                      fontFamily: "Poppins",
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
