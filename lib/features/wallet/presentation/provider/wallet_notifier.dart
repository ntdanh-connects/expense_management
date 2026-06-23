import 'dart:async';
import 'package:expense_management/features/wallet/domain/entities/wallet_entity.dart';
import 'package:expense_management/features/wallet/domain/di/domain_providers.dart';
import 'package:expense_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:expense_management/features/auth/domain/auth_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WalletNotifier extends StreamNotifier<List<WalletEntity>> {
  @override
  Stream<List<WalletEntity>> build() {
    // 👁️ Lắng nghe trạng thái đăng nhập: Khi đăng nhập thành công, Riverpod tự rebuild Notifier này!
    final isAuthenticated = ref.watch(authNotifierProvider.select((state) => state.maybeWhen(authenticated: (_) => true, orElse: () => false)));

    final watchWalletsUseCase = ref.read(watchWalletsUseCaseProvider);
    final syncWalletsUseCase = ref.read(syncWalletsUseCaseProvider);

    // Kích hoạt đồng bộ hóa dữ liệu từ Backend ngầm nếu đã đăng nhập thành công
    if (isAuthenticated) {
      Future.microtask(() => syncWalletsUseCase.execute());
    }

    // Trả về trực tiếp Stream từ Drift SQLite để Riverpod tự động quản lý và lắng nghe
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
