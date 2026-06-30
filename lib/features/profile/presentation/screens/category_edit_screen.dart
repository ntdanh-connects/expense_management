import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/profile/data/models/category_dto.dart';
import 'package:expense_management/features/profile/presentation/providers/category_provider.dart';
import 'package:expense_management/features/profile/presentation/widgets/category_ui_constants.dart';

import '../widgets/category_edit/category_edit_icon_picker_sheet.dart';
import '../widgets/category_edit/category_edit_delete_dialog.dart';

class CategoryEditScreen extends ConsumerStatefulWidget {
  final CategoryDto category;
  final List<CategoryDto> parentCategories;

  const CategoryEditScreen({
    super.key,
    required this.category,
    required this.parentCategories,
  });

  @override
  ConsumerState<CategoryEditScreen> createState() => _CategoryEditScreenState();
}

class _CategoryEditScreenState extends ConsumerState<CategoryEditScreen> {
  late TextEditingController _nameController;
  late String _selectedIconKey;
  late String _selectedColorHex;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category.name);
    _selectedIconKey = widget.category.icon ?? 'food';
    _selectedColorHex = widget.category.color ?? '#FF8F9C';
    _nameController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _isChanged {
    final hasNameChanged = _nameController.text.trim() != widget.category.name && _nameController.text.trim().isNotEmpty;
    final hasIconChanged = _selectedIconKey != widget.category.icon;
    final hasColorChanged = _selectedColorHex.toLowerCase() != (widget.category.color ?? '').toLowerCase();
    return hasNameChanged || hasIconChanged || hasColorChanged;
  }

  Future<void> _updateCategory() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(categoriesNotifierProvider.notifier).updateCategory(
        id: widget.category.id,
        name: _nameController.text.trim(),
        icon: _selectedIconKey,
        color: _selectedColorHex,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật danh mục thành công'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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

  void _triggerDeleteCategory() {
    showDialog(
      context: context,
      builder: (ctx) => CategoryEditDeleteDialog(
        category: widget.category,
        onSuccess: () {
          Navigator.pop(context); // Close edit screen after successful delete
        },
      ),
    );
  }

  void _showIconPickerBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return CategoryEditIconPickerSheet(
          category: widget.category,
          initialIconKey: _selectedIconKey,
          initialColorHex: _selectedColorHex,
          onDone: (iconKey, colorHex) {
            setState(() {
              _selectedIconKey = iconKey;
              _selectedColorHex = colorHex;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final parentCategory = widget.parentCategories.firstWhere(
      (c) => c.id == widget.category.parentId,
      orElse: () => CategoryDto(
        id: '',
        name: widget.category.type == 'income' ? 'Thu nhập' : 'Chi phí cố định',
        type: widget.category.type,
        sortOrder: 0,
        isDefault: false,
      ),
    );
    final parentIconData = CategoryUIConstants.getIconData(parentCategory.icon);
    final parentColor = CategoryUIConstants.getColorFromHex(parentCategory.color);

    final displayIconData = CategoryUIConstants.getIconData(_selectedIconKey);
    final displayColor = CategoryUIConstants.getColorFromHex(_selectedColorHex);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Chỉnh sửa danh mục',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.headset_mic_rounded, color: Color(0xFFD81B60), size: 20),
                  onPressed: () {},
                ),
                Container(
                  height: 16,
                  width: 1,
                  color: Colors.grey.withOpacity(0.3),
                ),
                IconButton(
                  icon: const Icon(Icons.home_outlined, color: Color(0xFFD81B60), size: 20),
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                ),
              ],
            ),
          )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFFF0F5).withOpacity(0.5),
              colors.background,
            ],
            stops: const [0.0, 0.4],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      // Icon Display
                      GestureDetector(
                        onTap: _showIconPickerBottomSheet,
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: displayColor.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                displayIconData,
                                color: displayColor,
                                size: 36,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Đổi biểu tượng',
                              style: TextStyle(
                                color: Color(0xFFD81B60),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Name input
                      TextFormField(
                        controller: _nameController,
                        maxLength: 30,
                        style: TextStyle(color: colors.textPrimary, fontSize: 16),
                        decoration: InputDecoration(
                          labelText: 'Tên danh mục (${_nameController.text.length}/30)*',
                          labelStyle: TextStyle(color: colors.textSecondary.withOpacity(0.7)),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.textSecondary.withOpacity(0.2)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFD81B60), width: 1.5),
                          ),
                          counterText: '',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Parent category (disabled/read-only)
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Không thể thay đổi nhóm danh mục cha'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: AbsorbPointer(
                          child: TextFormField(
                            initialValue: '  ${parentCategory.name}',
                            style: TextStyle(color: colors.textSecondary, fontSize: 16),
                            decoration: InputDecoration(
                              labelText: 'Thuộc danh mục*',
                              labelStyle: TextStyle(color: colors.textSecondary.withOpacity(0.7)),
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: parentColor.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(parentIconData, color: parentColor, size: 16),
                                ),
                              ),
                              prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                              suffixIcon: Icon(Icons.keyboard_arrow_down, color: colors.textSecondary.withOpacity(0.5)),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: colors.textSecondary.withOpacity(0.2))),
                              fillColor: colors.background.withOpacity(0.5),
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom Action buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              color: colors.surface,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _triggerDeleteCategory,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: colors.textSecondary.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Xóa danh mục',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_isChanged && !_isLoading) ? _updateCategory : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD81B60),
                        disabledBackgroundColor: Colors.grey.shade200,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Cập nhật',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
