import '../../domain/entities/recurring_rule_entity.dart';
import '../models/recurring_rule_dto.dart';

class RecurringMapper {
  static RecurringRuleEntity toEntity(RecurringRuleDto dto) {
    return RecurringRuleEntity(
      id: dto.id,
      userId: dto.userId,
      walletId: dto.walletId,
      categoryId: dto.categoryId,
      type: dto.type,
      amount: dto.amount,
      title: dto.title,
      frequency: dto.frequency,
      intervalValue: dto.intervalValue ?? 1,
      startDate: dto.startDate?.toLocal(),
      nextRunAt: dto.nextRunAt?.toLocal(),
      endAt: dto.endAt?.toLocal(),
      isActive: dto.isActive,
      walletName: dto.wallet?.name,
      walletIcon: dto.wallet?.icon,
      walletColor: dto.wallet?.color,
      walletCurrencyCode: dto.wallet?.currencyCode,
      categoryName: dto.category?.name,
      categoryIcon: dto.category?.icon,
      categoryColor: dto.category?.color,
      payeeId: dto.payeeId,
      payeeName: dto.payee?.payeeName,
      payeeAccountNumber: dto.payee?.identifier,
      payeeBankName: dto.payee?.bankName,
    );
  }
}