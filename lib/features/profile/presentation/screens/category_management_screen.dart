import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/profile/data/models/category_dto.dart';
import 'package:expense_management/features/profile/presentation/providers/category_provider.dart';

import '../widgets/category_management/category_management_shimmer.dart';
import '../widgets/category_management/category_management_tab_switcher.dart';
import '../widgets/category_management/category_management_new_category_card.dart';
import '../widgets/category_management/category_management_grid.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.invalidate(categoriesNotifierProvider);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          CategoryManagementTabSwitcher(
            activeTabIndex: _activeTabIndex,
            tabController: _tabController,
            onTabChanged: (index) {
              setState(() {
                _activeTabIndex = index;
              });
            },
          ),
          Expanded(
            child: _buildBody(colors, categoriesAsync),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AppColorsExtension colors, AsyncValue<List<CategoryDto>> categoriesAsync) {
    final allCategories = categoriesAsync.value;
    if (allCategories != null) {
      return _buildCategoryList(colors, allCategories);
    }

    if (categoriesAsync.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Lỗi tải danh mục từ Server',
              style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(categoriesAsync.error.toString(), style: TextStyle(color: colors.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(categoriesNotifierProvider.notifier).refreshCategories(),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return const CategoryManagementShimmer();
  }

  Widget _buildCategoryList(AppColorsExtension colors, List<CategoryDto> allCategories) {
    final type = _activeTabIndex == 0 ? 'expense' : 'income';
    final parents = allCategories
        .where((c) => c.type == type && c.parentId == null)
        .toList();

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
          CategoryManagementNewCategoryCard(
            type: type,
            parentCategories: parents,
            customCount: customCount,
          ),
          const SizedBox(height: 16),
          if (type == 'income')
            _buildIncomeView(parents, allCategories)
          else
            _buildExpenseView(parents, allCategories),
        ],
      ),
    );
  }

  Widget _buildIncomeView(List<CategoryDto> parents, List<CategoryDto> allCategories) {
    final colors = context.colors;
    if (parents.isEmpty) return const SizedBox();

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
      child: CategoryManagementGrid(
        children: children,
        allCategories: allCategories,
      ),
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

    final sortedParents = List<CategoryDto>.from(parents)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedParents.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final parent = sortedParents[index];
        final children = parent.children ?? [];

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
                        parent.name.tr(ref),
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
                  child: CategoryManagementGrid(
                    children: children,
                    allCategories: allCategories,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
