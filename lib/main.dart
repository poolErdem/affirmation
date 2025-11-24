import 'package:affirmation/l10n/app_localizations.dart';
import 'package:affirmation/ui/screens/onboarding/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' as admob;
import 'package:provider/provider.dart';

// Localization
import 'package:flutter_localizations/flutter_localizations.dart';

import 'state/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ads init
  await admob.MobileAds.instance.initialize();

  // ---- EN KRİTİK NOKTA ----
  // AppState'i önce oluşturup initialize çağırıyoruz
  final appState = AppState();
  await appState.initialize(); // 🔥 loading burada bitiyor
  appState.initializePurchaseListener(); // 🔥 ekstra listener

  runApp(
    ChangeNotifierProvider<AppState>.value(
      value: appState, // 🔥 aynı instance veriyoruz
      child: const AffirmationApp(),
    ),
  );
}

class AffirmationApp extends StatelessWidget {
  const AffirmationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        print(
            "🟦 MaterialApp → BUILD with locale = ${appState.preferences.languageCode}");

        // AppState tamamen load edilmeden UI çizmesin
        if (!appState.isLoaded) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          );
        }

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Affirmation',
          theme: ThemeData(
            brightness: Brightness.dark,
            useMaterial3: true,
            fontFamily: 'Roboto',
          ),

          // ⭐️ DİL SEÇİMİ
          locale: Locale(appState.selectedLocale),

          supportedLocales: const [
            Locale('en'),
            Locale('tr'),
            Locale('es'),
            Locale('de'),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          //home: appState.onboardingCompleted
          //  ? const HomeScreen()
          //  : const WelcomeScreen(),
          home: const WelcomeScreen(),
        );
      },
    );
  }
}
