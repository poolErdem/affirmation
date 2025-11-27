import 'package:affirmation/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xfff3ece7),
      appBar: AppBar(
        backgroundColor: const Color(0xfff3ece7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Transform.translate(
          offset: const Offset(-14, 0),
          child: Text(
            t.privacyPolicy,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Last Updated: November 2025",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              SizedBox(height: 20),
              _Header("1. Introduction"),
              _Body(
                "We value your privacy. This Privacy Policy explains how we collect, "
                "use, and protect your information when you use the Affirmation app.",
              ),
              _Header("2. Information We Collect"),
              _Body(
                "• Name (optional)\n"
                "• Preferences and selected categories\n"
                "• Favorite affirmations\n"
                "• App usage analytics (anonymous)\n"
                "• Local storage data for caching",
              ),
              _Header("3. How We Use Your Information"),
              _Body(
                "We use your information only to personalize your experience, "
                "improve the app, and store your selections.",
              ),
              _Header("4. Data Storage"),
              _Body(
                "All user settings and preferences are stored locally on your device. "
                "We do not upload, share, or sell your personal data.",
              ),
              _Header("5. Third-Party Services"),
              _Body(
                "We may use third-party services (such as analytics or ads) but none "
                "of them collect personally identifiable information.",
              ),
              _Header("6. Contact Us"),
              _Body(
                "If you have any questions regarding this Privacy Policy, feel free to contact us.",
              ),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final String text;
  const _Body(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        height: 1.45,
        color: Colors.black87,
      ),
    );
  }
}
