import 'package:flutter/material.dart';

import '../models/medication.dart';
import '../models/medication_intake.dart';
import '../services/medication_service.dart';
import 'add_edit_medication_screen.dart';
import 'medication_report_screen.dart';

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  final MedicationService _service = MedicationService();

  bool _loading = true;
  List<Medication> _medications = [];

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    setState(() => _loading = true);

    await _service.ensureDailyIntakesForAllActiveMedications();
    await _service.markPastPendingIntakesAsMissed();
    await _service.syncAllMedicationNotifications();

    final medications = _service.getAllMedications();

    if (!mounted) return;
    setState(() {
      _medications = medications;
      _loading = false;
    });
  }

  Future<void> _openAddMedication() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddEditMedicationScreen(),
      ),
    );

    if (updated == true) {
      await _loadMedications();
    }
  }

  Future<void> _openEditMedication(Medication medication) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditMedicationScreen(medication: medication),
      ),
    );

    if (updated == true) {
      await _loadMedications();
    }
  }

  Future<void> _markTaken(Medication medication, MedicationIntake intake) async {
    final quantity = await _askTakenQuantity(medication, intake);
    if (quantity == null) return;

    try {
      await _service.markIntakeTaken(
        intake.id,
        quantityTaken: quantity,
      );
      if (!mounted) return;
      await _loadMedications();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تسجيل الجرعة ($quantity قرص)')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تسجيل الجرعة: $e')),
      );
    }
  }

  Future<int?> _askTakenQuantity(
    Medication medication,
    MedicationIntake intake,
  ) async {
    final controller = TextEditingController(
      text: intake.quantityTaken.toString(),
    );

    try {
      return await showDialog<int>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('تأكيد الجرعة'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('كم قرصًا تناولت من ${medication.name}؟'),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'عدد الأقراص',
                    helperText:
                        'المتاح الآن: ${medication.remainingPills} قرص',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () {
                  final quantity = int.tryParse(controller.text.trim());
                  if (quantity == null || quantity <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('أدخل عددًا صحيحًا أكبر من صفر'),
                      ),
                    );
                    return;
                  }
                  if (quantity > medication.remainingPills) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'الكمية أكبر من المتبقي (${medication.remainingPills})',
                        ),
                      ),
                    );
                    return;
                  }
                  Navigator.pop(context, quantity);
                },
                child: const Text('تأكيد'),
              ),
            ],
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _deleteMedication(Medication medication) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('حذف الدواء'),
          content: Text(
            'هل تريد حذف ${medication.name}؟ سيتم حذف الجرعات والإشعارات المرتبطة به أيضًا.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _service.deleteMedication(medication.id);
      if (!mounted) return;
      await _loadMedications();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حذف ${medication.name}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر حذف الدواء: $e')),
      );
    }
  }

  Future<void> _refillMedication(Medication medication) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('إعادة تعبئة العلبة'),
          content: Text(
            'هل اشتريت عبوة جديدة من ${medication.name}؟ سيتم إعادة المتبقي إلى ${medication.pillsPerBox} قرص.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('تأكيد'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _service.refillMedication(medication.id);
      if (!mounted) return;
      await _loadMedications();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تمت إعادة تعبئة ${medication.name}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذرت إعادة التعبئة: $e')),
      );
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'taken':
        return 'تم تناولها';
      case 'missed':
        return 'فاتت';
      default:
        return 'معلقة';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'taken':
        return Colors.green;
      case 'missed':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _timeText(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _minutesToTimeText(int minutes) {
    final hour = (minutes ~/ 60).toString().padLeft(2, '0');
    final minute = (minutes % 60).toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  int _todayPendingCount() {
    var count = 0;
    for (final medication in _medications) {
      count += _service
          .getTodayMedicationIntakes(medication.id)
          .where((intake) => intake.status == 'pending')
          .length;
    }
    return count;
  }

  int _lowStockCount() {
    return _medications.where((medication) {
      final summary = _service.buildMedicationSummary(medication.id);
      return summary.isLowStock || summary.isOutOfStock;
    }).length;
  }

  Widget _buildOverviewCard() {
    final totalMedications = _medications.length;
    final lowStock = _lowStockCount();
    final pendingToday = _todayPendingCount();

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.medication_outlined, color: Colors.white),
              SizedBox(width: 10),
              Text(
                'ملخص المتابعة',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildOverviewStat(
                  label: 'الأدوية',
                  value: '$totalMedications',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildOverviewStat(
                  label: 'جرعات اليوم',
                  value: '$pendingToday',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildOverviewStat(
                  label: 'مخزون منخفض',
                  value: '$lowStock',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewStat({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntakeTile(Medication medication, MedicationIntake intake) {
    final status = intake.status;
    final statusColor = _statusColor(status);
    final backgroundColor = status == 'taken'
        ? const Color(0xFFE8F7EE)
        : status == 'missed'
            ? const Color(0xFFFDECEC)
            : const Color(0xFFFFF7E8);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              status == 'taken'
                  ? Icons.check_circle_outline
                  : status == 'missed'
                      ? Icons.error_outline
                      : Icons.schedule,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'جرعة ${_timeText(intake.scheduledAt)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _statusText(status),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (status == 'taken') ...[
                  const SizedBox(height: 6),
                  Text(
                    'الكمية المتناولة: ${intake.quantityTaken} قرص',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (status == 'pending' || status == 'missed')
            FilledButton.tonal(
              onPressed: () => _markTaken(medication, intake),
              style: FilledButton.styleFrom(
                foregroundColor: const Color(0xFF0F766E),
              ),
              child: Text(
                status == 'missed' ? 'تسجيلها الآن' : 'تأكيد تناولها',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMedicationCard(Medication medication) {
    final summary = _service.buildMedicationSummary(medication.id);
    final todayIntakes = _service.getTodayMedicationIntakes(medication.id);

    Color stockColor;
    String stockText;

    if (summary.isOutOfStock) {
      stockColor = Colors.red;
      stockText = 'الدواء خلص';
    } else if (summary.isLowStock) {
      stockColor = Colors.orange;
      stockText = 'المخزون منخفض';
    } else {
      stockColor = Colors.green;
      stockText = 'المخزون جيد';
    }

    final adherencePercent = (summary.adherenceRate * 100).toStringAsFixed(0);
    final doseTimes = medication.normalizedDoseTimes;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6FFFB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.medication_liquid_outlined,
                    color: Color(0xFF0F766E),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medication.name,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${medication.timesPerDay} جرعة يوميًا',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _openEditMedication(medication),
                  icon: const Icon(Icons.edit),
                  tooltip: 'تعديل',
                ),
                IconButton(
                  onPressed: () => _deleteMedication(medication),
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red,
                  tooltip: 'حذف',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildInfoChip(
                  icon: Icons.inventory_2_outlined,
                  label:
                      'المتبقي ${medication.remainingPills}/${medication.pillsPerBox}',
                  background: const Color(0xFFF3F4F6),
                  foreground: Colors.black87,
                ),
                _buildInfoChip(
                  icon: Icons.monitor_heart_outlined,
                  label: 'الالتزام $adherencePercent%',
                  background: const Color(0xFFE6F7FF),
                  foreground: const Color(0xFF0369A1),
                ),
                _buildInfoChip(
                  icon: summary.isOutOfStock
                      ? Icons.warning_amber_rounded
                      : Icons.shield_outlined,
                  label: stockText,
                  background: stockColor.withValues(alpha: 0.12),
                  foreground: stockColor,
                ),
              ],
            ),
            if (medication.remainingPills < medication.pillsPerBox) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _refillMedication(medication),
                icon: const Icon(Icons.inventory_outlined),
                label: const Text('إعادة تعبئة العلبة'),
              ),
            ],
            const SizedBox(height: 14),
            const Text(
              'ساعات الجرعات',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: doseTimes.map((minutes) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    _minutesToTimeText(minutes),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            const Text(
              'جرعات اليوم',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            if (todayIntakes.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Text('لا توجد جرعات اليوم'),
              )
            else
              ...todayIntakes.map((intake) => _buildIntakeTile(medication, intake)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color background,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 90),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6FFFB),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.medication_outlined,
                  size: 36,
                  color: Color(0xFF0F766E),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'لا توجد أدوية مضافة بعد',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ابدأ بإضافة أول دواء لتتبع الجرعات اليومية والمخزون بسهولة.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _openAddMedication,
                icon: const Icon(Icons.add),
                label: const Text('إضافة أول دواء'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('متابعة الأدوية'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MedicationReportScreen(),
                ),
              );
            },
            icon: const Icon(Icons.assessment_outlined),
            tooltip: 'تقرير الأدوية',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddMedication,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadMedications,
              child: _medications.isEmpty
                  ? _buildEmptyState()
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildOverviewCard(),
                        ..._medications.map(_buildMedicationCard),
                      ],
                    ),
            ),
    );
  }
}
