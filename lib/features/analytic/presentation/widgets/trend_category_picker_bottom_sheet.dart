import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/language/app_provider.dart';
import 'package:expense_management/features/profile/data/models/category_dto.dart';
import 'package:expense_management/features/profile/presentation/widgets/category_ui_constants.dart';
import 'package:expense_management/features/profile/presentation/providers/category_provider.dart';
import 'package:expense_management/features/analytic/presentation/providers/report_providers.dart';

// 🗂️ CUSTOM CATEGORY PICKER BOTTOM SHEET FOR TREND CHART (SUPPORTS PARENT/CHILD SELECTION)
class TrendCategoryPickerBottomSheet extends ConsumerWidget {
  const TrendCategoryPickerBottomSheet({super.key});

  Widget _buildSectionHeader(String title, Color color, AppColorsExtension colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final categories = ref.watch(categoriesNotifierProvider).value ?? [];
    final isEnglish = ref.watch(localeProvider) == 'en';

    final expenseParents = categories.where((c) => c.type == 'expense').toList();
    final incomeParents = categories.where((c) => c.type == 'income').toList();

    List<Widget> buildCategoryList(List<CategoryDto> parents) {
      return parents.expand((parent) {
        final list = <Widget>[];
        final isParentSelected = ref.watch(selectedTrendCategoryProvider)?.id == parent.id;

        list.add(
          _buildCategoryItem(
            context: context,
            ref: ref,
            name: parent.name,
            icon: CategoryUIConstants.getIconData(parent.icon, categoryName: parent.name),
            color: CategoryUIConstants.getColorFromHex(parent.color, categoryName: parent.name),
            isSelected: isParentSelected,
            isParent: true,
            onTap: () {
              ref.read(selectedTrendCategoryProvider.notifier).state = parent;
              Navigator.pop(context);
            },
          ),
        );

        if (parent.children != null && parent.children!.isNotEmpty) {
          for (final child in parent.children!) {
            final isChildSelected = ref.watch(selectedTrendCategoryProvider)?.id == child.id;
            list.add(
              _buildCategoryItem(
                context: context,
                ref: ref,
                name: child.name,
                icon: CategoryUIConstants.getIconData(child.icon, categoryName: child.name),
                color: CategoryUIConstants.getColorFromHex(child.color, categoryName: child.name),
                isSelected: isChildSelected,
                isChild: true,
                onTap: () {
                  ref.read(selectedTrendCategoryProvider.notifier).state = child;
                  Navigator.pop(context);
                },
              ),
            );
          }
        }
        
        list.add(const SizedBox(height: 8));
        return list;
      }).toList();
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 38,
              height: 4.5,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  const Spacer(),
                  Text(
                    isEnglish ? 'Filter by Category' : 'Lọc theo danh mục',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 0.5),
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: ListView(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // All categories option
                    _buildCategoryItem(
                      context: context,
                      ref: ref,
                      name: isEnglish ? 'All Categories' : 'Tất cả danh mục',
                      icon: Icons.all_inclusive_rounded,
                      color: colors.primary,
                      isSelected: ref.watch(selectedTrendCategoryProvider) == null,
                      onTap: () {
                        ref.read(selectedTrendCategoryProvider.notifier).state = null;
                        Navigator.pop(context);
                      },
                    ),
                    const Divider(height: 1, thickness: 0.5),

                    if (expenseParents.isNotEmpty) ...[
                      _buildSectionHeader(isEnglish ? 'Expense Categories' : 'Danh mục chi tiêu', colors.expenseRed, colors),
                      ...buildCategoryList(expenseParents),
                    ],

                    if (incomeParents.isNotEmpty) ...[
                      _buildSectionHeader(isEnglish ? 'Income Categories' : 'Danh mục thu nhập', colors.incomeGreen, colors),
                      ...buildCategoryList(incomeParents),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem({
    required BuildContext context,
    required WidgetRef ref,
    required String name,
    required IconData icon,
    required Color color,
    required bool isSelected,
    bool isParent = false,
    bool isChild = false,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.only(
          left: isChild ? 48.0 : 20.0,
          right: 20.0,
          top: 12.0,
          bottom: 12.0,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              width: isChild ? 32 : 40,
              height: isChild ? 32 : 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
                border: isSelected ? Border.all(color: color, width: 1.5) : null,
              ),
              child: Icon(
                icon,
                color: color,
                size: isChild ? 16 : 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name.tr(ref),
                style: TextStyle(
                  color: isSelected ? color : colors.textPrimary,
                  fontSize: isChild ? 13.5 : 15,
                  fontWeight: isSelected ? FontWeight.bold : (isParent ? FontWeight.w600 : FontWeight.normal),
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
