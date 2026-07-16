import 'package:expense_management/core/database/app_database.dart';
import '../../domain/entities/wallet_entity.dart';
import '../models/wallet_dto.dart';

class WalletMapper {
  static Wallet toDatabaseRow(WalletDto dto) {
    return Wallet(
      id: dto.id,
      name: dto.name,
      balance: dto.availableBalance,
      type: dto.type,
      icon: dto.icon ?? 'default_icon',
      color: dto.color ?? '#CCCCCC',
      isHidden: dto.isHidden ?? false,
      currencyCode: dto.currencyCode ?? 'VND',
      isDefaultReceiving: dto.isDefaultReceiving ?? false,
      minimumBalance: dto.minimumBalance,
      isMinimumBalanceAlertEnabled: dto.isMinimumBalanceAlertEnabled ?? true,
    );
  }

  static WalletEntity toEntity(Wallet row) {
    return WalletEntity(
      id: row.id,
      name: row.name,
      balance: row.balance,
      type: row.type,
      icon: row.icon,
      color: row.color,
      isHidden: row.isHidden,
      currencyCode: row.currencyCode,
      isDefaultReceiving: row.isDefaultReceiving,
      minimumBalance: row.minimumBalance,
      isMinimumBalanceAlertEnabled: row.isMinimumBalanceAlertEnabled ?? true,
    );
  }
}