import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../models/health_data.dart';
import '../services/doctor_whatsapp_service.dart';
import '../services/pdf_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

enum DoctorReportType { all, glucose, temp, bp }

class DoctorReportScreen extends StatefulWidget {
  const DoctorReportScreen({super.key});

  @override
  State<DoctorReportScreen> createState() => _DoctorReportScreenState();
}

class _DoctorReportScreenState extends State<DoctorReportScreen> {
  final _customPhoneController = TextEditingController();

  DoctorReportType _selectedType = DoctorReportType.all;
  bool _isSending = false;
  bool _isSharingPdf = false;

  @override
  void dispose() {
    _customPhoneController.dispose();
    super.dispose();
  }

  List<HealthData> _getSelectedData() {
    switch (_selectedType) {
      case DoctorReportType.glucose:
        return StorageService().getAllByType(DataTypes.glucose);
      case DoctorReportType.temp:
        return StorageService().getAllByType(DataTypes.temp);
      case DoctorReportType.bp:
        return StorageService().getAllByType(DataTypes.bp);
      case DoctorReportType.all:
        return StorageService().getAllHealthData();
    }
  }

  String _reportLabel(AppLocalizations t) {
    switch (_selectedType) {
      case DoctorReportType.glucose:
        return t.glucose;
      case DoctorReportType.temp:
        return t.temperature;
      case DoctorReportType.bp:
        return t.bloodpressure;
      case DoctorReportType.all:
        return Localizations.localeOf(context).languageCode == 'ar'
            ? 'تقرير شامل'
            : 'Full report';
    }
  }

  Future<void> _sendToPhone(String phone) async {
    final t = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final profile = StorageService().getUserProfile();
    final selectedData = _getSelectedData();

    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.noDataToGenerateReport)),
      );
      return;
    }

    if (selectedData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic ? 'لا توجد قراءات لإرسالها' : 'No readings available to send',
          ),
        ),
      );
      return;
    }

    if (!DoctorWhatsAppService.isValidPhone(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic ? 'أدخل رقم هاتف صحيح مع كود الدولة' : 'Enter a valid phone number with country code',
          ),
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final message = DoctorWhatsAppService.buildReportMessage(
        profile: profile,
        healthData: selectedData,
        reportLabel: _reportLabel(t),
        isArabic: isArabic,
      );

      await DoctorWhatsAppService.openWhatsApp(
        phone: phone,
        message: message,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic ? 'تعذر فتح واتساب: $e' : 'Could not open WhatsApp: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _sharePdf() async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final profile = StorageService().getUserProfile();
    final selectedData = _getSelectedData();

    if (profile == null || selectedData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic ? 'لا توجد بيانات كافية لمشاركة التقرير' : 'Not enough data to share the report',
          ),
        ),
      );
      return;
    }

    setState(() => _isSharingPdf = true);

    try {
      final file = await PdfService.generateReport(
        profile: profile,
        healthDataList: selectedData,
      );

      await Share.shareXFiles(
        [XFile(file.path)],
        text: isArabic ? 'تقرير صحي من تطبيق T-MED' : 'Health report from T-MED',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic ? 'تعذر مشاركة ملف التقرير: $e' : 'Could not share the PDF report: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSharingPdf = false);
      }
    }
  }

  Widget _buildPhoneField({
    required TextEditingController controller,
    required String label,
    required String hint,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              prefixIcon: const Icon(Icons.phone),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(height: 12),
            trailing,
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback? onTap,
    bool loading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Icon(icon),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'التواصل مع الدكتور' : 'Contact the doctor'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade700, Colors.teal.shade700],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.medical_information, color: Colors.white, size: 34),
                const SizedBox(height: 12),
                Text(
                  isArabic ? 'إرسال تقرير للدكتور عبر واتساب' : 'Send a report to the doctor via WhatsApp',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isArabic
                      ? 'اختر نوع التقرير ثم أرسل ملخصًا مباشرًا أو شارك ملف PDF.'
                      : 'Choose the report type, then send a direct summary or share a PDF.',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<DoctorReportType>(
            initialValue: _selectedType,
            decoration: InputDecoration(
              labelText: isArabic ? 'نوع التقرير' : 'Report type',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            items: [
              DropdownMenuItem(
                value: DoctorReportType.all,
                child: Text(isArabic ? 'تقرير شامل' : 'Full report'),
              ),
              DropdownMenuItem(
                value: DoctorReportType.glucose,
                child: Text(t.glucose),
              ),
              DropdownMenuItem(
                value: DoctorReportType.temp,
                child: Text(t.temperature),
              ),
              DropdownMenuItem(
                value: DoctorReportType.bp,
                child: Text(t.bloodpressure),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedType = value);
              }
            },
          ),
          const SizedBox(height: 20),
          _buildActionButton(
            icon: Icons.send,
            title: isArabic ? 'إرسال إلى دكتور T-MED' : 'Send to T-MED doctor',
            color: Colors.green,
            onTap: _isSending ? null : () => _sendToPhone(Constants.tmedDoctorPhone),
            loading: _isSending,
          ),
          const SizedBox(height: 20),
          _buildPhoneField(
            controller: _customPhoneController,
            label: isArabic ? 'رقم دكتور آخر' : 'Another doctor number',
            hint: isArabic ? 'أدخل الرقم مع كود الدولة' : 'Enter the number with country code',
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.person_add_alt_1,
            title: isArabic ? 'إرسال إلى رقم آخر' : 'Send to another number',
            color: Colors.teal,
            onTap: _isSending ? null : () => _sendToPhone(_customPhoneController.text),
            loading: _isSending,
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _isSharingPdf ? null : _sharePdf,
            icon: _isSharingPdf
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf),
            label: Text(isArabic ? 'مشاركة PDF' : 'Share PDF'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
