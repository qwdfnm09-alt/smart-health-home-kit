import 'dart:convert';

class AIConfig {
  /// 🔑 المفتاح الخاص بك (مؤمن عبر التعتيم)
  static String get geminiApiKey {
    // المفتاح الأصلي: AIzaSyAhrsyCxq9Xx3D7Glh_3ttacllgsUei4cE
    final List<int> keyData = [
      65, 73, 122, 97, 83, 121, 65, 104, 114, 115, 121, 67, 120, 113, 57, 88, 120, 51, 68, 55, 71, 108, 104, 95, 51, 116, 116, 97, 99, 108, 108, 103, 115, 85, 101, 105, 52, 99, 69
    ];
    return utf8.decode(keyData);
  }
  
  static const String modelName = 'gemini-flash-latest'; // الموديل القياسي المستقر
}
