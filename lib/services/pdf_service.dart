import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart' show Colors;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:screenshot/screenshot.dart';
import '../models/health_data.dart';
import '../models/user_profile.dart';
import '../utils/helper.dart';
import '../utils/constants.dart'; // لإضافة الـ thresholds
import 'package:flutter/widgets.dart';
import 'dart:ui' as ui;
import '../utils/logger.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart' as material;



class PdfService {
  // 🧾 1. تقرير عام لكل القراءات
  static Future<pw.ImageProvider?> _generateChartImage(List<HealthData> data) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()..color = const Color(0xFFFFFFFF);

      // حجم الرسم
      const width = 600.0;
      const height = 300.0;

      canvas.drawRect( const Rect.fromLTWH(0, 0, width, height), paint);

      // نقاط الرسم
      final points = data.asMap().entries.map((e) {
        final x = e.key * (width / (data.length - 1));
        final y = height - (e.value.value * (height / 300)); // 300 افترضنا حد أقصى للقيمة
        return Offset(x, y);
      }).toList();

      // خط الرسم
      final linePaint = Paint()
        ..color = const Color(0xFF2196F3)
        ..strokeWidth = 2;

      for (int i = 0; i < points.length - 1; i++) {
        canvas.drawLine(points[i], points[i + 1], linePaint);
      }

      // حفظ الصورة
      final picture = recorder.endRecording();
      final img = await picture.toImage(width.toInt(), height.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        return pw.MemoryImage(byteData.buffer.asUint8List());
      }
    } catch (e) {
      AppLogger.logInfo ("خطأ في إنشاء الرسم البياني: $e");
    }
    return null;
  }

  static Future<pw.ImageProvider?> _generateChartImageForBP(
      List<HealthData> data) async {
    if (data.isEmpty) return null;

    // نحول البيانات لــ FlSpot
    final List<FlSpot> systolicPoints = [];
    final List<FlSpot> diastolicPoints = [];

    for (int i = 0; i < data.length; i++) {
      final sys = (data[i].value as Map)['sys']?.toDouble() ?? 0.0;
      final dia = (data[i].value as Map)['dia']?.toDouble() ?? 0.0;
      systolicPoints.add(FlSpot(i.toDouble(), sys));
      diastolicPoints.add(FlSpot(i.toDouble(), dia));
    }

    final chart = SizedBox(
      width: 400,
      height: 250,
      child: LineChart(
        LineChartData(
          lineTouchData: const LineTouchData(enabled: true),
          lineBarsData: [
            LineChartBarData(
              spots: systolicPoints,
              isCurved: true,
              color: material.Colors.blue,
              barWidth: 3,
              dotData: const FlDotData(show: false),
            ),
            LineChartBarData(
              spots: diastolicPoints,
              isCurved: true,
              color: material.Colors.green,
              barWidth: 3,
              dotData: const FlDotData(show: false),
            ),
          ],
          betweenBarsData: [
            BetweenBarsData(
              fromIndex: 0, // systolic
              toIndex: 1,   // diastolic
              color: Colors.green.withValues(alpha:0.1),
            )
          ],

          extraLinesData: ExtraLinesData(horizontalLines: [
            HorizontalLine(
              y: 120, // Sys الطبيعي
              color: Colors.blue.withValues(alpha:0.5),
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
            HorizontalLine(
              y: 80, // Dia الطبيعي
              color: Colors.green.withValues(alpha:0.5),
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
          ]),

          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              axisNameWidget: const Text("رقم القراءة", style: TextStyle(fontSize: 12)),
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  // هنا ممكن تخلي القيمة تاريخ أو رقم القراءة
                  return Text((value.toInt() + 1).toString(), style: const TextStyle(fontSize: 10));
                },
              ),
            ),
            leftTitles: AxisTitles(
              axisNameWidget: const Text("الضغط (mmHg)", style: TextStyle(fontSize: 12)),
              sideTitles: SideTitles(
                showTitles: true,
                interval: 20, // كل 20 mmHg
                getTitlesWidget: (value, meta) {
                  return Text("${value.toInt()}", style: const TextStyle(fontSize: 10));
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),

          gridData: const FlGridData(show: true),
          borderData: FlBorderData(show: true),
        ),
      ),
    );

    // نستخدم ScreenshotController لتحويل الـ chart إلى صورة
    final controller = ScreenshotController();
    final Uint8List pngBytes = await controller.captureFromWidget(
      material.Directionality(
        textDirection: material.TextDirection.ltr,
        child: chart,
      ),
      delay: const Duration(milliseconds: 100),
    );
    return pw.MemoryImage(pngBytes);
  }




  static Future<File> generateReport({
    required UserProfile profile,
    required List<HealthData> healthDataList,
  }) async {
    final pdf = pw.Document(
      title: "Blood Pressure Report",
      author: profile.name,
      subject: "تحليل قراءات ضغط الدم",
      keywords: "Blood Pressure, Health, Report",
      creator: "Smart Health Home Kit",

    );

    final now = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());




    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text("تقرير الحالة الصحية", style: pw.TextStyle(
              fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 16),
          pw.Text("تاريخ التوليد: ${DateFormat('yyyy-MM-dd – kk:mm').format(
              DateTime.now())}"),
          pw.SizedBox(height: 16),
          pw.Text("👤 بيانات المستخدم:", style: pw.TextStyle(
              fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.Bullet(text: "الاسم: ${profile.name}"),
          pw.Bullet(text: "العمر: ${profile.age}"),
          pw.Bullet(text: "الجنس: ${profile.gender}"),
          pw.Bullet(text: "أمراض مزمنة: ${profile.conditions.join(', ')}"),
          pw.SizedBox(height: 24),
          pw.Text("📊 القراءات الصحية:", style: pw.TextStyle(
              fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.TableHelper.fromTextArray(
            headers: ['التاريخ', 'النوع', 'القيمة'],
            data: healthDataList.map((data) {
              final value = Helper.formatValueByType(data.type, data.value);
              final isOut = Helper.isOutOfRangeByType(data.type, data.value, Constants.alertThresholds);

              return [
                Helper.formatDate(data.timestamp),
                data.type,
                pw.Text(
                  "$value${isOut ? " ⚠" : ""}",
                  style: pw.TextStyle(
                    color: isOut ? PdfColors.red : PdfColors.green,
                  ),
                ),
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 16),
          pw.Text("ملاحظات:", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          ...healthDataList.map((data) {
            final isOut = Helper.isOutOfRangeByType(data.type, data.value, Constants.alertThresholds);
            return pw.Text(
              isOut
                  ? "⚠ ${data.type} خارج النطاق عند ${Helper.formatValueByType(data.type, data.value)}"
                  : "✅ ${data.type} في النطاق الطبيعي",
            );
          }),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/health_report_$now.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }



  // 🩸 2. تقرير مخصص للسكر
  static Future<File> generateGlucoseReport({
    required UserProfile profile,
    required List<HealthData> data,
  }) async {
    final pdf = pw.Document();
    final now = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final latest = data.isNotEmpty ? data.first : null;
    final chartImage = await _generateChartImage(data);

    // ✅ ترتيب البيانات (الأحدث أولاً)
    data.sort((a, b) => b.timestamp.compareTo(a.timestamp));



    // ✅ إضافة عنوان التقرير
    pdf.addPage(
      pw.MultiPage(
        footer: (context) => pw.Container(
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Text(
            "تقرير السكر - ${profile.name} - ${Helper.formatDate(DateTime.now())} | صفحة ${context.pageNumber} من ${context.pagesCount}",
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
        ),

        build: (context) => [
          // 🏷️ عنوان التقرير
          pw.Text(
            'تقرير جهاز قياس السكر',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              decoration: pw.TextDecoration.underline,
            ),
          ),
          // 👤 بيانات المريض
          pw.SizedBox(height: 16),
          pw.Text("👤 بيانات المستخدم:", style: const pw.TextStyle(fontSize: 16)),
          pw.Bullet(text: "الاسم: ${profile.name}"),
          pw.Bullet(text: "العمر: ${profile.age}"),
          pw.Bullet(text: "الجنس: ${profile.gender}"),
          if (profile.conditions.isNotEmpty)
            pw.Bullet(text: "أمراض مزمنة: ${profile.conditions.join(', ')}"),
          pw.SizedBox(height: 16),

          // 📌 آخر قراءة
          if (latest != null) ...[
            pw.SizedBox(height: 12),
            pw.Text("📌 آخر قراءة:", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.Text(
              "🔹 ${Helper.formatValueByType(latest.type, latest.value)} - ${Helper.formatDate(latest.timestamp)}",
              style: pw.TextStyle(
                fontSize: 14,
                color: Helper.isOutOfRangeByType(latest.type, latest.value, Constants.alertThresholds)
                    ? PdfColors.red
                    : PdfColors.green,
              ),
            ),
            pw.SizedBox(height: 12),
          ],

          // 📊 الرسم البياني
          if (chartImage != null) ...[
            pw.SizedBox(height: 16),
            pw.Text("📊 الرسم البياني:", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.Center(child: pw.Image(chartImage, height: 220)), // أكبر
            pw.SizedBox(height: 16),
          ],


          // 📊 ملخص القراءات
          pw.SizedBox(height: 16),
          pw.Text("📊 الملخص:", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Bullet(text: "إجمالي القراءات: ${data.length}"),
          pw.Bullet(
            text: "✅ داخل النطاق: ${data.where((d) => !Helper.isOutOfRangeByType(d.type, d.value, Constants.alertThresholds)).length}",
          ),
          pw.Bullet(
            text: "⚠️ خارج النطاق: ${data.where((d) => Helper.isOutOfRangeByType(d.type, d.value, Constants.alertThresholds)).length}",
          ),


          pw.Divider(thickness: 1),

          // 📋 قراءات السكر
          // 📋 القراءات (تفصيلي أو جدول)
          pw.Text("📋 قراءات السكر:", style: const pw.TextStyle(fontSize: 16)),
          if (data.length < 50) ...[
            // 👇 العرض التفصيلي
            for (int i = 0; i < data.length; i += 20) ...[
              ...data.skip(i).take(20).map((d) {
                final value = Helper.formatValueByType(d.type, d.value);
                final isOut = Helper.isOutOfRangeByType(d.type, d.value, Constants.alertThresholds);
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '🔹 $value${isOut ? " ⚠" : ""} - ${Helper.formatDate(d.timestamp)}',
                      style: pw.TextStyle(color: isOut ? PdfColors.red : PdfColors.green),
                    ),
                    pw.Text(isOut ? "⚠️ خارج النطاق" : "✅ طبيعية",
                        style: const pw.TextStyle(fontSize: 12)),
                    pw.SizedBox(height: 4),
                    pw.Divider(thickness: 0.5),
                  ],
                );
              }),
              if (i + 20 < data.length)
                pw.Column(children: [
                  pw.NewPage(),
                  pw.Text("متابعة القراءات...",
                      style: pw.TextStyle(fontSize: 14, fontStyle: pw.FontStyle.italic)),
                ]),
            ]
          ] else ...[
            // 👇 العرض الجدولي المختصر
            pw.TableHelper.fromTextArray(
              headers: ['التاريخ', 'القراءة', 'الحالة'],
              data: data.map((d) {
                final value = Helper.formatValueByType(d.type, d.value);
                final isOut = Helper.isOutOfRangeByType(d.type, d.value, Constants.alertThresholds);
                return [
                  Helper.formatDate(d.timestamp),
                  value,
                  isOut ? "⚠️ خارج النطاق" : "✅ طبيعية",
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              cellStyle: const pw.TextStyle(fontSize: 10),
              cellAlignment: pw.Alignment.centerLeft,
              cellHeight: 20,
            ),
          ],


          // ⚠ قسم التنبيهات
          if (data.any((d) => Helper.isOutOfRangeByType(d.type, d.value, Constants.alertThresholds))) ...[
            pw.SizedBox(height: 16),
            pw.Text("عدد القراءات خارج النطاق: ${data.where((d) => Helper.isOutOfRangeByType(d.type, d.value, Constants.alertThresholds)).length}"),
            pw.Text("⚠ تنبيهات:", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            ...data.where((d) => Helper.isOutOfRangeByType(d.type, d.value, Constants.alertThresholds)).map((d) =>
                pw.Text(
                  "• ${Helper.formatValueByType(d.type, d.value)} (${Helper.formatDate(d.timestamp)}) "
                      "(${d.value > Constants.alertThresholds[d.type]!['max']!
                      ? 'أعلى من ${Constants.alertThresholds[d.type]!['max']}'
                      : 'أقل من ${Constants.alertThresholds[d.type]!['min']}'} )",
                  style: const pw.TextStyle(color: PdfColors.red),

                )
            ),
          ],
          if (!data.any((d) => Helper.isOutOfRangeByType(d.type, d.value, Constants.alertThresholds)))
            pw.Text("✅ لا توجد قراءات خارج النطاق", style:const pw.TextStyle(color: PdfColors.green)),

          pw.Divider(thickness: 1),

        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/glucose_report_$now.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }


  // 🩺 3. تقرير مخصص للضغط
  static Future<File> generateBloodPressureReport({
    required UserProfile profile,
    required List<HealthData> data,
  }) async {
    final pdf = pw.Document();
    final now = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final latest = data.isNotEmpty ? data.first : null;
    final chartImage =  await _generateChartImageForBP(data);

    // ✅ ترتيب البيانات (الأحدث أولاً)
    data.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // 📊 ملخص القراءات
    final normalCount = data.where((d) => Helper.isNormalBP(d)).length;
    final highCount = data.where((d) => Helper.isHighBP(d)).length;
    final lowCount = data.where((d) => Helper.isLowBP(d)).length;


    // ✅ إضافة عنوان التقرير
    pdf.addPage(
      pw.MultiPage(
        footer: (context) => pw.Container(   // ✅ Footer統一
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Text(
            "تقرير الضغط - ${profile.name} - ${Helper.formatDate(DateTime.now())} | صفحة ${context.pageNumber} من ${context.pagesCount}",
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
        ),

        build: (context) => [
          // 🏷️ عنوان التقرير
          pw.Text(
            'تقرير جهاز قياس الضغط',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              decoration: pw.TextDecoration.underline,
            ),
          ),

          pw.SizedBox(height: 16),

          // 👤 بيانات المستخدم
          pw.Text("👤 بيانات المستخدم:", style: const pw.TextStyle(fontSize: 16)),
          pw.Bullet(text: "الاسم: ${profile.name}"),
          pw.Bullet(text: "العمر: ${profile.age}"),
          pw.Bullet(text: "الجنس: ${profile.gender}"),
          if (profile.conditions.isNotEmpty)
            pw.Bullet(text: "أمراض مزمنة: ${profile.conditions.join(', ')}"),
          pw.SizedBox(height: 16),


          // 📌 آخر قراءة
          if (latest != null) ...[
            pw.SizedBox(height: 12),
            pw.Text("📌 آخر قراءة:", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.Text(
              "🔹 ${Helper.formatValueByType(latest.type, latest.value)} - ${Helper.formatDate(latest.timestamp)}",
              style: pw.TextStyle(
                fontSize: 14,
                color: Helper.isOutOfRangeByType(latest.type, latest.value, Constants.alertThresholds)
                    ? PdfColors.red
                    : PdfColors.green,
              ),
            ),
            pw.SizedBox(height: 12),
          ],

          // 📊 ملخص-
          pw.Text("📊 ملخص القراءات:", style: const pw.TextStyle(fontSize: 16)),
          pw.Table(
            border: pw.TableBorder.all(),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text("الحالة", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text("العدد", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                ],
              ),
              pw.TableRow(children: [
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text("✅ طبيعية")),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text("$normalCount")),
              ]),
              pw.TableRow(children: [
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text("⚠ مرتفعة", style: const pw.TextStyle(color: PdfColors.red))),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text("$highCount")),
              ]),
              pw.TableRow(children: [
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text("⚠ منخفضة", style: const pw.TextStyle(color: PdfColors.orange))),
                pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text("$lowCount")),
              ]),
            ],
          ),

          pw.SizedBox(height: 16),




          // 📊 رسم بياني مصغّر (Placeholder لو لسه ما أضفنا الدالة)
          pw.Text("📈 اتجاه ضغط الدم", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 16),
          if (chartImage != null) ...[
            pw.Text("📊 الرسم البياني:", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.Center(child: pw.Image(chartImage, height: 220)), // ⬅ زودنا الحجم
            pw.SizedBox(height: 16),
          ],

          // ⚠ قسم التنبيهات
          if (data.any((d) => Helper.isOutOfRangeByType(d.type, d.value, Constants.alertThresholds))) ...[
            pw.SizedBox(height: 16),
            pw.Text("عدد القراءات خارج النطاق: ${data.where((d) => Helper.isOutOfRangeByType(d.type, d.value, Constants.alertThresholds)).length}"),
            pw.Text("⚠ تنبيهات:", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            ...data.where((d) =>
                Helper.isOutOfRangeByType(d.type, d.value, Constants.alertThresholds)).map((d) =>
                pw.Text(
                  "• ${Helper.formatValueByType(d.type, d.value)} (${Helper.formatDate(d.timestamp)}"
                      " (${Helper.isHighBP(d) ? "مرتفع" : Helper.isLowBP(d) ? "منخفض" : "غير محدد"})"

                )
            ),
          ],
          if (!data.any((d) => Helper.isOutOfRangeByType(d.type, d.value, Constants.alertThresholds)))
            pw.Text("✅ لا توجد قراءات خارج النطاق", style:const pw.TextStyle(color: PdfColors.green)),

          pw.Divider(thickness: 1),


          // 📋 القراءات (عرض ذكي)
          pw.Text("📋 قراءات الضغط:", style: const pw.TextStyle(fontSize: 16)),

          if (data.length < 50) ...[
            // 👇 العرض التفصيلي زي ما هو بتاعك
            for (int i = 0; i < data.length; i += 20) ...[
              ...data.skip(i).take(20).map((d) {
                final value = Helper.formatValueByType(d.type, d.value);
                final isOut = Helper.isOutOfRangeByType(d.type, d.value, Constants.alertThresholds);
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '🔹 $value${isOut ? " ⚠" : ""} - ${Helper.formatDate(d.timestamp)}',
                      style: pw.TextStyle(color: isOut ? PdfColors.red : PdfColors.green),
                    ),
                    pw.Text(
                      isOut
                          ? "⚠️ القراءة خارج النطاق الطبيعي"
                          : "✅ القراءة في النطاق الطبيعي",
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Divider(thickness: 0.5),
                  ],
                );
              }),
              if (i + 20 < data.length) ...[
                pw.NewPage(),
                pw.Text(
                  "متابعة القراءات...",
                  style: pw.TextStyle(fontSize: 14, fontStyle: pw.FontStyle.italic),
                ),
              ]
            ]
          ] else ...[
            // 👇 جدول مختصر
            pw.TableHelper.fromTextArray(
              headers: ['التاريخ', 'القراءة', 'الحالة'],
              data: data.map((d) {
                final value = Helper.formatValueByType(d.type, d.value);
                String status = Helper.isNormalBP(d)
                ? "✅ طبيعية"
                    : Helper.isHighBP(d)
                ? "📈 مرتفعة"
                    : "📉 منخفضة";
                return [
                Helper.formatDate(d.timestamp),
                value,
                  status,
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              cellStyle: const pw.TextStyle(fontSize: 10),
              cellAlignment: pw.Alignment.centerLeft,
              cellHeight: 20,
            ),
          ],

        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/bp_report_$now.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // 📂 4. دالة فتح ملف PDF
  static Future<void> openFile(File file) async {
    await OpenFile.open(file.path);
  }

  // 🌡 5. تقرير الحرارة
  static Future<File> generateTemperatureReport({
    required UserProfile profile,
    required List<HealthData> data,
  }) async {
    final pdf = pw.Document();
    final now = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final latest = data.isNotEmpty ? data.first : null;
    final chartImage = await _generateChartImage(data);

    // ✅ ترتيب البيانات (الأحدث أولاً)
    data.sort((a, b) => b.timestamp.compareTo(a.timestamp));



    // ✅ إضافة عنوان التقرير
    pdf.addPage(
      pw.MultiPage(
        footer: (context) => pw.Container(
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Text(
            "تقرير الحرارة - ${profile.name} - ${Helper.formatDate(DateTime.now())} | صفحة ${context.pageNumber} من ${context.pagesCount}",
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
        ),
        build: (context) => [
          // 🏷️ عنوان التقرير
          pw.Text(
            'تقرير جهاز قياس الحرارة',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              decoration: pw.TextDecoration.underline, // ⬅️ خط تحت الكلمة
            ),
          ),
          pw.SizedBox(height: 16),

          // 👤 بيانات المريض
          pw.Text("👤 بيانات المستخدم:", style: const pw.TextStyle(fontSize: 16)),
          pw.Bullet(text: "الاسم: ${profile.name}"),
          pw.Bullet(text: "العمر: ${profile.age}"),
          pw.Bullet(text: "الجنس: ${profile.gender}"),
          if (profile.conditions.isNotEmpty)
            pw.Bullet(text: "أمراض مزمنة: ${profile.conditions.join(', ')}"),
          pw.SizedBox(height: 16),

          // 📌 آخر قراءة
          if (latest != null) ...[
            pw.SizedBox(height: 12),
            pw.Text("📌 آخر قراءة:", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.Text(
              "🔹 ${Helper.formatValueByType(latest.type, latest.value)} - ${Helper.formatDate(latest.timestamp)}",
              style: pw.TextStyle(
                fontSize: 14,
                color: Helper.isOutOfRangeByType(latest.type, latest.value, Constants.alertThresholds)
                    ? PdfColors.red
                    : PdfColors.green,
              ),
            ),
            pw.SizedBox(height: 12),
          ],


          // 📊 رسم بياني مصغّر (Placeholder لو لسه ما أضفنا الدالة)
          pw.SizedBox(height: 16),
          if (chartImage != null) ...[
            pw.Text("📊 الرسم البياني:", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.Center(child: pw.Image(chartImage, height: 220)), // ممكن 200–250
            pw.SizedBox(height: 16),
          ],

          // 📊 ملخص القراءات
          pw.SizedBox(height: 16),
          pw.Text("📊 الملخص:", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.Bullet(text: "إجمالي القراءات: ${data.length}"),
          pw.Bullet(
            text: "✅ داخل النطاق: ${data.where((d) => !Helper.isOutOfRangeByType(d.type, d.value, Constants.alertThresholds)).length}",
          ),
          pw.Bullet(
            text: "⚠️ خارج النطاق: ${data.where((d) => Helper.isOutOfRangeByType(d.type, d.value, Constants.alertThresholds)).length}",
          ),

          pw.Divider(thickness: 1),


          // 📋 قراءات الحرارة
          pw.Text("🌡️ قراءات الحرارة:", style: const pw.TextStyle(fontSize: 16)),
          if (data.length < 50) ...[
            // 👇 العرض التفصيلي
            for (int i = 0; i < data.length; i += 20) ...[
              ...data.skip(i).take(20).map((d) {
                final value = Helper.formatValueByType(d.type, d.value);
                final isOut = Helper.isOutOfRangeByType(d.type, d.value, Constants.alertThresholds);
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '🔹 $value${isOut ? " ⚠" : ""} - ${Helper.formatDate(d.timestamp)}',
                      style: pw.TextStyle(color: isOut ? PdfColors.red : PdfColors.green),
                    ),
                    pw.Text(isOut ? "⚠️ خارج النطاق" : "✅ طبيعية",
                        style: const pw.TextStyle(fontSize: 12)),
                    pw.SizedBox(height: 4),
                    pw.Divider(thickness: 0.5),
                  ],
                );
              }),
              if (i + 20 < data.length)
                pw.Column(children: [
                  pw.NewPage(),
                  pw.Text("متابعة القراءات...",
                      style: pw.TextStyle(fontSize: 14, fontStyle: pw.FontStyle.italic)),
                ]),
            ]
          ] else ...[
            // 👇 العرض الجدولي المختصر
            pw.TableHelper.fromTextArray(
              headers: ['التاريخ', 'القراءة', 'الحالة'],
              data: data.map((d) {
                final value = Helper.formatValueByType(d.type, d.value);
                final isOut = Helper.isOutOfRangeByType(d.type, d.value, Constants.alertThresholds);
                return [
                  Helper.formatDate(d.timestamp),
                  value,
                  isOut ? "⚠️ خارج النطاق" : "✅ طبيعية",
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              cellStyle: const pw.TextStyle(fontSize: 10),
              cellAlignment: pw.Alignment.centerLeft,
              cellHeight: 20,
            ),
          ],



          // ⚠ قسم التنبيهات
          if (data.any((d) => Helper.isOutOfRangeByType(d.type, d.value, Constants.alertThresholds))) ...[
            pw.SizedBox(height: 16),
            pw.Text("عدد القراءات خارج النطاق: ${data.where((d) => Helper.isOutOfRangeByType(d.type, d.value, Constants.alertThresholds)).length}"),
            pw.Text("⚠ تنبيهات:", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            ...data.where((d) =>
                Helper.isOutOfRangeByType(d.type, d.value, Constants.alertThresholds)).map((d) =>
                pw.Text(
                  "• ${Helper.formatValueByType(d.type, d.value)} (${Helper.formatDate(d.timestamp)}) "
                      "(${d.value > Constants.alertThresholds[d.type]!['max']!
                      ? 'أعلى من ${Constants.alertThresholds[d.type]!['max']}'
                      : 'أقل من ${Constants.alertThresholds[d.type]!['min']}'} )",
                  style: const pw.TextStyle(color: PdfColors.red),
                )
            ),
          ],
          if (!data.any((d) => Helper.isOutOfRangeByType(d.type, d.value, Constants.alertThresholds)))
            pw.Text("✅ لا توجد قراءات خارج النطاق", style:const pw.TextStyle(color: PdfColors.green)),

          pw.Divider(thickness: 1),


         ]
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/temperature_report_$now.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
