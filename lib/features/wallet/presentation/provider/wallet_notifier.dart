import 'dart:async';
import 'package:expense_management/features/wallet/domain/entities/wallet_entity.dart';
import 'package:expense_management/features/wallet/domain/di/domain_providers.dart';
import 'package:expense_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:expense_management/features/wallet/data/models/create_wallet_request.dart';
import 'package:expense_management/core/storage/storage_provider.dart';
import 'package:expense_management/core/database/app_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

class WalletNotifier extends StreamNotifier<List<WalletEntity>> {
  bool _isCreatingDefaultWallet = false;

  @override
  Stream<List<WalletEntity>> build() {
    // 👁️ Lắng nghe trạng thái đăng nhập: Khi đăng nhập thành công, Riverpod tự rebuild Notifier này!
    final authState = ref.watch(authNotifierProvider);
    final isAuthenticated = authState.maybeWhen(authenticated: (_) => true, orElse: () => false);
    final userId = authState.maybeWhen(authenticated: (user) => user.id, orElse: () => '');

    final watchWalletsUseCase = ref.read(watchWalletsUseCaseProvider);
    final syncWalletsUseCase = ref.read(syncWalletsUseCaseProvider);

    // Xác định đồng bộ (chụp giá trị tức thời khi build chạy trước khi các post-frame callback xóa cờ)
    final storage = ref.read(localStoreHelperProvider);
    final isNewUser = isAuthenticated && userId.isNotEmpty && 
        (storage.needsNewUserSetup(userId) || !storage.hasSeenWalkthrough(userId));

    // Kích hoạt đồng bộ hóa dữ liệu từ Backend ngầm nếu đã đăng nhập thành công
    if (isAuthenticated && userId.isNotEmpty) {
      Future.microtask(() async {
        try {
          // 1. Chờ đồng bộ ví từ Remote BE về SQLite hoàn tất để đảm bảo có thông tin ví cũ
          await syncWalletsUseCase.execute();

          // 2. Kiểm tra xem DB SQLite thực tế có ví nào không
          final db = ref.read(appDatabaseProvider);
          final wallets = await db.select(db.wallets).get();

          if (wallets.isEmpty && !_isCreatingDefaultWallet && isNewUser) {
            _isCreatingDefaultWallet = true;
            try {
              final createWalletUseCase = ref.read(createWalletUseCaseProvider);
              await createWalletUseCase.execute(CreateWalletRequest(
                name: 'Tiền mặt',
                type: 'cash',
                icon: 'payments',
                color: '#10B981',
                isHidden: false,
                availableBalance: '0',
                currencyCode: 'VND',
              ));
              await storage.setNeedsNewUserSetup(userId, true);
              await syncWalletsUseCase.execute();
            } catch (e) {
              print('Error creating default cash wallet: $e');
            } finally {
              _isCreatingDefaultWallet = false;
            }
          }
        } catch (_) {}
      });
    }

    // Trả về trực tiếp Stream từ Drift SQLite
    return watchWalletsUseCase.execute();
  }

  // 🔄 Thực hiện đồng bộ tươi mới trực tiếp danh sách ví từ remote DB về SQLite local
  Future<void> refreshWallets() async {
    try {
      final syncWalletsUseCase = ref.read(syncWalletsUseCaseProvider);
      await syncWalletsUseCase.execute();
    } catch (e) {
      print('Error manually refreshing wallets: $e');
    }
  }
}

final walletNotifierProvider = StreamNotifierProvider<WalletNotifier, List<WalletEntity>>(() {
  return WalletNotifier();
});

final showHiddenWalletsProvider = StateProvider<bool>((ref) => false);
