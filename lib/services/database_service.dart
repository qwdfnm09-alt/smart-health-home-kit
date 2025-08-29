import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

class DatabaseService {
  static Future<void> init() async {
    final dir = await path_provider.getApplicationDocumentsDirectory();
    Hive.init(dir.path);

    // هنا ممكن نضيف الـ adapters بتوعنا بعد ما نعرّف الموديل
  }

  // فتح Box
  static Future<Box> openBox(String boxName) async {
    return await Hive.openBox(boxName);
  }

  // إضافة بيانات
  static Future<void> addData(String boxName, dynamic data) async {
    final box = await openBox(boxName);
    await box.add(data);
  }

  // جلب كل البيانات
  static Future<List<dynamic>> getAllData(String boxName) async {
    final box = await openBox(boxName);
    return box.values.toList();
  }
}
