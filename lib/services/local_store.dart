import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_models.dart';

class LocalStore {
  static const _historyKey = 'xynova_history_v2';
  static const _themeKey = 'xynova_theme';
  static const _modelKey = 'xynova_model';
  static const _languageKey = 'xynova_language';

  Future<List<Conversation>> loadConversations() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map>()
          .map((e) => Conversation.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveConversations(List<Conversation> conversations) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _historyKey,
      jsonEncode(conversations.map((e) => e.toJson()).toList()),
    );
  }

  Future<String?> getPreference(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<void> setPreference(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<String?> getTheme() => getPreference(_themeKey);
  Future<void> setTheme(String value) => setPreference(_themeKey, value);
  Future<String?> getModel() => getPreference(_modelKey);
  Future<void> setModel(String value) => setPreference(_modelKey, value);
  Future<String?> getLanguage() => getPreference(_languageKey);
  Future<void> setLanguage(String value) => setPreference(_languageKey, value);
}
