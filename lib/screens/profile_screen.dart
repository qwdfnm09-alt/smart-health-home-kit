import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/storage_service.dart';
import '../models/user_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _profile = StorageService().getUserProfile();

    // ✅ لو مفيش بيانات → افتح شاشة تعديل الملف الشخصي تلقائيًا
    if (_profile == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamed(context, '/edit_profile').then((_) {
          // ✅ بعد الرجوع من شاشة التعديل، نحدث الحالة
          setState(() {
            _profile = StorageService().getUserProfile();
          });
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(local.profile),
      ),
      body: _profile == null
          ? Center(
        child: Text(
          local.noDataToGenerateReport,
          style: const TextStyle(fontSize: 16),
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              local.profilePage,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Text('👤 ${local.profile}: ${_profile!.name}'),
            const SizedBox(height: 12),
            Text('🎂 ${local.age}: ${_profile!.age}'),
            const SizedBox(height: 12),
            Text('⚥ ${local.gender}: ${_profile!.gender}'),
            const SizedBox(height: 12),
            Text('🩺 ${local.healthConditions}: ${_profile!.conditions.join(', ')}'),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: Text(local.editProfile),
                onPressed: () {
                  Navigator.pushNamed(context, '/edit_profile').then((_) {
                    setState(() {
                      _profile = StorageService().getUserProfile();
                    });
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
