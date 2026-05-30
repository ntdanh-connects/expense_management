import 'package:expense_management/features/wallet/data/models/create_wallet_request.dart';
import 'package:expense_management/features/wallet/domain/repository/wallet_repository.dart';

class UpdateWalletUseCase {
  final WalletRepository _repository;

  UpdateWalletUseCase(this._repository);

  Future<void> execute(String id, CreateWalletRequest request) async {
    return await _repository.updateWallet(id, request);
  }
}
