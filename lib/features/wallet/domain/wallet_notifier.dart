import 'dart:async';
import 'package:expense_management/features/wallet/domain/entities/wallet_entity.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WalletNotifier extends StreamNotifier<List<WalletEntity>> {
  @override
  Stream<List<WalletEntity>> build() {
    //UseCase từ provider
    final watchWalletsUseCase = ref.read(watchWalletsUseCaseProvider);
    final syncWalletsUseCase = ref.read(syncWalletsUseCaseProvider);

    // Kích hoạt đồng bộ hóa dữ liệu từ Backend ngầm
    Future.microtask(() => syncWalletsUseCase.execute());

    // Trả về trực tiếp Stream từ Drift SQLite để Riverpod tự động quản lý và lắng nghe
    return watchWalletsUseCase.execute();
  }
}

final walletNotifierProvider = StreamNotifierProvider<WalletNotifier, List<WalletEntity>>(() {
  return WalletNotifier();
});