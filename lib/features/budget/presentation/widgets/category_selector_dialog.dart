import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/profile/data/models/category_dto.dart';
import 'package:expense_management/features/profile/presentation/widgets/category_ui_constants.dart';

class ParentChildCategoryPickerDialog extends ConsumerStatefulWidget {
  final List<CategoryDto> allCategories;
  final Set<String?> excludedCategoryIds;

  const ParentChildCategoryPickerDialog({
    super.key,
    required this.allCategories,
    required this.excludedCategoryIds,
  });

  @override
  ConsumerState<ParentChildCategoryPickerDialog> createState() => _ParentChildCategoryPickerDialogState();
}

class _ParentChildCategoryPickerDialogState extends ConsumerState<ParentChildCategoryPickerDialog> {
  CategoryDto? _selectedParent;
  
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    
    // Filter parent categories (parentId == null and type == 'expense')
    final parentCategories = widget.allCategories
        .where((c) => c.parentId == null && c.type.toLowerCase() == 'expense')
        .toList();
    parentCategories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    // Filter subcategories of the selected parent category, excluding already selected ones
    final subcategories = _selectedParent == null
        ? <CategoryDto>[]
        : (_selectedParent!.children ?? widget.allCategories.where((c) => c.parentId == _selectedParent!.id).toList())
            .where((c) => !widget.excludedCategoryIds.contains(c.id))
            .toList();
    subcategories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and navigation header
            Row(
              children: [
                if (_selectedParent != null)
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.textPrimary, size: 18),
                    onPressed: () {
                      setState(() {
                        _selectedParent = null;
                      });
                    },
                  ),
                Expanded(
                  child: Text(
                    _selectedParent == null ? 'select_parent_category'.tr(ref) : 'select_subcategory'.tr(ref),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Content
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: _selectedParent == null
                  ? _buildParentGrid(parentCategories, colors)
                  : _buildSubcategoryGrid(subcategories, colors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParentGrid(List<CategoryDto> parents, AppColorsExtension colors) {
    if (parents.isEmpty) {
      return Center(
        child: Text(
          'no_parent_category_found'.tr(ref),
          style: TextStyle(color: colors.textSecondary),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.8,
      ),
      itemCount: parents.length,
      itemBuilder: (context, index) {
        final parent = parents[index];
        final iconData = CategoryUIConstants.getIconData(parent.icon, categoryName: parent.name);
        final color = CategoryUIConstants.getColorFromHex(parent.color, categoryName: parent.name);

        return InkWell(
          onTap: () {
            setState(() {
              _selectedParent = parent;
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.2), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    parent.name,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubcategoryGrid(List<CategoryDto> subs, AppColorsExtension colors) {
    if (subs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Text(
            'all_subcategories_have_budget'.tr(ref),
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: subs.length,
      itemBuilder: (context, index) {
        final sub = subs[index];
        final iconData = CategoryUIConstants.getIconData(sub.icon, categoryName: sub.name);
        final color = CategoryUIConstants.getColorFromHex(sub.color, categoryName: sub.name);

        return InkWell(
          onTap: () {
            Navigator.pop(context, sub);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: colors.textSecondary.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.textSecondary.withOpacity(0.08), width: 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, color: color, size: 20),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    sub.name,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
