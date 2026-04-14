import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import '../l10n/app_localizations.dart';
import '../services/storage_service.dart';
import '../services/pdf_service.dart';
import '../utils/helper.dart';
import '../utils/constants.dart';
import '../models/health_data.dart';




class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}
enum SelectedDevice { glucose, temp, bp }

class _ReportScreenState extends State<ReportScreen> {
  bool _isGenerating = false;

  late List<HealthData> _allHealthData;       // كل البيانات
  late List<HealthData> _filteredHealthData;  // بيانات الجهاز المحدد
  SelectedDevice selectedDevice = SelectedDevice.glucose; // الجهاز الافتراضي


  void _filterData() {
    setState(() {
      _filteredHealthData = _allHealthData.where((d) {
        switch (selectedDevice) {
          case SelectedDevice.glucose:
            return d.type == DataTypes.glucose;
          case SelectedDevice.temp:
            return d.type == DataTypes.temp;
          case SelectedDevice.bp:
            return d.type == DataTypes.bp;
        }
      }).toList();
    });
  }

  Widget _buildDeviceSelector(AppLocalizations t) {
    return Row(
      children: [
        _buildDeviceCard(
          label: t.glucose,
          icon: Icons.bloodtype,
          isSelected: selectedDevice == SelectedDevice.glucose,
          onTap: () {
            selectedDevice = SelectedDevice.glucose;
            _filterData();
          },
        ),
        const SizedBox(width: 8),
        _buildDeviceCard(
          label: t.temperature,
          icon: Icons.thermostat,
          isSelected: selectedDevice == SelectedDevice.temp,
          onTap: () {
            selectedDevice = SelectedDevice.temp;
            _filterData();
          },
        ),
        const SizedBox(width: 8),
        _buildDeviceCard(
          label: t.bloodpressure,
          icon: Icons.monitor_heart,
          isSelected: selectedDevice == SelectedDevice.bp,
          onTap: () {
            selectedDevice = SelectedDevice.bp;
            _filterData();
          },
        ),
      ],
    );
  }

  Widget _buildDeviceCard({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final borderColor = isSelected ? Colors.blue : Colors.grey.shade300;
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = isSelected ? colorScheme.primary.withValues(alpha: 0.08) : Colors.transparent;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }


  Future<void> _generateReport() async {
    final profile = StorageService().getUserProfile();
    final healthData = _filteredHealthData;

    final t = AppLocalizations.of(context)!; // ✅ النصوص المترجمة

    if (profile == null || healthData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.noDataToGenerateReport)), // ✅
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final file = await PdfService.generateReport(
        profile: profile,
        healthDataList: healthData,
      );

      setState(() => _isGenerating = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.reportGeneratedSuccessfully)), // ✅
      );




      await OpenFile.open(file.path);
    } catch (e) {
      setState(() => _isGenerating = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${t.errorGeneratingReport}: $e')), // ✅
      );
    }
  }


  @override
  void initState() {
    super.initState();
    _allHealthData = StorageService().getAllHealthData();
    _filterData(); // فلترة حسب الجهاز الافتراضي
  }



  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.healthReportTitle)), // ✅
      body: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildDeviceSelector(t),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: _filteredHealthData.isEmpty
                ? Center(child: Text(t.noDataToDisplay))
                : RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _allHealthData = StorageService().getAllHealthData();
                  _filterData();
                });
              },
              child: ListView.builder(
                itemCount: _filteredHealthData.length,
                itemBuilder: (context, index) {
                  final data = _filteredHealthData[index];
                  final value = Helper.formatDisplayText(data);
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

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      title: Text(
                        "${data.type} - $value",
                       style: TextStyle(
                          color: isOut ? Colors.red : Colors.green,
                         fontWeight: FontWeight.bold,
                       ),
                      ),
                       subtitle: Text(
                         isOut
                            ? "⚠ ${t.outOfRangeWarning}"
                            : "✅ ${t.withinNormalRange}",
                         style: const TextStyle(fontSize: 12),
                       ),
                     trailing: Text(
                        Helper.formatDate(data.timestamp),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                     ),
                    ),
                  );
                },
              ),

             ),
           ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _isGenerating
               ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                  onPressed: _generateReport,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: Text(t.generateReport),
                ),
            ),
          ),
        ],
      ),
    );
  }
}



