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
import 'charts_screen.dart';
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

  Future<void> _checkPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  @override
  void initState() {
    super.initState();
    _checkPermissions();

    // ✅ Listen to BLE Errors (like Bluetooth is OFF)
    _bleService.errors.listen((message) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: "إغلاق",
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  void _startScan() async {
    try {
      setState(() {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('جاري البحث عن الأجهزة...')),
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
        _bleService.stopScan();
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
        notifyCharUuid = "fff4";
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
        if (device.platformName.contains("BPM")) {
          route = '/bp';
        } else if (device.platformName.contains("Samico")) {
          route = '/glucose';
        } else if (device.platformName.contains("TEMP")) {
          route = '/temp';
        } else {
          route = '/';
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
    _scanResults.clear();
    _controller.dispose();
    _bleService.stopScan();
    super.dispose();
  }

  String _getGreeting(AppLocalizations t) {
    final hour = DateTime.now().hour;
    final userProfile = StorageService().getUserProfile();
    final userName = userProfile?.name;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    String timeGreeting;
    if (hour < 12) {
      timeGreeting = isArabic ? "صباح الخير" : "Good Morning";
    } else if (hour < 17) {
      timeGreeting = isArabic ? "طاب يومك" : "Good Day";
    } else {
      timeGreeting = isArabic ? "مساء الخير" : "Good Evening";
    }

    if (userName != null && userName.isNotEmpty) {
      return isArabic ? "أهلاً يا $userName، $timeGreeting" : "Hello $userName, $timeGreeting";
    }
    return timeGreeting;
  }

  Widget _buildSectionTitle(String title, {VoidCallback? onSeeAll, String? seeAllText}) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
          if (onSeeAll != null)
            InkWell(
              onTap: onSeeAll,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  seeAllText ?? (Localizations.localeOf(context).languageCode == 'ar' ? "الكل" : "See All"),
                  style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReadingCard(HealthData data, AppLocalizations t) {
    final displayText = Helper.formatDisplayText(data);
    final isOut = Helper.isOutOfRangeByType(
      data.type,
      data.value,
      {...Constants.alertThresholds, ...Constants.bpThresholds},
      data: data,
    );

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isOut
              ? [Colors.red.shade400, Colors.red.shade800]
              : [Colors.teal.shade400, Colors.teal.shade800],
        ),
        boxShadow: [
          BoxShadow(
            color: (isOut ? Colors.red : Colors.teal).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(
              data.type == DataTypes.bp
                  ? Icons.favorite
                  : data.type == DataTypes.glucose
                      ? Icons.bloodtype
                      : Icons.thermostat,
              color: Colors.white.withValues(alpha: 0.1),
              size: 80,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      data.type == DataTypes.bp
                          ? Icons.favorite
                          : data.type == DataTypes.glucose
                              ? Icons.bloodtype
                              : Icons.thermostat,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  Text(
                    isOut ? "⚠" : "✅",
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                displayText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isOut ? t.outOfRangeWarning : t.withinNormalRange,
                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmartDeviceCard({
    required IconData icon,
    required String title,
    required List<Color> colors,
    required VoidCallback onTap,
    required AppLocalizations t,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: colors.last.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t.presstostart,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 18),
          ],
        ),
      ),
    );
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
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.teal.shade800,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    "assets/images/devices.png",
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.1),
                          Colors.teal.shade900.withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _isScanning ? Colors.orange : Colors.greenAccent,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_isScanning ? Colors.orange : Colors.greenAccent).withValues(alpha: 0.5),
                                      blurRadius: 5,
                                      spreadRadius: 2,
                                    )
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isScanning 
                                  ? (isArabic ? "جاري البحث..." : "Scanning...") 
                                  : (isArabic ? "البلوتوث نشط" : "Bluetooth Active"),
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _getGreeting(t),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            shadows: const [Shadow(color: Colors.black45, blurRadius: 4)],
                          ),
                        ),
                        Text(
                          t.yourhealthconditiontoday,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            shadows: [Shadow(color: Colors.black45, blurRadius: 8)],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              centerTitle: false,
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.notifications_outlined, color: Colors.white),
                ),
                onPressed: () => Navigator.push(context, createSlideRoute(const AlertsScreen())),
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.person_outline, color: Colors.white),
                ),
                onPressed: () => Navigator.push(context, createFadeRoute(const ProfileScreen())),
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: ValueListenableBuilder(
              valueListenable: StorageService().healthDataBox.listenable(),
              builder: (context, box, _) {
                final latestGlucose = StorageService().getLatestByType(DataTypes.glucose);
                final latestTemp = StorageService().getLatestByType(DataTypes.temp);
                final latestBp = StorageService().getLatestByType(DataTypes.bp);
                final latestList = [
                  if (latestGlucose != null) latestGlucose,
                  if (latestTemp != null) latestTemp,
                  if (latestBp != null) latestBp,
                ];

                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (latestList.isNotEmpty) ...[
                        _buildSectionTitle(t.recentReadings,
                            onSeeAll: () => Navigator.push(context, createFadeRoute(const ReportScreen())),
                            seeAllText: t.viewAll),
                        SizedBox(
                          height: 180,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: latestList.length,
                            itemBuilder: (context, index) => _buildReadingCard(latestList[index], t),
                          ),
                        ),
                      ],
                      _buildSectionTitle(t.smartDevices),
                      _buildSmartDeviceCard(
                        icon: Icons.bloodtype,
                        title: t.glucoseDevice,
                        colors: [Colors.blueGrey.shade800, Colors.red.shade700],
                        t: t,
                        onTap: () async {
                          final updated = await Navigator.pushNamed(context, '/glucose');
                          if (updated == true) setState(() {});
                        },
                      ),
                      _buildSmartDeviceCard(
                        icon: Icons.favorite,
                        title: t.bloodPressureDevice,
                        colors: [Colors.blueGrey.shade800, Colors.blue.shade700],
                        t: t,
                        onTap: () async {
                          final updated = await Navigator.pushNamed(context, '/bp');
                          if (updated == true) setState(() {});
                        },
                      ),
                      _buildSmartDeviceCard(
                        icon: Icons.thermostat,
                        title: t.thermometerDevice,
                        colors: [Colors.blueGrey.shade800, Colors.orange.shade700],
                        t: t,
                        onTap: () async {
                          final updated = await Navigator.pushNamed(context, '/temp');
                          if (updated == true) setState(() {});
                        },
                      ),
                      _buildSectionTitle(t.services),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 3,
                          mainAxisSpacing: 15,
                          crossAxisSpacing: 15,
                          childAspectRatio: 0.95,
                          children: [
                            _buildActionCard(
                              icon: Icons.show_chart,
                              title: t.charts,
                              color: Colors.teal,
                              onTap: () => Navigator.push(context, createSlideRoute(const ChartsScreen())),
                            ),
                            _buildActionCard(
                              icon: Icons.health_and_safety,
                              title: t.healthadvices,
                              color: Colors.blue,
                              onTap: () => Navigator.push(context, createSlideRoute(const AdviceScreen())),
                            ),
                            _buildActionCard(
                              icon: Icons.calendar_month,
                              title: t.dailyroutine,
                              color: Colors.orange,
                              onTap: () => Navigator.pushNamed(context, '/routine'),
                            ),
                            _buildActionCard(
                              icon: Icons.psychology,
                              title: t.aiConsultant,
                              color: Colors.purple,
                              onTap: () => Navigator.pushNamed(context, '/ai_chat'),
                            ),
                            _buildActionCard(
                              icon: Icons.picture_as_pdf,
                              title: t.generateReport,
                              color: Colors.red,
                              onTap: () => Navigator.push(context, createFadeRoute(const ReportScreen())),
                            ),
                            _buildActionCard(
                              icon: Icons.settings,
                              title: t.settings,
                              color: Colors.blueGrey,
                              onTap: () => Navigator.pushNamed(context, '/settings'),
                            ),
                          ],
                        ),
                      ),
                      _buildSectionTitle(t.availableDevices),
                      Container(
                        height: 220,
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 20,
                            )
                          ],
                        ),
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
                                          Icon(Icons.bluetooth_searching, size: 45, color: Colors.teal.withValues(alpha: 0.3)),
                                          const SizedBox(height: 15),
                                          Text(t.noDevicesFound, style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    )
                                  : ListView.separated(
                                      padding: const EdgeInsets.all(15),
                                      itemCount: filteredResults.length,
                                      separatorBuilder: (_, __) => const Divider(height: 1),
                                      itemBuilder: (context, index) {
                                        final result = filteredResults[index];
                                        final device = result.device;
                                        return ListTile(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                                          leading: CircleAvatar(
                                            backgroundColor: Colors.teal.withValues(alpha: 0.1),
                                            child: const Icon(Icons.bluetooth, color: Colors.teal, size: 20),
                                          ),
                                          title: Text(device.platformName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          subtitle: Text(device.remoteId.str, style: const TextStyle(fontSize: 10)),
                                          trailing: const Icon(Icons.link, size: 18),
                                          onTap: () => _connectToDevice(device),
                                        );
                                      },
                                    );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 120),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isScanning ? _stopScan : _startScan,
        elevation: 10,
        backgroundColor: _isScanning ? Colors.redAccent : Colors.teal,
        icon: _isScanning
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
            : const Icon(Icons.bluetooth_searching),
        label: Text(
          _isScanning 
            ? (isArabic ? "إيقاف البحث" : "Stop Scan") 
            : (isArabic ? "بحث عن أجهزة" : "Search Devices"),
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ),
    );
  }
}



