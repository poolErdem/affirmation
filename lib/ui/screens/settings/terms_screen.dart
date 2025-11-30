import 'package:affirmation/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xfff3ece7),
      appBar: AppBar(
        backgroundColor: const Color(0xfff3ece7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Transform.translate(
          offset: const Offset(-14, 0),
          child: Text(
            t.terms,
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
              _Header("1. Acceptance of Terms"),
              _Body(
                "By using the Affirmation app, you agree to these Terms & Conditions. "
                "If you do not agree, please discontinue using the application.",
              ),
              _Header("2. Use of the App"),
              _Body(
                "This app is for personal and non-commercial use. You may not copy, "
                "modify, distribute, or sell any content without permission.",
              ),
              _Header("3. User Responsibilities"),
              _Body(
                "You agree not to misuse the app, attempt to disrupt service, "
                "or engage in any harmful or illegal activity while using the app.",
              ),
              _Header("4. Premium Features"),
              _Body(
                "Certain content and themes may require a Premium subscription. "
                "Payments are handled through your app store and follow their policies.",
              ),
              _Header("5. Limitation of Liability"),
              _Body(
                "We are not responsible for emotional, psychological, or health outcomes "
                "that may result from using the app. This app is for motivational purposes only.",
              ),
              _Header("6. Updates to Terms"),
              _Body(
                "We may update these Terms & Conditions from time to time. "
                "Continued use of the app means you agree to the updated terms.",
              ),
              _Header("7. Contact Us"),
              _Body(
                "If you have any questions about these Terms, feel free to contact us.",
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
