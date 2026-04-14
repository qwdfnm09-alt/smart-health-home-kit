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
  // ✅ الشخصية (الجديدة)
  PersonalityType _personality = PersonalityType.balanced;

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
      _personality = profile.personality; // ✅ تحميل الشخصية

    }
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final newProfile = UserProfile(
        name: _nameController.text.trim(),
        age: int.tryParse(_ageController.text) ?? 0,
        gender: _gender,
        conditions:_conditionsController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        personality: _personality, // ✅ مهم جدًا
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

  Widget _buildInputCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.blueGrey.shade800,
            Colors.teal.shade700,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.editProfile),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // 🔥 HEADER
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    Colors.blueGrey.shade800,
                    Colors.teal.shade700,
                  ],
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: CircleAvatar(
                      radius: 38,
                      backgroundColor: Colors.teal.shade300,
                      child: const Icon(Icons.person, size: 40, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isEditing ? "Edit Profile" : "Create Profile",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 🔥 NAME
            _buildInputCard(
              child: TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: t.profile,
                  labelStyle: const TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.white),
                validator: (value) =>
                value == null || value.isEmpty ? 'من فضلك ادخل الاسم' : null,
              ),
            ),

            // 🔥 AGE
            _buildInputCard(
              child: TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: t.age,
                  labelStyle: const TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.white),
                validator: (value) =>
                value == null || value.isEmpty ? 'من فضلك ادخل سنك' : null,
              ),
            ),

            // 🔥 GENDER
            _buildInputCard(
              child: DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: InputDecoration(
                  labelText: t.gender,
                  labelStyle: const TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                dropdownColor: Colors.blueGrey.shade800,
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _gender = value);
                  }
                },
                items: const [
                  DropdownMenuItem(value: 'ذكر', child: Text('ذكر')),
                  DropdownMenuItem(value: 'أنثى', child: Text('أنثى')),
                ],
              ),
            ),

            // 🔥 CONDITIONS
            _buildInputCard(
              child: TextFormField(
                controller: _conditionsController,
                decoration: InputDecoration(
                  labelText: t.healthConditions,
                  labelStyle: const TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ),

            // 🔥 PERSONALITY
            _buildInputCard(
              child: DropdownButtonFormField<PersonalityType>(
                initialValue: _personality,
                decoration: InputDecoration(
                  labelText: t.styleofadvice,
                  labelStyle: const TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                dropdownColor: Colors.blueGrey.shade800,
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _personality = value);
                  }
                },
                items: const [
                  DropdownMenuItem(
                    value: PersonalityType.strict,
                    child: Text('صارم'),
                  ),
                  DropdownMenuItem(
                    value: PersonalityType.balanced,
                    child: Text('متوازن'),
                  ),
                  DropdownMenuItem(
                    value: PersonalityType.relaxed,
                    child: Text('مريح'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            //  SAVE BUTTON
             AnimatedContainer(
               duration: const Duration(milliseconds: 200),
               child: GestureDetector(
                 onTap: _saveProfile,
                 child: Container(
                   padding: const EdgeInsets.all(16),
                   decoration: BoxDecoration(
                     borderRadius: BorderRadius.circular(16),
                     gradient: LinearGradient(
                       colors: [
                         Colors.teal.shade400,
                         Colors.teal.shade700,
                       ],
                     ),
                   ),
                   child: Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       const Icon(Icons.save, color: Colors.white),
                       const SizedBox(width: 10),
                       Text(
                         t.save,
                         style: const TextStyle(
                           color: Colors.white,
                           fontWeight: FontWeight.bold,
                         ),
                       ),
                     ],
                   ),
                 ),
               ),
             )],
        ),
      ),
    );
  }
}
