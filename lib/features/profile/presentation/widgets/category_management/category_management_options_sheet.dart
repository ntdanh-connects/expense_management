import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/profile/data/models/category_dto.dart';
import 'package:expense_management/features/profile/presentation/providers/category_provider.dart';
import 'package:expense_management/features/profile/presentation/widgets/category_ui_constants.dart';
import 'package:expense_management/features/profile/presentation/screens/category_edit_screen.dart';
import 'merge_category_sheet.dart';
import 'category_management_confirm_delete_dialog.dart';

class CategoryManagementOptionsSheet extends ConsumerWidget {
  final CategoryDto category;
  final List<CategoryDto> allCategories;

  const CategoryManagementOptionsSheet({
    super.key,
    required this.category,
    required this.allCategories,
  });

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => CategoryManagementConfirmDeleteDialog(category: category),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final iconData = CategoryUIConstants.getIconData(category.icon);
    final themeColor = CategoryUIConstants.getColorFromHex(category.color);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: themeColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name.tr(ref),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category.isDefault
                          ? 'Danh mục mặc định hệ thống'
                          : 'Danh mục tùy chỉnh cá nhân',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (category.isDefault) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: colors.textSecondary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'cannot_delete_default_category'.tr(ref),
                      style: TextStyle(color: colors.textSecondary, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            ListTile(
              leading: Icon(Icons.edit_outlined, color: colors.textPrimary),
              title: Text('Chỉnh sửa danh mục', style: TextStyle(color: colors.textPrimary)),
              onTap: () {
                Navigator.pop(context); // Close sheet
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CategoryEditScreen(
                      category: category,
                      parentCategories: allCategories.where((c) => c.type == category.type).toList(),
                    ),
                  ),
                ).then((_) {
                  ref.read(categoriesNotifierProvider.notifier).refreshCategories(silent: true);
                });
              },
            ),
            Divider(color: colors.textSecondary.withOpacity(0.1)),
            ListTile(
              leading: Icon(Icons.merge_type_rounded, color: colors.textPrimary),
              title: Text('Gộp danh mục', style: TextStyle(color: colors.textPrimary)),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => MergeCategorySheet(
                    fromCategory: category,
                    allCategories: allCategories,
                  ),
                );
              },
            ),
            Divider(color: colors.textSecondary.withOpacity(0.1)),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: colors.expenseRed),
              title: Text('Xóa danh mục', style: TextStyle(color: colors.expenseRed)),
              onTap: () {
                Navigator.pop(context); // Close sheet
                _confirmDelete(context);
              },
            ),
          ],
        ],
      ),
    );
  }
}
