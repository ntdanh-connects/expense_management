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
  TextColumn get avatarUrl => text().nullable()();
  TextColumn get currency => text()();
  TextColumn get language => text()();
  TextColumn get theme => text()();

  @override
  Set<Column> get primaryKey => {id}; // Đóng chặt khóa chính
}

class Wallets extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get balance => real()();
  TextColumn get type => text()();
  TextColumn get icon => text()();
  TextColumn get color => text()();
  BoolColumn get isHidden => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}


@DriftDatabase(tables: [Users,Wallets])
class AppDatabase extends _$AppDatabase {
  AppDatabase(): super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(wallets);
      }
    },
  );

  Future<void> saveUserProfile(User userRow) async{
    await into(users).insertOnConflictUpdate(userRow);
  }

  Future<User?> getUserProfile(String userId) async {
    return await (select(users)..where((t) => t.id.equals(userId))).getSingleOrNull();
  }

  Stream<User?> watchUserProfile(String userId) {
    return (select(users)..where((t) => t.id.equals(userId))).watchSingleOrNull();
  }
  Future<void> saveAllWallets(List<Wallet> walletRows) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(wallets, walletRows);
    });
  }

  Future<void> createWallet(Wallet walletRow) async {
    await into(wallets).insertOnConflictUpdate(walletRow);
  }

  // Stream danh sách ví theo thời gian thực ra UI lướt sóng
  Stream<List<Wallet>> watchAllWallets() {
    return select(wallets).watch();
  }

  Future<void> clearAuthData() async {
    await delete(users).go();
    await delete(wallets).go();
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