import 'package:affirmation/l10n/app_localizations.dart';
import 'package:affirmation/models/user_preferences.dart';
import 'package:affirmation/state/reminder_state.dart';
import 'package:affirmation/ui/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' as admob;
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'state/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await admob.MobileAds.instance.initialize();

  // ---- AppState ----
  final appState = AppState();
  await appState.initialize();

  // ---- ReminderState ----
  final reminderState = ReminderState(appState: appState);
  await reminderState.initialize(appState.preferences.isPremiumValid);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>.value(value: appState),
        ChangeNotifierProvider<ReminderState>.value(value: reminderState),
      ],
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
            "🟦 MaterialApp → BUILD with locale = ${appState.selectedLocale}");

        // AppState yüklenene kadar loading ekranı
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
          home: const HomeScreen(),
        );
      },
    );
  }
}
