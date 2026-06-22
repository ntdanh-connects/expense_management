import 'package:expense_management/features/wallet/domain/repository/wallet_repository.dart';

class SimulateSandboxTransferUseCase {
  final WalletRepository _repository;

  SimulateSandboxTransferUseCase(this._repository);

  Future<String?> execute({
    required String walletId,
    required double amount,
    String? senderName,
    String? notes,
  }) async {
    return await _repository.simulateSandboxTransfer(
      walletId: walletId,
      amount: amount,
      senderName: senderName,
      notes: notes,
    );
  }
}
