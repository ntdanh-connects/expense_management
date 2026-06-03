import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/profile/data/models/category_dto.dart';
import 'package:expense_management/features/profile/category_provider.dart';
import 'package:expense_management/features/profile/presentation/widgets/category_ui_constants.dart';
import 'package:go_router/go_router.dart';

class EditCategoryScreen extends ConsumerStatefulWidget {
  final CategoryDto category;
  final List<CategoryDto> parentCategories;

  const EditCategoryScreen({
    super.key,
    required this.category,
    required this.parentCategories,
  });

  @override
  ConsumerState<EditCategoryScreen> createState() => _EditCategoryScreenState();
}

class _EditCategoryScreenState extends ConsumerState<EditCategoryScreen> {
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
          SnackBar(
            content: Text('update_category_success'.tr(ref)),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
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

  Future<void> _deleteCategory() async {
    final colors = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'delete_category_confirm'.tr(ref),
            style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Hành động này sẽ xóa vĩnh viễn danh mục "${widget.category.name}".',
            style: TextStyle(color: colors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('cancel'.tr(ref), style: TextStyle(color: colors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(backgroundColor: colors.expenseRed),
              child: Text('delete'.tr(ref), style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await ref.read(categoriesNotifierProvider.notifier).deleteCategory(widget.category.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('delete_category_success'.tr(ref)),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
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
  }

  void _showIconPickerBottomSheet() {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              height: MediaQuery.of(context).size.height * 0.65,
              child: Column(
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
                    'Đổi biểu tượng & màu sắc',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'select_color'.tr(ref),
                    style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: CategoryUIConstants.colorsList.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final colorHex = CategoryUIConstants.colorsList[index];
                        final colorVal = CategoryUIConstants.getColorFromHex(colorHex);
                        final isSel = _selectedColorHex.toLowerCase() == colorHex.toLowerCase();
                        return GestureDetector(
                          onTap: () {
                            setSheetState(() => _selectedColorHex = colorHex);
                            setState(() => _selectedColorHex = colorHex);
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: colorVal,
                              shape: BoxShape.circle,
                              border: isSel ? Border.all(color: colors.textPrimary, width: 3) : null,
                            ),
                            child: isSel ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'select_icon'.tr(ref),
                    style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ref.watch(supportedIconsProvider).when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, __) => Text('Error loading icons: $e'),
                      data: (icons) {
                        final filteredIcons = icons.where((icon) {
                          if (widget.category.type == 'income') {
                            return CategoryUIConstants.incomeIcons.contains(icon);
                          } else {
                            return CategoryUIConstants.expenseIcons.contains(icon);
                          }
                        }).toList();
                        final displayIcons = filteredIcons.isNotEmpty ? filteredIcons : icons;

                        return GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                          ),
                          itemCount: displayIcons.length,
                          itemBuilder: (context, idx) {
                            final iconKey = displayIcons[idx];
                            final iconData = CategoryUIConstants.getIconData(iconKey);
                            final isSel = _selectedIconKey == iconKey;
                            final themeColor = CategoryUIConstants.getColorFromHex(_selectedColorHex);
                            return GestureDetector(
                              onTap: () {
                                setSheetState(() => _selectedIconKey = iconKey);
                                setState(() => _selectedIconKey = iconKey);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSel ? themeColor.withOpacity(0.15) : colors.background,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isSel ? themeColor : Colors.transparent, width: 2),
                                ),
                                child: Icon(iconData, color: isSel ? themeColor : colors.textSecondary, size: 24),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CategoryUIConstants.getColorFromHex(_selectedColorHex),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Xong', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
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
          onPressed: () => context.pop(),
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
                    while (context.canPop()) {
                      context.pop();
                    }
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
              const Color(0xFFFFF0F5).withOpacity(0.5), // Soft Pinkish/Momo top
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
                          // Disabled, show a hint
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
                                borderSide: BorderSide(color: colors.textSecondary.withOpacity(0.2)),
                              ),
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
                      onPressed: _isLoading ? null : _deleteCategory,
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
                          : Text(
                              'Cập nhật',
                              style: TextStyle(
                                color: _isChanged ? Colors.white : Colors.grey.shade400,
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
