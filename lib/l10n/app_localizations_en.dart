// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'T-MED';

  @override
  String get homeTitle => 'Smart Health Devices';

  @override
  String get glucoseMonitor => 'Glucose Monitor';

  @override
  String get bloodPressureMonitor => 'Blood Pressure Monitor';

  @override
  String get thermometer => 'Thermometer';

  @override
  String get startScan => 'Start scanning for devices';

  @override
  String get stopScan => 'Stop scanning';

  @override
  String get viewAlerts => 'View Alerts';

  @override
  String get generateReport => 'Generate Report';

  @override
  String get profile => 'Profile';

  @override
  String get profilePage => 'Profile Page';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get healthReportTitle => 'Health Report';

  @override
  String get noDataToGenerateReport => 'Not enough data to generate report';

  @override
  String get reportGeneratedSuccessfully => 'Report generated successfully!';

  @override
  String get errorGeneratingReport => 'Error generating report';

  @override
  String get healthAlerts => 'Health Alerts';

  @override
  String get noAlerts => 'No alerts available at the moment.';

  @override
  String get glucoseDevice => 'Glucose Meter';

  @override
  String get latestReading => '🩸 Latest Reading';

  @override
  String get noReading => 'No reading yet.';

  @override
  String get chart => '📈 Chart';

  @override
  String get autoConnection =>
      'Device auto-connect and data is being received.';

  @override
  String get smartAlertEnabled => 'Smart alert is enabled for abnormal values.';

  @override
  String get notEnoughData => 'Not enough data to display the chart.';

  @override
  String atTime(Object hour, Object minute) {
    return 'at $hour:$minute';
  }

  @override
  String get bloodPressureDevice => 'Blood Pressure Monitor';

  @override
  String get lastReading => 'Last Reading';

  @override
  String get at => 'at';

  @override
  String get thermometerDevice => 'Thermometer';

  @override
  String get unknownDevice => 'Unknown Device';

  @override
  String get smartDevices => 'Smart Devices';

  @override
  String get age => 'Age';

  @override
  String get gender => 'Gender';

  @override
  String get healthConditions => 'Health Conditions';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get save => 'Save';

  @override
  String get profileSavedSuccessfully => 'Profile saved successfully!';

  @override
  String get profileCreatedSuccessfully => 'Profile created successfully!';

  @override
  String get profileUpdatedSuccessfully => 'Profile updated successfully!';

  @override
  String get welcomeMessage => '🎉 تم إنشاء ملفك بنجاح!';

  @override
  String get startUsing => 'ابدأ الاستخدام';

  @override
  String get startUsage => 'Start using the app';

  @override
  String get theme => 'Theme';

  @override
  String get resetAppData => 'Reset App Data';

  @override
  String get userData => 'User Data';

  @override
  String get confirmResetTitle => 'Are you sure?';

  @override
  String get confirmResetMessage =>
      'This will delete all your data. This action cannot be undone.';

  @override
  String get confirm => 'Confirm';

  @override
  String get cancel => 'Cancel';

  @override
  String get fontSize => 'Font Size';

  @override
  String get enableAlerts => 'Enable Alerts';

  @override
  String get availableDevices => 'Available Devices';

  @override
  String get enableDataEncryption => 'Enable Data Encryption';

  @override
  String get noDataToDisplay => 'No data to display';

  @override
  String get outOfRangeWarning => ' Needs follow-up';

  @override
  String get withinNormalRange => ' normal ';

  @override
  String get recentReadings => 'Recent Readings';

  @override
  String get viewAll => 'View All';

  @override
  String get done => 'Done';

  @override
  String get noDevicesFound => 'No devices found';

  @override
  String get reconnect => 'Reconnect';

  @override
  String get reportGenerated => 'Report generated successfully';

  @override
  String get alerts => 'Alerts';

  @override
  String get charts => 'Charts';

  @override
  String get alertDeleted => 'Alert deleted';

  @override
  String get healthadvices => 'Health advices';

  @override
  String get dailyroutine => 'Daily routine';

  @override
  String get aiConsultant => 'AI Consultant';

  @override
  String get yourhealthconditiontoday => 'Wellness Made Simple';

  @override
  String get presstostart => 'Tab to start';

  @override
  String get services => 'Smart Services';

  @override
  String get styleofadvice => 'Style Of Advice';

  @override
  String get bloodpressure => 'Blood Pressure';

  @override
  String get temperature => 'Temperature';

  @override
  String get glucose => 'Glucose';
}
