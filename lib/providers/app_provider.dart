import 'package:flutter/material.dart';
import '../models/message.dart';
import '../models/education_level.dart';
import '../services/api_service.dart';
import '../services/preferences_service.dart';
import '../services/tts_service.dart';

class AppProvider extends ChangeNotifier {
  // Language
  String _languageCode = 'en';
  String get languageCode => _languageCode;

  // Education Level
  String _educationLevelId = 'high';
  String get educationLevelId => _educationLevelId;
  
  EducationLevel get currentEducationLevel =>
      EducationLevelData.levels.firstWhere(
        (l) => l.id == _educationLevelId,
        orElse: () => EducationLevelData.levels[2],
      );

  // Chat
  final List<Message> _messages = [];
  List<Message> get messages => List.unmodifiable(_messages);
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _currentSubject = 'ask_anything';
  String get currentSubject => _currentSubject;

  // Backend configuration
  bool _isBackendConfigured = false;
  bool get isBackendConfigured => _isBackendConfigured;

  // TTS
  final TtsService _ttsService = TtsService();
  bool get isSpeaking => _ttsService.isSpeaking;

  AppProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    _languageCode = await PreferencesService.getLanguage();
    _educationLevelId = await PreferencesService.getEducationLevel();
    
    final supabaseUrl = await PreferencesService.getSupabaseUrl();
    final supabaseAnonKey = await PreferencesService.getSupabaseAnonKey();
    final geminiKey = await PreferencesService.getGeminiApiKey();
    
    if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
      ApiService.configure(
        supabaseUrl: supabaseUrl,
        supabaseAnonKey: supabaseAnonKey,
        geminiApiKey: geminiKey,
      );
      _isBackendConfigured = true;
    } else if (geminiKey.isNotEmpty) {
      ApiService.setGeminiApiKey(geminiKey);
      _isBackendConfigured = true;
    }

    await _ttsService.initialize();
    notifyListeners();
  }

  // Language methods
  Future<void> setLanguage(String code) async {
    _languageCode = code;
    await PreferencesService.setLanguage(code);
    notifyListeners();
  }

  bool get isRtl => _languageCode == 'ur' || _languageCode == 'ps';

  // Education level methods
  Future<void> setEducationLevel(String levelId) async {
    _educationLevelId = levelId;
    await PreferencesService.setEducationLevel(levelId);
    notifyListeners();
  }

  // Subject
  void setSubject(String subjectId) {
    _currentSubject = subjectId;
    notifyListeners();
  }

  // Chat methods
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = Message(
      content: text.trim(),
      role: MessageRole.user,
    );
    _messages.add(userMessage);
    _isLoading = true;
    notifyListeners();

    try {
      String response;
      if (_isBackendConfigured) {
        response = await ApiService.sendMessage(
          conversationHistory: _messages,
          currentMessage: text.trim(),
          languageCode: _languageCode,
          educationLevelId: _educationLevelId,
          subjectId: _currentSubject,
        );
      } else {
        response = await ApiService.sendDemoMessage(
          currentMessage: text.trim(),
          languageCode: _languageCode,
        );
      }

      final aiMessage = Message(
        content: response,
        role: MessageRole.assistant,
      );
      _messages.add(aiMessage);
    } on ApiException catch (e) {
      final errorMessage = Message(
        content: e.message,
        role: MessageRole.assistant,
        isError: true,
      );
      _messages.add(errorMessage);
    } catch (e) {
      final errorMessage = Message(
        content: _getErrorMessage(),
        role: MessageRole.assistant,
        isError: true,
      );
      _messages.add(errorMessage);
    }

    _isLoading = false;
    notifyListeners();
  }

  String _getErrorMessage() {
    switch (_languageCode) {
      case 'ur':
        return 'معذرت، کچھ غلطی ہو گئی۔ براہ کرم دوبارہ کوشش کریں۔';
      case 'ps':
        return 'بخښنه، یوه تېروتنه وشوه. مهرباني وکړئ بیا هڅه وکړئ.';
      default:
        return 'Sorry, something went wrong. Please try again.';
    }
  }

  void clearConversation() {
    _messages.clear();
    _ttsService.stop();
    notifyListeners();
  }

  // TTS methods
  Future<void> speakMessage(String text) async {
    await _ttsService.speak(text, _languageCode);
    notifyListeners();
  }

  Future<void> stopSpeaking() async {
    await _ttsService.stop();
    notifyListeners();
  }

  Map<String, bool> get ttsLanguageSupport => _ttsService.languageSupport;

  // Backend configuration
  Future<void> configureBackend(String url, String anonKey,
      [String? geminiApiKey]) async {
    await PreferencesService.setSupabaseUrl(url);
    await PreferencesService.setSupabaseAnonKey(anonKey);
    if (geminiApiKey != null) {
      await PreferencesService.setGeminiApiKey(geminiApiKey);
    }
    final key = geminiApiKey ?? await PreferencesService.getGeminiApiKey();
    ApiService.configure(
      supabaseUrl: url,
      supabaseAnonKey: anonKey,
      geminiApiKey: key,
    );
    _isBackendConfigured = true;
    notifyListeners();
  }

  // Localized strings helper
  String tr(String key) {
    return _strings[_languageCode]?[key] ?? _strings['en']![key] ?? key;
  }

  static const Map<String, Map<String, String>> _strings = {
    'en': {
      'appTitle': 'AI Tutor',
      'welcome': 'Welcome to AI Tutor',
      'welcomeSubtitle': 'Your personal AI-powered learning companion',
      'askQuestion': 'Ask any question...',
      'subjects': 'Subjects',
      'settings': 'Settings',
      'language': 'Language',
      'educationLevel': 'Education Level',
      'clearChat': 'Clear Conversation',
      'clearChatConfirm': 'Are you sure you want to clear this conversation?',
      'cancel': 'Cancel',
      'clear': 'Clear',
      'send': 'Send',
      'typeMessage': 'Type your question here...',
      'chat': 'Chat',
      'home': 'Home',
      'startLearning': 'Start Learning',
      'backendConfig': 'Backend Configuration',
      'supabaseUrl': 'Supabase Project URL',
      'supabaseAnonKey': 'Supabase Anon Key',
      'save': 'Save',
      'saved': 'Saved!',
      'demoMode': 'Demo Mode',
      'demoModeDesc': 'Configure Supabase backend in Settings to use AI Tutor',
      'configureBackend': 'Configure Backend',
      'voiceInput': 'Voice Input',
      'voiceNotAvailable': 'Voice input is not available on this device',
      'listening': 'Listening...',
      'speakNow': 'Speak now...',
      'readAloud': 'Read aloud',
      'stopReading': 'Stop reading',
      'voiceLangNotSupported': 'Voice is not supported for this language on your device',
      'selectLanguage': 'Select Language',
      'selectLevel': 'Select Education Level',
      'english': 'English',
      'urdu': 'اردو (Urdu)',
      'pashto': 'پښتو (Pashto)',
    },
    'ur': {
      'appTitle': 'AI ٹیوٹر',
      'welcome': 'AI ٹیوٹر میں خوش آمدید',
      'welcomeSubtitle': 'آپ کا ذاتی AI تعلیمی ساتھی',
      'askQuestion': 'کوئی بھی سوال پوچھیں...',
      'subjects': 'مضامین',
      'settings': 'ترتیبات',
      'language': 'زبان',
      'educationLevel': 'تعلیمی سطح',
      'clearChat': 'گفتگو صاف کریں',
      'clearChatConfirm': 'کیا آپ واقعی اس گفتگو کو صاف کرنا چاہتے ہیں؟',
      'cancel': 'منسوخ',
      'clear': 'صاف کریں',
      'send': 'بھیجیں',
      'typeMessage': 'اپنا سوال یہاں لکھیں...',
      'chat': 'چیٹ',
      'home': 'ہوم',
      'startLearning': 'سیکھنا شروع کریں',
      'backendConfig': 'بیک اینڈ ترتیب',
      'supabaseUrl': 'Supabase پروجیکٹ URL',
      'supabaseAnonKey': 'Supabase Anon Key',
      'save': 'محفوظ کریں',
      'saved': 'محفوظ ہو گیا!',
      'demoMode': 'ڈیمو موڈ',
      'demoModeDesc': 'AI ٹیوٹر استعمال کرنے کے لیے ترتیبات میں Supabase بیک اینڈ ترتیب دیں',
      'configureBackend': 'بیک اینڈ ترتیب دیں',
      'voiceInput': 'آواز سے ان پٹ',
      'voiceNotAvailable': 'آواز ان پٹ اس آلے پر دستیاب نہیں ہے',
      'listening': 'سن رہا ہے...',
      'speakNow': 'اب بولیں...',
      'readAloud': 'بلند آواز سے پڑھیں',
      'stopReading': 'پڑھنا بند کریں',
      'voiceLangNotSupported': 'آپ کے آلے پر اس زبان کے لیے آواز دستیاب نہیں ہے',
      'selectLanguage': 'زبان منتخب کریں',
      'selectLevel': 'تعلیمی سطح منتخب کریں',
      'english': 'English (انگریزی)',
      'urdu': 'اردو',
      'pashto': 'پښتو (پشتو)',
    },
    'ps': {
      'appTitle': 'AI ښوونکی',
      'welcome': 'AI ښوونکي ته ښه راغلاست',
      'welcomeSubtitle': 'ستاسو شخصي AI زده کړې ملګری',
      'askQuestion': 'هره پوښتنه وپوښتئ...',
      'subjects': 'مضامین',
      'settings': 'ترتیبات',
      'language': 'ژبه',
      'educationLevel': 'د زده کړې کچه',
      'clearChat': 'خبرې اترې پاکې کړئ',
      'clearChatConfirm': 'ایا تاسو ډاډه یاست چې دا خبرې اترې پاکې کول غواړئ؟',
      'cancel': 'لغوه',
      'clear': 'پاکول',
      'send': 'لیږل',
      'typeMessage': 'خپله پوښتنه دلته ولیکئ...',
      'chat': 'چیٹ',
      'home': 'کور',
      'startLearning': 'زده کړه پیل کړئ',
      'backendConfig': 'بیک اینډ ترتیب',
      'supabaseUrl': 'Supabase پروژې URL',
      'supabaseAnonKey': 'Supabase Anon Key',
      'save': 'خوندي کول',
      'saved': 'خوندي شو!',
      'demoMode': 'ډیمو حالت',
      'demoModeDesc': 'د AI ښوونکي کارولو لپاره په ترتیباتو کې Supabase بیک اینډ تنظیم کړئ',
      'configureBackend': 'بیک اینډ تنظیم کړئ',
      'voiceInput': 'غږیز ان پټ',
      'voiceNotAvailable': 'غږیز ان پټ ستاسو په وسیله کې شتون نلري',
      'listening': 'اورېدل...',
      'speakNow': 'اوس خبرې وکړئ...',
      'readAloud': 'لوړ غږ سره ولولئ',
      'stopReading': 'لوستل ودروئ',
      'voiceLangNotSupported': 'ستاسو په وسیله کې د دې ژبې لپاره غږ شتون نلري',
      'selectLanguage': 'ژبه وټاکئ',
      'selectLevel': 'د زده کړې کچه وټاکئ',
      'english': 'English (انګلیسي)',
      'urdu': 'اردو (اردو)',
      'pashto': 'پښتو',
    },
  };
}
