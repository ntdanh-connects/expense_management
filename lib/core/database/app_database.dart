import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p; 
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'app_database.g.dart';

class Users extends Table {
  TextColumn get id => text()(); // userId trả về từ Backend của ní
  TextColumn get email => text()();
  TextColumn get fullName => text()();
  TextColumn get currency => text()();
  TextColumn get language => text()();
  TextColumn get theme => text()();

  @override
  Set<Column> get primaryKey => {id}; // Đóng chặt khóa chính
}


@DriftDatabase(tables: [Users])
class AppDatabase extends _$AppDatabase {
  AppDatabase(): super(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<void> saveUserProfile(User userRow) async{
    await into(users).insertOnConflictUpdate(userRow);
  }

  Future<User?> getUserProfile(String userId) async {
    return await (select(users)..where((t) => t.id.equals(userId))).getSingleOrNull();
  }

  Stream<User?> watchUserProfile(String userId) {
    return (select(users)..where((t) => t.id.equals(userId))).watchSingleOrNull();
  }

  Future<void> clearAuthData() async {
    await delete(users).go();
  }
}

QueryExecutor _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'exp_mgmt.sqlite'));
    return NativeDatabase.createInBackground(file); // Chạy ngầm Isolate tối ưu RAM
  });
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});