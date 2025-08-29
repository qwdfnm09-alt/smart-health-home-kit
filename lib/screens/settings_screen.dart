import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/storage_service.dart';
import '../models/app_theme_mode.dart';

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
  bool _encryptionEnabled = false; // حالة تشفير البيانات

  @override
  void initState() {
    super.initState();
    _selectedLocale = widget.initialLocale;
    _selectedTheme = widget.currentTheme;
    _alertsEnabled = widget.alertsEnabled;

    _loadEncryptionSetting();
  }

  Future<void> _loadEncryptionSetting() async {
    final enabled = await StorageService().isEncryptionEnabled();
    setState(() {
      _encryptionEnabled = enabled;
    });
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

  void _toggleAlerts(bool value) {
    setState(() {
      _alertsEnabled = value;
    });
    widget.onAlertsToggle(value);
  }

  void _toggleEncryption(bool value) async {
    setState(() {
      _encryptionEnabled = value;
    });
    await StorageService().setEncryptionEnabled(value);
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
              Text(
                t.language,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              DropdownButton<Locale>(
                value: _selectedLocale,
                onChanged: (Locale? newValue) {
                  if (newValue != null) {
                    _changeLanguage(newValue);
                  }
                },
                items: const [
                  DropdownMenuItem(
                    value: Locale('ar'),
                    child: Text('العربية'),
                  ),
                  DropdownMenuItem(
                    value: Locale('en'),
                    child: Text('English'),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // الثيم
              Text(
                t.theme,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              DropdownButton<AppThemeMode>(
                value: _selectedTheme,
                onChanged: (AppThemeMode? newTheme) {
                  if (newTheme != null) {
                    _changeTheme(newTheme);
                  }
                },
                items: const [
                  DropdownMenuItem(
                    value: AppThemeMode.light,
                    child: Text('Light'),
                  ),
                  DropdownMenuItem(
                    value: AppThemeMode.dark,
                    child: Text('Dark'),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // التنبيهات
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    t.enableAlerts,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Switch(
                    value: _alertsEnabled,
                    onChanged: _toggleAlerts,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // زر تفعيل/ايقاف تشفير البيانات
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    t.enableDataEncryption, // تأكد تضيف المفتاح ده في الترجمة
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Switch(
                    value: _encryptionEnabled,
                    onChanged: _toggleEncryption,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // بيانات المستخدم مع تغليف ببطاقة لزيادة الوضوح وترتيب الأزرار
              Text(
                t.userData,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Column(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: Text(t.editProfile),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/edit_profile');
                        },
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.delete_forever),
                        label: Text(t.resetAppData),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        onPressed: () async {
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
                            if (!context.mounted) return; // ✅ التحقق بالطريقة الجديدة
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/welcome',
                                  (route) => false,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

