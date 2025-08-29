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

class _ReportScreenState extends State<ReportScreen> {
  bool _isGenerating = false;

  Future<void> _generateReport() async {
    final profile = StorageService().getUserProfile();
    final healthData = StorageService().getAllHealthData();

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
  late List<HealthData> _healthData;

  @override
  void initState() {
    super.initState();
    _healthData = StorageService().getAllHealthData();
  }



  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.healthReportTitle)), // ✅
      body: Column(
        children: [
          Expanded(
           child: _healthData.isEmpty
           ? Center(child: Text(t.noDataToDisplay))
             : RefreshIndicator(
                   onRefresh: () async {
                 setState(() {
                 _healthData = StorageService().getAllHealthData();
                  });
                 },
              child  : ListView.builder(
                itemCount: _healthData.length,
                itemBuilder: (context, index) {
                  final data = _healthData[index];
                  final value = Helper.formatValueByType(data.type, data.value);
                  final isOut = Helper.isOutOfRangeByType(data.type, data.value, Constants.alertThresholds);

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



