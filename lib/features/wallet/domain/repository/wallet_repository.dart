import '../../domain/entities/wallet_entity.dart';

abstract class WalletRepository {
  // 🔄 Kích nổ lệnh kéo mảng ví từ Backend Ngrok về lưu lặn ngầm xuống DB Local
  Future<void> syncWalletsImplicit();

  // 📺 Luồng Stream tươi sống bốc dữ liệu từ SQLite Local bắn thẳng lên UI lướt sóng
  Stream<List<WalletEntity>> watchWallets();
}