import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/transaction/domain/entities/transaction_entity.dart';
import 'package:expense_management/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:expense_management/features/profile/category_provider.dart';
import 'package:expense_management/features/profile/data/models/category_dto.dart';
import 'package:expense_management/features/profile/presentation/widgets/category_ui_constants.dart';
import 'package:expense_management/features/transaction/presentation/screens/sub_category_selection_screen.dart';

class TransactionDetailScreen extends ConsumerStatefulWidget {
  final TransactionEntity transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  ConsumerState<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends ConsumerState<TransactionDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  
  bool _isLoadingDetail = true;
  bool _isActionLoading = false;
  TransactionEntity? _liveTransaction;
  
  CategoryDto? _selectedCategory; 
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.transaction.title);
    _notesController = TextEditingController(text: widget.transaction.notes ?? '');
    _liveTransaction = widget.transaction;

    _initDefaultCategory();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetchFreshTransaction();
    });
  }

  void _initDefaultCategory() {
    final categories = ref.read(categoriesNotifierProvider).asData?.value ?? [];
    for (var parent in categories) {
      if (parent.id == widget.transaction.categoryId) {
        _selectedCategory = parent;
        break;
      }
      if (parent.children != null) {
        final sub = parent.children!.where((c) => c.id == widget.transaction.categoryId).firstOrNull;
        if (sub != null) {
          _selectedCategory = sub;
          break;
        }
      }
    }
  }

  Future<void> _fetchFreshTransaction() async {
    try {
      final freshTx = await ref
          .read(transactionListProvider.notifier)
          .getTransactionById(widget.transaction.id);
      if (mounted) {
        setState(() {
          _liveTransaction = freshTx;
          _titleController.text = freshTx.title;
          _notesController.text = freshTx.notes ?? '';
          _isLoadingDetail = false;
        });
        _initDefaultCategory();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingDetail = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // ── Chỉnh sửa: Hạ thấp chiều cao xuống 0.6 và bổ sung hiển thị Icon cha ──
  void _showCategorySelection() {
    final categories = ref.read(categoriesNotifierProvider).asData?.value ?? [];
    final filteredCategories = categories.where((c) => c.type == _liveTransaction?.type).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        // Hạ tỷ lệ chiều cao từ 0.75 xuống thành 0.60 giúp giao diện gọn và thấp xuống
        height: MediaQuery.of(context).size.height * 0.60,
        decoration: BoxDecoration(
          color: context.colors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 38,
              height: 4.5,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            
            // Phần Header tiêu đề bọc Icon danh mục cha hiện tại bên cạnh chữ giống Add Screen
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_selectedCategory != null) ...[
                    Icon(
                      CategoryUIConstants.getIconData(_selectedCategory!.icon),
                      color: CategoryUIConstants.getColorFromHex(_selectedCategory!.color),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Text(
                    'Chọn danh mục',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 0.5),
            
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 18,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.88,
                ),
                itemCount: filteredCategories.length,
                itemBuilder: (context,index) {
                  // Giữ nguyên logic map IconData và Color từ dữ liệu động hệ thống
                  final cat = filteredCategories[index];
                  final iconData = CategoryUIConstants.getIconData(cat.icon);
                  final color = CategoryUIConstants.getColorFromHex(cat.color);

                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.pop(this.context);
                      if (cat.children != null && cat.children!.isNotEmpty) {
                        Navigator.push(
                          this.context,
                          MaterialPageRoute(
                            builder: (ctx) => SubCategorySelectionScreen(
                              parentCategory: cat,
                              selectedSubCategory: _selectedCategory,
                            ),
                          ),
                        ).then((selectedSub) {
                          if (selectedSub != null && mounted) {
                            setState(() => _selectedCategory = selectedSub as CategoryDto);
                          }
                        });
                      } else {
                        setState(() => _selectedCategory = cat);
                      }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: color.withOpacity(0.12),
                          child: Icon(iconData, color: color, size: 24),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          cat.name,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUpdate() async {
    if (_titleController.text.trim().isEmpty) return;

    setState(() => _isActionLoading = true);
    try {
      MultipartFile? attachment;
      if (_selectedImage != null) {
        attachment = await MultipartFile.fromFile(_selectedImage!.path);
      }

      await ref.read(transactionListProvider.notifier).updateTransaction(
            transactionId: widget.transaction.id,
            title: _titleController.text.trim(),
            categoryId: _selectedCategory?.id,
            notes: _notesController.text.trim(),
            attachment: attachment,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật giao dịch thành công!')),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cập nhật thất bại: $e')));
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa giao dịch này không? Số dư ví sẽ được hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isActionLoading = true);
    try {
      await ref.read(transactionListProvider.notifier).deleteTransaction(widget.transaction.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa giao dịch thành công!')),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xóa thất bại: $e')));
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tx = _liveTransaction ?? widget.transaction;

    final currencySymbol = tx.currencyCode ?? 'đ';
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formattedAmount = tx.amount.toStringAsFixed(0).replaceAllMapped(reg, (Match m) => '${m[1]},');
    final sign = tx.type == 'income' ? '+' : (tx.type == 'expense' ? '-' : '');
    final amountColor = tx.type == 'income' ? colors.incomeGreen : (tx.type == 'expense' ? colors.expenseRed : colors.textSecondary);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: Text('Chi tiết giao dịch', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoadingDetail
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              Text(
                                '$sign$formattedAmount $currencySymbol',
                                style: TextStyle(color: amountColor, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(20)),
                                child: Text('Ví: ${tx.walletName ?? "Mặc định"}', style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        Text('Tiêu đề giao dịch', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _titleController,
                          style: TextStyle(color: colors.textPrimary, fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'Nhập tên hoặc tiêu đề...',
                            filled: true,
                            fillColor: colors.surface,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 18),

                        Text('Danh mục chi tiêu', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _showCategorySelection,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(14)),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: CategoryUIConstants.getColorFromHex(_selectedCategory?.color).withOpacity(0.15),
                                  child: Icon(CategoryUIConstants.getIconData(_selectedCategory?.icon), color: CategoryUIConstants.getColorFromHex(_selectedCategory?.color), size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _selectedCategory?.name ?? tx.categoryName ?? 'Chưa phân loại',
                                    style: TextStyle(color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios_rounded, color: colors.textSecondary.withOpacity(0.6), size: 16),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        Text('Ghi chú / Mô tả', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _notesController,
                          maxLines: 2,
                          style: TextStyle(color: colors.textPrimary, fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'Thêm chi tiết ghi chú...',
                            filled: true,
                            fillColor: colors.surface,
                            contentPadding: const EdgeInsets.all(16),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 18),

                        Text('Ảnh hóa đơn đính kèm', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: double.infinity,
                            height: 160,
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: colors.textSecondary.withOpacity(0.1)),
                            ),
                            child: _selectedImage != null
                                ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.file(_selectedImage!, fit: BoxFit.cover))
                                : (tx.attachmentUrls.isNotEmpty
                                    ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(tx.attachmentUrls.first, fit: BoxFit.cover))
                                    : Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add_a_photo_rounded, color: colors.textSecondary.withOpacity(0.5), size: 32),
                                            const SizedBox(height: 6),
                                            Text('Thay đổi hoặc thêm ảnh biên nhận', style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                                          ],
                                        ),
                                      )),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24, top: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: _isActionLoading ? null : _handleDelete,
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                            label: const Text('Xóa', style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.redAccent, width: 1.2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              backgroundColor: Colors.red.withOpacity(0.02),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      Expanded(
                        flex: 3,
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isActionLoading ? null : _handleUpdate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: _isActionLoading
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                : const Text('Lưu thay đổi', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}