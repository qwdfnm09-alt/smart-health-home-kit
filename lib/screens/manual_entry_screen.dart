import 'package:flutter/material.dart';
import '../services/manual_entry_service.dart';
import '../utils/constants.dart';

enum ManualEntryType { glucose, temperature, bloodPressure }

class ManualEntryScreen extends StatefulWidget {
  final String? initialType;

  const ManualEntryScreen({super.key, this.initialType});

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _manualEntryService = ManualEntryService();

  final _glucoseController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _pulseController = TextEditingController();

  late ManualEntryType _selectedType;
  DateTime _selectedDateTime = DateTime.now();
  bool _isSaving = false;

  bool get _isArabic => Localizations.localeOf(context).languageCode == 'ar';

  String get _titleText => _isArabic ? 'إدخال يدوي' : 'Manual Entry';
  String get _readingTypeText => _isArabic ? 'نوع القياس' : 'Reading Type';
  String get _measurementTimeText =>
      _isArabic ? 'وقت القياس' : 'Measurement Time';
  String get _changeTimeText => _isArabic ? 'تغيير الوقت' : 'Change Time';
  String get _saveText => _isArabic ? 'إضافة القراءة' : 'Add Reading';
  String get _invalidInputText =>
      _isArabic ? 'يرجى إدخال قيم صحيحة' : 'Please enter valid values';
  String get _readingAddedText => _isArabic
      ? 'تمت إضافة القراءة بنجاح'
      : 'Reading added successfully';
  String get _manualHintText => _isArabic
      ? 'أدخل القياس يدويًا وسيتم تشغيل التنبيهات والتقارير والنصائح عليه تلقائيًا.'
      : 'Enter a reading manually and the app will use it in alerts, reports, and advice automatically.';
  String get _glucoseText => _isArabic ? 'سكر الدم' : 'Glucose';
  String get _temperatureText => _isArabic ? 'الحرارة' : 'Temperature';
  String get _bloodPressureText => _isArabic ? 'ضغط الدم' : 'Blood Pressure';
  String get _glucoseLabel =>
      _isArabic ? 'قيمة السكر (mg/dL)' : 'Glucose Value (mg/dL)';
  String get _temperatureLabel =>
      _isArabic ? 'درجة الحرارة (°C)' : 'Temperature Value (°C)';
  String get _systolicLabel =>
      _isArabic ? 'الضغط الانقباضي (SYS)' : 'Systolic (SYS)';
  String get _diastolicLabel =>
      _isArabic ? 'الضغط الانبساطي (DIA)' : 'Diastolic (DIA)';
  String get _pulseLabel => _isArabic ? 'النبض' : 'Pulse';

  @override
  void initState() {
    super.initState();
    _selectedType = _resolveInitialType(widget.initialType);
  }

  ManualEntryType _resolveInitialType(String? initialType) {
    switch (initialType) {
      case DataTypes.glucose:
        return ManualEntryType.glucose;
      case DataTypes.temp:
        return ManualEntryType.temperature;
      case DataTypes.bp:
        return ManualEntryType.bloodPressure;
      default:
        return ManualEntryType.glucose;
    }
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );

    if (pickedTime == null || !mounted) return;

    setState(() {
      _selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _saveReading() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar(_invalidInputText, isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      switch (_selectedType) {
        case ManualEntryType.glucose:
          await _manualEntryService.saveGlucose(
            glucose: int.parse(_glucoseController.text.trim()),
            timestamp: _selectedDateTime,
          );
          break;
        case ManualEntryType.temperature:
          await _manualEntryService.saveTemperature(
            temperature: double.parse(_temperatureController.text.trim()),
            timestamp: _selectedDateTime,
          );
          break;
        case ManualEntryType.bloodPressure:
          await _manualEntryService.saveBloodPressure(
            systolic: int.parse(_systolicController.text.trim()),
            diastolic: int.parse(_diastolicController.text.trim()),
            pulse: int.parse(_pulseController.text.trim()),
            timestamp: _selectedDateTime,
          );
          break;
      }

      if (!mounted) return;
      _showSnackBar(_readingAddedText);
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      _showSnackBar(_invalidInputText, isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSnackBar(String text, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  String? _validateInt(String? value, {int min = 1, int max = 1000}) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed < min || parsed > max) {
      return _invalidInputText;
    }
    return null;
  }

  String? _validateDouble(
    String? value, {
    double min = 1,
    double max = 1000,
  }) {
    final parsed = double.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed < min || parsed > max) {
      return _invalidInputText;
    }
    return null;
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _readingTypeText,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ChoiceChip(
              label: Text(_glucoseText),
              selected: _selectedType == ManualEntryType.glucose,
              onSelected: (_) {
                setState(() => _selectedType = ManualEntryType.glucose);
              },
            ),
            ChoiceChip(
              label: Text(_temperatureText),
              selected: _selectedType == ManualEntryType.temperature,
              onSelected: (_) {
                setState(() => _selectedType = ManualEntryType.temperature);
              },
            ),
            ChoiceChip(
              label: Text(_bloodPressureText),
              selected: _selectedType == ManualEntryType.bloodPressure,
              onSelected: (_) {
                setState(() => _selectedType = ManualEntryType.bloodPressure);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateTimeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, color: Colors.teal),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _measurementTimeText,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedDateTime.toLocal().toString().substring(0, 16),
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _pickDateTime,
            child: Text(_changeTimeText),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    bool allowDecimal = false,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildFields() {
    switch (_selectedType) {
      case ManualEntryType.glucose:
        return _buildNumberField(
          controller: _glucoseController,
          label: _glucoseLabel,
          validator: (value) => _validateInt(value, min: 20, max: 600),
        );
      case ManualEntryType.temperature:
        return _buildNumberField(
          controller: _temperatureController,
          label: _temperatureLabel,
          allowDecimal: true,
          validator: (value) => _validateDouble(value, min: 30, max: 45),
        );
      case ManualEntryType.bloodPressure:
        return Column(
          children: [
            _buildNumberField(
              controller: _systolicController,
              label: _systolicLabel,
              validator: (value) => _validateInt(value, min: 60, max: 260),
            ),
            const SizedBox(height: 12),
            _buildNumberField(
              controller: _diastolicController,
              label: _diastolicLabel,
              validator: (value) => _validateInt(value, min: 40, max: 180),
            ),
            const SizedBox(height: 12),
            _buildNumberField(
              controller: _pulseController,
              label: _pulseLabel,
              validator: (value) => _validateInt(value, min: 30, max: 220),
            ),
          ],
        );
    }
  }

  @override
  void dispose() {
    _glucoseController.dispose();
    _temperatureController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleText),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: [
                    Colors.teal.shade700,
                    Colors.teal.shade500,
                  ],
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.edit_note, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _manualHintText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildTypeSelector(),
            const SizedBox(height: 20),
            _buildDateTimeCard(),
            const SizedBox(height: 20),
            _buildFields(),
            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveReading,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_chart),
                label: Text(_saveText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
