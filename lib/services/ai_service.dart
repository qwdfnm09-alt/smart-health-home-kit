import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';
import '../config/ai_config.dart';
import '../models/health_data.dart';
import '../models/user_profile.dart';
import '../models/routine_task.dart';
import '../models/health_advice.dart';
import 'storage_service.dart';
import '../utils/logger.dart';
import '../utils/constants.dart';

class AIResponse {
  final String text;
  final bool addedAdvice;
  final bool addedTask;

  AIResponse({required this.text, this.addedAdvice = false, this.addedTask = false});
}

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  void init() {
    if (!AIConfig.hasGeminiApiKey) {
      AppLogger.logError("⚠️ Gemini API Key is missing!");
    }
  }

  Future<AIResponse> sendMessage(
    String userMessage, {
    List<int>? imageBytes,
    List<Map<String, String>> chatHistory = const [],
  }) async {
    if (!AIConfig.hasGeminiApiKey) {
      return AIResponse(
        text: "خدمة الذكاء الاصطناعي غير مفعلة حاليًا لأن مفتاح Gemini غير مضبوط.",
      );
    }

    final String apiKey = AIConfig.geminiApiKey;
    final String model = AIConfig.modelName;
    final String url = "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey";

    try {
      final storage = StorageService();
      final profile = storage.getUserProfile();
      
      final bpHistory = storage.getAllByType(DataTypes.bp).reversed.take(10).toList();
      final glucoseHistory = storage.getAllByType(DataTypes.glucose).reversed.take(10).toList();
      final tempHistory = storage.getAllByType(DataTypes.temp).reversed.take(10).toList();

      String systemInstruction = _buildSystemPrompt(profile, bpHistory, glucoseHistory, tempHistory);

      List<Map<String, dynamic>> contents = [];
      for (var msg in chatHistory) {
        contents.add({
          "role": msg['role'] == 'user' ? 'user' : 'model',
          "parts": [{"text": msg['text']}]
        });
      }

      List<Map<String, dynamic>> currentParts = [
        {"text": "System Instructions: $systemInstruction\n\nUser Message: $userMessage"}
      ];

      if (imageBytes != null) {
        currentParts.add({
          "inline_data": {
            "mime_type": "image/jpeg",
            "data": base64Encode(imageBytes)
          }
        });
      }

      contents.add({"role": "user", "parts": currentParts});

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"contents": contents}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String aiText = data['candidates'][0]['content']['parts'][0]['text'] ?? "";
        
        bool adviceStatus = await _processSuggestedAdvice(aiText);
        bool taskStatus = await _processSuggestedTasks(aiText);
        
        String cleanText = aiText
            .replaceAll(RegExp(r'\[TASK:.*?\]'), '')
            .replaceAll(RegExp(r'\[ADVICE:.*?\]'), '')
            .trim();

        return AIResponse(text: cleanText, addedAdvice: adviceStatus, addedTask: taskStatus);
      } else if (response.statusCode == 429) {
        return AIResponse(text: "عذراً، لقد انتهت حصة الرسائل المجانية المتاحة حالياً. يرجى الانتظار دقيقة والمحاولة مرة أخرى.");
      } else if (response.statusCode == 503) {
        return AIResponse(text: "سيرفرات جوجل مزدحمة حالياً. يرجى المحاولة مرة أخرى بعد ثوانٍ قليلة.");
      } else {
        final errorData = jsonDecode(response.body);
        String msg = errorData['error']?['message'] ?? "خطأ غير معروف";
        return AIResponse(text: "حدث خطأ في الاتصال ($msg).");
      }
    } catch (e) {
      AppLogger.logError("❌ AI Error: $e");
      return AIResponse(text: "عذراً، حدث خطأ في معالجة طلبك.");
    }
  }

  Future<bool> _processSuggestedAdvice(String text) async {
    final adviceRegex = RegExp(r'\[ADVICE: (.*?)\]');
    final match = adviceRegex.firstMatch(text);
    if (match == null) return false;

    try {
      final jsonStr = match.group(1);
      if (jsonStr == null) return false;
      final adviceData = jsonDecode(jsonStr);

      final newAdvice = HealthAdvice(
        id: const Uuid().v4(),
        title: adviceData['title'] ?? "نصيحة ذكية",
        description: adviceData['desc'] ?? "",
        category: AdviceCategory.lifestyle,
        priority: AdvicePriority.medium,
        measurementTime: DateTime.now(),
        risk: AdviceRisk.normal,
        type: "ai",
      );

      await Hive.box<HealthAdvice>('adviceBox').add(newAdvice);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _processSuggestedTasks(String text) async {
    final taskRegex = RegExp(r'\[TASK: (.*?)\]');
    final matches = taskRegex.allMatches(text);
    if (matches.isEmpty) return false;

    final storage = StorageService();
    List<RoutineTask> currentTasks = storage.getDailyRoutine();

    bool added = false;
    for (var match in matches) {
      try {
        final jsonStr = match.group(1);
        if (jsonStr == null) continue;
        final taskData = jsonDecode(jsonStr);
        currentTasks.add(RoutineTask(
          title: taskData['title'] ?? "مهمة صحية",
          description: taskData['desc'] ?? "",
          time: taskData['time'] ?? "09:00 AM",
          category: taskData['cat'] ?? "Monitoring",
          type: 'ai',
        ));
        added = true;
      } catch (e) {
        AppLogger.logError("Error parsing AI task: $e");
      }
    }
    if (added) await storage.saveDailyRoutine(currentTasks);
    return added;
  }

  String _buildSystemPrompt(UserProfile? profile, List<HealthData> bp, List<HealthData> glucose, List<HealthData> temp) {
    String pInfo = profile != null 
      ? "المستخدم: ${profile.name}, عمره: ${profile.age}, جنسه: ${profile.gender}, حالاته: ${profile.conditions.join(', ')}."
      : "بيانات المستخدم ناقصة.";

    String healthLog = "سجل القراءات الأخير:\n"
      "- الضغط: ${bp.map((d) => "${d.systolic}/${d.diastolic}").join(', ')}\n"
      "- السكر: ${glucose.map((d) => d.value).join(', ')}\n"
      "- الحرارة: ${temp.map((d) => d.value).join(', ')}";

    return """
أنت "T-MED AI"، استشاري صحي ذكي خبير وصديق للمستخدم.
$pInfo
$healthLog

قواعد المحادثة الهامة:
1. **الرد البشري أولاً**: تحدث مع المستخدم بشكل طبيعي وودود، اشرح له النصيحة الطبية أو الروتين المقترح داخل نص المحادثة بأسلوبك الخاص.
2. **التسجيل البرمجي ثانياً**: بعد أن تنتهي من كلامك تماماً، أضف الأوسمة التالية في نهاية الرسالة ليقوم النظام بحفظها في الشاشات المخصصة:
   - للنصائح: [ADVICE: {"title": "عنوان", "desc": "وصف"}]
   - للروتين: [TASK: {"title": "...", "desc": "...", "time": "...", "cat": "..."}]
3. **تحليل الصور**: إذا أرسل صورة، اشرح محتواها (روشتة، أكل، تحليل) في الشات بوضوح قبل إضافة الوسم.
4. **الأمان**: وجه المستخدم للطبيب في حالات الخطر، واستخدم Markdown لتنسيق ردك.
5. **الخاتمة**: أنهِ كلامك دائماً بجملة: "هذه المعلومات استرشادية فقط ولا تعوض عن التشخيص الطبي".
""";
  }

  void resetChat() {}
}
