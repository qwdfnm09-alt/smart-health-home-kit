import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/storage_service.dart';
import '../models/app_theme_mode.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  final Function(Locale) onLocaleChanged;
  final AppThemeMode currentTheme;
  final Function(AppThemeMode) onThemeChanged;
  final bool alertsEnabled;
  final Function(bool) onAlertsToggle;
  final Locale initialLocale;

  const SettingsScreen({
    super.key,
    required this.onLocaleChanged,
    required this.currentTheme,
    required this.onThemeChanged,
    required this.alertsEnabled,
    required this.onAlertsToggle,
    required this.initialLocale,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Locale _selectedLocale;
  late AppThemeMode _selectedTheme;
  late bool _alertsEnabled;

  @override
  void initState() {
    super.initState();
    _selectedLocale = widget.initialLocale;
    _selectedTheme = widget.currentTheme;
    _alertsEnabled = widget.alertsEnabled;
  }

  void _changeLanguage(Locale newLocale) {
    setState(() {
      _selectedLocale = newLocale;
    });
    widget.onLocaleChanged(newLocale);
    StorageService().saveLocale(newLocale.languageCode);
  }

  void _changeTheme(AppThemeMode newTheme) {
    setState(() {
      _selectedTheme = newTheme;
    });
    widget.onThemeChanged(newTheme);
  }

  Future<void> _toggleAlerts(bool value) async {
    setState(() {
      _alertsEnabled = value;
    });
    await widget.onAlertsToggle(value);
    await NotificationService.syncNotifications(enabled: value);
  }

  Widget buildSettingCard({
    required IconData icon,
    required String title,
    Widget? trailing,
    String? subtitle,
    VoidCallback? onTap, // 👈 أضف دي
  }) {
    return GestureDetector( // ✅ ده المهم
        onTap: onTap,
        child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
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
          // 🔥 Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white),
          ),

          const SizedBox(width: 16),

          // 🔥 Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70),
                  ),
              ],
            ),
          ),

          if (trailing != null) trailing,
        ],
      ),
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.settings),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // اللغة
              buildSettingCard(
                icon: Icons.language,
                title: t.language,
                subtitle: _selectedLocale.languageCode == 'ar' ? "العربية" : "English",
                trailing: DropdownButton<Locale>(
                  dropdownColor: Colors.blueGrey.shade800,
                  value: _selectedLocale,
                  underline: const SizedBox(),
                  iconEnabledColor: Colors.white,
                  onChanged: (Locale? newValue) {
                    if (newValue != null) {
                      _changeLanguage(newValue);
                    }
                  },
                  items: const [
                    DropdownMenuItem(
                      value: Locale('ar'),
                      child: Text('العربية', style: TextStyle(color: Colors.white)),
                    ),
                    DropdownMenuItem(
                      value: Locale('en'),
                      child: Text('English', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // الثيم
              buildSettingCard(
                icon: Icons.dark_mode,
                title: t.theme,
                subtitle: _selectedTheme == AppThemeMode.dark ? "Dark" : "Light",
                trailing: DropdownButton<AppThemeMode>(
                  dropdownColor: Colors.blueGrey.shade800,
                  value: _selectedTheme,
                  underline: const SizedBox(),
                  iconEnabledColor: Colors.white,
                  onChanged: (AppThemeMode? newTheme) {
                    if (newTheme != null) {
                      _changeTheme(newTheme);
                    }
                  },
                  items: const [
                    DropdownMenuItem(
                      value: AppThemeMode.light,
                      child: Text('Light', style: TextStyle(color: Colors.white)),
                    ),
                    DropdownMenuItem(
                      value: AppThemeMode.dark,
                      child: Text('Dark', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // التنبيهات
              buildSettingCard(
                icon: Icons.notifications,
                title: t.enableAlerts,
                trailing: Switch(
                  value: _alertsEnabled,
                  onChanged: _toggleAlerts,
                  activeThumbColor: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              // زر تفعيل/ايقاف تشفير البيانات
              buildSettingCard(
                icon: Icons.lock,
                title: t.enableDataEncryption,
                subtitle: _selectedLocale.languageCode == 'ar'
                    ? 'يتم حفظ بيانات التطبيق الحساسة محليًا باستخدام تخزين مشفر.'
                    : 'Sensitive app data is stored locally using encrypted storage.',
                trailing: const Icon(Icons.verified_user, color: Colors.white),
              ),

              const SizedBox(height:16),

              // بيانات المستخدم مع تغليف ببطاقة لزيادة الوضوح وترتيب الأزرار
              Text(
                t.userData,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 18),

              buildSettingCard(
                icon: Icons.person,
                title: t.userData,
                subtitle: t.editProfile,
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                onTap: () {
                  Navigator.pushNamed(context, '/edit_profile');
                },
              ),

              const SizedBox(height: 16),

              buildSettingCard(
                icon: Icons.privacy_tip,
                title: _selectedLocale.languageCode == 'ar' ? 'سياسة الخصوصية' : 'Privacy Policy',
                subtitle: _selectedLocale.languageCode == 'ar' ? 'كيف نحمي بياناتك' : 'How we protect your data',
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                onTap: () {
                  Navigator.pushNamed(context, '/privacy_policy');
                },
              ),

              const SizedBox(height: 16),

              buildSettingCard(
                icon: Icons.delete_forever,
                title: t.resetAppData,
                subtitle: t.confirmResetMessage,
                trailing: const Icon(Icons.warning, color: Colors.white),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(t.confirmResetTitle),
                      content: Text(t.confirmResetMessage),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(t.cancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(t.confirm),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await StorageService().resetAllData();
                    if (!context.mounted) return;
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/edit_profile',
                          (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

