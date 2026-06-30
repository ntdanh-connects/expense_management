import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/profile/data/models/category_dto.dart';
import 'package:expense_management/features/profile/presentation/widgets/category_ui_constants.dart';
import 'category_management_options_sheet.dart';

class CategoryManagementGrid extends ConsumerWidget {
  final List<CategoryDto> children;
  final List<CategoryDto> allCategories;

  const CategoryManagementGrid({
    super.key,
    required this.children,
    required this.allCategories,
  });

  void _showCategoryOptions(BuildContext context, CategoryDto category) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CategoryManagementOptionsSheet(
        category: category,
        allCategories: allCategories,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final sortedChildren = List<CategoryDto>.from(children)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: sortedChildren.length,
      itemBuilder: (context, index) {
        final category = sortedChildren[index];
        final iconData = CategoryUIConstants.getIconData(category.icon);
        final color = CategoryUIConstants.getColorFromHex(category.color);

        return GestureDetector(
          onTap: () => _showCategoryOptions(context, category),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      iconData,
                      color: color,
                      size: 24,
                    ),
                  ),
                  if (!category.isDefault)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: colors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.surface, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  category.name.tr(ref),
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
