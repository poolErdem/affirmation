import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    // 🔥 Artık favoriler ALL AFFIRMATIONS içinden alınacak
    // Çünkü ALL AFFIRMATIONS tüm kategorilerin birleşimi
    final favIds = appState.preferences.favoriteAffirmationIds;
    final all = appState.allAffirmations; // tüm kategori jsonlarının birleşimi
    final list = all.where((a) => favIds.contains(a.id)).toList();

    return Scaffold(
      backgroundColor: const Color(0xfff3ece7),
      appBar: AppBar(
        backgroundColor: const Color(0xfff3ece7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Favorites",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
      body: list.isEmpty
          ? const Center(
              child: Text(
                "No favorites yet.",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: list.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 32, color: Colors.black12),
              itemBuilder: (context, index) {
                final aff = list[index];

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            aff.text,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xff1c355b),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Saved",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.more_vert, color: Colors.teal),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
