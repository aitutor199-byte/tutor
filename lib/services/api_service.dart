import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';

class ApiService {
  // These should be configured via environment or settings
  // Never hardcode actual API keys here
  static String _supabaseUrl = '';
  static String _supabaseAnonKey = '';
  static const String _edgeFunctionName = 'gemini-chat';

  static void configure({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) {
    _supabaseUrl = supabaseUrl;
    _supabaseAnonKey = supabaseAnonKey;
  }

  static bool get isConfigured =>
      _supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty;

  /// Sends a chat message to the Gemini API via Supabase Edge Function.
  /// Returns the AI response text.
  static Future<String> sendMessage({
    required List<Message> conversationHistory,
    required String currentMessage,
    required String languageCode,
    required String educationLevelId,
    required String subjectId,
  }) async {
    if (!isConfigured) {
      throw ApiException(
        'Backend not configured. Please set your Supabase URL and anon key in Settings.',
        code: 'NOT_CONFIGURED',
      );
    }

    final url = Uri.parse('$_supabaseUrl/functions/v1/$_edgeFunctionName');

    // Build conversation history for the API
    final historyPayload = conversationHistory.map((msg) {
          return {
            'role': msg.role == MessageRole.user ? 'user' : 'model',
            'parts': [
              {'text': msg.content}
            ],
          };
        }).toList();

    final body = jsonEncode({
      'message': currentMessage,
      'history': historyPayload,
      'language': languageCode,
      'educationLevel': educationLevelId,
      'subject': subjectId,
    });

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_supabaseAnonKey',
              'apikey': _supabaseAnonKey,
            },
            body: body,
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['reply'] as String?;
        if (reply == null || reply.isEmpty) {
          throw ApiException(
            'Received empty response from AI tutor.',
            code: 'EMPTY_RESPONSE',
          );
        }
        return reply;
      } else if (response.statusCode == 429) {
        throw ApiException(
          'Too many requests. Please wait a moment and try again.',
          code: 'RATE_LIMITED',
        );
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw ApiException(
          'Authentication failed. Please check your backend configuration.',
          code: 'AUTH_ERROR',
        );
      } else {
        String errorMsg = 'Server error (${response.statusCode}).';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['error'] != null) {
            errorMsg = errorData['error'] as String;
          }
        } catch (_) {}
        throw ApiException(errorMsg, code: 'SERVER_ERROR');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw ApiException(
          'Request timed out. Please check your internet connection and try again.',
          code: 'TIMEOUT',
        );
      }
      throw ApiException(
        'Could not connect to the AI tutor. Please check your internet connection.',
        code: 'NETWORK_ERROR',
      );
    }
  }

  /// Sends a demo response for testing without backend.
  /// This clearly indicates it's a demo mode.
  static Future<String> sendDemoMessage({
    required String currentMessage,
    required String languageCode,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    switch (languageCode) {
      case 'ur':
        return '⚠️ **ڈیمو موڈ**\n\nیہ ایک ڈیمو جواب ہے۔ مکمل AI ٹیوٹر استعمال کرنے کے لیے، براہ کرم سیٹنگز میں اپنا Supabase بیک اینڈ ترتیب دیں۔\n\nآپ کا سوال تھا: "$currentMessage"\n\nبیک اینڈ کنکشن کے بعد، AI ٹیوٹر آپ کو تفصیلی وضاحتیں فراہم کرے گا۔';
      case 'ps':
        return '⚠️ **ډیمو حالت**\n\nدا یو ډیمو ځواب دی۔ د بشپړ AI ښوونکي کارولو لپاره، مهرباني وکړئ په ترتیباتو کې خپل Supabase بیک اینډ تنظیم کړئ.\n\nستاسو پوښتنه وه: "$currentMessage"\n\nد بیک اینډ اتصال وروسته، AI ښوونکی به تاسو ته تفصیلي توضیحات وړاندې کړي.';
      default:
        return '⚠️ **Demo Mode**\n\nThis is a demo response. To use the full AI Tutor, please configure your Supabase backend in Settings.\n\nYour question was: "$currentMessage"\n\nOnce connected to the backend, the AI Tutor will provide detailed, step-by-step explanations tailored to your education level.';
    }
  }
}

class ApiException implements Exception {
  final String message;
  final String code;

  ApiException(this.message, {this.code = 'UNKNOWN'});

  @override
  String toString() => message;
}
