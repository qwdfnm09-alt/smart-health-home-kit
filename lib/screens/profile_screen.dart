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

  Widget buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
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
        child: SingleChildScrollView(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
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
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: const Icon(Icons.person, size: 45, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _profile!.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${_profile!.age} • ${_profile!.gender}",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
                )
            ),
            const SizedBox(height: 20),
            buildInfoCard(
              icon: Icons.person,
              title: local.profile,
              value: _profile!.name,
            ),

            buildInfoCard(
              icon: Icons.cake,
              title: local.age,
              value: _profile!.age.toString(),
            ),

            buildInfoCard(
              icon: Icons.wc,
              title: local.gender,
              value: _profile!.gender,
            ),

            buildInfoCard(
              icon: Icons.health_and_safety,
              title: local.healthConditions,
              value: _profile!.conditions.join(', '),
            ),
            const SizedBox(height: 10),
            Center(
              child:Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.pushNamed(context, '/edit_profile').then((_) {
                      setState(() {
                        _profile = StorageService().getUserProfile();
                      });
                    });
                  },
                child: Container(
                  width: double.infinity,
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
                      const Icon(Icons.edit, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        local.editProfile,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ),
            )],
        ),
      ),
      )
    );
  }
}
