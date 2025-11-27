import 'package:affirmation/l10n/app_localizations.dart';
import 'package:affirmation/ui/screens/settings/content_preferences_screen.dart';
import 'package:affirmation/ui/screens/settings/language_screen.dart';
import 'package:affirmation/ui/screens/settings/name_screen.dart';
import 'package:affirmation/ui/screens/premium_screen.dart';
import 'package:affirmation/ui/screens/settings/privacy_policy_screen.dart';
import 'package:affirmation/ui/screens/settings/reminder_screen.dart';
import 'package:affirmation/ui/screens/settings/sound_screen.dart';
import 'package:affirmation/ui/screens/settings/terms_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../state/app_state.dart';
import 'package:affirmation/models/user_preferences.dart';

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
        title: Transform.translate(
          offset: const Offset(-14, 0),
          child: Text(
            t.settings,
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
          _section(t.general),

          _tile(
            context,
            title: t.name,
            icon: Icons.person_outline_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NameScreen()),
              );
            },
          ),

          _tile(
            context,
            title: t.preferences,
            icon: Icons.tune,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ContentPreferencesScreen(),
                ),
              );
            },
          ),

          _tile(
            context,
            title: t.language,
            icon: Icons.language,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LanguageScreen()),
              );
            },
          ),

          _tile(
            context,
            title: t.reminders,
            icon: Icons.notifications_none_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RemindersScreen()),
              );
            },
          ),

          _tile(
            context,
            title: t.sound,
            icon: Icons.volume_up_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SoundScreen()),
              );
            },
          ),

          // LEGAL
          _section(t.about),
          _tile(
            context,
            title: t.privacyPolicy,
            icon: Icons.description_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
              );
            },
          ),
          _tile(
            context,
            title: t.terms,
            icon: Icons.verified_user_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TermsScreen()),
              );
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 95,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: AssetImage(
              isPremium
                  ? "assets/premium/gold_bg.jpg" // premium arka plan
                  : "assets/premium/premium_offer.jpg", // upgrade arka plan
            ),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: isPremium
                  ? Colors.amber.withAlpha(140)
                  : Colors.black.withAlpha(60),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: isPremium ? const Color(0xFFFFD700) : Colors.black12,
            width: isPremium ? 2 : 1,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                Colors.black.withAlpha(120),
                Colors.black.withAlpha(20),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Row(
            children: [
              // ICON
              Icon(
                Icons.workspace_premium,
                color: Colors.white,
                size: 30,
              ),

              const SizedBox(width: 18),

              // TEXT
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.1,
                  ),
                ),
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
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("$title coming soon")));
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
            Icon(
              icon, size: 24, color: const Color.fromARGB(255, 58, 54, 54),
              weight: 100, // ⭐ 100 → ultra ince, 700 → kalın
              grade: -75, // (-25) daha ince görünüm
              opticalSize: 10, // simgenin optik boyutu
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color.fromARGB(255, 58, 54, 54),
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
