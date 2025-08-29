import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'screens/profile_screen.dart';
import 'screens/report_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/glucose_screen.dart';
import 'screens/blood_pressure_screen.dart';
import 'screens/thermometer_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/storage_service.dart';
import 'models/user_profile.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/app_theme_mode.dart';
import 'utils/animated_routes.dart';






void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService().init();
  runApp(const SmartHealthApp());
}

class SmartHealthApp extends StatefulWidget {
  const SmartHealthApp({super.key});

  @override
  State<SmartHealthApp> createState() => _SmartHealthAppState();
}

class _SmartHealthAppState extends State<SmartHealthApp> {
  Locale? _locale;
  AppThemeMode _themeMode = AppThemeMode.light;
  bool _alertsEnabled = true;

  final _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }



  Future<void> _loadSettings() async {
    final savedTheme = await _secureStorage.read(key: 'theme');
    final savedAlerts = await _secureStorage.read(key: 'alertsEnabled');
    final savedLocale = await StorageService().getSavedLocale();

    _locale = savedLocale;
    _themeMode = savedTheme == 'dark' ? AppThemeMode.dark : AppThemeMode.light;
    _alertsEnabled = savedAlerts != 'false';

    setState(() {});
  }

  Future<void> _saveTheme(AppThemeMode mode) async {
    await _secureStorage.write(key: 'theme', value: mode.name);
  }

  Future<void> _saveAlertsEnabled(bool enabled) async {
    await _secureStorage.write(key: 'alertsEnabled', value: enabled.toString());
  }

  void _changeTheme(AppThemeMode newTheme) {
    if (newTheme == _themeMode) return; // ما يحدثش لو نفس القيمة
    setState(() {
      _themeMode = newTheme;
    });
    _saveTheme(newTheme);
  }

  void _changeLocale(Locale newLocale) {
    if (newLocale == _locale) return; // ما يحدثش لو نفس القيمة
    setState(() {
      _locale = newLocale;
    });
    StorageService().saveLocale(newLocale.languageCode);
  }

  void _changeAlertsEnabled(bool enabled) {
    setState(() {
      _alertsEnabled = enabled;
    });
    _saveAlertsEnabled(enabled);
  }



  @override
  Widget build(BuildContext context) {
    if (_locale == null) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return FutureBuilder(
      future: Future.wait([
        Future.value(StorageService().getUserProfile()),
        StorageService().isProfileCompleted(),
      ]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        Widget initialScreen;

        if (snapshot.connectionState == ConnectionState.waiting) {
          initialScreen = const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else {
          final UserProfile? profile = snapshot.data![0];
          // ignore: unused_local_variable
          final bool isCompleted = snapshot.data![1];


          if (profile == null) {
            initialScreen = const EditProfileScreen();


          } else {
            initialScreen = const  WelcomeScreen();
          }
        }

        return MaterialApp(
          title: 'Smart Health Kit',
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: _themeMode == AppThemeMode.dark ? ThemeMode.dark : ThemeMode.light,
          locale: _locale ?? const Locale('ar'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('ar'),
          ],
          localeResolutionCallback: (locale, supportedLocales) {
            if (locale == null) return supportedLocales.first;
            for (var supported in supportedLocales) {
              if (supported.languageCode == locale.languageCode) {
                return supported;
              }
            }
            return supportedLocales.first;
          },
          home: snapshot.connectionState == ConnectionState.waiting
              ? const Scaffold(body: Center(child: CircularProgressIndicator()))
              : initialScreen,
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/profile':
                return createFadeRoute(const ProfileScreen());
              case '/report':
                return createFadeRoute(const ReportScreen());
              case '/alerts':
                return createSlideRoute(const AlertsScreen());
              case '/glucose':
                return createSlideRoute(const GlucoseScreen());
              case '/bp':
                return createSlideRoute(const BloodPressureScreen());
              case '/temp':
                return createSlideRoute(const ThermometerScreen());
              case '/settings':
                return createFadeRoute(SettingsScreen(
                  onLocaleChanged: _changeLocale,
                  onThemeChanged: _changeTheme,
                  currentTheme: _themeMode,
                  alertsEnabled: _alertsEnabled,
                  onAlertsToggle: _changeAlertsEnabled,
                  initialLocale: _locale ?? const Locale('ar'),
                ));
              case '/edit_profile':
                return createFadeRoute(const EditProfileScreen());
              case '/welcome':
                return createFadeRoute(const WelcomeScreen());
              default:
                return MaterialPageRoute(
                  builder: (_) => const Scaffold(
                    body: Center(child: Text('404 - الصفحة غير موجودة')),
                  ),
                );
            }
          },
        );
      },
    );
  }
}
