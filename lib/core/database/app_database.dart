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
  TextColumn get timezone => text().withDefault(const Constant('Asia/Ho_Chi_Minh'))();

  @override
  Set<Column> get primaryKey => {id}; // Đóng chặt khóa chính
}

class Wallets extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get balance => real()();
  TextColumn get type => text()();
  TextColumn get currencyCode => text().withDefault(const Constant('VND'))();
  TextColumn get icon => text()();
  TextColumn get color => text()();
  BoolColumn get isHidden => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get parentId => text().nullable()();
  TextColumn get type => text()();
  TextColumn get name => text()();
  TextColumn get icon => text().nullable()();
  TextColumn get color => text().nullable()();
  IntColumn get sortOrder => integer()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get walletId => text()();
  TextColumn get categoryId => text().nullable()();
  RealColumn get amount => real()();
  RealColumn get amountInUserCurrency => real()();
  TextColumn get type => text()(); // income / expense
  TextColumn get title => text()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get transactionDate => dateTime()();
  TextColumn get sourceType => text().nullable()(); // manual / recurring / transfer
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(true))();

  // Beneficiary fields
  TextColumn get payeeId => text().nullable()();
  TextColumn get payeeName => text().nullable()();
  TextColumn get payeeAccountNumber => text().nullable()();
  TextColumn get payeeBankName => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalRecurringTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get walletId => text()();
  TextColumn get categoryId => text().nullable()();
  RealColumn get amount => real()();
  TextColumn get type => text()(); // income / expense
  TextColumn get title => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get frequency => text()(); // daily, weekly, monthly, yearly
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  DateTimeColumn get nextOccurrence => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Users, Wallets, Categories, LocalTransactions, LocalRecurringTransactions])
class AppDatabase extends _$AppDatabase {
  AppDatabase(): super(_openConnection());

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        try {
          await m.createTable(wallets);
        } catch (e) {
          // Bỏ qua nếu bảng đã tồn tại
        }
      }
      if (from < 3) {
        try {
          await m.addColumn(users, users.avatarUrl);
        } catch (e) {
          // Bỏ qua nếu cột đã tồn tại
        }
      }
      if (from < 4) {
        try {
          await m.addColumn(users, users.timezone);
        } catch (e) {
          // Bỏ qua nếu cột đã tồn tại
        }
      }
      if (from < 5) {
        try {
          await m.addColumn(wallets, wallets.currencyCode);
        } catch (e) {
          // Bỏ qua nếu cột đã tồn tại
        }
      }
      if (from < 6) {
        try {
          await m.createTable(categories);
        } catch (e) {
          // Bỏ qua nếu bảng đã tồn tại
        }
      }
      if (from < 7) {
        try {
          await m.createTable(localTransactions);
          await m.createTable(localRecurringTransactions);
        } catch (e) {
          // Bỏ qua nếu bảng đã tồn tại
        }
      }
      if (from < 8) {
        try {
          await m.addColumn(localTransactions, localTransactions.payeeId);
          await m.addColumn(localTransactions, localTransactions.payeeName);
          await m.addColumn(localTransactions, localTransactions.payeeAccountNumber);
          await m.addColumn(localTransactions, localTransactions.payeeBankName);
        } catch (e) {
          // Bỏ qua nếu cột đã tồn tại
        }
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

  Future<void> saveAllCategories(List<Category> categoryRows) async {
    await transaction(() async {
      await delete(categories).go();
      await batch((batch) {
        batch.insertAll(categories, categoryRows);
      });
    });
  }

  Future<List<Category>> getAllCategories() async {
    return await select(categories).get();
  }

  // Helper cho Transactions
  Future<void> saveAllTransactions(List<LocalTransaction> transactionRows) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(localTransactions, transactionRows);
    });
  }

  Future<void> saveTransaction(LocalTransaction transactionRow) async {
    await into(localTransactions).insertOnConflictUpdate(transactionRow);
  }

  Future<List<LocalTransaction>> getCachedTransactions(String userId) async {
    return await (select(localTransactions)
          ..where((t) => t.userId.equals(userId) & t.deletedAt.isNull() & t.isSynced.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.transactionDate, mode: OrderingMode.desc)]))
        .get();
  }

  Future<List<LocalTransaction>> getPendingTransactions(String userId) async {
    return await (select(localTransactions)
          ..where((t) => t.userId.equals(userId) & t.isSynced.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.transactionDate, mode: OrderingMode.desc)]))
        .get();
  }

  Stream<List<LocalTransaction>> watchAllTransactions(String userId) {
    return (select(localTransactions)
          ..where((t) => t.userId.equals(userId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.transactionDate, mode: OrderingMode.desc)]))
        .watch();
  }

  Future<void> deleteTransaction(String id) async {
    await (delete(localTransactions)..where((t) => t.id.equals(id))).go();
  }

  Future<void> clearAuthData() async {
    await delete(users).go();
    await delete(wallets).go();
    await delete(categories).go();
    await delete(localTransactions).go();
    await delete(localRecurringTransactions).go();
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