import 'dart:io';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/medication.dart';
import '../models/user_profile.dart';
import 'medication_service.dart';
import 'storage_service.dart';

class MedicationReportItem {
  final Medication medication;
  final int totalDoses;
  final int takenDoses;
  final int totalPillsTaken;
  final int missedDoses;
  final int pendingDoses;
  final double adherenceRate;
  final bool isOutOfStock;
  final bool isLowStock;

  const MedicationReportItem({
    required this.medication,
    required this.totalDoses,
    required this.takenDoses,
    required this.totalPillsTaken,
    required this.missedDoses,
    required this.pendingDoses,
    required this.adherenceRate,
    required this.isOutOfStock,
    required this.isLowStock,
  });
}

class MedicationReportData {
  final UserProfile? profile;
  final List<MedicationReportItem> items;
  final DateTime generatedAt;

  const MedicationReportData({
    required this.profile,
    required this.items,
    required this.generatedAt,
  });
}

class MedicationReportService {
  static final MedicationReportService _instance =
      MedicationReportService._internal();
  factory MedicationReportService() => _instance;
  MedicationReportService._internal();

  final MedicationService _medicationService = MedicationService();
  final StorageService _storage = StorageService();

  MedicationReportData buildReportData() {
    final medications = _medicationService.getAllMedications();
    final items = medications.map((medication) {
      final summary = _medicationService.buildMedicationSummary(medication.id);
      final totalPillsTaken = _medicationService
          .getMedicationIntakes(medication.id)
          .where((intake) => intake.status == 'taken')
          .fold<int>(0, (sum, intake) => sum + intake.quantityTaken);
      return MedicationReportItem(
        medication: medication,
        totalDoses: summary.totalDoses,
        takenDoses: summary.takenDoses,
        totalPillsTaken: totalPillsTaken,
        missedDoses: summary.missedDoses,
        pendingDoses: summary.pendingDoses,
        adherenceRate: summary.adherenceRate,
        isOutOfStock: summary.isOutOfStock,
        isLowStock: summary.isLowStock,
      );
    }).toList();

    return MedicationReportData(
      profile: _storage.getUserProfile(),
      items: items,
      generatedAt: DateTime.now(),
    );
  }

  String buildShareText(MedicationReportData report) {
    final buffer = StringBuffer();
    final generated = DateFormat('yyyy-MM-dd HH:mm').format(report.generatedAt);

    buffer.writeln('تقرير متابعة الأدوية');
    buffer.writeln('تاريخ الإنشاء: $generated');

    final profile = report.profile;
    if (profile != null) {
      buffer.writeln('الاسم: ${profile.name}');
      buffer.writeln('العمر: ${profile.age}');
      buffer.writeln('الجنس: ${profile.gender}');
    }

    buffer.writeln('');

    if (report.items.isEmpty) {
      buffer.writeln('لا توجد أدوية مسجلة حالياً.');
      return buffer.toString();
    }

    for (final item in report.items) {
      final adherencePercent = (item.adherenceRate * 100).toStringAsFixed(0);
      final stockStatus = item.isOutOfStock
          ? 'منتهي'
          : item.isLowStock
              ? 'منخفض'
              : 'جيد';

      buffer.writeln('• ${item.medication.name}');
      buffer.writeln('  - عدد المرات يومياً: ${item.medication.timesPerDay}');
      buffer.writeln(
          '  - المتبقي: ${item.medication.remainingPills}/${item.medication.pillsPerBox}');
      buffer.writeln('  - حالة المخزون: $stockStatus');
      buffer.writeln('  - الجرعات المجدولة: ${item.totalDoses}');
      buffer.writeln('  - تم أخذها: ${item.takenDoses}');
      buffer.writeln('  - إجمالي الأقراص المتناولة: ${item.totalPillsTaken}');
      buffer.writeln('  - فائتة: ${item.missedDoses}');
      buffer.writeln('  - معلقة: ${item.pendingDoses}');
      buffer.writeln('  - نسبة الالتزام: $adherencePercent%');
      buffer.writeln('');
    }

    return buffer.toString().trimRight();
  }

  Future<File> generatePdf(MedicationReportData report) async {
    final arabicFont = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
    final arabicFontBold = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');

    final ttf = pw.Font.ttf(arabicFont);
    final ttfBold = pw.Font.ttf(arabicFontBold);
    final pdf = pw.Document(
      title: 'Medication Report',
      author: report.profile?.name ?? 'T-MED',
      creator: 'T-MED',
    );

    final generated = DateFormat('yyyy-MM-dd HH:mm').format(report.generatedAt);

    pdf.addPage(
      pw.MultiPage(
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
        build: (context) => [
          pw.Text(
            'تقرير متابعة الأدوية',
            style: pw.TextStyle(font: ttfBold, fontSize: 24),
          ),
          pw.SizedBox(height: 12),
          pw.Text('تاريخ الإنشاء: $generated'),
          pw.SizedBox(height: 16),
          if (report.profile != null) ...[
            pw.Text(
              'بيانات المستخدم',
              style: pw.TextStyle(font: ttfBold, fontSize: 18),
            ),
            pw.Bullet(text: 'الاسم: ${report.profile!.name}'),
            pw.Bullet(text: 'العمر: ${report.profile!.age}'),
            pw.Bullet(text: 'الجنس: ${report.profile!.gender}'),
            pw.SizedBox(height: 16),
          ],
          if (report.items.isEmpty)
            pw.Text('لا توجد أدوية مسجلة حالياً.')
          else
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(font: ttfBold),
              headers: const [
                'الدواء',
                'المتبقي',
                'المجدولة',
                'تم أخذها',
                'الأقراص',
                'فائتة',
                'معلقة',
                'الالتزام',
              ],
              data: report.items.map((item) {
                final adherencePercent =
                    (item.adherenceRate * 100).toStringAsFixed(0);
                return [
                  item.medication.name,
                  '${item.medication.remainingPills}/${item.medication.pillsPerBox}',
                  item.totalDoses.toString(),
                  item.takenDoses.toString(),
                  item.totalPillsTaken.toString(),
                  item.missedDoses.toString(),
                  item.pendingDoses.toString(),
                  '$adherencePercent%',
                ];
              }).toList(),
            ),
          if (report.items.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Text(
              'حالة المخزون',
              style: pw.TextStyle(font: ttfBold, fontSize: 18),
            ),
            pw.SizedBox(height: 8),
            ...report.items.map((item) {
              final stockStatus = item.isOutOfStock
                  ? 'منتهي'
                  : item.isLowStock
                      ? 'منخفض'
                      : 'جيد';
              final color = item.isOutOfStock
                  ? PdfColors.red
                  : item.isLowStock
                      ? PdfColors.orange
                      : PdfColors.green;
              return pw.Text(
                '${item.medication.name}: $stockStatus',
                style: pw.TextStyle(color: color),
              );
            }),
          ],
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        'medication_report_${DateFormat('yyyyMMdd_HHmm').format(report.generatedAt)}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
