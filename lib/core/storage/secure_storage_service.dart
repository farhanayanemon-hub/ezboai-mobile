import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'ezboai_jwt_token';
  static const _userKey = 'ezboai_user_data';
  static const _modelKey = 'ezboai_selected_model';
  static const _webSearchKey = 'ezboai_web_search_enabled';
  static const _onboardingKey = 'ezboai_onboarding_completed';

  // Token operations
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> clearAuth() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }

  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Model preference
  static Future<void> saveSelectedModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modelKey, model);
  }

  static Future<String> getSelectedModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_modelKey) ?? 'google/gemini-2.0-flash-exp:free';
  }

  // Web search toggle
  static Future<void> saveWebSearch(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_webSearchKey, enabled);
  }

  static Future<bool> getWebSearch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_webSearchKey) ?? false;
  }

  // Onboarding
  static Future<void> setOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }
}
