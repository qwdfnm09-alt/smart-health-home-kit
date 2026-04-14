import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'سياسة الخصوصية' : 'Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              isArabic ? 'جمع البيانات' : 'Data Collection',
              isArabic 
                ? 'نحن نجمع البيانات الصحية (مثل ضغط الدم، السكر، والحرارة) من أجهزتك المتصلة عبر البلوتوث لغرض عرضها لك وتحليلها بواسطة الذكاء الاصطناعي.'
                : 'We collect health data (BP, Glucose, Temperature) from your connected BLE devices to display and analyze them using AI.',
            ),
            _buildSection(
              isArabic ? 'التخزين والأمان' : 'Storage & Security',
              isArabic
                ? 'يتم تخزين جميع بياناتك الصحية محلياً على جهازك بتنسيق مشفر (AES). نحن لا نقوم برفع بياناتك الصحية إلى خوادم خارجية إلا عند التفاعل مع خدمة الذكاء الاصطناعي (Gemini) لتحليل النصائح.'
                : 'All your health data is stored locally on your device in an encrypted format (AES). We do not upload your health data to external servers except when interacting with the AI service (Gemini) for advice analysis.',
            ),
            _buildSection(
              isArabic ? 'أذونات البلوتوث والموقع' : 'Bluetooth & Location Permissions',
              isArabic
                ? 'يتطلب التطبيق الوصول إلى البلوتوث والموقع (في الإصدارات القديمة من أندرويد) للبحث عن الأجهزة الطبية والاتصال بها. نحن لا نتتبع موقعك الجغرافي.'
                : 'The app requires Bluetooth and Location access (on older Android versions) to scan and connect to medical devices. We do not track your geographic location.',
            ),
            _buildSection(
              isArabic ? 'الذكاء الاصطناعي' : 'Artificial Intelligence',
              isArabic
                ? 'يستخدم التطبيق خدمة Google Gemini لتحليل بياناتك وتقديم نصائح صحية. تخضع هذه البيانات لسياسة خصوصية Google عند إرسالها للتحليل.'
                : 'The app uses Google Gemini to analyze your data and provide health advice. This data is subject to Google\'s privacy policy when sent for analysis.',
            ),
            const SizedBox(height: 20),
            Text(
              isArabic ? 'آخر تحديث: أبريل 2026' : 'Last Updated: April 2026',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
        ],
      ),
    );
  }
}
