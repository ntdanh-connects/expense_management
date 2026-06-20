import 'package:expense_management/features/wallet/data/models/create_wallet_request.dart';
import 'package:expense_management/features/wallet/domain/entities/internal_transfer_record.dart';

import '../../domain/entities/wallet_entity.dart';

abstract class WalletRepository {
  // 🔄 Kích nổ lệnh kéo mảng ví từ Backend Ngrok về lưu lặn ngầm xuống DB Local
  Future<void> syncWalletsImplicit();

  // 📺 Luồng Stream tươi sống bốc dữ liệu từ SQLite Local bắn thẳng lên UI lướt sóng
  Stream<List<WalletEntity>> watchWallets();

  Future<void> createWallet(CreateWalletRequest request);

  Future<void> updateWallet(String id, CreateWalletRequest request);

  Future<void> transferMoney({
    required String fromWalletId,
    required String toWalletId,
    required double amount,
    String? notes,
    String? timezone,
  });

  // 🧾 Lấy lịch sử chuyển tiền nội bộ của tất cả các ví
  Future<List<InternalTransferRecord>> getTransferHistory();

  // 📥 Thiết lập ví nhận mặc định
  Future<void> setDefaultReceivingWallet(String id);

  Future<void> simulateSandboxTransfer({
    required String walletId,
    required double amount,
    String? senderName,
    String? notes,
  });
}