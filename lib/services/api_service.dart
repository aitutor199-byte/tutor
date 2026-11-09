import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';

class ApiService {
  // These should be configured via environment or settings
  static String _supabaseUrl = '';
  static String _supabaseAnonKey = '';
  static String _geminiApiKey = '';
  static const String _edgeFunctionName = 'gemini-chat';

  static void configure({
    required String supabaseUrl,
    required String supabaseAnonKey,
    String? geminiApiKey,
  }) {
    _supabaseUrl = supabaseUrl;
    _supabaseAnonKey = supabaseAnonKey;
    if (geminiApiKey != null) {
      _geminiApiKey = geminiApiKey;
    }
  }

  static void setGeminiApiKey(String key) {
    _geminiApiKey = key;
  }

  static bool get isConfigured =>
      _supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty;

  static bool get hasGeminiKey => _geminiApiKey.isNotEmpty;

  /// Sends a chat message to the Gemini API (via Supabase Edge Function with direct Gemini fallback).
  /// Returns the AI response text.
  static Future<String> sendMessage({
    required List<Message> conversationHistory,
    required String currentMessage,
    required String languageCode,
    required String educationLevelId,
    required String subjectId,
  }) async {
    // 1. Try Supabase Edge Function if configured
    if (isConfigured) {
      try {
        final reply = await _callSupabaseEdgeFunction(
          conversationHistory: conversationHistory,
          currentMessage: currentMessage,
          languageCode: languageCode,
          educationLevelId: educationLevelId,
          subjectId: subjectId,
        );
        return reply;
      } catch (e) {
        // If Edge Function is not deployed / unreachable and we have Gemini key, fallback to direct
        if (hasGeminiKey) {
          return await _callGeminiDirect(
            conversationHistory: conversationHistory,
            currentMessage: currentMessage,
            languageCode: languageCode,
            educationLevelId: educationLevelId,
            subjectId: subjectId,
          );
        }
        rethrow;
      }
    }

    // 2. If Supabase is not configured, but Gemini key is available
    if (hasGeminiKey) {
      return await _callGeminiDirect(
        conversationHistory: conversationHistory,
        currentMessage: currentMessage,
        languageCode: languageCode,
        educationLevelId: educationLevelId,
        subjectId: subjectId,
      );
    }

    throw ApiException(
      'Backend not configured. Please set your Supabase URL or Gemini API key in Settings.',
      code: 'NOT_CONFIGURED',
    );
  }

  static Future<String> _callSupabaseEdgeFunction({
    required List<Message> conversationHistory,
    required String currentMessage,
    required String languageCode,
    required String educationLevelId,
    required String subjectId,
  }) async {
    final url = Uri.parse('$_supabaseUrl/functions/v1/$_edgeFunctionName');

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
          .timeout(const Duration(seconds: 45));

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
        "Could not connect to the Supabase Edge Function 'gemini-chat'. Please ensure the function is created and deployed in your Supabase project (yrkwrrsgectccvmitmfb).",
        code: 'NETWORK_ERROR',
      );
    }
  }

  static String _buildSystemPrompt(
      String languageCode, String educationLevelId, String subjectId) {
    String levelPrompt;
    switch (educationLevelId) {
      case 'primary':
        levelPrompt =
            'The student is in primary school (Class 1-5, ages 5-10). Use very simple, warm language, short sentences, and everyday examples.';
        break;
      case 'middle':
        levelPrompt =
            'The student is in middle school (Class 6-8, ages 11-13). Use clear language, step-by-step reasoning, and practical examples.';
        break;
      case 'college':
        levelPrompt =
            'The student is at college/intermediate level. Use academic language, comprehensive proofs, and advanced theory.';
        break;
      case 'university':
        levelPrompt =
            'The student is at university level. Provide rigorous academic explanations, cite recognized theories, algorithms, and frameworks.';
        break;
      default:
        levelPrompt =
            'The student is in high school (Class 9-12, ages 14-18). Use proper academic terms, show step-by-step derivations, and explain why things work.';
    }

    String langPrompt;
    switch (languageCode) {
      case 'ur':
        langPrompt =
            'Respond entirely in Urdu (اردو) script with natural educational vocabulary.';
        break;
      case 'ps':
        langPrompt =
            'Respond entirely in Pashto (پښتو) script with authentic educational vocabulary.';
        break;
      default:
        langPrompt =
            'Respond in English with clear, engaging educational language.';
    }

    return '''You are "AI Tutor", a patient, friendly, step-by-step personal teacher.
Subject focus: $subjectId.
$levelPrompt
$langPrompt
Always teach step-by-step, give clear explanations, illustrate with examples, and encourage the student. Never just give the final answer.''';
  }

  static Future<String> _callGeminiDirect({
    required List<Message> conversationHistory,
    required String currentMessage,
    required String languageCode,
    required String educationLevelId,
    required String subjectId,
  }) async {
    const model = 'gemini-3-flash-preview';
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_geminiApiKey');

    final systemPrompt =
        _buildSystemPrompt(languageCode, educationLevelId, subjectId);

    final contents = <Map<String, dynamic>>[];
    final recent = conversationHistory.length > 8
        ? conversationHistory.sublist(conversationHistory.length - 8)
        : conversationHistory;

    for (final msg in recent) {
      contents.add({
        'role': msg.role == MessageRole.user ? 'user' : 'model',
        'parts': [
          {'text': msg.content}
        ],
      });
    }

    contents.add({
      'role': 'user',
      'parts': [
        {'text': currentMessage}
      ],
    });

    final body = jsonEncode({
      'contents': contents,
      'systemInstruction': {
        'parts': [
          {'text': systemPrompt}
        ]
      },
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 2048,
      },
    });

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidate = data['candidates']?[0];
        final text =
            candidate?['content']?['parts']?[0]?['text'] as String?;
        if (text != null && text.isNotEmpty) {
          return text;
        }
        return 'I received an empty response. Please try asking again.';
      } else {
        final errorData = jsonDecode(response.body);
        final msg = errorData['error']?['message'] ??
            'Gemini API error (${response.statusCode})';
        throw ApiException(msg, code: 'GEMINI_ERROR');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        'Could not connect to Gemini API. Please check your internet connection.',
        code: 'NETWORK_ERROR',
      );
    }
  }

  /// Tests the connection to the Supabase Edge Function.
  static Future<Map<String, dynamic>> testConnection() async {
    if (!isConfigured) {
      return {
        'success': false,
        'message': 'Supabase URL and Anon Key are not configured.',
      };
    }

    final url = Uri.parse('$_supabaseUrl/functions/v1/$_edgeFunctionName');
    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_supabaseAnonKey',
              'apikey': _supabaseAnonKey,
            },
            body: jsonEncode({'message': 'ping'}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Connected successfully! AI Tutor is ready.',
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message':
              "Edge Function 'gemini-chat' not found (404). Please create and deploy it in your Supabase Dashboard.",
        };
      } else if (response.statusCode == 500) {
        final body = response.body;
        if (body.contains('GEMINI_API_KEY')) {
          return {
            'success': false,
            'message':
                "Edge Function is reachable, but GEMINI_API_KEY secret is not set in Supabase.",
          };
        }
        return {
          'success': false,
          'message': 'Server error (500): $body',
        };
      } else {
        return {
          'success': false,
          'message': 'Server responded with status code ${response.statusCode}.',
        };
      }
    } catch (_) {
      return {
        'success': false,
        'message':
            "Could not reach Edge Function 'gemini-chat'. Please deploy it in Supabase under Edge Functions.",
      };
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
