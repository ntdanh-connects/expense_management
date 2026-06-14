import 'package:expense_management/features/wallet/domain/repository/wallet_repository.dart';

class SetDefaultReceivingWalletUseCase {
  final WalletRepository _repository;

  SetDefaultReceivingWalletUseCase(this._repository);

  Future<void> execute(String id) async {
    return await _repository.setDefaultReceivingWallet(id);
  }
}
