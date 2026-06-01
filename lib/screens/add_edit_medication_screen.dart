import 'package:flutter/material.dart';

import '../models/medication.dart';
import '../services/medication_service.dart';

class AddEditMedicationScreen extends StatefulWidget {
  final Medication? medication;

  const AddEditMedicationScreen({super.key, this.medication});

  @override
  State<AddEditMedicationScreen> createState() => _AddEditMedicationScreenState();
}

class _AddEditMedicationScreenState extends State<AddEditMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _pillsPerBoxController = TextEditingController();
  final _service = MedicationService();

  bool _saving = false;
  int _timesPerDay = 1;
  List<TimeOfDay> _doseTimes = [];

  bool get _isEdit => widget.medication != null;

  @override
  void initState() {
    super.initState();
    final medication = widget.medication;
    if (medication != null) {
      _nameController.text = medication.name;
      _timesPerDay = medication.timesPerDay;
      _doseTimes = medication.normalizedDoseTimes
          .map((minutes) => TimeOfDay(
                hour: minutes ~/ 60,
                minute: minutes % 60,
              ))
          .toList();
      _pillsPerBoxController.text = medication.pillsPerBox.toString();
    } else {
      _doseTimes = _defaultTimeOfDayList(_timesPerDay);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pillsPerBoxController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final pillsPerBox = int.parse(_pillsPerBoxController.text.trim());
    final doseTimes = _doseTimes.map(_toMinutes).toList()..sort();

    if (!_hasUniqueTimes(doseTimes)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر ساعات مختلفة لكل جرعة')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      if (_isEdit) {
        await _service.updateMedication(
          medicationId: widget.medication!.id,
          name: name,
          timesPerDay: _timesPerDay,
          doseTimes: doseTimes,
          pillsPerBox: pillsPerBox,
        );
      } else {
        await _service.addMedication(
          name: name,
          timesPerDay: _timesPerDay,
          doseTimes: doseTimes,
          pillsPerBox: pillsPerBox,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر حفظ الدواء: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'هذا الحقل مطلوب';
    }
    return null;
  }

  String? _validatePositiveInt(String? value) {
    final requiredValidation = _validateRequired(value);
    if (requiredValidation != null) return requiredValidation;

    final number = int.tryParse(value!.trim());
    if (number == null || number <= 0) {
      return 'أدخل رقمًا صحيحًا أكبر من صفر';
    }
    return null;
  }

  List<TimeOfDay> _defaultTimeOfDayList(int timesPerDay) {
    return Medication.defaultDoseTimesFor(timesPerDay)
        .map((minutes) => TimeOfDay(
              hour: minutes ~/ 60,
              minute: minutes % 60,
            ))
        .toList();
  }

  int _toMinutes(TimeOfDay time) => (time.hour * 60) + time.minute;

  bool _hasUniqueTimes(List<int> minutes) {
    return minutes.toSet().length == minutes.length;
  }

  Future<void> _pickDoseTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _doseTimes[index],
    );

    if (picked == null || !mounted) return;
    setState(() {
      _doseTimes[index] = picked;
    });
  }

  void _updateTimesPerDay(int? value) {
    if (value == null || value == _timesPerDay) return;
    setState(() {
      _timesPerDay = value;
      _doseTimes = _defaultTimeOfDayList(value);
    });
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'تعديل الدواء' : 'إضافة دواء'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'اسم الدواء',
                border: OutlineInputBorder(),
              ),
              validator: _validateRequired,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _timesPerDay,
              decoration: const InputDecoration(
                labelText: 'عدد المرات في اليوم',
                border: OutlineInputBorder(),
              ),
              items: List.generate(
                6,
                (index) => DropdownMenuItem<int>(
                  value: index + 1,
                  child: Text('${index + 1}'),
                ),
              ),
              onChanged: _saving ? null : _updateTimesPerDay,
            ),
            const SizedBox(height: 16),
            const Text(
              'ساعات الجرعات اليومية',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...List.generate(_doseTimes.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : () => _pickDoseTime(index),
                  icon: const Icon(Icons.access_time),
                  label: Text('الجرعة ${index + 1}: ${_formatTime(_doseTimes[index])}'),
                ),
              );
            }),
            const SizedBox(height: 8),
            TextFormField(
              controller: _pillsPerBoxController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'عدد الأقراص في العلبة',
                border: OutlineInputBorder(),
              ),
              validator: _validatePositiveInt,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEdit ? 'حفظ التعديل' : 'إضافة الدواء'),
            ),
          ],
        ),
      ),
    );
  }
}
