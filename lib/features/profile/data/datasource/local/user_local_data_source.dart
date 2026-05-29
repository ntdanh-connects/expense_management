import 'package:expense_management/core/database/app_database.dart';

class ProfileLocalDataSource {
  final AppDatabase _db;
  ProfileLocalDataSource(this._db);

  // Cập nhật từng trường thông tin vào Local DB
  Future<void> updateLocalFullName(String userId, String newFullName) async {
    final currentUser = await _db.getUserProfile(userId);
    
    if (currentUser != null) {
      final updatedUser = currentUser.copyWith(fullName: newFullName);
      await _db.saveUserProfile(updatedUser);
    }
  }
}