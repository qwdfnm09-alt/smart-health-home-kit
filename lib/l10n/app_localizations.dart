import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

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
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'T-MED'**
  String get appTitle;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart Health Devices'**
  String get homeTitle;

  /// No description provided for @glucoseMonitor.
  ///
  /// In en, this message translates to:
  /// **'Glucose Monitor'**
  String get glucoseMonitor;

  /// No description provided for @bloodPressureMonitor.
  ///
  /// In en, this message translates to:
  /// **'Blood Pressure Monitor'**
  String get bloodPressureMonitor;

  /// No description provided for @thermometer.
  ///
  /// In en, this message translates to:
  /// **'Thermometer'**
  String get thermometer;

  /// No description provided for @startScan.
  ///
  /// In en, this message translates to:
  /// **'Start scanning for devices'**
  String get startScan;

  /// No description provided for @stopScan.
  ///
  /// In en, this message translates to:
  /// **'Stop scanning'**
  String get stopScan;

  /// No description provided for @viewAlerts.
  ///
  /// In en, this message translates to:
  /// **'View Alerts'**
  String get viewAlerts;

  /// No description provided for @generateReport.
  ///
  /// In en, this message translates to:
  /// **'Generate Report'**
  String get generateReport;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @profilePage.
  ///
  /// In en, this message translates to:
  /// **'Profile Page'**
  String get profilePage;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @healthReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Health Report'**
  String get healthReportTitle;

  /// No description provided for @noDataToGenerateReport.
  ///
  /// In en, this message translates to:
  /// **'Not enough data to generate report'**
  String get noDataToGenerateReport;

  /// No description provided for @reportGeneratedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Report generated successfully!'**
  String get reportGeneratedSuccessfully;

  /// No description provided for @errorGeneratingReport.
  ///
  /// In en, this message translates to:
  /// **'Error generating report'**
  String get errorGeneratingReport;

  /// No description provided for @healthAlerts.
  ///
  /// In en, this message translates to:
  /// **'Health Alerts'**
  String get healthAlerts;

  /// No description provided for @noAlerts.
  ///
  /// In en, this message translates to:
  /// **'No alerts available at the moment.'**
  String get noAlerts;

  /// No description provided for @glucoseDevice.
  ///
  /// In en, this message translates to:
  /// **'Glucose Meter'**
  String get glucoseDevice;

  /// No description provided for @latestReading.
  ///
  /// In en, this message translates to:
  /// **'🩸 Latest Reading'**
  String get latestReading;

  /// No description provided for @noReading.
  ///
  /// In en, this message translates to:
  /// **'No reading yet.'**
  String get noReading;

  /// No description provided for @chart.
  ///
  /// In en, this message translates to:
  /// **'📈 Chart'**
  String get chart;

  /// No description provided for @autoConnection.
  ///
  /// In en, this message translates to:
  /// **'Device auto-connect and data is being received.'**
  String get autoConnection;

  /// No description provided for @smartAlertEnabled.
  ///
  /// In en, this message translates to:
  /// **'Smart alert is enabled for abnormal values.'**
  String get smartAlertEnabled;

  /// No description provided for @notEnoughData.
  ///
  /// In en, this message translates to:
  /// **'Not enough data to display the chart.'**
  String get notEnoughData;

  /// No description provided for @atTime.
  ///
  /// In en, this message translates to:
  /// **'at {hour}:{minute}'**
  String atTime(Object hour, Object minute);

  /// No description provided for @bloodPressureDevice.
  ///
  /// In en, this message translates to:
  /// **'Blood Pressure Monitor'**
  String get bloodPressureDevice;

  /// No description provided for @lastReading.
  ///
  /// In en, this message translates to:
  /// **'Last Reading'**
  String get lastReading;

  /// No description provided for @at.
  ///
  /// In en, this message translates to:
  /// **'at'**
  String get at;

  /// No description provided for @thermometerDevice.
  ///
  /// In en, this message translates to:
  /// **'Thermometer'**
  String get thermometerDevice;

  /// No description provided for @unknownDevice.
  ///
  /// In en, this message translates to:
  /// **'Unknown Device'**
  String get unknownDevice;

  /// No description provided for @smartDevices.
  ///
  /// In en, this message translates to:
  /// **'Smart Devices'**
  String get smartDevices;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @healthConditions.
  ///
  /// In en, this message translates to:
  /// **'Health Conditions'**
  String get healthConditions;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @profileSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile saved successfully!'**
  String get profileSavedSuccessfully;

  /// No description provided for @profileCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile created successfully!'**
  String get profileCreatedSuccessfully;

  /// No description provided for @profileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profileUpdatedSuccessfully;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'🎉 تم إنشاء ملفك بنجاح!'**
  String get welcomeMessage;

  /// No description provided for @startUsing.
  ///
  /// In en, this message translates to:
  /// **'ابدأ الاستخدام'**
  String get startUsing;

  /// No description provided for @startUsage.
  ///
  /// In en, this message translates to:
  /// **'Start using the app'**
  String get startUsage;

  /// Label for the app theme setting
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @resetAppData.
  ///
  /// In en, this message translates to:
  /// **'Reset App Data'**
  String get resetAppData;

  /// No description provided for @userData.
  ///
  /// In en, this message translates to:
  /// **'User Data'**
  String get userData;

  /// No description provided for @confirmResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get confirmResetTitle;

  /// No description provided for @confirmResetMessage.
  ///
  /// In en, this message translates to:
  /// **'This will delete all your data. This action cannot be undone.'**
  String get confirmResetMessage;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get fontSize;

  /// No description provided for @enableAlerts.
  ///
  /// In en, this message translates to:
  /// **'Enable Alerts'**
  String get enableAlerts;

  /// No description provided for @availableDevices.
  ///
  /// In en, this message translates to:
  /// **'Available Devices'**
  String get availableDevices;

  /// No description provided for @enableDataEncryption.
  ///
  /// In en, this message translates to:
  /// **'Enable Data Encryption'**
  String get enableDataEncryption;

  /// No description provided for @noDataToDisplay.
  ///
  /// In en, this message translates to:
  /// **'No data to display'**
  String get noDataToDisplay;

  /// No description provided for @outOfRangeWarning.
  ///
  /// In en, this message translates to:
  /// **' Needs follow-up'**
  String get outOfRangeWarning;

  /// No description provided for @withinNormalRange.
  ///
  /// In en, this message translates to:
  /// **' normal '**
  String get withinNormalRange;

  /// No description provided for @recentReadings.
  ///
  /// In en, this message translates to:
  /// **'Recent Readings'**
  String get recentReadings;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @noDevicesFound.
  ///
  /// In en, this message translates to:
  /// **'No devices found'**
  String get noDevicesFound;

  /// No description provided for @reconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get reconnect;

  /// No description provided for @reportGenerated.
  ///
  /// In en, this message translates to:
  /// **'Report generated successfully'**
  String get reportGenerated;

  /// No description provided for @alerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alerts;

  /// No description provided for @charts.
  ///
  /// In en, this message translates to:
  /// **'Charts'**
  String get charts;

  /// No description provided for @alertDeleted.
  ///
  /// In en, this message translates to:
  /// **'Alert deleted'**
  String get alertDeleted;

  /// No description provided for @healthadvices.
  ///
  /// In en, this message translates to:
  /// **'Health advices'**
  String get healthadvices;

  /// No description provided for @dailyroutine.
  ///
  /// In en, this message translates to:
  /// **'Daily routine'**
  String get dailyroutine;

  /// No description provided for @yourhealthconditiontoday.
  ///
  /// In en, this message translates to:
  /// **'Wellness Made Simple'**
  String get yourhealthconditiontoday;

  /// No description provided for @presstostart.
  ///
  /// In en, this message translates to:
  /// **'Tab to start'**
  String get presstostart;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Smart Services'**
  String get services;

  /// No description provided for @styleofadvice.
  ///
  /// In en, this message translates to:
  /// **'Style Of Advice'**
  String get styleofadvice;

  /// No description provided for @bloodpressure.
  ///
  /// In en, this message translates to:
  /// **'Blood Pressure'**
  String get bloodpressure;

  /// No description provided for @temperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// No description provided for @glucose.
  ///
  /// In en, this message translates to:
  /// **'Glucose'**
  String get glucose;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
