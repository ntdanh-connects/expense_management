import 'dart:convert';
import 'package:expense_management/features/transaction/domain/entities/transaction_entity.dart';
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

  static const String _transactionsKey = 'cached_transactions';

  List<TransactionEntity> getCachedTransactions() {
    final String? jsonStr = _prefs.getString(_transactionsKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> list = json.decode(jsonStr);
      return list.map((item) => TransactionEntity.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> saveCachedTransactions(List<TransactionEntity> transactions) async {
    try {
      final List<Map<String, dynamic>> list = transactions.map((tx) => tx.toJson()).toList();
      final String jsonStr = json.encode(list);
      return await _prefs.setString(_transactionsKey, jsonStr);
    } catch (_) {
      return false;
    }
  }

  static const String _pendingTransactionsKey = 'pending_transactions';

  List<TransactionEntity> getPendingTransactions() {
    final String? jsonStr = _prefs.getString(_pendingTransactionsKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> list = json.decode(jsonStr);
      return list.map((item) => TransactionEntity.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> savePendingTransactions(List<TransactionEntity> transactions) async {
    try {
      final List<Map<String, dynamic>> list = transactions.map((tx) => tx.toJson()).toList();
      final String jsonStr = json.encode(list);
      return await _prefs.setString(_pendingTransactionsKey, jsonStr);
    } catch (_) {
      return false;
    }
  }
}