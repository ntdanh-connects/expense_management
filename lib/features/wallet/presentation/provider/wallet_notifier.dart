import 'dart:async';
import 'package:expense_management/features/wallet/domain/entities/wallet_entity.dart';
import 'package:expense_management/features/wallet/domain/di/domain_providers.dart';
import 'package:expense_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:expense_management/features/auth/domain/auth_state.dart';
import 'package:expense_management/features/wallet/data/models/create_wallet_request.dart';
import 'package:expense_management/core/storage/storage_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    // Kích hoạt đồng bộ hóa dữ liệu từ Backend ngầm nếu đã đăng nhập thành công
    if (isAuthenticated) {
      Future.microtask(() => syncWalletsUseCase.execute());
    }

    // Trả về trực tiếp Stream từ Drift SQLite và tự động tạo ví Tiền mặt mặc định nếu trống và là tài khoản mới
    return watchWalletsUseCase.execute().asyncMap((wallets) async {
      if (isAuthenticated && userId.isNotEmpty && wallets.isEmpty && !_isCreatingDefaultWallet) {
        final storage = ref.read(localStoreHelperProvider);
        if (storage.needsNewUserSetup(userId)) {
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
            await syncWalletsUseCase.execute();
          } catch (e) {
            print('Error creating default cash wallet: $e');
          } finally {
            _isCreatingDefaultWallet = false;
          }
        }
      }
      return wallets;
    });
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
