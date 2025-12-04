import 'package:affirmation/l10n/app_localizations.dart';
import 'package:affirmation/models/user_preferences.dart';
import 'package:affirmation/state/my_affirmation_state.dart';
import 'package:affirmation/state/reminder_state.dart';
import 'package:affirmation/ui/screens/onboarding/welcome_screen.dart';
import 'package:affirmation/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'state/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();

  final deviceTzName = DateTime.now().timeZoneName;
  print("📌 MAIN → Device timezone name: $deviceTzName");

  final normalized = normalizeTimeZone(deviceTzName);
  print("📌 MAIN → Normalized timezone: $normalized");

  tz.setLocalLocation(tz.getLocation(normalized));
  print("🌍 MAIN → Local timezone set edildi: ${tz.local}");

  //await admob.MobileAds.instance.initialize();
  //print("✅ MAIN → AdMob hazır.");

  final myAffirmationState = MyAffirmationState();
  await myAffirmationState.initialize();
  print("✅ MAIN → MyAffirmationState initialize bitti.");

  final appState = AppState();
  await appState.initialize();
  print("✅ MAIN → AppState initialize bitti.");

  final reminderState = ReminderState(appState: appState);
  await reminderState.initialize(appState.preferences.isPremiumValid);
  print("✅ MAIN → ReminderState initialize tamam!");

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: myAffirmationState),
        ChangeNotifierProvider.value(value: appState),
        ChangeNotifierProvider.value(value: reminderState),
      ],
      child: const AffirmationApp(),
    ),
  );
}

class AffirmationApp extends StatelessWidget {
  const AffirmationApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final myAffState = context.watch<MyAffirmationState>();
    final reminderState = context.watch<ReminderState>();

    print("🟦 MaterialApp → BUILD with locale = ${appState.selectedLocale}");

    final allLoaded =
        appState.isLoaded && myAffState.isLoaded && reminderState.isLoaded;

    if (!allLoaded) {
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
      home: const WelcomeScreen(),
    );
  }
}
