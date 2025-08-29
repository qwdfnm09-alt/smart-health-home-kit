import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../l10n/app_localizations.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String _gender = 'ذكر';
  final _conditionsController = TextEditingController();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _isEditing = false; // هل المستخدم يعدّل بيانات موجودة؟

  @override
  void initState() {
    super.initState();
    final profile = StorageService().getUserProfile();
    if (profile != null) {
      _isEditing = true; // تعديل بيانات
      _nameController.text = profile.name;
      _ageController.text = profile.age.toString();
      _gender = profile.gender;
      _conditionsController.text = profile.conditions.join(', ');
    }
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final newProfile = UserProfile(
        name: _nameController.text.trim(),
        age: int.tryParse(_ageController.text) ?? 0,
        gender: _gender,
        conditions:
        _conditionsController.text.split(',').map((s) => s.trim()).toList(),
      );
      await StorageService().saveUserProfile(newProfile);

      // لو الملف جديد، نكتب المفتاح عشان تظهر رسالة نجاح إنشاء الملف مرة واحدة
      if (!_isEditing) {
        await _secureStorage.write(key: 'profileCreated', value: 'true');
      }

      if (mounted) {
        final t = AppLocalizations.of(context)!;
        final message = _isEditing
            ? t.profileUpdatedSuccessfully
            : t.profileCreatedSuccessfully;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );

        await StorageService().markProfileCompleted();

        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/welcome', (_) => false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.editProfile),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: t.profile),
                validator: (value) =>
                value == null || value.isEmpty ? '⚠️' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: t.age),
                validator: (value) =>
                value == null || value.isEmpty ? '⚠️' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: InputDecoration(labelText: t.gender),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _gender = value;
                    });
                  }
                },
                items: const [
                  DropdownMenuItem(value: 'ذكر', child: Text('ذكر')),
                  DropdownMenuItem(value: 'أنثى', child: Text('أنثى')),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _conditionsController,
                decoration: InputDecoration(labelText: t.healthConditions),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _saveProfile,
                icon: const Icon(Icons.save),
                label: Text(t.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

