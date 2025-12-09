import 'package:affirmation/constants/constants.dart';
import 'package:affirmation/ui/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:affirmation/state/app_state.dart';
import 'package:affirmation/models/affirmation.dart';
import 'package:affirmation/l10n/app_localizations.dart';
import 'package:affirmation/ui/widgets/shared_blur_background.dart';
import 'package:share_plus/share_plus.dart';

//-------------------------------------------
// FAVORITES SCREEN
//-------------------------------------------
class FavoritesListScreen extends StatelessWidget {
  const FavoritesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final appState = context.watch<AppState>();

    final favorites = appState.favoritesFeed;
    final bg = appState.activeThemeImage;

    return SharedBlurBackground(
      imageAsset: bg,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leadingWidth: 40,
          leading: Padding(
            padding: const EdgeInsets.only(left: 6),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 22),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: Transform.translate(
            offset: const Offset(-8, 0),
            child: Text(
              t.favorites,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: favorites.isEmpty
              ? _buildEmpty(t)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
                  itemCount: favorites.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (_, index) {
                    final aff = favorites[index];
                    final rendered =
                        aff.renderWithName(appState.preferences.userName);

                    return _FavoriteRow(
                      affirmation: aff,
                      displayText: rendered,
                      timestamp: appState.favoriteTimestamps[aff.id],
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildEmpty(AppLocalizations t) {
    return Center(
      child: Text(
        t.favoritesEmpty,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white70,
        ),
      ),
    );
  }
}

//-------------------------------------------
// FAVORITE ROW WITH DATE BELOW TEXT
//-------------------------------------------
class _FavoriteRow extends StatelessWidget {
  final Affirmation affirmation;
  final String displayText;
  final int? timestamp;

  const _FavoriteRow({
    required this.affirmation,
    required this.displayText,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final date = timestamp != null
        ? formatFavoriteDate(DateTime.fromMillisecondsSinceEpoch(timestamp!))
        : null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final app = context.read<AppState>();
        app.setActiveCategoryIdOnly(Constants.favoritesCategoryId);

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              initialCategoryId: Constants.favoritesCategoryId,
              initialAffirmationId: affirmation.id,
            ),
          ),
          (route) => false,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.20),
            width: 1.2,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------------------------------
            // LEFT SIDE (TEXT + DATE)
            // ------------------------------
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.35,
                      fontFamily: "Poppins",
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (date != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      date,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.60),
                        fontSize: 13,
                        height: 1.2,
                        fontFamily: "Poppins",
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ]
                ],
              ),
            ),

            const SizedBox(width: 10),

            // ------------------------------
            // RIGHT SIDE BUTTONS
            // ------------------------------
            Column(
              children: [
                GestureDetector(
                  onTap: () {
                    final rendered = affirmation.renderWithName(
                      context.read<AppState>().userName ?? "",
                    );
                    Share.share(rendered);
                  },
                  child: Icon(
                    Icons.ios_share,
                    color: Colors.white.withValues(alpha: 0.85),
                    size: 22,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    context.read<AppState>().toggleFavorite(affirmation.id);
                  },
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.pinkAccent,
                    size: 24,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _monthName(int m) {
  return Constants.months[m];
}

String formatFavoriteDate(DateTime d) {
  return "${d.day.toString().padLeft(2, '0')} "
      "${_monthName(d.month)} "
      "${d.year} • "
      "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";
}
