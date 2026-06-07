import 'package:expense_management/features/profile/category_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/profile/data/models/category_dto.dart';
import 'category_ui_constants.dart';

class MergeCategorySheet extends ConsumerStatefulWidget {
  final CategoryDto fromCategory;
  final List<CategoryDto> allCategories;

  const MergeCategorySheet({
    super.key,
    required this.fromCategory,
    required this.allCategories,
  });

  @override
  ConsumerState<MergeCategorySheet> createState() => _MergeCategorySheetState();
}

class _MergeCategorySheetState extends ConsumerState<MergeCategorySheet> {
  String? _selectedToCategoryId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Gather all candidate categories (same type, same child level, not equals fromCategory)
    final candidates = _getCandidates();
    if (candidates.isNotEmpty) {
      _selectedToCategoryId = candidates.first.id;
    }
  }

  List<CategoryDto> _getCandidates() {
    final candidates = <CategoryDto>[];
    for (final parent in widget.allCategories) {
      if (parent.type != widget.fromCategory.type) continue;
      
      // If parent has children, we add children (since fromCategory is a child)
      if (parent.children != null) {
        for (final child in parent.children!) {
          if (child.id != widget.fromCategory.id) {
            candidates.add(child);
          }
        }
      }
    }
    return candidates;
  }

  Future<void> _submit() async {
    if (_selectedToCategoryId == null) return;
    
    setState(() => _isLoading = true);
    try {
      await ref.read(categoriesNotifierProvider.notifier).mergeCategories(
        fromCategoryId: widget.fromCategory.id,
        toCategoryId: _selectedToCategoryId!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'merge_categories'.trRead(ref)} ${'success'.trRead(ref).toLowerCase()}!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Close merge sheet
        Navigator.pop(context); // Close option sheet as well
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final candidates = _getCandidates();

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textSecondary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'merge_categories'.tr(ref),
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'merge_categories_desc'.tr(ref),
            style: TextStyle(color: colors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 20),

          Text(
            'select_target_category'.tr(ref),
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (candidates.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Không có danh mục nào phù hợp để gộp.',
                style: TextStyle(color: colors.textSecondary, fontStyle: FontStyle.italic),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedToCategoryId,
                  dropdownColor: colors.surface,
                  icon: Icon(Icons.keyboard_arrow_down, color: colors.textSecondary),
                  isExpanded: true,
                  items: candidates.map((c) {
                    final iconData = CategoryUIConstants.getIconData(c.icon);
                    final color = CategoryUIConstants.getColorFromHex(c.color);
                    return DropdownMenuItem<String>(
                      value: c.id,
                      child: Row(
                        children: [
                          Icon(iconData, color: color, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            c.name.tr(ref),
                            style: TextStyle(color: colors.textPrimary, fontSize: 15),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedToCategoryId = val);
                  },
                ),
              ),
            ),
          const SizedBox(height: 24),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colors.textSecondary.withOpacity(0.2)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'cancel'.tr(ref),
                    style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: (_isLoading || _selectedToCategoryId == null) ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'confirm'.tr(ref),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
