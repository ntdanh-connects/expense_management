import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:image_picker/image_picker.dart';
import 'package:timezone/timezone.dart' as tz;
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
  ConsumerState<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState
    extends ConsumerState<TransactionDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;

  bool _isLoadingDetail = true;
  bool _isActionLoading = false;
  TransactionEntity? _liveTransaction;

  CategoryDto? _selectedCategory;
  final List<File> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.transaction.title);
    _notesController = TextEditingController(
      text: widget.transaction.notes ?? '',
    );
    _liveTransaction = widget.transaction;

    _initDefaultCategory();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetchFreshTransaction();
    });
  }

  void _initDefaultCategory() {
    final categories = ref.read(categoriesNotifierProvider).value ?? [];
    for (var parent in categories) {
      if (parent.id == widget.transaction.categoryId) {
        _selectedCategory = parent;
        break;
      }
      if (parent.children != null) {
        final sub = parent.children!
            .where((c) => c.id == widget.transaction.categoryId)
            .firstOrNull;
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
      if (mounted) {
        setState(() => _isLoadingDetail = false);
        String errorMsg = e.toString();
        if (e is DioException) {
          final responseData = e.response?.data;
          if (responseData != null && responseData['message'] != null) {
            errorMsg = responseData['message'];
          }
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMsg)));
        context.pop();
      }
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
    final pickedFiles = await picker.pickMultiImage(
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(pickedFiles.map((x) => File(x.path)));
      });
    }
  }

  String _formatDateTime(DateTime date, String? timezoneName) {
    final tzName = timezoneName ?? 'UTC';

    try {
      final location = tz.getLocation(tzName);

      // Chỉ lấy offset của timezone
      final now = tz.TZDateTime.now(location);
      final offset = now.timeZoneOffset;

      final sign = offset.isNegative ? '-' : '+';
      final hours = offset.inHours.abs().toString().padLeft(2, '0');
      final minutes =
          (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');

      // Giữ nguyên giờ từ backend
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      final second = date.second.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year;

      return '$hour:$minute:$second '
          '$day/$month/$year '
          '(UTC$sign$hours:$minutes)';
    } catch (_) {
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      final second = date.second.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year;

      return '$hour:$minute:$second '
          '$day/$month/$year '
          '(UTC+00:00)';
    }
  }

  // ── Chỉnh sửa: Hạ thấp chiều cao xuống 0.6 và bổ sung hiển thị Icon cha ──
  void _showCategorySelection() {
    final categories = ref.read(categoriesNotifierProvider).value ?? [];
    final filteredCategories = categories
        .where((c) => c.type == _liveTransaction?.type)
        .toList();

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
                      CategoryUIConstants.getIconData(
                        _selectedCategory!.icon,
                        categoryName: _selectedCategory!.name,
                      ),
                      color: CategoryUIConstants.getColorFromHex(
                        _selectedCategory!.color,
                        categoryName: _selectedCategory!.name,
                      ),
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    'select_category'.tr(ref),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
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
                itemBuilder: (context, index) {
                  // Giữ nguyên logic map IconData và Color từ dữ liệu động hệ thống
                  final cat = filteredCategories[index];
                  final iconData = CategoryUIConstants.getIconData(
                    cat.icon,
                    categoryName: cat.name,
                  );
                  final color = CategoryUIConstants.getColorFromHex(
                    cat.color,
                    categoryName: cat.name,
                  );

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
                            setState(
                              () => _selectedCategory =
                                  selectedSub as CategoryDto,
                            );
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
                          cat.name.tr(ref),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
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
      final List<MultipartFile> attachments = [];
      for (final image in _selectedImages) {
        attachments.add(await MultipartFile.fromFile(image.path));
      }

      await ref
          .read(transactionListProvider.notifier)
          .updateTransaction(
            transactionId: widget.transaction.id,
            title: _titleController.text.trim(),
            categoryId: _selectedCategory?.id,
            notes: _notesController.text.trim(),
            attachments: attachments,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('update_transaction_success'.trRead(ref))),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'update_transaction_failed'
                  .trRead(ref)
                  .replaceAll('{error}', e.toString()),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('confirm_delete'.trRead(ref)),
        content: Text('delete_transaction_confirm_msg'.trRead(ref)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.trRead(ref)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('delete'.trRead(ref)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isActionLoading = true);
    try {
      await ref
          .read(transactionListProvider.notifier)
          .deleteTransaction(widget.transaction.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('delete_transaction_success'.trRead(ref))),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'delete_transaction_failed'
                  .trRead(ref)
                  .replaceAll('{error}', e.toString()),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tx = _liveTransaction ?? widget.transaction;
    final isTransfer = tx.sourceType == 'transfer';

    final currencySymbol = tx.currencyCode ?? 'đ';
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formattedAmount = tx.amount
        .toStringAsFixed(0)
        .replaceAllMapped(reg, (Match m) => '${m[1]},');
    final sign = tx.type == 'income' ? '+' : (tx.type == 'expense' ? '-' : '');
    final amountColor = tx.type == 'income'
        ? colors.incomeGreen
        : (tx.type == 'expense' ? colors.expenseRed : colors.textSecondary);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: Text(
          'transaction_details'.tr(ref),
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: colors.textPrimary,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoadingDetail
          ? const TransactionDetailShimmer()
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
                                style: TextStyle(
                                  color: amountColor,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.surface,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'wallet_with_name'
                                      .tr(ref)
                                      .replaceAll(
                                        '{name}',
                                        tx.walletName ??
                                            'default_label'.tr(ref),
                                      ),
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        Text(
                          'transaction_title_label'.tr(ref),
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _titleController,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            hintText: 'enter_title_hint'.tr(ref),
                            filled: true,
                            fillColor: colors.surface,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        Text(
                          'spending_category'.tr(ref),
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: isTransfer ? null : _showCategorySelection,
                          child: Opacity(
                            opacity: isTransfer ? 0.6 : 1.0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: colors.surface,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor:
                                        CategoryUIConstants.getColorFromHex(
                                          _selectedCategory?.color,
                                          categoryName: _selectedCategory?.name,
                                        ).withOpacity(0.15),
                                    child: Icon(
                                      CategoryUIConstants.getIconData(
                                        _selectedCategory?.icon,
                                        categoryName: _selectedCategory?.name,
                                      ),
                                      color:
                                          CategoryUIConstants.getColorFromHex(
                                            _selectedCategory?.color,
                                            categoryName:
                                                _selectedCategory?.name,
                                          ),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      (_selectedCategory?.name ??
                                                  tx.categoryName)
                                              ?.tr(ref) ??
                                          'uncategorized'.tr(ref),
                                      style: TextStyle(
                                        color: colors.textPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (!isTransfer)
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: colors.textSecondary.withOpacity(
                                        0.6,
                                      ),
                                      size: 16,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        Text(
                          'transaction_date_time'.tr(ref),
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                color: colors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _formatDateTime(
                                    tx.transactionDate,
                                    tx.timezone,
                                  ),
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        Text(
                          'notes_description'.tr(ref),
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _notesController,
                          maxLines: 2,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            hintText: 'add_notes_hint'.tr(ref),
                            filled: true,
                            fillColor: colors.surface,
                            contentPadding: const EdgeInsets.all(16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        Text(
                          'attached_receipt_image'.tr(ref),
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 120,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            children: [
                              GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: colors.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: colors.textSecondary.withOpacity(
                                        0.1,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_a_photo_rounded,
                                        color: colors.textSecondary.withOpacity(
                                          0.5,
                                        ),
                                        size: 28,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'add_photo'.tr(ref),
                                        style: TextStyle(
                                          color: colors.textSecondary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ...tx.attachmentUrls.map(
                                (url) => Container(
                                  width: 120,
                                  height: 120,
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: colors.textSecondary.withOpacity(
                                        0.1,
                                      ),
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.network(
                                      url,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              color: colors.surface,
                                              child: Icon(
                                                Icons.broken_image_rounded,
                                                color: colors.textSecondary
                                                    .withOpacity(0.5),
                                                size: 32,
                                              ),
                                            );
                                          },
                                    ),
                                  ),
                                ),
                              ),
                              ..._selectedImages.map(
                                (file) => Stack(
                                  children: [
                                    Container(
                                      width: 120,
                                      height: 120,
                                      margin: const EdgeInsets.only(right: 10),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: colors.textSecondary
                                              .withOpacity(0.1),
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: Image.file(
                                          file,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 14,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedImages.remove(file);
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 14,
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
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 24,
                    top: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: _isActionLoading ? null : _handleDelete,
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.redAccent,
                            ),
                            label: Text(
                              'delete'.tr(ref),
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Colors.redAccent,
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: _isActionLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    'save_changes'.tr(ref),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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

class TransactionDetailShimmer extends StatelessWidget {
  const TransactionDetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[900]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 180,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: 100,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: 120,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: 120,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: 120,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: 120,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 24,
              top: 8,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
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
