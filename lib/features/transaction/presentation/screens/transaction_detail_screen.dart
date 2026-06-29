import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/shared/widgets/image_overlay_viewer.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/language/app_provider.dart';
import 'package:expense_management/features/transaction/domain/entities/transaction_entity.dart';
import 'package:expense_management/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:expense_management/features/profile/presentation/providers/category_provider.dart';
import 'package:expense_management/features/profile/data/models/category_dto.dart';
import 'package:expense_management/features/profile/presentation/widgets/category_ui_constants.dart';
import 'package:expense_management/features/transaction/presentation/widgets/category_picker_bottom_sheet.dart';
import 'package:expense_management/core/constants/app_constant.dart';
import 'package:expense_management/core/utils/currency_utils.dart';
import 'package:expense_management/features/transaction/presentation/widgets/transaction_detail/transaction_detail_shimmer.dart';
import 'package:expense_management/features/transaction/presentation/widgets/transaction_detail/transaction_detail_header.dart';
import 'package:expense_management/features/transaction/presentation/widgets/transaction_detail/transaction_detail_fields.dart';
import 'package:expense_management/features/transaction/presentation/widgets/transaction_detail/transaction_detail_actions.dart';

class TransactionDetailScreen extends ConsumerStatefulWidget {
  final TransactionEntity? transaction;
  final String? transactionId;

  const TransactionDetailScreen({
    super.key,
    this.transaction,
    this.transactionId,
  });

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

  String get _transactionId =>
      widget.transaction?.id ?? widget.transactionId ?? _liveTransaction?.id ?? '';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.transaction?.title ?? '');
    _notesController = TextEditingController(
      text: widget.transaction?.notes ?? '',
    );
    _liveTransaction = widget.transaction;

    _initDefaultCategory();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetchFreshTransaction();
    });
  }

  void _initDefaultCategory() {
    final tx = _liveTransaction ?? widget.transaction;
    if (tx == null) return;
    final categories = ref.read(categoriesNotifierProvider).value ?? [];
    for (var parent in categories) {
      if (parent.id == tx.categoryId) {
        _selectedCategory = parent;
        break;
      }
      if (parent.children != null) {
        final sub = parent.children!
            .where((c) => c.id == tx.categoryId)
            .firstOrNull;
        if (sub != null) {
          _selectedCategory = sub;
          break;
        }
      }
    }
  }

  Future<void> _fetchFreshTransaction() async {
    final txId = _transactionId;
    if (txId.isEmpty) return;
    try {
      final freshTx = await ref
          .read(transactionListProvider.notifier)
          .getTransactionById(txId);
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
      final tzDateTime = tz.TZDateTime.from(date.toUtc(), location);
      final offset = tzDateTime.timeZoneOffset;

      final sign = offset.isNegative ? '-' : '+';
      final hours = offset.inHours.abs().toString().padLeft(2, '0');
      final minutes =
          (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');

      final hour = tzDateTime.hour.toString().padLeft(2, '0');
      final minute = tzDateTime.minute.toString().padLeft(2, '0');
      final second = tzDateTime.second.toString().padLeft(2, '0');
      final day = tzDateTime.day.toString().padLeft(2, '0');
      final month = tzDateTime.month.toString().padLeft(2, '0');
      final year = tzDateTime.year;

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

  Future<void> _updateCategoryImmediately(CategoryDto newCategory) async {
    setState(() {
      _selectedCategory = newCategory;
      if (_liveTransaction != null) {
        _liveTransaction = _liveTransaction!.copyWith(
          categoryId: newCategory.id,
          categoryName: newCategory.name,
          categoryIcon: newCategory.icon,
          categoryColor: newCategory.color,
        );
      }
    });

    try {
      await ref
          .read(transactionListProvider.notifier)
          .updateTransactionCategoryOptimistic(
            transactionId: _transactionId,
            categoryId: newCategory.id,
          );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('update_transaction_success'.trRead(ref))),
        );
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
    }
  }

  void _showCategorySelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategoryPickerBottomSheet(
        transactionType: _liveTransaction?.type ?? 'expense',
        selectedCategory: _selectedCategory,
        onCategorySelected: (newCat) {
          _updateCategoryImmediately(newCat);
        },
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
            transactionId: _transactionId,
            title: _titleController.text.trim(),
            categoryId: _selectedCategory?.id,
            notes: _notesController.text.trim(),
            attachments: attachments,
            payeeId: _liveTransaction?.payeeId ?? widget.transaction?.payeeId,
            sourceType: _liveTransaction?.sourceType ?? widget.transaction?.sourceType,
            type: _liveTransaction?.type ?? widget.transaction?.type ?? 'expense',
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
          .deleteTransaction(_transactionId);
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
    final localeCode = ref.watch(localeProvider);
    final tx = _liveTransaction ?? widget.transaction;

    if (tx == null) {
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
        body: const TransactionDetailShimmer(),
      );
    }

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
                        TransactionDetailHeader(
                          transaction: tx,
                          localeCode: localeCode,
                        ),
                        const SizedBox(height: 28),
                        TransactionDetailFields(
                          transaction: tx,
                          titleController: _titleController,
                          notesController: _notesController,
                          selectedCategory: _selectedCategory,
                          selectedImages: _selectedImages,
                          onCategoryTap: _showCategorySelection,
                          formattedDateTime: _formatDateTime(
                            tx.transactionDate,
                            tx.timezone,
                          ),
                          onPickImage: _pickImage,
                          onRemoveLocalImage: (file) {
                            setState(() {
                              _selectedImages.remove(file);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                TransactionDetailActions(
                  isActionLoading: _isActionLoading,
                  onDelete: _handleDelete,
                  onUpdate: _handleUpdate,
                ),
              ],
            ),
    );
  }
}


