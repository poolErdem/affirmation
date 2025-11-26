import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:affirmation/state/app_state.dart';
import 'package:affirmation/l10n/app_localizations.dart';
import 'package:affirmation/ui/screens/premium_screen.dart';
import 'package:affirmation/models/user_preferences.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final categories = appState.categories;
    final activeId = appState.activeCategoryId;
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xfff5f2ee),
      appBar: AppBar(
        backgroundColor: const Color(0xfff5f2ee),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          t.categories,
          style: const TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: false,
      ),

      /// 🔥 TAGLINE (premium vibe)
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              "✨ Choose the energy you want to feel today",
              style: TextStyle(
                fontFamily: "Poppins",
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: Colors.black.withValues(alpha: 0.55),
              ),
            ),
          ),
          const SizedBox(height: 14),

          /// GRID
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              itemCount: categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 18,
                crossAxisSpacing: 18,
                childAspectRatio: 0.78,
              ),
              itemBuilder: (_, index) {
                final category = categories[index];
                final isSelected = category.id == activeId;
                final isPremiumLocked = category.isPremiumLocked &&
                    !appState.preferences.isPremiumValid;

                return GestureDetector(
                  onTap: () async {
                    if (isPremiumLocked) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PremiumScreen()),
                      );
                      return;
                    }
                    await appState.setActiveCategory(category.id);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: AnimatedScale(
                    scale: isSelected ? 1.03 : 1.0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: Colors.white,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF40916C)
                              : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 12,
                            spreadRadius: 1,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: Stack(
                              children: [
                                /// CATEGORY IMAGE
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(18),
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: AssetImage(category.imageAsset),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.transparent,
                                            Colors.black
                                                .withValues(alpha: 0.28),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                /// 🔒 LOCKED BADGE — premium görünüm
                                if (isPremiumLocked)
                                  Positioned(
                                    bottom: 10,
                                    left: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade700,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        "UNLOCK",
                                        style: TextStyle(
                                          fontFamily: "Poppins",
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),

                                /// SELECTED BADGE
                                if (isSelected)
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check_circle,
                                        color: Color(0xFF2D6A4F),
                                        size: 22,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          /// CATEGORY NAME
                          const SizedBox(height: 10),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10.0),
                            child: Text(
                              _titleCase(category.name),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 15.5,
                                fontWeight: FontWeight.w600,
                                height: 1.25,
                                color: Colors.black.withValues(alpha: 0.85),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _titleCase(String text) {
    if (text.isEmpty) return text;
    return text
        .split(" ")
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(" ");
  }
}
