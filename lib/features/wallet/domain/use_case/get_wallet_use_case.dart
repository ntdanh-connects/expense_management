import 'package:expense_management/features/wallet/domain/entities/wallet_entity.dart';
import 'package:expense_management/features/wallet/domain/repository/wallet_repository.dart';

class GetWalletUseCase {
  final WalletRepository _repository;
  GetWalletUseCase(this._repository);

  Stream<List<WalletEntity>> execute() {
    return _repository.watchWallets();
  }
}