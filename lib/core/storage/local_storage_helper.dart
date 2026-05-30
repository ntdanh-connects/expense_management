import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageHelper {
  final SharedPreferences _prefs;

  LocalStorageHelper(this._prefs);

  static const String _themeKey = 'app_theme_mode';
  static const String _localeKey = 'app_user_locale';

  int? getThemeIndex() {
    return _prefs.getInt(_themeKey);
  }

  Future<bool> saveThemeIndex(int index) async {
    return await _prefs.setInt(_themeKey, index);
  }

  String? getLanguageCode() {
    return _prefs.getString(_localeKey);
  }

  Future<bool> saveLanguageCode(String code) async {
    return await _prefs.setString(_localeKey, code);
  }

  bool getBiometricLogin() {
    return _prefs.getBool('biometric_login_enabled') ?? false;
  }

  Future<bool> saveBiometricLogin(bool enabled) async {
    return await _prefs.setBool('biometric_login_enabled', enabled);
  }

  bool getBiometricTx() {
    return _prefs.getBool('biometric_tx_enabled') ?? false;
  }

  Future<bool> saveBiometricTx(bool enabled) async {
    return await _prefs.setBool('biometric_tx_enabled', enabled);
  }

  Future<bool> clearAll() async {
    return await _prefs.clear();
  }
}