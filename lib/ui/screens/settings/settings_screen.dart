import 'package:affirmation/l10n/app_localizations.dart';
import 'package:affirmation/ui/screens/settings/content_preferences_screen.dart';
import 'package:affirmation/ui/screens/favorites_screen.dart';
import 'package:affirmation/ui/screens/settings/language_screen.dart';
import 'package:affirmation/ui/screens/settings/name_screen.dart';
import 'package:affirmation/ui/screens/premium_screen.dart';
import 'package:affirmation/ui/screens/settings/privacy_policy_screen.dart';
import 'package:affirmation/ui/screens/settings/sound_screen.dart';
import 'package:affirmation/ui/screens/settings/terms_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../state/app_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final appState = context.watch<AppState>();
    final isPremium = appState.preferences.isPremiumValid;

    return Scaffold(
      backgroundColor: const Color(0xfff3ece7),
      appBar: AppBar(
        backgroundColor: const Color(0xfff3ece7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Settings",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
        children: [
          const SizedBox(height: 6),

          // PREMIUM CARD
          _premiumCard(
            context: context,
            title: isPremium ? "You're Premium!" : t.goPremium,
            isPremium: isPremium,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PremiumScreen()),
              );
            },
          ),

          const SizedBox(height: 20),

          // GENERAL
          _section("General"),
          _tile(
            context,
            title: t.preferences,
            icon: Icons.tune,
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ContentPreferencesScreen()));
            },
          ),
          _tile(
            context,
            title: t.language,
            icon: Icons.language,
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LanguageScreen()));
            },
          ),
          _tile(
            context,
            title: t.sound,
            icon: Icons.volume_up_rounded,
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SoundScreen()));
            },
          ),
          _tile(
            context,
            title: t.reminders,
            icon: Icons.notifications_none_rounded,
          ),

          const SizedBox(height: 20),

          // ACCOUNT
          _section("Account"),
          _tile(
            context,
            title: t.name,
            icon: Icons.person_outline_rounded,
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const NameScreen()));
            },
          ),
          _tile(
            context,
            title: t.favorites,
            icon: Icons.favorite_border,
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const FavoritesScreen()));
            },
          ),

          const SizedBox(height: 20),

          // LEGAL
          _section("About"),
          _tile(
            context,
            title: t.privacyPolicy,
            icon: Icons.description_outlined,
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PrivacyPolicyScreen()));
            },
          ),
          _tile(
            context,
            title: t.terms,
            icon: Icons.verified_user_outlined,
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const TermsScreen()));
            },
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------
  // SECTION TITLE
  // -----------------------------------------------
  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12.5,
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // -----------------------------------------------
  // PREMIUM CARD
  // -----------------------------------------------
  Widget _premiumCard({
    required BuildContext context,
    required String title,
    required bool isPremium,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 75,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: isPremium
              ? const LinearGradient(
                  colors: [Color(0xffffd700), Color(0xffffa500)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isPremium ? null : Colors.white,
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 14,
              offset: Offset(0, 5),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(
                isPremium
                    ? Icons.workspace_premium
                    : Icons.workspace_premium_outlined,
                color: isPremium ? Colors.white : Colors.amber.shade700,
                size: 26,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w600,
                    color: isPremium ? Colors.white : Colors.black,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isPremium ? Colors.white70 : Colors.grey.shade600,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -----------------------------------------------
  // TILE (GENEL AYAR KARTI)
  // -----------------------------------------------
  Widget _tile(
    BuildContext context, {
    required String title,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap ??
          () {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text("$title coming soon")));
          },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Colors.teal),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade500, size: 26),
          ],
        ),
      ),
    );
  }
}
