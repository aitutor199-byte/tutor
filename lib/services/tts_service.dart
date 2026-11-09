import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

/// Text-to-Speech service with multi-language support.
/// Provides voice output for AI tutor responses.
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;
  final Map<String, bool> _languageSupport = {};

  bool get isSpeaking => _isSpeaking;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _tts.setVolume(1.0);
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
      });

      _tts.setCancelHandler(() {
        _isSpeaking = false;
      });

      _tts.setErrorHandler((msg) {
        _isSpeaking = false;
        debugPrint('TTS Error: $msg');
      });

      // Check language support
      await _checkLanguageSupport();

      _isInitialized = true;
    } catch (e) {
      debugPrint('TTS initialization error: $e');
    }
  }

  Future<void> _checkLanguageSupport() async {
    try {
      final languages = await _tts.getLanguages;
      final langList = (languages as List).map((l) => l.toString().toLowerCase()).toList();

      _languageSupport['en'] = langList.any((l) => l.startsWith('en'));
      _languageSupport['ur'] = langList.any((l) => l.startsWith('ur'));
      _languageSupport['ps'] = langList.any((l) => l.startsWith('ps'));

      debugPrint('TTS Language support: $_languageSupport');
      debugPrint('TTS Available languages: $langList');
    } catch (e) {
      debugPrint('Error checking TTS languages: $e');
      _languageSupport['en'] = true; // Assume English is available
      _languageSupport['ur'] = false;
      _languageSupport['ps'] = false;
    }
  }

  bool isLanguageSupported(String languageCode) {
    return _languageSupport[languageCode] ?? false;
  }

  Map<String, bool> get languageSupport => Map.unmodifiable(_languageSupport);

  Future<void> speak(String text, String languageCode) async {
    if (!_isInitialized) await initialize();

    // Stop any current speech
    await stop();

    // Set language
    String ttsLang;
    switch (languageCode) {
      case 'ur':
        ttsLang = 'ur-PK';
        break;
      case 'ps':
        ttsLang = 'ps-AF';
        break;
      default:
        ttsLang = 'en-US';
    }

    // Check if the language is supported, fall back to English
    if (!isLanguageSupported(languageCode)) {
      if (languageCode != 'en') {
        debugPrint('TTS: $languageCode not supported, falling back to English');
        ttsLang = 'en-US';
      }
    }

    try {
      await _tts.setLanguage(ttsLang);
      _isSpeaking = true;

      // Strip markdown formatting for cleaner speech
      final cleanText = _stripMarkdown(text);
      await _tts.speak(cleanText);
    } catch (e) {
      _isSpeaking = false;
      debugPrint('TTS speak error: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
      _isSpeaking = false;
    } catch (e) {
      debugPrint('TTS stop error: $e');
    }
  }

  String _stripMarkdown(String text) {
    return text
        .replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1') // bold
        .replaceAll(RegExp(r'\*(.+?)\*'), r'$1') // italic
        .replaceAll(RegExp(r'`(.+?)`'), r'$1') // inline code
        .replaceAll(RegExp(r'```[\s\S]*?```'), '') // code blocks
        .replaceAll(RegExp(r'#{1,6}\s'), '') // headings
        .replaceAll(RegExp(r'\[(.+?)\]\(.+?\)'), r'$1') // links
        .replaceAll(RegExp(r'[⚠️📌💡🔢✅❌🎯]'), '') // emojis
        .replaceAll(RegExp(r'\n{3,}'), '\n\n') // excess newlines
        .trim();
  }

  Future<void> dispose() async {
    await stop();
  }
}
