import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/profile/data/models/category_dto.dart';
import 'package:expense_management/features/profile/presentation/widgets/category_ui_constants.dart';
import 'package:expense_management/features/profile/presentation/providers/category_provider.dart';
import 'package:go_router/go_router.dart';

class CategoryPickerBottomSheet extends ConsumerStatefulWidget {
  final String transactionType; // 'income' or 'expense'
  final CategoryDto? selectedCategory;
  final ValueChanged<CategoryDto> onCategorySelected;

  const CategoryPickerBottomSheet({
    super.key,
    required this.transactionType,
    this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  ConsumerState<CategoryPickerBottomSheet> createState() => _CategoryPickerBottomSheetState();
}

class _CategoryPickerBottomSheetState extends ConsumerState<CategoryPickerBottomSheet> {
  String _searchQuery = '';
  bool _includeInStats = true;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final categories = ref.watch(categoriesNotifierProvider).value ?? [];
    final filteredParentCategories = categories.where((c) => c.type == widget.transactionType).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 38,
            height: 4.5,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          
          // Title and Close
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
            child: Row(
              children: [
                const Spacer(),
                Text(
                  'select_category'.tr(ref),
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
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5),

          // Search and Create new row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Search field
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.textSecondary.withValues(alpha: 0.1)),
                    ),
                    child: TextField(
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      style: TextStyle(color: colors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'search_subcategory_hint'.tr(ref),
                        hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.6), fontSize: 13),
                        prefixIcon: Icon(Icons.search_rounded, color: colors.textSecondary.withValues(alpha: 0.6), size: 18),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Create button
                SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/profile/category-management');
                    },
                    icon: Icon(Icons.add_circle_outline_rounded, color: colors.textPrimary, size: 18),
                    label: Text(
                      'create_new'.tr(ref),
                      style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.surface,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: colors.textSecondary.withValues(alpha: 0.1)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Include in stats toggle row (Mockup design matching MoMo)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.primary.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Icon(Icons.bar_chart_rounded, color: colors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.transactionType == 'expense' 
                          ? 'Tính khoản này vào Chi tiêu'.tr(ref)
                          : 'Tính khoản này vào Thu nhập'.tr(ref),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Switch(
                    value: _includeInStats,
                    onChanged: (val) {
                      setState(() {
                        _includeInStats = val;
                      });
                    },
                    activeThumbColor: colors.primary,
                  ),
                ],
              ),
            ),
          ),

          // Scrollable Category Groups List
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  ..._buildGroups(filteredParentCategories, colors),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGroups(List<CategoryDto> parentCategories, AppColorsExtension colors) {
    final List<Widget> groupWidgets = [];
    for (final parent in parentCategories) {
      final List<CategoryDto> selectableItems = [];
      if (parent.children != null && parent.children!.isNotEmpty) {
        selectableItems.addAll(parent.children!);
      } else {
        selectableItems.add(parent);
      }

      final matchedItems = selectableItems.where((item) {
        if (_searchQuery.isEmpty) return true;
        return item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               item.name.tr(ref).toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();

      if (matchedItems.isNotEmpty) {
        groupWidgets.add(
          _buildCategoryGroup(
            parentName: parent.name,
            parentColorStr: parent.color,
            items: matchedItems,
            colors: colors,
            ref: ref,
            selectedCategory: widget.selectedCategory,
            onSelect: (cat) {
              widget.onCategorySelected(cat);
              Navigator.pop(context);
            },
          ),
        );
      }
    }
    return groupWidgets;
  }

  Widget _buildCategoryGroup({
    required String parentName,
    required String? parentColorStr,
    required List<CategoryDto> items,
    required AppColorsExtension colors,
    required WidgetRef ref,
    required CategoryDto? selectedCategory,
    required Function(CategoryDto) onSelect,
  }) {
    final groupColor = CategoryUIConstants.getColorFromHex(parentColorStr, categoryName: parentName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        // Group Header Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: groupColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                parentName.tr(ref),
                style: TextStyle(
                  color: groupColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        // Grid of Categories under this Group
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 16,
            crossAxisSpacing: 8,
            childAspectRatio: 0.85,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final category = items[index];
            final iconData = CategoryUIConstants.getIconData(category.icon, categoryName: category.name);
            final categoryColor = CategoryUIConstants.getColorFromHex(category.color, categoryName: category.name);
            final isSelected = selectedCategory?.id == category.id;

            return GestureDetector(
              onTap: () => onSelect(category),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: isSelected ? 0.25 : 0.08),
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
                  const SizedBox(height: 6),
                  Text(
                    category.name.tr(ref),
                    style: TextStyle(
                      color: isSelected ? categoryColor : colors.textPrimary,
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
      ],
    );
  }
}
