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

  List<TransactionEntity> getCachedTransactions({String userId = ''}) {
    final key = userId.isEmpty ? _transactionsKey : 'cached_transactions_$userId';
    final String? jsonStr = _prefs.getString(key);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> list = json.decode(jsonStr);
      return list.map((item) => TransactionEntity.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> saveCachedTransactions(List<TransactionEntity> transactions, {String userId = ''}) async {
    try {
      final key = userId.isEmpty ? _transactionsKey : 'cached_transactions_$userId';
      final List<Map<String, dynamic>> list = transactions.map((tx) => tx.toJson()).toList();
      final String jsonStr = json.encode(list);
      return await _prefs.setString(key, jsonStr);
    } catch (_) {
      return false;
    }
  }

  static const String _pendingTransactionsKey = 'pending_transactions';

  List<TransactionEntity> getPendingTransactions({String userId = ''}) {
    final key = userId.isEmpty ? _pendingTransactionsKey : 'pending_transactions_$userId';
    final String? jsonStr = _prefs.getString(key);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> list = json.decode(jsonStr);
      return list.map((item) => TransactionEntity.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> savePendingTransactions(List<TransactionEntity> transactions, {String userId = ''}) async {
    try {
      final key = userId.isEmpty ? _pendingTransactionsKey : 'pending_transactions_$userId';
      final List<Map<String, dynamic>> list = transactions.map((tx) => tx.toJson()).toList();
      final String jsonStr = json.encode(list);
      return await _prefs.setString(key, jsonStr);
    } catch (_) {
      return false;
    }
  }

  bool hasSeenWalkthrough(String userId) {
    return _prefs.getBool('seen_walkthrough_$userId') ?? false;
  }

  Future<bool> setSeenWalkthrough(String userId, bool seen) async {
    return await _prefs.setBool('seen_walkthrough_$userId', seen);
  }

  bool isJustRegistered(String email) {
    return _prefs.getBool('just_registered_${email.trim().toLowerCase()}') ?? false;
  }

  Future<bool> setJustRegistered(String email, bool value) async {
    return await _prefs.setBool('just_registered_${email.trim().toLowerCase()}', value);
  }

  bool needsNewUserSetup(String userId) {
    return _prefs.getBool('needs_new_user_setup_$userId') ?? false;
  }

  Future<bool> setNeedsNewUserSetup(String userId, bool value) async {
    return await _prefs.setBool('needs_new_user_setup_$userId', value);
  }
}