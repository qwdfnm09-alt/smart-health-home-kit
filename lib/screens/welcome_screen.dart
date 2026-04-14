import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../l10n/app_localizations.dart';
import 'home_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _bgOpacity = 0;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _showSuccessMessage = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      _navigateOnce();
    });


    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward();



    // ظهور الخلفية تدريجياً
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _bgOpacity = 1;
      });
    });

    _checkProfileCreated();
  }



  Future<void> _checkProfileCreated() async {
    String? created = await _secureStorage.read(key: 'profileCreated');
    if (created == 'true') {
      setState(() {
        _showSuccessMessage = true;
      });
      await _secureStorage.delete(key: 'profileCreated');
    }
  }

  void _navigateOnce() {
    if (_hasNavigated) return;

    _hasNavigated = true;
    _goToHome();
  }

  void _goToHome() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.2, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeIn,
              ),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
                child: child,
              ),
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 900), // مدة الحركة
      ),
    );
  }




  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [

          // 🟢 1. Fade Animation للصورة (تظهر تدريجي)


          AnimatedOpacity(
            opacity:  _bgOpacity,
            duration: const Duration(seconds: 2),
            curve: Curves.easeInOut,
            child: Image.asset(
              'assets/images/app_logo.png',
              fit: BoxFit.cover,
            ),
          ),



      Column(
        children: [

          // 🟢 مسافة فوق علشان نوصل لمكان اللوجو
          const Spacer(flex: 5),

          // 🟢 الزرار تحت كلمة T-MED مباشرة
          ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.05).animate(
              CurvedAnimation(
                parent: _controller,
                curve: Curves.easeInOut,
              ),
            ),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.home),
              label: Text(
                _showSuccessMessage
                    ? "🎉 ${t.profileCreatedSuccessfully}"
                    : t.startUsage,
                textAlign: TextAlign.center,
              ),
              onPressed: () async {
                await Future.delayed(const Duration(milliseconds: 300));
                _navigateOnce();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 20,
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 10,
              ),
            ),
          ),

          // 🟢 مسافة تحت
          const Spacer(flex: 2),
        ],
      ),
      ]),
    );
  }
}
