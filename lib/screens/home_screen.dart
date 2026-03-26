import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/ble_service.dart';
import '../l10n/app_localizations.dart';
import '../utils/animated_routes.dart';
import 'profile_screen.dart';
import 'report_screen.dart';
import 'alerts_screen.dart';
import '../services/storage_service.dart';
import '../utils/helper.dart';
import '../utils/constants.dart';
import '../models/health_data.dart';
import '../utils/logger.dart';
import 'charts_screen.dart';
import 'package:share_plus/share_plus.dart';
import '../services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'advice_screen.dart';






class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});




  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final BleService _bleService = BleService();
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;

  late AnimationController _controller;
  double _backgroundOpacity = 0.0;


  Future<void> _checkPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.8),
              color,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }



  @override
  void initState() {
    super.initState();
    checkDailyUsage();
    _checkPermissions(); // ✅ طلب أذونات البلوتوث والموقع


    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      setState(() {
        _backgroundOpacity = 1.0;
      });
    });
  }

  void _startScan() async {
    try {
    setState(() {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content:Text('جاري البحث عن الأجهزة...')),
      );
      _scanResults = [];
      _isScanning = true;
    });
    _bleService.scanForDevices(timeout: const Duration(seconds: 8)).listen((results) {
      setState(() {
        _scanResults = results;
      });
    }).onDone(() {
      setState(() {
        _isScanning = false;
      });
      _bleService.stopScan(); // إضافة هذا السطر
    });
    } catch (e) {
      setState(() => _isScanning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر بدء المسح: $e')),
      );
    }
  }


  void _stopScan() {
    _bleService.stopScan();
    setState(() {
      _isScanning = false;
    });

  }


  void _connectToDevice(BluetoothDevice device) async {
    try {
      String serviceUuid = "";
      String notifyCharUuid = "";

      if (device.platformName.contains("Samico")) {
        serviceUuid = "fff0";
        notifyCharUuid = "fff4";
      } else if (device.platformName.contains("BPM")) {
        serviceUuid = "fff0";
        notifyCharUuid = "fff4"; // أو fff6
      } else if (device.platformName.contains("TEMP")) {
        serviceUuid = "1809";
        notifyCharUuid = "2a1c";
      }

      await _bleService.connectToDevice(
        device,
        serviceUuid: serviceUuid,
        notifyCharUuid: notifyCharUuid,
      );

      if (mounted) {
        String route;
        if (device.platformName.contains("BP")) {
          route = '/bp';
        } else if (device.platformName.contains("Samico")) {
          route = '/glucose';
        } else if (device.platformName.contains("TEMP")) {
          route = '/temp';
        } else {
          route = '/'; // أو صفحة Error
        }

        Navigator.pushNamed(
          context,
          route,
          arguments: device.platformName,
        );
      }

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل الاتصال بالجهاز: $e')),
      );
    }
  }



  @override
  void dispose() {
    _scanResults.clear(); // تفريغ النتائج القديمة
    _controller.dispose();
    _bleService.stopScan();
    super.dispose();
  }



  Future<void> checkDailyUsage() async {
    final box = StorageService().getAllHealthData();
    final today = DateTime.now();
    bool hasTodayReading = box.any((data) =>
    data.timestamp.year == today.year &&
        data.timestamp.month == today.month &&
        data.timestamp.day == today.day);

    if (!hasTodayReading) {
      await NotificationService.showReminderNotification();
    }
  }

  Widget _buildSmartDeviceCard({
    required IconData icon,
    required String title,
    required List<Color> colors,
    required VoidCallback onTap,
    required AppLocalizations t, // ✅ ضيف دي
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: colors,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.last.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // 🔥 Icon كبير
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),

            const SizedBox(width: 16),

            // 🔥 النص
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.presstostart,
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            // 🔥 سهم
            const Icon(Icons.arrow_forward_ios, color: Colors.white),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyMedium?.color,

        title:Row(
          children: const [
            Icon(Icons.health_and_safety, color: Colors.teal),
            SizedBox(width: 8),
            Text(
              "T-MED",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 25,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(context, createFadeRoute(const ProfileScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => Navigator.push(context, createSlideRoute(const AlertsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),// 📌 هنا ضيف الزر الجديد
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isScanning)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: CircularProgressIndicator(color: Colors.teal),
            ),
          FloatingActionButton(
            onPressed: _isScanning ? _stopScan : _startScan,
            child: Icon(_isScanning ? Icons.stop : Icons.search),
          ),
        ],
      ),

      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedOpacity(
            opacity: _backgroundOpacity,
            duration: const Duration(seconds: 1),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: Theme.of(context).scaffoldBackgroundColor)
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 31),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      gradient: LinearGradient(
                        colors: [
                          Colors.blueGrey.shade800,
                          Colors.teal.shade700,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // 🔥 صورة الأجهزة فوق
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(25),
                            topRight: Radius.circular(25),
                          ),
                          child: Image.asset(
                            "assets/images/devices.png", // 👈 غيرها باسم صورتك
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),

                        // 🔥 المحتوى
                        Padding(
                          padding: const EdgeInsets.all(1),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center, // يحرك كل العناصر للوسط
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // 🔥 أيقونة
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.favorite,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),

                              const SizedBox(width: 0),

                              // 🔥 النص

                                 Text(
                                  t.yourhealthconditiontoday,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                 )],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: StorageService().healthDataBox.listenable(),
                    builder: (context, box, _) {
                      final healthData = box.values.cast<HealthData>().toList();

                      // هنا بنجيب آخر قراءة لكل نوع
                      final latestGlucose = StorageService().getLatestByType(DataTypes.glucose);
                      final latestTemp = StorageService().getLatestByType(DataTypes.temp);
                      final latestBp = StorageService().getLatestByType(DataTypes.bp);
                      AppLogger.logInfo("🔎 Latest types -> glucose: ${latestGlucose?.type}, temp: ${latestTemp?.type}, bp: ${latestBp?.type}");


                      final latestList = [
                        if (latestGlucose != null) latestGlucose,
                        if (latestTemp != null) latestTemp,
                        if (latestBp != null) latestBp,
                      ];

                      return ListView(
                        children: <Widget>[
                          const SizedBox(height: 12),
                          if (healthData.isNotEmpty) ...[
                            Text(
                              t.recentReadings,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),

                            ...latestList.map((data) {
                              final displayText = Helper.formatDisplayText(data);
                              // ✅ نجمع كل الـ thresholds (سكر + حرارة + ضغط)
                              final Map<String, dynamic> allThresholds = {
                                ...Constants.alertThresholds,
                                ...Constants.bpThresholds,
                              };

                              // ✅ نتحقق لو القيمة خارج النطاق لأي نوع (بما فيهم الضغط)
                              final isOut = Helper.isOutOfRangeByType(
                                data.type,
                                data.value,
                                allThresholds,
                                data: data, // مهم علشان الـ BP فيه systolic/diastolic
                              );

                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    colors: isOut ? [
                                      Colors.red.shade900,
                                      Colors.red.shade600
                                      ,]
                                        : [
                                      Colors.teal.shade400,
                                      Colors.teal.shade700,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isOut ? Colors.red : Colors.teal).withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      data.type == DataTypes.bp
                                          ? Icons.favorite
                                          : data.type == DataTypes.glucose
                                          ? Icons.bloodtype
                                          : Icons.thermostat,
                                      color: Colors.white, // ✅ أبيض
                                      size: 28,
                                    ),

                                    const SizedBox(width: 12),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            displayText,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white, // ✅ أبيض
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            isOut
                                                ? "⚠ ${t.outOfRangeWarning}"
                                                : "✅ ${t.withinNormalRange}",
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.white70, // ✅ أبيض شفاف
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    IconButton(
                                      icon: const Icon(Icons.share, color: Colors.white),
                                      onPressed: () {
                                        Share.share("📊 $displayText");
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => Navigator.push(context, createFadeRoute(const ReportScreen())),
                                child: Text(t.viewAll),
                              ),
                            ),
                          ],
                          Text(
                            t.smartDevices,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),

                          _buildSmartDeviceCard(
                            icon: Icons.bloodtype,
                            title: t.glucoseDevice,
                            colors: [
                              Colors.blueGrey.shade800,
                              Colors.red.shade700,
                            ],
                            t: t,
                            onTap: () async {
                              final updated = await Navigator.pushNamed(context, '/glucose');
                              if (updated == true) setState(() {});
                            },
                          ),

                          _buildSmartDeviceCard(
                            icon: Icons.favorite,
                            title: t.bloodPressureDevice,
                            colors: [
                              Colors.blueGrey.shade800,
                              Colors.blue.shade700,
                            ],
                            t: t,
                            onTap: () async {
                              final updated = await Navigator.pushNamed(context, '/bp');
                              if (updated == true) setState(() {});
                            },
                          ),

                          _buildSmartDeviceCard(
                            icon: Icons.thermostat,
                            title: t.thermometerDevice,
                            colors: [
                              Colors.blueGrey.shade800,
                              Colors.orange.shade700,
                            ],
                            t: t,
                            onTap: () async {
                              final updated = await Navigator.pushNamed(context, '/temp');
                              if (updated == true) setState(() {});
                            },
                          ), const SizedBox(height: 20),
                          Text(
                            t.services,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            children: [
                              _buildActionCard(
                                icon: Icons.warning,
                                title: t.viewAlerts,
                                color:Colors.blueGrey.shade800,
                                onTap: () {
                                  Navigator.push(context, createSlideRoute(const AlertsScreen()));
                                  },
                              ),
                              _buildActionCard(
                                icon: Icons.picture_as_pdf,
                                title: t.generateReport,
                                color:Colors.blueGrey.shade800,
                                onTap: () {
                                  Navigator.push(context, createFadeRoute(const ReportScreen()));
                                  },
                              ),
                              _buildActionCard(
                                icon: Icons.show_chart,
                                title: t.charts,
                                color:Colors.blueGrey.shade800,
                                onTap: () {
                                  Navigator.push(context, createSlideRoute(const ChartsScreen()));
                                  },
                              ),
                              _buildActionCard(
                                icon: Icons.health_and_safety,
                                title: t.healthadvices,
                                color: Colors.blueGrey.shade800,
                                onTap: () {
                                  Navigator.push(context, createSlideRoute(const AdviceScreen()));
                                  },
                              ),
                            ],
                      ), // ✅ مهم جدًا القوس ده
                          const SizedBox(height: 16),
                          Text(
                            t.availableDevices,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 200,
                            child: RefreshIndicator(
                              onRefresh: () async {
                                if (_isScanning) _stopScan();
                                _startScan();
                              },
                              child: Builder(
                                builder: (context) {
                                  final filteredResults = _scanResults
                                      .where((r) => r.device.platformName.isNotEmpty)
                                      .toList();

                                  return filteredResults.isEmpty
                                      ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.bluetooth_disabled, size: 50, color: Colors.grey),
                                        const SizedBox(height: 10),
                                        Text(t.noDevicesFound),
                                      ],
                                    ),
                                  )
                                      : ListView.builder(
                                    itemCount: filteredResults.length,
                                    itemBuilder: (context, index) {
                                      final result = filteredResults[index];
                                      final device = result.device;
                                      return Card(
                                        child: ListTile(
                                          title: Text(device.platformName),
                                          subtitle: Text(device.remoteId.str),
                                          trailing: const Icon(Icons.bluetooth),
                                          onTap: () => _connectToDevice(device),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                       ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



