import 'package:expense_management/features/profile/presentation/providers/category_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/profile/data/models/category_dto.dart';
import 'category_ui_constants.dart';

class AddEditCategorySheet extends ConsumerStatefulWidget {
  final CategoryDto? categoryToEdit;
  final String categoryType; // 'expense' or 'income'
  final List<CategoryDto> parentCategories;
  final String? lockedParentId; // When set, the parent is pre-filled and locked

  const AddEditCategorySheet({
    super.key,
    this.categoryToEdit,
    required this.categoryType,
    required this.parentCategories,
    this.lockedParentId,
  });

  @override
  ConsumerState<AddEditCategorySheet> createState() => _AddEditCategorySheetState();
}

class _AddEditCategorySheetState extends ConsumerState<AddEditCategorySheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  String? _selectedParentId;
  String _selectedIcon = 'food';
  String _selectedColor = '#FF8F9C';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final edit = widget.categoryToEdit;
    _nameController = TextEditingController(text: edit?.name ?? '');
    
    _selectedIcon = widget.categoryType == 'income' ? 'salary' : 'food';
    
    if (edit != null) {
      _selectedParentId = edit.parentId;
      _selectedIcon = edit.icon ?? _selectedIcon;
      _selectedColor = edit.color ?? '#FF8F9C';
    } else {
      // If locked parent is provided, use it
      if (widget.lockedParentId != null) {
        _selectedParentId = widget.lockedParentId;
      } else if (widget.parentCategories.isNotEmpty) {
        _selectedParentId = widget.parentCategories.first.id;
      }
      _selectedColor = CategoryUIConstants.colorsList.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedParentId == null && widget.categoryType == 'expense') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng chọn danh mục cha!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final notifier = ref.read(categoriesNotifierProvider.notifier);

      if (widget.categoryToEdit != null) {
        await notifier.updateCategory(
          id: widget.categoryToEdit!.id,
          name: name,
          icon: _selectedIcon,
          color: _selectedColor,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('update_category_success'.trRead(ref)),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        // Find parent ID for Income if not chosen
        String? parentId = _selectedParentId;
        if (widget.categoryType == 'income') {
          // In Momo, income has only 1 parent category: "Thu nhập"
          final incomeParent = widget.parentCategories.firstWhere(
            (c) => c.type == 'income',
            orElse: () => widget.parentCategories.first,
          );
          parentId = incomeParent.id;
        }

        await notifier.createCategory(
          name: name,
          parentId: parentId!,
          icon: _selectedIcon,
          color: _selectedColor,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('create_category_success'.trRead(ref)),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
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
    final iconsAsync = ref.watch(supportedIconsProvider);
    final isEdit = widget.categoryToEdit != null;

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
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
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
                isEdit ? 'edit_category'.tr(ref) : 'new_category'.tr(ref),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Name field
              Text(
                'category_name'.tr(ref),
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'enter_category_name'.tr(ref),
                  hintStyle: TextStyle(color: colors.textSecondary.withOpacity(0.5)),
                  filled: true,
                  fillColor: colors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'name_cannot_be_empty'.tr(ref);
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Parent group (Read-only if editing OR if lockedParentId is set)
              if (widget.categoryType == 'expense') ...[
                Text(
                  'select_parent_category'.tr(ref),
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (isEdit || widget.lockedParentId != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: colors.background.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.textSecondary.withOpacity(0.1)),
                    ),
                    child: Text(
                      widget.parentCategories.firstWhere(
                        (c) => c.id == _selectedParentId,
                        orElse: () => CategoryDto(id: '', name: 'Không xác định', type: 'expense', sortOrder: 0, isDefault: false),
                      ).name.tr(ref),
                      style: TextStyle(color: colors.textSecondary.withOpacity(0.8), fontSize: 15),
                    ),
                  ),
                ] else if (widget.parentCategories.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: colors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedParentId,
                        dropdownColor: colors.surface,
                        icon: Icon(Icons.keyboard_arrow_down, color: colors.textSecondary),
                        isExpanded: true,
                        items: widget.parentCategories.map((c) {
                          return DropdownMenuItem<String>(
                            value: c.id,
                            child: Text(
                              c.name.tr(ref),
                              style: TextStyle(color: colors.textPrimary, fontSize: 15),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedParentId = val);
                        },
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
              ],

              // Color picker
              Text(
                'select_color'.tr(ref),
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: CategoryUIConstants.colorsList.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final colorHex = CategoryUIConstants.colorsList[index];
                    final color = CategoryUIConstants.getColorFromHex(colorHex);
                    final isSelected = _selectedColor.toLowerCase() == colorHex.toLowerCase();

                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedColor = colorHex);
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: colors.textPrimary, width: 3)
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: isSelected
                            ? Icon(Icons.check, color: Colors.white, size: 18)
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Icon picker
              Text(
                'select_icon'.tr(ref),
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              iconsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, __) => Text('Error loading icons: $e', style: TextStyle(color: colors.expenseRed)),
                data: (icons) {
                  final filteredIcons = icons.where((icon) {
                    if (widget.categoryType == 'income') {
                      return CategoryUIConstants.incomeIcons.contains(icon);
                    } else {
                      return CategoryUIConstants.expenseIcons.contains(icon);
                    }
                  }).toList();

                  final displayIcons = filteredIcons.isNotEmpty ? filteredIcons : icons;

                  return SizedBox(
                    height: 180,
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                      ),
                      itemCount: displayIcons.length,
                      itemBuilder: (context, index) {
                        final iconKey = displayIcons[index];
                        final iconData = CategoryUIConstants.getIconData(iconKey);
                        final isSelected = _selectedIcon == iconKey;
                        final themeColor = CategoryUIConstants.getColorFromHex(_selectedColor);

                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedIcon = iconKey);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? themeColor.withOpacity(0.15)
                                  : colors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? themeColor : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              iconData,
                              color: isSelected ? themeColor : colors.textSecondary,
                              size: 24,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
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
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CategoryUIConstants.getColorFromHex(_selectedColor),
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
                              'save'.tr(ref),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
