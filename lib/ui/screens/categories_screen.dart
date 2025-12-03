import 'package:affirmation/constants/constants.dart';
import 'package:affirmation/models/user_preferences.dart';
import 'package:affirmation/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:affirmation/state/app_state.dart';
import 'package:affirmation/l10n/app_localizations.dart';
import 'package:affirmation/ui/screens/premium_screen.dart';

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
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Transform.translate(
          offset: const Offset(-14, 0),
          child: Text(
            t.categories,
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              "✨ ${t.categoryTitle}",
              style: TextStyle(
                fontFamily: "Poppins",
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: Colors.black.withAlpha(140),
              ),
            ),
          ),
          const SizedBox(height: 14),
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
                  onTap: () {
                    if (isPremiumLocked) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PremiumScreen()),
                      );
                      return;
                    }

                    // 🔥 Sadece ID'yi güncelle, veri yükleme yapmadan
                    appState.setActiveCategoryIdOnly(category.id);
                    Navigator.pop(context);
                  },
                  child: AnimatedScale(
                    scale: isSelected ? 1.05 : 1.0,
                    duration: const Duration(milliseconds: 190),
                    curve: Curves.easeOut,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFC9A85D)
                              : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(35),
                            blurRadius: 14,
                            spreadRadius: 1,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: AssetImage(category.imageAsset),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Color(0x00000000),
                                            Color(0x33000000),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // LIMITED LABEL
                                if ((category.id ==
                                            Constants.generalCategoryId ||
                                        category.id ==
                                            Constants.favoritesCategoryId ||
                                        category.id ==
                                            Constants.myCategoryId) &&
                                    !appState.preferences.isPremiumValid)
                                  Positioned(
                                    top: 10,
                                    left: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade700,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Text(
                                        t.limited,
                                        style: TextStyle(
                                          fontFamily: "Poppins",
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),

                                // LOCKED LABEL
                                if (isPremiumLocked)
                                  Positioned(
                                    bottom: 12,
                                    left: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade700,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Text(
                                        t.unlock,
                                        style: TextStyle(
                                          fontFamily: "Poppins",
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),

                                // SELECTED CHECK
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
                                        color: Color(0xFFC9A85D),
                                        size: 22,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10.0),
                            child: Text(
                              _titleCase(
                                (localizedCategoryName(t, category.name)),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 15.5,
                                fontWeight: FontWeight.w600,
                                height: 1.25,
                                color: Colors.black.withAlpha(220),
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
