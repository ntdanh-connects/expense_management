import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/profile/data/models/category_dto.dart';
import 'package:expense_management/features/profile/presentation/widgets/category_ui_constants.dart';
import 'package:expense_management/features/profile/presentation/providers/category_provider.dart';

class CategoryEditIconPickerSheet extends ConsumerStatefulWidget {
  final CategoryDto category;
  final String initialIconKey;
  final String initialColorHex;
  final void Function(String iconKey, String colorHex) onDone;

  const CategoryEditIconPickerSheet({
    super.key,
    required this.category,
    required this.initialIconKey,
    required this.initialColorHex,
    required this.onDone,
  });

  @override
  ConsumerState<CategoryEditIconPickerSheet> createState() => _CategoryEditIconPickerSheetState();
}

class _CategoryEditIconPickerSheetState extends ConsumerState<CategoryEditIconPickerSheet> {
  late String _selectedIconKey;
  late String _selectedColorHex;

  @override
  void initState() {
    super.initState();
    _selectedIconKey = widget.initialIconKey;
    _selectedColorHex = widget.initialColorHex;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

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
              onPressed: () {
                widget.onDone(_selectedIconKey, _selectedColorHex);
                Navigator.pop(context);
              },
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
  }
}
