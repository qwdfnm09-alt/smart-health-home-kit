import 'package:flutter/material.dart';
import '../../utils/permissions_helper.dart';
import '../../utils/logger.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/storage_service.dart';
import 'package:battery_optimization_helper/battery_optimization_helper.dart';
import 'edit_profile_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen>
    with SingleTickerProviderStateMixin {
  bool _bluetoothGranted = false;
  bool _locationGranted = false;
  bool _batteryUnrestricted = false;
  bool _loading = false;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _checkAll();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _markSetupCompleted() async {
    await StorageService().setSetupCompleted(true);
  }

  Future<void> _checkAll() async {
    final bluetooth = await Permission.bluetoothScan.isGranted &&
        await Permission.bluetoothConnect.isGranted;
    final location = await Permission.locationWhenInUse.isGranted;
    final battery = await PermissionsHelper.isBatteryOptimizationDisabled();

    setState(() {
      _bluetoothGranted = bluetooth;
      _locationGranted = location;
      _batteryUnrestricted = battery;
    });

    AppLogger.logInfo(
        "Permissions → BT: $_bluetoothGranted, Location: $_locationGranted, Battery: $_batteryUnrestricted");
  }

  Future<void> _setupApp() async {
    setState(() => _loading = true);

    await PermissionsHelper.requestPermissions();
    await PermissionsHelper.requestNotificationPermission();
    await PermissionsHelper.requestDisableBatteryOptimization();

    await _checkAll();

    if (_bluetoothGranted && _locationGranted && _batteryUnrestricted) {
      await _markSetupCompleted();
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 1400), // 👈 زوّد أو قلّل
          pageBuilder: (context, animation, secondaryAnimation) =>
          const EditProfileScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final fade = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );

            final slide = Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(fade);

            return FadeTransition(
              opacity: fade,
              child: SlideTransition(
                position: slide,
                child: child,
              ),
            );
          },
        ),
      );

    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("الرجاء تفعيل كل الصلاحيات قبل المتابعة"),
        ),
      );
    }

    setState(() => _loading = false);
  }

  void _openBatterySettings() async {
    await BatteryOptimizationHelper.openBatteryOptimizationSettings();
  }

  Widget _permissionCard({
    required String title,
    required String description,
    required bool granted,
    IconData icon = Icons.security,
    Widget? action,
  }) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.grey.shade100,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                size: 28, color: granted ? Colors.green : Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(description,
                      style: TextStyle(
                          fontSize: 14, color: Colors.grey.shade700)),
                  if (action != null) ...[
                    const SizedBox(height: 8),
                    action,
                  ]
                ],
              ),
            ),
            Icon(granted ? Icons.check_circle : Icons.cancel,
                color: granted ? Colors.green : Colors.red),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تهيئة التطبيق")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "علشان التطبيق يشتغل بكفاءة، محتاج شوية صلاحيات بسيطة 👇",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),

            _permissionCard(
              title: "Bluetooth",
              description:
              "نستخدم البلوتوث للاتصال بأجهزة القياس الطبية وقراءة البيانات تلقائيًا.",
              granted: _bluetoothGranted,
              icon: Icons.bluetooth,
            ),

            _permissionCard(
              title: "Location",
              description:
              "مطلوب من أندرويد لتشغيل البلوتوث بشكل صحيح (ولا يتم تتبع موقعك).",
              granted: _locationGranted,
              icon: Icons.location_on,
            ),

            _permissionCard(
              title: "Battery Optimization",
              description:
              "لمنع النظام من إيقاف التطبيق أثناء الاتصال بالأجهزة في الخلفية.",
              granted: _batteryUnrestricted,
              icon: Icons.battery_full,
              action: !_batteryUnrestricted
                  ? TextButton(
                onPressed: _openBatterySettings,
                child: const Text("افتح الإعدادات"),
              )
                  : null,
            ),

            const SizedBox(height: 30),

            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _setupApp,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 14)),
              child: const Text("بدء استخدام التطبيق"),
            ),
          ],
        ),
      ),
    );
  }
}
