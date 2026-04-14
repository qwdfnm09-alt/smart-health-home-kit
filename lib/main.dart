import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart'; // ✅ أضفنا هذا
import 'package:firebase_crashlytics/firebase_crashlytics.dart'; // ✅ أضفنا هذا
import 'dart:ui'; // ✅ أضفنا هذا للتعامل مع Platform errors
import 'firebase_options.dart';
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
import 'screens/routine_screen.dart';
import 'screens/ai_chat_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'services/storage_service.dart';
import 'models/user_profile.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/app_theme_mode.dart';
import 'utils/animated_routes.dart';
import '../utils/logger.dart';
import 'services/notification_service.dart';
import 'services/ai_service.dart'; // ✅ أضفنا هذا
import 'screens/setup_screen.dart';


// ✅ هنا عرّف المفتاح
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 1. تهيئة Firebase باستخدام الخيارات المناسبة للمنصة
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 2. إرسال سجل بسيط لـ Firebase يوضح أن التطبيق بدأ بنجاح
    FirebaseCrashlytics.instance.log("App Started and Firebase Initialized");
    
    // التقاط جميع أخطاء Flutter (أخطاء الواجهات)
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };

    // 3. التقاط الأخطاء التي تحدث خارج إطار Flutter
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    await StorageService().init();
    AIService().init(); // ✅ تهيئة الـ AI
  } catch (e, st) {
    AppLogger.logError("❌ Initialization failed: $e", e, st);
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Initialization failed'),
          ),
        ),
      ),
    );
    return;
  }

  // حذف السطور القديمة واستخدام الـ handlers الجدد فوق
  /*
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };
  */

  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null) {
      AppLogger.logInfo("PRINT: $message");
    }
  };
  runApp(const SmartHealthApp());

  await Future.delayed(const Duration(seconds: 1)); // تأخير بسيط لضمان الواجهة اشتغلت
  await NotificationService.init();
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
    await NotificationService.checkAndNotifyNow();
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
        Future(() async => StorageService().getUserProfile()),
        StorageService().isProfileCompleted(),
        StorageService().isSetupCompleted(), // ✅ هنا
      ]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        Widget initialScreen;

        if (snapshot.connectionState == ConnectionState.waiting) {
          initialScreen = const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }  else if (snapshot.hasError) {
          initialScreen = Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        } else {
          final data = snapshot.data!;
          final UserProfile? profile = data[0] as UserProfile?;
          final bool isCompleted = data[1] as bool? ?? false;
          final bool setupCompleted = data[2] as bool? ?? false; // ✅ جبتها من snapshot.data


          if (!setupCompleted) {
            initialScreen = const SetupScreen(); // هتعمل SetupScreen جديد
          } else if (profile == null || !isCompleted) {
            initialScreen = const EditProfileScreen();
          } else {
            initialScreen = const WelcomeScreen();
          }

        }


        return MaterialApp(
          navigatorKey: navigatorKey, // ✅ هنا أضفها
          title: 'T-MED',
          debugShowCheckedModeBanner: false,
          theme:ThemeData(
          brightness: Brightness.light,
          primaryColor: Colors.teal,

          scaffoldBackgroundColor: Colors.grey[100],

          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
          ),

          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),

          iconTheme: const IconThemeData(
            color: Colors.teal,
          ),

          colorScheme: ColorScheme.light(
            primary: Colors.teal,
            secondary: Colors.tealAccent,
          ),

          textTheme: const TextTheme(
            titleLarge: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            titleMedium: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            bodyMedium: TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: Colors.teal,

            scaffoldBackgroundColor: const Color(0xFF121212),

            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
              elevation: 0,
            ),

            cardTheme: CardThemeData(
              color: const Color(0xFF1E1E1E),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),

            iconTheme: const IconThemeData(
              color: Colors.tealAccent,
            ),

            colorScheme: ColorScheme.dark(
              primary: Colors.teal,
              secondary: Colors.tealAccent,
            ),

            textTheme: const TextTheme(
              titleLarge: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              titleMedium: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              bodyMedium: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ),
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
            AppLogger.logInfo("🔗 Navigating to: ${settings.name}");
            AppLogger.logInfo("📌 Requested route: ${settings.name}");

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
              case '/routine':
                return createSlideRoute(const RoutineScreen());
              case '/ai_chat':
                return createSlideRoute(const AIChatScreen());
              case '/privacy_policy':
                return createFadeRoute(const PrivacyPolicyScreen());
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
