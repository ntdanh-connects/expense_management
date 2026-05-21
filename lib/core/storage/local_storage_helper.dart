import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageHelper {
  final SharedPreferences _prefs;

  LocalStorageHelper(this._prefs);

  static const String _themeKey = 'app_theme_mode';
  static const String _localeKey = 'app_user_locale';

  // --- THEME ---
  int? getThemeIndex() {
    return _prefs.getInt(_themeKey);
  }

  Future<bool> saveThemeIndex(int index) async {
    return await _prefs.setInt(_themeKey, index);
  }

  // --- LOCALE ---
  String? getLanguageCode() {
    return _prefs.getString(_localeKey);
  }

  Future<bool> saveLanguageCode(String code) async {
    return await _prefs.setString(_localeKey, code);
  }

  // --- CLEAR ALL (Dùng khi Logout tài khoản để reset sạch preferences) ---
  Future<bool> clearAll() async {
    return await _prefs.clear();
  }
}