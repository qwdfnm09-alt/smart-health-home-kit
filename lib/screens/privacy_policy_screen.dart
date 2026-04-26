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
                ? 'يقوم التطبيق بجمع البيانات الصحية التي تدخلها بنفسك أو التي تتم قراءتها من الأجهزة الطبية المتصلة، مثل ضغط الدم والسكر والحرارة، بهدف عرضها لك ومساعدتك على متابعتها داخل التطبيق.'
                : 'The app collects health data that you enter manually or that is read from connected medical devices, such as blood pressure, glucose, and temperature, in order to display and help you track it inside the app.',
            ),
            _buildSection(
              isArabic ? 'التخزين والأمان' : 'Storage & Security',
              isArabic
                ? 'يتم تخزين بياناتك الصحية وبيانات الملف الشخصي محلياً على جهازك باستخدام تخزين مشفر. لا يتم إرسال هذه البيانات إلى خوادم خارجية بشكل تلقائي لمجرد استخدام التطبيق اليومي.'
                : 'Your health data and profile data are stored locally on your device using encrypted storage. This data is not automatically sent to external servers as part of normal day-to-day app usage.',
            ),
            _buildSection(
              isArabic ? 'أذونات البلوتوث والموقع' : 'Bluetooth & Location Permissions',
              isArabic
                ? 'يستخدم التطبيق أذونات البلوتوث للبحث عن الأجهزة الطبية والاتصال بها. وقد يحتاج التطبيق إلى إذن الموقع على بعض إصدارات أندرويد الأقدم حتى تعمل عملية البحث عن الأجهزة بشكل صحيح. نحن لا نستخدم هذه الأذونات لتتبع موقعك الجغرافي.'
                : 'The app uses Bluetooth permissions to scan for medical devices and connect to them. On some older Android versions, location permission may also be required for device scanning to work correctly. We do not use these permissions to track your geographic location.',
            ),
            _buildSection(
              isArabic ? 'الخدمات الخارجية' : 'External Services',
              isArabic
                ? 'عند استخدامك للمحادثة الذكية أو إرسال نصوص أو صور للتحليل، يتم إرسال المحتوى الذي تختاره إلى خدمة Google Gemini لمعالجة الطلب. كما قد يتم إرسال تقارير الأعطال التقنية إلى Firebase Crashlytics للمساعدة في تحسين استقرار التطبيق. لا يتم استخدام هذه الخدمات إلا في نطاق وظائفها المذكورة.'
                : 'When you use the AI chat or submit text or images for analysis, the content you choose to send is transmitted to Google Gemini to process your request. Technical crash reports may also be sent to Firebase Crashlytics to help improve app stability. These services are used only within their stated functions.',
            ),
            _buildSection(
              isArabic ? 'المشاركة بواسطة المستخدم' : 'User-Initiated Sharing',
              isArabic
                ? 'إذا اخترت مشاركة تقرير PDF أو إرسال ملخص عبر واتساب، فإن المشاركة تتم فقط بناءً على إجراء صريح منك. لا يقوم التطبيق بمشاركة بياناتك الطبية تلقائياً مع أي جهة خارجية.'
                : 'If you choose to share a PDF report or send a summary through WhatsApp, sharing happens only as a direct action initiated by you. The app does not automatically share your medical data with third parties.',
            ),
            _buildSection(
              isArabic ? 'الأذونات الإضافية' : 'Additional Permissions',
              isArabic
                ? 'قد يطلب التطبيق إذن الميكروفون إذا استخدمت الإدخال الصوتي داخل المحادثة الذكية، كما قد يطلب إذن الإشعارات لإرسال التذكيرات المحلية. ويمكنك التحكم في هذه الأذونات من إعدادات جهازك.'
                : 'The app may request microphone access if you use voice input inside the AI chat, and it may request notification permission to send local reminders. You can control these permissions from your device settings.',
            ),
            _buildSection(
              isArabic ? 'التحكم في البيانات' : 'Data Control',
              isArabic
                ? 'يمكنك حذف بيانات التطبيق من خلال خيار إعادة الضبط داخل الإعدادات. كما يمكنك التوقف عن استخدام ميزات مثل الذكاء الاصطناعي أو مشاركة التقارير إذا كنت لا ترغب في إرسال أي محتوى خارج جهازك.'
                : 'You can clear app data through the reset option inside settings. You may also stop using features such as AI or report sharing if you do not want to send any content outside your device.',
            ),
            _buildSection(
              isArabic ? 'تنبيه طبي' : 'Medical Notice',
              isArabic
                ? 'هذا التطبيق مخصص للمتابعة والتنظيم والمساعدة العامة، ولا يُعد بديلاً عن الطبيب أو عن التشخيص والعلاج الطبي المتخصص.'
                : 'This app is intended for tracking, organization, and general assistance, and it is not a substitute for a physician or for professional medical diagnosis or treatment.',
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
