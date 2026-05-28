import 'package:expense_management/features/wallet/domain/repository/wallet_repository.dart';

class SyncWalletsUseCase {
  final WalletRepository _repository;

  SyncWalletsUseCase(this._repository);

  Future<void> execute() async {
    return await _repository.syncWalletsImplicit();
  }
}