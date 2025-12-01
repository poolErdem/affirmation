import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('tr')
  ];

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your path to inner clarity starts here.'**
  String get welcomeSubtitle;

  /// No description provided for @startButton.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startButton;

  /// No description provided for @continueAgree.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our'**
  String get continueAgree;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsOfUse;

  /// No description provided for @and.
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get and;

  /// No description provided for @nameQuestion.
  ///
  /// In en, this message translates to:
  /// **'What’s your name?'**
  String get nameQuestion;

  /// No description provided for @personalize.
  ///
  /// In en, this message translates to:
  /// **'We\'ll personalize your affirmations'**
  String get personalize;

  /// No description provided for @hitname.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get hitname;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @goPremium.
  ///
  /// In en, this message translates to:
  /// **'Go Premium'**
  String get goPremium;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Content Preferences'**
  String get preferences;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @themes.
  ///
  /// In en, this message translates to:
  /// **'Themes'**
  String get themes;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @sound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get sound;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get terms;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @languageDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose the language you want to use in the app.\nYour entire experience will adapt instantly.'**
  String get languageDescription;

  /// No description provided for @genderDescription.
  ///
  /// In en, this message translates to:
  /// **'We’ll personalize the experience based on your preference.'**
  String get genderDescription;

  /// No description provided for @nameDescription.
  ///
  /// In en, this message translates to:
  /// **'Your name helps us personalize your affirmations.'**
  String get nameDescription;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Continue button text
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @identifyGender.
  ///
  /// In en, this message translates to:
  /// **'Identify your gender'**
  String get identifyGender;

  /// No description provided for @genderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This helps personalize your journey'**
  String get genderSubtitle;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @others.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get others;

  /// No description provided for @choosePreferences.
  ///
  /// In en, this message translates to:
  /// **'Which areas of your life do you want to improve?'**
  String get choosePreferences;

  /// No description provided for @youCanChangeLater.
  ///
  /// In en, this message translates to:
  /// **'You can change this anytime'**
  String get youCanChangeLater;

  /// No description provided for @pleasePrefs.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one preference.'**
  String get pleasePrefs;

  /// No description provided for @yourNamePersonalize.
  ///
  /// In en, this message translates to:
  /// **'Your name is used to personalize your affirmations'**
  String get yourNamePersonalize;

  /// No description provided for @typeYourName.
  ///
  /// In en, this message translates to:
  /// **'Type your name...'**
  String get typeYourName;

  /// No description provided for @nameSaved.
  ///
  /// In en, this message translates to:
  /// **'Name saved'**
  String get nameSaved;

  /// No description provided for @pickTheme.
  ///
  /// In en, this message translates to:
  /// **'Pick a theme'**
  String get pickTheme;

  /// No description provided for @changeLater.
  ///
  /// In en, this message translates to:
  /// **'You can change it later'**
  String get changeLater;

  /// No description provided for @pleaseSelectTheme.
  ///
  /// In en, this message translates to:
  /// **'Please select a theme first.'**
  String get pleaseSelectTheme;

  /// No description provided for @reminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminderTitle;

  /// No description provided for @reminderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stay consistent with gentle daily reminders.'**
  String get reminderSubtitle;

  /// No description provided for @addReminder.
  ///
  /// In en, this message translates to:
  /// **'Add Reminder'**
  String get addReminder;

  /// No description provided for @editReminder.
  ///
  /// In en, this message translates to:
  /// **'Edit Reminder'**
  String get editReminder;

  /// No description provided for @deleteReminder.
  ///
  /// In en, this message translates to:
  /// **'Delete Reminder'**
  String get deleteReminder;

  /// No description provided for @freeLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You’ve reached your free reminder limit.'**
  String get freeLimitReached;

  /// No description provided for @premiumUnlockMore.
  ///
  /// In en, this message translates to:
  /// **'Unlock Premium to add up to 5 reminders.'**
  String get premiumUnlockMore;

  /// No description provided for @unlockMore.
  ///
  /// In en, this message translates to:
  /// **'Unlock more reminders'**
  String get unlockMore;

  /// No description provided for @reminderCategory.
  ///
  /// In en, this message translates to:
  /// **'Affirmation Category'**
  String get reminderCategory;

  /// No description provided for @reminderTimes.
  ///
  /// In en, this message translates to:
  /// **'Times'**
  String get reminderTimes;

  /// No description provided for @reminderStartTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get reminderStartTime;

  /// No description provided for @reminderEndTime.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get reminderEndTime;

  /// No description provided for @reminderRepeatCount.
  ///
  /// In en, this message translates to:
  /// **'Repeat Count'**
  String get reminderRepeatCount;

  /// No description provided for @reminderRepeatDays.
  ///
  /// In en, this message translates to:
  /// **'Repeat Days'**
  String get reminderRepeatDays;

  /// No description provided for @reminderEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get reminderEnabled;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select a category...'**
  String get selectCategory;

  /// No description provided for @premiumCategoryLocked.
  ///
  /// In en, this message translates to:
  /// **'This category is available in Premium.'**
  String get premiumCategoryLocked;

  /// No description provided for @onlySelfCareAvailable.
  ///
  /// In en, this message translates to:
  /// **'Only the Self Care category is available in the free plan.'**
  String get onlySelfCareAvailable;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select a time'**
  String get selectTime;

  /// No description provided for @startBeforeEnd.
  ///
  /// In en, this message translates to:
  /// **'Start time must be before end time.'**
  String get startBeforeEnd;

  /// No description provided for @selectDays.
  ///
  /// In en, this message translates to:
  /// **'Select days'**
  String get selectDays;

  /// No description provided for @mon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mon;

  /// No description provided for @tue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tue;

  /// No description provided for @wed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wed;

  /// No description provided for @thu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thu;

  /// No description provided for @fri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get fri;

  /// No description provided for @sat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get sat;

  /// No description provided for @sun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sun;

  /// No description provided for @repeatTimesPerDay.
  ///
  /// In en, this message translates to:
  /// **'Times per day'**
  String get repeatTimesPerDay;

  /// No description provided for @maxRepeatReached.
  ///
  /// In en, this message translates to:
  /// **'Maximum repeat count reached'**
  String get maxRepeatReached;

  /// No description provided for @minRepeatReached.
  ///
  /// In en, this message translates to:
  /// **'Minimum repeat count reached'**
  String get minRepeatReached;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete reminder?'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This reminder will be removed permanently.'**
  String get deleteConfirmMessage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @noRemindersYet.
  ///
  /// In en, this message translates to:
  /// **'No reminders yet'**
  String get noRemindersYet;

  /// No description provided for @tapToAddReminder.
  ///
  /// In en, this message translates to:
  /// **'Tap the button below to add your first reminder.'**
  String get tapToAddReminder;

  /// No description provided for @freeReminderBadge.
  ///
  /// In en, this message translates to:
  /// **'Free Reminder'**
  String get freeReminderBadge;

  /// No description provided for @reminderLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached your reminder limit.'**
  String get reminderLimitReached;

  /// No description provided for @unlockMoreReminders.
  ///
  /// In en, this message translates to:
  /// **'Unlock more reminders'**
  String get unlockMoreReminders;

  /// No description provided for @reminderFreeOnlyCategory.
  ///
  /// In en, this message translates to:
  /// **'Free users can only use the Self-Care category.'**
  String get reminderFreeOnlyCategory;

  /// No description provided for @reminderPremiumRequired.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium to add more reminders.'**
  String get reminderPremiumRequired;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en', 'es', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'tr': return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
