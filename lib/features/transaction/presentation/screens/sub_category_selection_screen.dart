import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/profile/data/models/category_dto.dart';
import 'package:expense_management/features/profile/presentation/widgets/category_ui_constants.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/language/app_provider.dart';

class SubCategorySelectionScreen extends ConsumerStatefulWidget {
  final CategoryDto parentCategory;
  final CategoryDto? selectedSubCategory;

  const SubCategorySelectionScreen({
    super.key,
    required this.parentCategory,
    this.selectedSubCategory,
  });

  @override
  ConsumerState<SubCategorySelectionScreen> createState() => _SubCategorySelectionScreenState();
}

class _SubCategorySelectionScreenState extends ConsumerState<SubCategorySelectionScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final children = widget.parentCategory.children ?? [];
    
    // Filter children by search query
    final filteredChildren = children.where((child) {
      return child.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
             child.name.tr(ref).toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Sort children by sortOrder
    filteredChildren.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    // Determine parent theme color/icon
    Color parentColor;
    IconData parentIcon;
    switch (widget.parentCategory.name) {
      case 'Chi tiêu - sinh hoạt':
      case 'Living Expenses':
        parentColor = const Color(0xFFF97316);
        parentIcon = Icons.home_rounded;
        break;
      case 'Chi phí phát sinh':
      case 'Occasional Expenses':
        parentColor = const Color(0xFFEAB308);
        parentIcon = Icons.lightbulb_rounded;
        break;
      case 'Chi phí cố định':
      case 'Fixed Expenses':
        parentColor = const Color(0xFF3B82F6);
        parentIcon = Icons.receipt_long_rounded;
        break;
      case 'Đầu tư - tiết kiệm':
      case 'Investment & Savings':
        parentColor = const Color(0xFF10B981);
        parentIcon = Icons.trending_up_rounded;
        break;
      case 'Thu nhập':
      case 'Income':
        parentColor = const Color(0xFF8B5CF6);
        parentIcon = Icons.monetization_on_rounded;
        break;
      default:
        parentColor = colors.primary;
        parentIcon = Icons.category_rounded;
    }

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'select_subcategory'.tr(ref),
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          // Parent category banner card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: parentColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: parentColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: parentColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(parentIcon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.parentCategory.name.tr(ref),
                      style: TextStyle(color: parentColor, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'parent_category_label'.tr(ref),
                      style: TextStyle(color: colors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 🔎 Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.textSecondary.withOpacity(0.1)),
              ),
              child: TextField(
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'search_subcategory_hint'.tr(ref),
                  hintStyle: TextStyle(color: colors.textSecondary.withOpacity(0.6)),
                  prefixIcon: Icon(Icons.search_rounded, color: colors.textSecondary.withOpacity(0.6)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // Grid View
          Expanded(
            child: filteredChildren.isEmpty
                ? Center(
                    child: Text(
                      'no_categories_found'.tr(ref),
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: filteredChildren.length,
                    itemBuilder: (context, index) {
                      final category = filteredChildren[index];
                      final iconData = CategoryUIConstants.getIconData(category.icon);
                      final categoryColor = CategoryUIConstants.getColorFromHex(category.color);
                      final isSelected = widget.selectedSubCategory?.id == category.id;

                      return GestureDetector(
                        onTap: () => Navigator.pop(context, category),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: categoryColor.withOpacity(isSelected ? 0.3 : 0.12),
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: categoryColor, width: 2)
                                    : Border.all(color: Colors.transparent),
                              ),
                              child: Icon(
                                iconData,
                                color: categoryColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: Text(
                                category.name.tr(ref),
                                style: TextStyle(
                                  color: isSelected ? categoryColor : colors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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
                  ),
          ),
        ],
      ),
    );
  }
}
