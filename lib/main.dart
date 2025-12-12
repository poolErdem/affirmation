import 'package:affirmation/l10n/app_localizations.dart';
import 'package:affirmation/state/my_affirmation_state.dart';
import 'package:affirmation/state/reminder_state.dart';
import 'package:affirmation/ui/screens/home_screen.dart';
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
  final normalized = normalizeTimeZone(deviceTzName);

  tz.setLocalLocation(tz.getLocation(normalized));

  final myAffirmationState = MyAffirmationState();
  await myAffirmationState.initialize();

  final appState = AppState();
  await appState.initialize();

  final reminderState = ReminderState(appState: appState);
  await reminderState.initialize();

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
      home: //appState.onboardingCompleted
          // ? const HomeScreen()
          const WelcomeScreen(),
    );
  }
}
