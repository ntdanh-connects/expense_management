import 'package:expense_management/features/wallet/data/models/create_wallet_request.dart';
import 'package:expense_management/features/wallet/domain/repository/wallet_repository.dart';

class CreateWalletUseCase {
  final WalletRepository _repository;

  CreateWalletUseCase(this._repository);

  Future<void> execute(CreateWalletRequest request) async {
    return await _repository.createWallet(request);
  }
}
