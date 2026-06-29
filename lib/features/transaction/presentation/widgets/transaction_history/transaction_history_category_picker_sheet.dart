import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:expense_management/features/profile/data/models/category_dto.dart';
import 'package:expense_management/features/profile/presentation/widgets/category_ui_constants.dart';
import 'package:expense_management/features/profile/presentation/providers/category_provider.dart';
import 'package:expense_management/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';

class TransactionHistoryCategoryPickerSheet extends ConsumerStatefulWidget {
  final AsyncValue<List<CategoryDto>> categoryState;
  final VoidCallback onClear;
  final ValueChanged<CategoryDto> onSelected;

  const TransactionHistoryCategoryPickerSheet({
    super.key,
    required this.categoryState,
    required this.onClear,
    required this.onSelected,
  });

  @override
  ConsumerState<TransactionHistoryCategoryPickerSheet> createState() =>
      _TransactionHistoryCategoryPickerSheetState();
}

class _TransactionHistoryCategoryPickerSheetState
    extends ConsumerState<TransactionHistoryCategoryPickerSheet> {
  String? _pickerSelectedParentId;

  Widget _buildPickerShimmer(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[900]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 120,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final filter = ref.watch(transactionFilterProvider);

    return widget.categoryState.when(
      data: (allCategories) {
        final parents = allCategories.where((c) => c.parentId == null).toList();
        final Map<String, List<CategoryDto>> childMap = {};
        for (final cat in allCategories) {
          if (cat.parentId != null) {
            childMap.putIfAbsent(cat.parentId!, () => []).add(cat);
          }
        }

        final children = _pickerSelectedParentId != null
            ? (childMap[_pickerSelectedParentId] ?? [])
            : <CategoryDto>[];

        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            maxChildSize: 0.9,
            builder: (_, scrollCtrl) => Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.textSecondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      if (_pickerSelectedParentId != null)
                        IconButton(
                          onPressed: () => setState(() => _pickerSelectedParentId = null),
                          icon: Icon(Icons.arrow_back_ios_rounded,
                              size: 18, color: colors.textPrimary),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      if (_pickerSelectedParentId != null) const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _pickerSelectedParentId == null
                              ? 'select_category'.tr(ref)
                              : (parents
                                  .firstWhere((p) => p.id == _pickerSelectedParentId)
                                  .name
                                  .tr(ref)),
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (filter.categoryId != null)
                        TextButton(
                          onPressed: widget.onClear,
                          child: Text(
                            'clear'.tr(ref),
                            style: TextStyle(color: colors.expenseRed),
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    controller: scrollCtrl,
                    children: [
                      if (_pickerSelectedParentId == null)
                        ListTile(
                          leading: Icon(
                            Icons.apps_rounded,
                            color: filter.categoryId == null ? colors.primary : colors.textSecondary,
                          ),
                          title: Text(
                            'all_categories'.tr(ref),
                            style: TextStyle(
                              color: filter.categoryId == null ? colors.primary : colors.textPrimary,
                              fontWeight: filter.categoryId == null ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          trailing: filter.categoryId == null
                              ? Icon(Icons.check_circle_rounded, color: colors.primary, size: 20)
                              : null,
                          onTap: widget.onClear,
                        ),
                      if (_pickerSelectedParentId == null)
                        ...parents.map((parent) {
                          final hasChildren = childMap.containsKey(parent.id) &&
                              childMap[parent.id]!.isNotEmpty;
                          final icon = CategoryUIConstants.getIconData(parent.icon,
                              categoryName: parent.name);
                          final color = CategoryUIConstants.getColorFromHex(parent.color,
                              categoryName: parent.name);
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, color: color, size: 18),
                            ),
                            title: Text(
                              parent.name.tr(ref),
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: hasChildren
                                ? Icon(Icons.chevron_right_rounded, color: colors.textSecondary)
                                : null,
                            onTap: () {
                              if (hasChildren) {
                                setState(() => _pickerSelectedParentId = parent.id);
                              } else {
                                widget.onSelected(parent);
                              }
                            },
                          );
                        }),
                      if (_pickerSelectedParentId != null)
                        ...children.map((child) {
                          final isSelected = filter.categoryId == child.id;
                          final icon = CategoryUIConstants.getIconData(child.icon,
                              categoryName: child.name);
                          final color = CategoryUIConstants.getColorFromHex(child.color,
                              categoryName: child.name);
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, color: color, size: 18),
                            ),
                            title: Text(
                              child.name.tr(ref),
                              style: TextStyle(
                                color: isSelected ? colors.primary : colors.textPrimary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            trailing: isSelected
                                ? Icon(Icons.check_circle_rounded, color: colors.primary, size: 20)
                                : null,
                            onTap: () => widget.onSelected(child),
                          );
                        }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, scrollCtrl) => SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textSecondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(child: _buildPickerShimmer(context)),
            ],
          ),
        ),
      ),
      error: (err, _) => Center(child: Text('load_transactions_error'.tr(ref))),
    );
  }
}
