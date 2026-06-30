import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/router/app_route.dart';
import 'package:expense_management/features/transaction/domain/entities/transaction_entity.dart';
import 'package:expense_management/features/profile/presentation/widgets/category_ui_constants.dart';
import 'package:expense_management/features/transaction/presentation/widgets/category_picker_bottom_sheet.dart';
import 'package:expense_management/features/profile/data/models/category_dto.dart';
import 'package:expense_management/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_notifier.dart';

class CategoryDetailTxList extends ConsumerStatefulWidget {
  final List<TransactionEntity> displayTxs;
  final String type;
  final String? selectedSubcategoryFilter;
  final VoidCallback onClearSubcategoryFilter;
  final String? categoryColor;
  final String? categoryIcon;

  const CategoryDetailTxList({
    super.key,
    required this.displayTxs,
    required this.type,
    required this.selectedSubcategoryFilter,
    required this.onClearSubcategoryFilter,
    this.categoryColor,
    this.categoryIcon,
  });

  @override
  ConsumerState<CategoryDetailTxList> createState() => _CategoryDetailTxListState();
}

class _CategoryDetailTxListState extends ConsumerState<CategoryDetailTxList> {
  String _activeFilterTab = 'all';

  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
    return format.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Danh sách giao dịch',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Filter tabs
          Row(
            children: [
              _buildTabButton('all', 'Tất cả', Icons.list_alt_rounded, widget.displayTxs.length),
              const SizedBox(width: 8),
              _buildTabButton('top_spend', widget.type == 'expense' ? 'Top chi tiêu' : 'Top thu nhập', Icons.bar_chart_rounded, null),
              const SizedBox(width: 8),
              _buildTabButton('top_recipient', widget.type == 'expense' ? 'Top người nhận' : 'Top nguồn gửi', Icons.person_outline_rounded, null),
            ],
          ),
          if (widget.selectedSubcategoryFilter != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Chip(
                  label: Text(
                    'Lọc theo: ${widget.selectedSubcategoryFilter}',
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: colors.primary.withValues(alpha: 0.1),
                  deleteIcon: Icon(
                    Icons.close,
                    size: 14,
                    color: colors.primary,
                  ),
                  onDeleted: widget.onClearSubcategoryFilter,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide.none,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          _buildTransactionListContent(widget.displayTxs, colors),
        ],
      ),
    );
  }

  Widget _buildTabButton(String key, String label, IconData icon, int? count) {
    final colors = context.colors;
    final isActive = _activeFilterTab == key;
    final displayLabel = count != null ? '$label ($count)' : label;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeFilterTab = key;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? colors.primary.withValues(alpha: 0.08) : colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? colors.primary : colors.textSecondary.withValues(alpha: 0.15),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive ? colors.primary : colors.textSecondary,
                size: 14,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  displayLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isActive ? colors.primary : colors.textSecondary,
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionListContent(List<TransactionEntity> originalList, AppColorsExtension colors) {
    if (originalList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'Không có giao dịch nào trong kỳ này',
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
        ),
      );
    }

    if (_activeFilterTab == 'all') {
      final Map<String, List<TransactionEntity>> grouped = {};
      for (final tx in originalList) {
        final dateStr = DateFormat('dd/MM/yyyy').format(tx.transactionDate);
        grouped.putIfAbsent(dateStr, () => []).add(tx);
      }

      final keys = grouped.keys.toList();
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: keys.length,
        separatorBuilder: (context, index) => const SizedBox(height: 18),
        itemBuilder: (context, index) {
          final dateStr = keys[index];
          final txs = grouped[dateStr]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.textSecondary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  dateStr,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...txs.map((tx) => _buildTransactionItemRow(tx, colors)),
            ],
          );
        },
      );
    } else if (_activeFilterTab == 'top_spend') {
      final sortedList = List<TransactionEntity>.from(originalList)
        ..sort((a, b) => (b.amount * (b.exchangeRate ?? 1.0)).compareTo(a.amount * (a.exchangeRate ?? 1.0)));

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sortedList.length,
        separatorBuilder: (context, index) => const Divider(height: 12, thickness: 0.5),
        itemBuilder: (context, index) {
          final tx = sortedList[index];
          return _buildTransactionItemRow(tx, colors);
        },
      );
    } else {
      final Map<String, ({double amount, int count})> payeeGroups = {};

      for (final tx in originalList) {
        final String payee = (tx.payeeName != null && tx.payeeName!.trim().isNotEmpty)
            ? tx.payeeName!.trim()
            : tx.title.trim();

        final txAmount = tx.amount * (tx.exchangeRate ?? 1.0);
        final existing = payeeGroups[payee];
        if (existing != null) {
          payeeGroups[payee] = (
            amount: existing.amount + txAmount,
            count: existing.count + 1,
          );
        } else {
          payeeGroups[payee] = (amount: txAmount, count: 1);
        }
      }

      final sortedPayees = payeeGroups.keys.toList()
        ..sort((a, b) => payeeGroups[b]!.amount.compareTo(payeeGroups[a]!.amount));

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sortedPayees.length,
        separatorBuilder: (context, index) => const Divider(height: 12, thickness: 0.5),
        itemBuilder: (context, index) {
          final name = sortedPayees[index];
          final data = payeeGroups[name]!;

          final isDark = Theme.of(context).brightness == Brightness.dark;
          final rankColor = isDark ? Colors.grey[400] : Colors.grey[600];

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: rankColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                CircleAvatar(
                  backgroundColor: colors.primary.withValues(alpha: 0.1),
                  radius: 20,
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: colors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${data.count} giao dịch',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  (widget.type == 'expense' ? '-' : '+') + _formatCurrency(data.amount),
                  style: TextStyle(
                    color: widget.type == 'expense' ? colors.expenseRed : colors.incomeGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  Widget _buildCategoryDropdownChip(BuildContext context, TransactionEntity tx, Color catColor, IconData catIcon, AppColorsExtension colors) {
    final hasCategory = tx.categoryId != null && tx.categoryId!.isNotEmpty;

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => CategoryPickerBottomSheet(
            transactionType: tx.type,
            selectedCategory: hasCategory
                ? CategoryDto(
                    id: tx.categoryId!,
                    name: tx.categoryName ?? '',
                    type: tx.type,
                    icon: tx.categoryIcon,
                    color: tx.categoryColor,
                    sortOrder: 0,
                    isDefault: false,
                  )
                : null,
            onCategorySelected: (newCat) async {
              try {
                await ref.read(transactionListProvider.notifier).updateTransactionCategoryOptimistic(
                      transactionId: tx.id,
                      categoryId: newCat.id,
                    );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi cập nhật danh mục: $e')),
                  );
                }
              }
            },
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: catColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: catColor.withValues(alpha: 0.2),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(catIcon, color: catColor, size: 12),
            const SizedBox(width: 4),
            Text(
              hasCategory ? (tx.categoryName?.tr(ref) ?? 'uncategorized'.tr(ref)) : 'uncategorized'.tr(ref),
              style: TextStyle(
                color: catColor,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down_rounded, color: catColor, size: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItemRow(TransactionEntity tx, AppColorsExtension colors) {
    final hasCategory = tx.categoryId != null && tx.categoryId!.isNotEmpty;
    final catColor = hasCategory
        ? CategoryUIConstants.getColorFromHex(tx.categoryColor ?? widget.categoryColor, categoryName: tx.categoryName)
        : colors.textSecondary;
    final catIcon = hasCategory
        ? CategoryUIConstants.getIconData(tx.categoryIcon ?? widget.categoryIcon, categoryName: tx.categoryName)
        : Icons.help_outline_rounded;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeStr = DateFormat('HH:mm').format(tx.transactionDate);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? colors.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.textSecondary.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          context.push(RoutePaths.transactionDetail, extra: tx).then((shouldRefresh) {
            if (shouldRefresh == true) {
              ref.invalidate(transactionListProvider);
              ref.invalidate(filteredTransactionListProvider);
              ref.invalidate(walletNotifierProvider);
            }
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: catColor.withValues(alpha: 0.12),
                radius: 20,
                child: Icon(catIcon, color: catColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tx.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeStr,
                          style: TextStyle(
                            color: colors.textSecondary.withValues(alpha: 0.7),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _buildCategoryDropdownChip(context, tx, catColor, catIcon, colors),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.textSecondary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.account_balance_wallet_rounded,
                                size: 10,
                                color: colors.textSecondary.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                tx.walletName ?? 'Ví chính',
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (tx.payeeName != null && tx.payeeName!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.person_outline_rounded, size: 11.5, color: colors.textSecondary.withValues(alpha: 0.7)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Đối tác: ${tx.payeeName!.trim()}',
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (tx.notes != null && tx.notes!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.notes_rounded, size: 11.5, color: colors.textSecondary.withValues(alpha: 0.7)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              tx.notes!.trim(),
                              style: TextStyle(
                                color: colors.textSecondary.withValues(alpha: 0.8),
                                fontSize: 11.5,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    (tx.type == 'expense' ? '-' : '+') + _formatCurrency(tx.amount * (tx.exchangeRate ?? 1.0)),
                    style: TextStyle(
                      color: tx.type == 'expense' ? colors.expenseRed : colors.incomeGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  if (tx.attachmentUrls.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.attach_file_rounded, size: 13, color: colors.textSecondary.withValues(alpha: 0.6)),
                        const SizedBox(width: 2),
                        Text(
                          '${tx.attachmentUrls.length}',
                          style: TextStyle(
                            fontSize: 10,
                            color: colors.textSecondary.withValues(alpha: 0.6),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
