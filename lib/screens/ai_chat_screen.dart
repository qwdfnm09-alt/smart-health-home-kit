import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:share_plus/share_plus.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/ai_service.dart';
import '../utils/logger.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  static const String _aiDisclosureAcceptedKey = 'ai_disclosure_accepted';

  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  Uint8List? _imageBytes;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _aiDisclosureAccepted = false;

  @override
  void initState() {
    super.initState();
    _messages.add({
      'role': 'ai',
      'text': 'أهلاً بك! أنا استشارك الصحي الذكي. يمكنك التحدث إليّ مباشرة بالضغط على زر المايك 🎙️'
    });
    _loadAiDisclosureStatus();
  }

  bool get _isArabic => Localizations.localeOf(context).languageCode == 'ar';

  Future<void> _loadAiDisclosureStatus() async {
    final accepted = await _secureStorage.read(key: _aiDisclosureAcceptedKey);
    if (!mounted) return;
    setState(() {
      _aiDisclosureAccepted = accepted == 'true';
    });
  }

  Future<bool> _ensureAiDisclosureAccepted() async {
    if (_aiDisclosureAccepted) return true;
    if (!mounted) return false;

    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(_isArabic ? 'تنبيه الخصوصية' : 'Privacy Notice'),
        content: Text(
          _isArabic
              ? 'عند استخدام T-MED AI، سيتم إرسال النصوص أو الصور التي تختارها إلى Google Gemini لمعالجة طلبك. وإذا استخدمت الميكروفون، سيُطلب إذن الصوت لهذه الميزة فقط. هل توافق على المتابعة؟'
              : 'When you use T-MED AI, the text or images you choose may be sent to Google Gemini to process your request. If you use the microphone, audio permission will be requested for this feature only. Do you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(_isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(_isArabic ? 'موافق' : 'Continue'),
          ),
        ],
      ),
    );

    if (accepted == true) {
      await _secureStorage.write(key: _aiDisclosureAcceptedKey, value: 'true');
      if (!mounted) return true;
      setState(() {
        _aiDisclosureAccepted = true;
      });
      return true;
    }

    return false;
  }

  void _listen() async {
    final canProceed = await _ensureAiDisclosureAccepted();
    if (!canProceed || !mounted) return;

    if (!_isListening) {
      final status = await Permission.microphone.request();
      if (!mounted) return;
      if (status != PermissionStatus.granted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('برجاء تفعيل إذن المايك')));
        return;
      }
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (!mounted) return;
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (val) => AppLogger.logError('Speech Error: $val'),
      );
      if (!mounted) return;
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            if (!mounted) return;
            setState(() {
              _controller.text = val.recognizedWords;
            });
          },
          localeId: 'ar_SA',
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _pickImage() async {
    final canProceed = await _ensureAiDisclosureAccepted();
    if (!canProceed) return;

    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        if (!mounted) return;
        setState(() { _selectedImage = image; _imageBytes = bytes; });
      }
    } catch (e) { AppLogger.logError("Error picking image: $e"); }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _handleSendMessage() async {
    final text = _controller.text.trim();
    final imageBytes = _imageBytes;
    if (text.isEmpty && imageBytes == null) return;

    final canProceed = await _ensureAiDisclosureAccepted();
    if (!canProceed) return;

    setState(() {
      _messages.add({
        'role': 'user',
        'text': text.isEmpty ? "أرسل صورة للتحليل" : text,
        'image': imageBytes != null ? MemoryImage(imageBytes) : null,
      });
      _isLoading = true;
    });

    final currentText = text;
    final currentImage = imageBytes;
    _controller.clear();
    setState(() { _selectedImage = null; _imageBytes = null; });
    _scrollToBottom();
    try {
      final history = _messages
          .where((m) => m['text'] != null)
          .map((m) => {'role': m['role'] as String, 'text': m['text'] as String})
          .toList();

      final response = await AIService().sendMessage(currentText, imageBytes: currentImage, chatHistory: history);
      if (!mounted) return;

      setState(() {
        _messages.add({
          'role': 'ai',
          'text': response.text,
          'addedAdvice': response.addedAdvice,
          'addedTask': response.addedTask,
        });
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _messages.add({'role': 'ai', 'text': 'عذراً، حدث خطأ ما.'}); _isLoading = false; });
    }
    if (!mounted) return;
    _scrollToBottom();
  }

  @override
  void dispose() {
    _speech.stop();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Row(children: const [Icon(Icons.psychology, color: Colors.teal), SizedBox(width: 10), Text('T-MED AI', style: TextStyle(fontWeight: FontWeight.bold))]),
        actions: [IconButton(icon: const Icon(Icons.delete_sweep_outlined), onPressed: () { setState(() { _messages.clear(); _messages.add({'role': 'ai', 'text': 'تم مسح المحادثة.'}); }); })],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildChatBubble(_messages[index], isDark),
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(minHeight: 2),
          if (_selectedImage != null) _buildImagePreview(),
          _buildInputArea(isDark),
        ],
      ),
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> msg, bool isDark) {
    final isUser = msg['role'] == 'user';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) const CircleAvatar(child: Icon(Icons.psychology, size: 20)),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser ? (isDark ? Colors.teal[800] : Colors.teal[600]) : (isDark ? Colors.grey[900] : Colors.grey[200]),
                    borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: const Radius.circular(16), bottomLeft: isUser ? const Radius.circular(16) : Radius.zero, bottomRight: isUser ? Radius.zero : const Radius.circular(16)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (msg['image'] != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image(image: msg['image'], height: 200, width: double.infinity, fit: BoxFit.cover))),
                      if (isUser) Text(msg['text'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 16))
                      else MarkdownBody(data: msg['text'] ?? '', styleSheet: MarkdownStyleSheet(p: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16))),
                    ],
                  ),
                ),
                if (!isUser) ...[
                  if (msg['addedAdvice'] == true || msg['addedTask'] == true) _buildSuccessChips(msg),
                  _buildActionButtons(msg['text'] ?? ''),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isUser) const CircleAvatar(child: Icon(Icons.person, size: 20)),
        ],
      ),
    );
  }

  Widget _buildSuccessChips(Map<String, dynamic> msg) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        children: [
          if (msg['addedAdvice'] == true)
            ActionChip(
              avatar: const Icon(Icons.check_circle, size: 16, color: Colors.green),
              label: const Text("تم إضافة نصيحة AI", style: TextStyle(fontSize: 12)),
              onPressed: () => Navigator.pushNamed(context, '/advice'),
            ),
          if (msg['addedTask'] == true)
            ActionChip(
              avatar: const Icon(Icons.check_circle, size: 16, color: Colors.green),
              label: const Text("تم تحديث الروتين الذكي", style: TextStyle(fontSize: 12)),
              onPressed: () => Navigator.pushNamed(context, '/routine'),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String text) {
    return Row(
      children: [
        IconButton(icon: const Icon(Icons.copy, size: 16), onPressed: () { Clipboard.setData(ClipboardData(text: text)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم النسخ'))); }),
        IconButton(icon: const Icon(Icons.share, size: 16), onPressed: () => Share.share(text)),
      ],
    );
  }

  Widget _buildImagePreview() {
    if (_selectedImage == null) return const SizedBox.shrink();
    return Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.vertical(top: Radius.circular(12))), child: Row(children: [ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(_selectedImage!.path), height: 60, width: 60, fit: BoxFit.cover)), const SizedBox(width: 12), const Expanded(child: Text("الصورة جاهزة للتحليل...", style: TextStyle(fontWeight: FontWeight.bold))), IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => setState(() { _selectedImage = null; _imageBytes = null; }))]));
  }

  Widget _buildInputArea(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: isDark ? const Color(0xFF121212) : Colors.white,
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.add_a_photo_outlined, color: Colors.teal), onPressed: _pickImage),
          IconButton(icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: _isListening ? Colors.red : Colors.teal), onPressed: _listen),
          Expanded(child: TextField(controller: _controller, maxLines: null, decoration: InputDecoration(hintText: _isListening ? 'أنا أسمعك...' : 'اسأل أو تحدث...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none), filled: true, fillColor: isDark ? Colors.grey[900] : Colors.grey[100], contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)), onSubmitted: (_) => _handleSendMessage())),
          const SizedBox(width: 8),
          CircleAvatar(backgroundColor: Colors.teal, radius: 24, child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: _handleSendMessage)),
        ],
      ),
    );
  }
}
