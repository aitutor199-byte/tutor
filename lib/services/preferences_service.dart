import 'package:shared_preferences/shared_preferences.dart';

/// Service for persisting user preferences locally.
class PreferencesService {
  static const String _languageKey = 'preferred_language';
  static const String _educationLevelKey = 'education_level';
  static const String _supabaseUrlKey = 'supabase_url';
  static const String _supabaseAnonKeyKey = 'supabase_anon_key';
  static const String _onboardingCompleteKey = 'onboarding_complete';

  static Future<SharedPreferences> get _prefs =>
      SharedPreferences.getInstance();

  // Language
  static Future<String> getLanguage() async {
    final prefs = await _prefs;
    return prefs.getString(_languageKey) ?? 'en';
  }

  static Future<void> setLanguage(String code) async {
    final prefs = await _prefs;
    await prefs.setString(_languageKey, code);
  }

  // Education Level
  static Future<String> getEducationLevel() async {
    final prefs = await _prefs;
    return prefs.getString(_educationLevelKey) ?? 'high';
  }

  static Future<void> setEducationLevel(String level) async {
    final prefs = await _prefs;
    await prefs.setString(_educationLevelKey, level);
  }

  static const String defaultSupabaseUrl =
      'https://yrkwrrsgectccvmitmfb.supabase.co';
  static const String defaultSupabaseAnonKey =
      'sb_publishable_ue9A-nxeVzDEwsebd2XVuA_nsgj_7gQ';

  // Supabase Configuration
  static Future<String> getSupabaseUrl() async {
    final prefs = await _prefs;
    final url = prefs.getString(_supabaseUrlKey);
    return (url != null && url.isNotEmpty) ? url : defaultSupabaseUrl;
  }

  static Future<void> setSupabaseUrl(String url) async {
    final prefs = await _prefs;
    await prefs.setString(_supabaseUrlKey, url);
  }

  static Future<String> getSupabaseAnonKey() async {
    final prefs = await _prefs;
    final key = prefs.getString(_supabaseAnonKeyKey);
    return (key != null && key.isNotEmpty) ? key : defaultSupabaseAnonKey;
  }

  static Future<void> setSupabaseAnonKey(String key) async {
    final prefs = await _prefs;
    await prefs.setString(_supabaseAnonKeyKey, key);
  }

  // Onboarding
  static Future<bool> isOnboardingComplete() async {
    final prefs = await _prefs;
    return prefs.getBool(_onboardingCompleteKey) ?? false;
  }

  static Future<void> setOnboardingComplete(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(_onboardingCompleteKey, value);
  }

  // Clear all preferences
  static Future<void> clearAll() async {
    final prefs = await _prefs;
    await prefs.clear();
  }
}
