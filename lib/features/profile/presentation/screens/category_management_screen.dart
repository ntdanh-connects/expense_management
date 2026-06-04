import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/profile/data/models/category_dto.dart';
import 'package:expense_management/features/profile/category_provider.dart';
import 'package:expense_management/features/profile/presentation/widgets/category_ui_constants.dart';
import 'package:expense_management/features/profile/presentation/widgets/add_edit_category_sheet.dart';
import 'package:expense_management/features/profile/presentation/widgets/merge_category_sheet.dart';
import 'package:expense_management/features/profile/presentation/screens/category_edit_screen.dart';

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends ConsumerState<CategoryManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _activeTabIndex = 0; // 0 for Expense, 1 for Income

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        _activeTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddCategorySheet(BuildContext context, String type, List<CategoryDto> parentCategories) {
    // Count custom categories of this type
    final allParents = ref.read(categoriesNotifierProvider).value ?? [];
    int customCount = 0;
    for (final parent in allParents) {
      if (parent.type == type && parent.children != null) {
        customCount += parent.children!.where((c) => !c.isDefault).length;
      }
    }

    if (customCount >= 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('max_category_limit_reached'.trRead(ref)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditCategorySheet(
        categoryType: type,
        parentCategories: parentCategories,
      ),
    );
  }

  void _showCategoryOptions(BuildContext context, CategoryDto category, List<CategoryDto> allCategories) {
    final colors = context.colors;
    final iconData = CategoryUIConstants.getIconData(category.icon);
    final themeColor = CategoryUIConstants.getColorFromHex(category.color);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(iconData, color: themeColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category.isDefault
                              ? 'Danh mục mặc định hệ thống'
                              : 'Danh mục tùy chỉnh cá nhân',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (category.isDefault) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: colors.textSecondary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'cannot_delete_default_category'.tr(ref),
                          style: TextStyle(color: colors.textSecondary, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                ListTile(
                  leading: Icon(Icons.edit_outlined, color: colors.textPrimary),
                  title: Text('Chỉnh sửa danh mục', style: TextStyle(color: colors.textPrimary)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CategoryEditScreen(
                          category: category,
                          parentCategories: allCategories.where((c) => c.type == category.type).toList(),
                        ),
                      ),
                    );
                  },
                ),
                Divider(color: colors.textSecondary.withOpacity(0.1)),
                ListTile(
                  leading: Icon(Icons.merge_type_rounded, color: colors.textPrimary),
                  title: Text('Gộp danh mục', style: TextStyle(color: colors.textPrimary)),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => MergeCategorySheet(
                        fromCategory: category,
                        allCategories: allCategories,
                      ),
                    );
                  },
                ),
                Divider(color: colors.textSecondary.withOpacity(0.1)),
                ListTile(
                  leading: Icon(Icons.delete_outline_rounded, color: colors.expenseRed),
                  title: Text('Xóa danh mục', style: TextStyle(color: colors.expenseRed)),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDelete(context, category);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, CategoryDto category) {
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'delete_category_confirm'.trRead(ref),
            style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Hành động này sẽ xóa vĩnh viễn danh mục "${category.name}".',
            style: TextStyle(color: colors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('cancel'.trRead(ref), style: TextStyle(color: colors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await ref.read(categoriesNotifierProvider.notifier).deleteCategory(category.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('delete_category_success'.trRead(ref)),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString().replaceFirst('Exception: ', '')),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: colors.expenseRed),
              child: Text('delete'.trRead(ref), style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final categoriesAsync = ref.watch(categoriesNotifierProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'category_management'.tr(ref),
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.home_outlined, color: colors.textPrimary),
            onPressed: () {
              while (context.canPop()) {
                context.pop();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Custom Tab bar switcher
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colors.textSecondary.withOpacity(0.1), width: 1.5),
              ),
            ),
            child: Row(
              children: [
                _buildTabItem(
                  index: 0,
                  label: 'expense_label'.tr(ref),
                  icon: Icons.trending_down_rounded,
                  activeColor: colors.profileInfo,
                ),
                _buildTabItem(
                  index: 1,
                  label: 'income_label'.tr(ref),
                  icon: Icons.trending_up_rounded,
                  activeColor: colors.incomeGreen,
                ),
              ],
            ),
          ),

          Expanded(
            child: categoriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, __) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Lỗi tải danh mục từ Server',
                      style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(error.toString(), style: TextStyle(color: colors.textSecondary), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.read(categoriesNotifierProvider.notifier).refreshCategories(),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
              data: (allCategories) {
                final type = _activeTabIndex == 0 ? 'expense' : 'income';
                final parents = allCategories.where((c) => c.type == type).toList();

                // Compute custom categories count
                int customCount = 0;
                for (final parent in allCategories) {
                  if (parent.type == type && parent.children != null) {
                    customCount += parent.children!.where((c) => !c.isDefault).length;
                  }
                }

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      // New Category Button Row
                      _buildNewCategoryRow(type, parents, customCount),
                      const SizedBox(height: 16),

                      // List Content
                      if (type == 'income')
                        _buildIncomeView(parents, allCategories)
                      else
                        _buildExpenseView(parents, allCategories),
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

  Widget _buildTabItem({
    required int index,
    required String label,
    required IconData icon,
    required Color activeColor,
  }) {
    final colors = context.colors;
    final isActive = _activeTabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeTabIndex = index;
            _tabController.animateTo(index);
          });
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: isActive ? activeColor : colors.textSecondary.withOpacity(0.7),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: isActive ? activeColor : colors.textSecondary.withOpacity(0.7),
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 3,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isActive ? activeColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewCategoryRow(String type, List<CategoryDto> parentCategories, int customCount) {
    final colors = context.colors;
    final isIncome = type == 'income';
    final activeThemeColor = isIncome ? colors.incomeGreen : colors.profileInfo;

    return Container(
      decoration: BoxDecoration(
        color: colors.authCardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAddCategorySheet(context, type, parentCategories),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: activeThemeColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.add,
                    color: activeThemeColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'custom_category_count'.tr(ref).replaceFirst('{count}', '$customCount'),
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'create_custom_category_desc'.tr(ref),
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: colors.textSecondary.withOpacity(0.5),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIncomeView(List<CategoryDto> parents, List<CategoryDto> allCategories) {
    final colors = context.colors;
    if (parents.isEmpty) return const SizedBox();

    // In Momo design, Income typically lists all children directly
    final incomeParent = parents.first;
    final children = incomeParent.children ?? [];

    if (children.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'Chưa có danh mục thu nhập nào.',
            style: TextStyle(color: colors.textSecondary),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.authCardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: _buildCategoryGrid(children, allCategories),
    );
  }

  Widget _buildExpenseView(List<CategoryDto> parents, List<CategoryDto> allCategories) {
    final colors = context.colors;

    if (parents.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'Chưa có nhóm danh mục chi tiêu nào.',
            style: TextStyle(color: colors.textSecondary),
          ),
        ),
      );
    }

    // Sort parents by sortOrder
    parents.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: parents.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final parent = parents[index];
        final children = parent.children ?? [];

        // Assign colors/icons for parents dynamically
        Color headerColor;
        IconData headerIcon;
        switch (parent.name) {
          case 'Chi tiêu - sinh hoạt':
          case 'Living Expenses':
            headerColor = const Color(0xFFF97316); // Orange
            headerIcon = Icons.home_rounded;
            break;
          case 'Chi phí phát sinh':
          case 'Occasional Expenses':
            headerColor = const Color(0xFFEAB308); // Yellow
            headerIcon = Icons.lightbulb_rounded;
            break;
          case 'Chi phí cố định':
          case 'Fixed Expenses':
            headerColor = const Color(0xFF3B82F6); // Blue
            headerIcon = Icons.receipt_long_rounded;
            break;
          case 'Đầu tư - tiết kiệm':
          case 'Investment & Savings':
            headerColor = const Color(0xFF10B981); // Green
            headerIcon = Icons.trending_up_rounded;
            break;
          default:
            headerColor = colors.primary;
            headerIcon = Icons.category_rounded;
        }

        return Container(
          decoration: BoxDecoration(
            color: colors.authCardBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header of group
              Container(
                decoration: BoxDecoration(
                  color: headerColor.withOpacity(0.08),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: headerColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(headerIcon, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        parent.name,
                        style: TextStyle(
                          color: headerColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Children Grid
              if (children.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Không có danh mục con.',
                      style: TextStyle(color: colors.textSecondary, fontSize: 13),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildCategoryGrid(children, allCategories),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryGrid(List<CategoryDto> children, List<CategoryDto> allCategories) {
    // Sort children by sortOrder
    children.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) {
        final category = children[index];
        final iconData = CategoryUIConstants.getIconData(category.icon);
        final color = CategoryUIConstants.getColorFromHex(category.color);
        final colors = context.colors;

        return GestureDetector(
          onTap: () => _showCategoryOptions(context, category, allCategories),
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
                  category.name,
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
