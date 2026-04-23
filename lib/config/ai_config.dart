class AIConfig {
  static const String _geminiApiKey =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  static String get geminiApiKey => _geminiApiKey.trim();
  static bool get hasGeminiApiKey => geminiApiKey.isNotEmpty;

  static const String modelName = 'gemini-flash-latest';
}
