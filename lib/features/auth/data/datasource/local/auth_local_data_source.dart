import 'package:expense_management/core/database/app_database.dart';

class AuthLocalDataSource {
  final AppDatabase _db;
  AuthLocalDataSource(this._db);

  Future<void> cacheProfile(User userRow) async {
    await _db.saveUserProfile(userRow);
  }

  Future<User?> getCachedProfile(String userId) async {
    return await _db.getUserProfile(userId);
  }

  Future<void> clearCache() async {
    await _db.clearAuthData();
  }
}
