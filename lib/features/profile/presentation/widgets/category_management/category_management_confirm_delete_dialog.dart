import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/profile/data/models/category_dto.dart';
import 'package:expense_management/features/profile/presentation/providers/category_provider.dart';

class CategoryManagementConfirmDeleteDialog extends ConsumerWidget {
  final CategoryDto category;

  const CategoryManagementConfirmDeleteDialog({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'delete_category_confirm'.trRead(ref),
        style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
      ),
      content: Text(
        'Hành động này sẽ xóa vĩnh viễn danh mục "${category.name.tr(ref)}".',
        style: TextStyle(color: colors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('cancel'.trRead(ref), style: TextStyle(color: colors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            try {
              await ref.read(categoriesNotifierProvider.notifier).deleteCategory(category.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('delete_category_success'.trRead(ref)),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString().replaceFirst('Exception: ', '')),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: colors.expenseRed),
          child: Text('delete'.trRead(ref), style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
