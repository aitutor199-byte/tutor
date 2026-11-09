import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

/// Speech-to-Text service for voice input.
class SttService {
  static final SttService _instance = SttService._internal();
  factory SttService() => _instance;
  SttService._internal();

  final SpeechToText _stt = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  bool _isAvailable = false;
  final Map<String, bool> _languageSupport = {};

  bool get isListening => _isListening;
  bool get isAvailable => _isAvailable;

  /// Initialize the speech recognition service.
  Future<bool> initialize() async {
    if (_isInitialized) return _isAvailable;

    try {
      _isAvailable = await _stt.initialize(
        onError: _onError,
        onStatus: _onStatus,
      );

      if (_isAvailable) {
        await _checkLanguageSupport();
      }

      _isInitialized = true;
      debugPrint('STT initialized. Available: $_isAvailable');
      return _isAvailable;
    } catch (e) {
      debugPrint('STT initialization error: $e');
      _isAvailable = false;
      _isInitialized = true;
      return false;
    }
  }

  Future<void> _checkLanguageSupport() async {
    try {
      final locales = await _stt.locales();
      final localeIds = locales.map((l) => l.localeId.toLowerCase()).toList();

      _languageSupport['en'] = localeIds.any((l) => l.startsWith('en'));
      _languageSupport['ur'] = localeIds.any((l) => l.startsWith('ur'));
      _languageSupport['ps'] = localeIds.any((l) => l.startsWith('ps'));

      debugPrint('STT Language support: $_languageSupport');
    } catch (e) {
      debugPrint('Error checking STT languages: $e');
      _languageSupport['en'] = true;
      _languageSupport['ur'] = false;
      _languageSupport['ps'] = false;
    }
  }

  bool isLanguageSupported(String languageCode) {
    return _languageSupport[languageCode] ?? false;
  }

  Map<String, bool> get languageSupport => Map.unmodifiable(_languageSupport);

  /// Start listening for speech input.
  Future<void> startListening({
    required Function(String text) onResult,
    required Function() onDone,
    required Function(String error) onError,
    String languageCode = 'en',
  }) async {
    if (!_isInitialized) {
      final available = await initialize();
      if (!available) {
        onError('Speech recognition is not available on this device.');
        return;
      }
    }

    if (!_isAvailable) {
      onError('Speech recognition is not available on this device.');
      return;
    }

    if (_isListening) {
      await stopListening();
    }

    // Determine locale
    String localeId;
    switch (languageCode) {
      case 'ur':
        localeId = 'ur_PK';
        break;
      case 'ps':
        localeId = 'ps_AF';
        break;
      default:
        localeId = 'en_US';
    }

    // Warn if language not supported
    if (!isLanguageSupported(languageCode) && languageCode != 'en') {
      debugPrint('STT: $languageCode not supported. Using en_US fallback.');
      localeId = 'en_US';
    }

    try {
      _isListening = true;
      await _stt.listen(
        onResult: (SpeechRecognitionResult result) {
          onResult(result.recognizedWords);
          if (result.finalResult) {
            _isListening = false;
            onDone();
          }
        },
        localeId: localeId,
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.dictation,
          cancelOnError: true,
          partialResults: true,
        ),
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );
    } catch (e) {
      _isListening = false;
      onError('Failed to start speech recognition: $e');
    }
  }

  Future<void> stopListening() async {
    try {
      await _stt.stop();
      _isListening = false;
    } catch (e) {
      debugPrint('STT stop error: $e');
    }
  }

  void _onError(SpeechRecognitionError error) {
    debugPrint('STT error: ${error.errorMsg}');
    _isListening = false;
  }

  void _onStatus(String status) {
    debugPrint('STT status: $status');
    if (status == 'done' || status == 'notListening') {
      _isListening = false;
    }
  }

  Future<void> dispose() async {
    await stopListening();
  }
}
