import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_notifier.dart';
import 'package:expense_management/features/profile/presentation/providers/category_provider.dart';

class ExportFilterSection extends ConsumerWidget {
  final DateTimeRange selectedDateRange;
  final String? selectedCategoryId;
  final String? selectedWalletId;
  final String? selectedTransactionType;

  final ValueChanged<DateTimeRange> onDateRangeChanged;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onWalletChanged;
  final ValueChanged<String?> onTransactionTypeChanged;

  const ExportFilterSection({
    super.key,
    required this.selectedDateRange,
    required this.selectedCategoryId,
    required this.selectedWalletId,
    required this.selectedTransactionType,
    required this.onDateRangeChanged,
    required this.onCategoryChanged,
    required this.onWalletChanged,
    required this.onTransactionTypeChanged,
  });

  void _selectDateRange(BuildContext context, WidgetRef ref) async {
    final colors = context.colors;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 2),
      initialDateRange: selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: colors.primary,
                  onPrimary: Colors.white,
                  surface: colors.surface,
                  onSurface: colors.textPrimary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onDateRangeChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final walletsAsync = ref.watch(walletNotifierProvider);
    final categoriesAsync = ref.watch(categoriesNotifierProvider);

    final dateFormat = DateFormat('dd/MM/yyyy');
    final rangeText =
        '${dateFormat.format(selectedDateRange.start)} - ${dateFormat.format(selectedDateRange.end)}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.textSecondary.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list_rounded, color: colors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'data_filter'.tr(ref),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: colors.textSecondary.withOpacity(0.08), height: 1),
          const SizedBox(height: 16),

          // Calendar Date Range Picker
          Text(
            'time_range'.tr(ref),
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _selectDateRange(context, ref),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          color: colors.textSecondary, size: 18),
                      const SizedBox(width: 12),
                      Text(
                        rangeText,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.keyboard_arrow_down, color: colors.textSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Categories Filter Chips
          Text(
            'category_label'.tr(ref),
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          categoriesAsync.when(
            data: (categories) {
              final parents =
                  categories.where((c) => c.parentId == null).toList();
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildChoiceChip(
                      context: context,
                      isSelected: selectedCategoryId == null,
                      label: 'all_categories'.tr(ref),
                      onSelected: (_) => onCategoryChanged(null),
                    ),
                    ...parents.map((c) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 6.0),
                        child: _buildChoiceChip(
                          context: context,
                          isSelected: selectedCategoryId == c.id,
                          label: c.name,
                          onSelected: (_) => onCategoryChanged(c.id),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
            loading: () => const SizedBox(
              height: 40,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 16),

          // Wallets Filter Chips
          Text(
            'wallet_label'.tr(ref),
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          walletsAsync.when(
            data: (wallets) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildChoiceChip(
                      context: context,
                      isSelected: selectedWalletId == null,
                      label: 'all_wallets'.tr(ref),
                      onSelected: (_) => onWalletChanged(null),
                    ),
                    ...wallets.map((w) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 6.0),
                        child: _buildChoiceChip(
                          context: context,
                          isSelected: selectedWalletId == w.id,
                          label: w.name,
                          onSelected: (_) => onWalletChanged(w.id),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
            loading: () => const SizedBox(
              height: 40,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const SizedBox(),
          ),
          const SizedBox(height: 16),

          // Transaction Types Filter Chips
          Text(
            'transaction_type_label'.tr(ref),
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildChoiceChip(
                  context: context,
                  isSelected: selectedTransactionType == null,
                  label: 'all_types'.tr(ref),
                  onSelected: (_) => onTransactionTypeChanged(null),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildChoiceChip(
                  context: context,
                  isSelected: selectedTransactionType == 'income',
                  label: 'income_type'.tr(ref),
                  onSelected: (_) => onTransactionTypeChanged('income'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildChoiceChip(
                  context: context,
                  isSelected: selectedTransactionType == 'expense',
                  label: 'expense_type'.tr(ref),
                  onSelected: (_) => onTransactionTypeChanged('expense'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip({
    required BuildContext context,
    required bool isSelected,
    required String label,
    required void Function(bool) onSelected,
  }) {
    final colors = context.colors;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: colors.incomeGreen.withOpacity(0.08),
      backgroundColor: colors.background,
      labelStyle: TextStyle(
        color: isSelected ? colors.incomeGreen : colors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 12.5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? colors.incomeGreen
              : colors.textSecondary.withOpacity(0.1),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      showCheckmark: false,
    );
  }
}
