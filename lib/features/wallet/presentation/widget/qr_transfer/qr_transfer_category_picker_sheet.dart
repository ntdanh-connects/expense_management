import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/profile/data/models/category_dto.dart';
import 'package:expense_management/features/profile/presentation/widgets/category_ui_constants.dart';

class QrTransferCategoryPickerSheet extends ConsumerWidget {
  final List<CategoryDto> parentCategories;
  final CategoryDto? selectedCategory;
  final ValueChanged<CategoryDto> onCategorySelected;
  final ScrollController scrollController;

  const QrTransferCategoryPickerSheet({
    super.key,
    required this.parentCategories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: color.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: color.textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Chọn danh mục chi tiêu',
            style: TextStyle(
              color: color.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: parentCategories.length,
              itemBuilder: (context, idx) {
                final parent = parentCategories[idx];
                final subCats = parent.children ?? [];
                if (subCats.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        parent.name.tr(ref),
                        style: TextStyle(
                          color: color.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 8,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: subCats.length,
                      itemBuilder: (context, sIdx) {
                        final subCat = subCats[sIdx];
                        final iconData = CategoryUIConstants.getIconData(subCat.icon);
                        final catColor = CategoryUIConstants.getColorFromHex(subCat.color);
                        final isSelected = selectedCategory?.id == subCat.id;

                        return InkWell(
                          onTap: () {
                            onCategorySelected(subCat);
                            Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: catColor.withOpacity(isSelected ? 0.3 : 0.12),
                                  shape: BoxShape.circle,
                                  border: isSelected
                                      ? Border.all(color: catColor, width: 2)
                                      : null,
                                ),
                                child: Icon(iconData, color: catColor, size: 22),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                subCat.name.tr(ref),
                                style: TextStyle(
                                  color: isSelected ? catColor : color.textPrimary,
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
