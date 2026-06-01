import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../services/medication_report_service.dart';

class MedicationReportScreen extends StatefulWidget {
  const MedicationReportScreen({super.key});

  @override
  State<MedicationReportScreen> createState() => _MedicationReportScreenState();
}

class _MedicationReportScreenState extends State<MedicationReportScreen> {
  final MedicationReportService _service = MedicationReportService();

  bool _loading = true;
  bool _sharingText = false;
  bool _sharingPdf = false;
  MedicationReportData? _report;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _loading = true);
    final report = _service.buildReportData();
    if (!mounted) return;
    setState(() {
      _report = report;
      _loading = false;
    });
  }

  Future<void> _shareText() async {
    final report = _report;
    if (report == null) return;

    setState(() => _sharingText = true);
    try {
      await Share.share(_service.buildShareText(report));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذرت مشاركة التقرير النصي: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _sharingText = false);
      }
    }
  }

  Future<void> _sharePdf() async {
    final report = _report;
    if (report == null) return;

    setState(() => _sharingPdf = true);
    try {
      final file = await _service.generatePdf(report);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'تقرير متابعة الأدوية',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذرت مشاركة ملف التقرير: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _sharingPdf = false);
      }
    }
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required bool loading,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير الأدوية'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : report == null
              ? const Center(child: Text('تعذر تحميل التقرير'))
              : RefreshIndicator(
                  onRefresh: _loadReport,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Row(
                        children: [
                          _buildActionButton(
                            title: 'مشاركة نصية',
                            icon: Icons.share,
                            loading: _sharingText,
                            onPressed: _shareText,
                            color: Colors.teal,
                          ),
                          const SizedBox(width: 12),
                          _buildActionButton(
                            title: 'مشاركة PDF',
                            icon: Icons.picture_as_pdf,
                            loading: _sharingPdf,
                            onPressed: _sharePdf,
                            color: Colors.red,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (report.profile != null)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'بيانات المستخدم',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text('الاسم: ${report.profile!.name}'),
                                Text('العمر: ${report.profile!.age}'),
                                Text('الجنس: ${report.profile!.gender}'),
                              ],
                            ),
                          ),
                        ),
                      if (report.items.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: Text('لا توجد أدوية مسجلة حالياً'),
                            ),
                          ),
                        )
                      else
                        ...report.items.map((item) {
                          final adherencePercent =
                              (item.adherenceRate * 100).toStringAsFixed(0);
                          final stockText = item.isOutOfStock
                              ? 'منتهي'
                              : item.isLowStock
                                  ? 'منخفض'
                                  : 'جيد';
                          final stockColor = item.isOutOfStock
                              ? Colors.red
                              : item.isLowStock
                                  ? Colors.orange
                                  : Colors.green;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.medication.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'المتبقي: ${item.medication.remainingPills}/${item.medication.pillsPerBox}',
                                  ),
                                  Text(
                                    'حالة المخزون: $stockText',
                                    style: TextStyle(
                                      color: stockColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text('الجرعات المجدولة: ${item.totalDoses}'),
                                  Text('تم أخذها: ${item.takenDoses}'),
                                  Text(
                                    'إجمالي الأقراص المتناولة: ${item.totalPillsTaken}',
                                  ),
                                  Text('فائتة: ${item.missedDoses}'),
                                  Text('معلقة: ${item.pendingDoses}'),
                                  Text('الالتزام: $adherencePercent%'),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }
}
