// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => ' الصحة الذكية';

  @override
  String get homeTitle => 'أجهزة الصحة الذكية';

  @override
  String get glucoseMonitor => 'جهاز قياس السكر';

  @override
  String get bloodPressureMonitor => 'جهاز قياس الضغط';

  @override
  String get thermometer => 'جهاز قياس الحرارة';

  @override
  String get startScan => 'ابدأ البحث عن الأجهزة';

  @override
  String get stopScan => 'إيقاف البحث';

  @override
  String get viewAlerts => 'عرض التنبيهات';

  @override
  String get generateReport => 'توليد التقرير';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get profilePage => 'صفحة الملف الشخصي';

  @override
  String get settings => 'الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String get healthReportTitle => 'تقرير الحالة الصحية';

  @override
  String get noDataToGenerateReport => 'لا توجد بيانات كافية لتوليد التقرير';

  @override
  String get reportGeneratedSuccessfully => 'تم توليد التقرير بنجاح!';

  @override
  String get errorGeneratingReport => 'حدث خطأ أثناء توليد التقرير';

  @override
  String get healthAlerts => 'التنبيهات الصحية';

  @override
  String get noAlerts => 'لا توجد تنبيهات حالياً.';

  @override
  String get glucoseDevice => 'جهاز قياس السكر';

  @override
  String get latestReading => '🩸 آخر قراءة';

  @override
  String get noReading => 'لا توجد قراءة بعد.';

  @override
  String get chart => '📈 الرسم البياني';

  @override
  String get autoConnection =>
      'يتم الاتصال بالجهاز واستقبال البيانات تلقائيًا.';

  @override
  String get smartAlertEnabled => 'التنبيه الذكي مفعّل للقيم غير الطبيعية.';

  @override
  String get notEnoughData => 'لا توجد قراءات كافية لعرض الرسم البياني.';

  @override
  String atTime(Object hour, Object minute) {
    return 'في $hour:$minute';
  }

  @override
  String get bloodPressureDevice => 'جهاز قياس الضغط';

  @override
  String get lastReading => 'آخر قراءة';

  @override
  String get at => 'في';

  @override
  String get thermometerDevice => 'جهاز قياس الحرارة';

  @override
  String get unknownDevice => 'جهاز غير معروف';

  @override
  String get smartDevices => 'أجهزة الصحة الذكية';

  @override
  String get age => 'العمر';

  @override
  String get gender => 'النوع';

  @override
  String get healthConditions => 'الحالات الصحية';

  @override
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String get save => 'حفظ';

  @override
  String get profileSavedSuccessfully => 'تم حفظ البيانات بنجاح!';

  @override
  String get profileCreatedSuccessfully => 'تم إنشاء الملف الشخصي بنجاح!';

  @override
  String get profileUpdatedSuccessfully => 'تم تحديث الملف الشخصي بنجاح!';

  @override
  String get welcomeMessage => '🎉 تم إنشاء ملفك بنجاح!';

  @override
  String get startUsing => 'ابدأ الاستخدام';

  @override
  String get startUsage => 'ابدأ الاستخدام';

  @override
  String get theme => 'الثيم';

  @override
  String get resetAppData => 'حذف جميع البيانات';

  @override
  String get userData => 'بيانات المستخدم';

  @override
  String get confirmResetTitle => 'هل أنت متأكد؟';

  @override
  String get confirmResetMessage => 'سيتم حذف جميع البيانات ولا يمكن التراجع.';

  @override
  String get confirm => 'تأكيد';

  @override
  String get cancel => 'إلغاء';

  @override
  String get fontSize => 'حجم الخط';

  @override
  String get enableAlerts => 'تفعيل التنبيهات';

  @override
  String get availableDevices => 'الأجهزة المتاحة';

  @override
  String get enableDataEncryption => 'تفعيل تشفير البيانات';

  @override
  String get noDataToDisplay => 'لا توجد بيانات للعرض';

  @override
  String get outOfRangeWarning => '⚠ القراءة خارج النطاق الطبيعي';

  @override
  String get withinNormalRange => '✅ القراءة في النطاق الطبيعي';

  @override
  String get recentReadings => 'آخر القراءات';

  @override
  String get viewAll => 'عرض الكل';

  @override
  String get done => 'تم';

  @override
  String get noDevicesFound => 'لا توجد أجهزة متاحة';

  @override
  String get reconnect => 'إعادة الاتصال';

  @override
  String get reportGenerated => '✅ تم إنشاء التقرير بنجاح';

  @override
  String get alerts => 'التنبيهات';
}
