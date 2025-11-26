import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:affirmation/state/app_state.dart';
import 'package:affirmation/l10n/app_localizations.dart';

class ContentPreferencesScreen extends StatefulWidget {
  const ContentPreferencesScreen({super.key});

  @override
  State<ContentPreferencesScreen> createState() => _ContentPreferencesScreen();
}

class _ContentPreferencesScreen extends State<ContentPreferencesScreen> {
  Set<String> selected = {};

  final prefs = [
    "self_care",
    "personal_growth",
    "stress_anxiety",
    "body_positivity",
    "happiness",
    "attracting_love",
    "confidence",
    "motivation",
    "mindfulness",
    "gratitude",
  ];

  @override
  void initState() {
    super.initState();

    // 🔥 ÖNCEKİ SEÇİMLERİ GERİ YÜKLE
    final st = context.read<AppState>();
    selected = Set<String>.from(st.preferences.selectedContentPreferences);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final st = context.read<AppState>();

    return Scaffold(
      backgroundColor: const Color(0xfff3ece7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ❌ Header (X + Title)
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 28,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    t.preferences,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              const Text(
                "✨ You can change this any time",
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 26),

              // PREMIUM GRID
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.only(bottom: 12),
                  itemCount: prefs.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 18,
                    childAspectRatio: 2.9,
                  ),
                  itemBuilder: (_, index) {
                    final item = prefs[index];
                    final isSelected = selected.contains(item);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          isSelected
                              ? selected.remove(item)
                              : selected.add(item);
                        });

                        // 🔥 STATE’E KAYDET
                        st.setSelectedContentPreferences(selected);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color:
                                isSelected ? Colors.green : Colors.transparent,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected
                                  ? Colors.green.withValues(alpha: 0.20)
                                  : Colors.black.withValues(alpha: 0.06),
                              blurRadius: isSelected ? 16 : 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _formatText(item),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatText(String id) {
    return id
        .replaceAll("_", " ")
        .split(" ")
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(" ");
  }
}
