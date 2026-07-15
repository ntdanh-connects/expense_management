import 'dart:io';
import 'dart:async';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:expense_management/core/utils/currency_utils.dart';

import 'package:expense_management/core/router/app_route.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/profile/presentation/providers/category_provider.dart';
import 'package:expense_management/features/profile/data/models/category_dto.dart';
import 'package:expense_management/features/profile/presentation/widgets/category_ui_constants.dart';

import 'package:expense_management/features/profile/presentation/providers/user_provider.dart';
import 'package:expense_management/features/transaction/domain/entities/transaction_params.dart';
import 'package:expense_management/features/transaction/presentation/screens/sub_category_selection_screen.dart';
import 'package:expense_management/features/wallet/domain/entities/wallet_entity.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_notifier.dart';
import 'package:expense_management/features/wallet/presentation/provider/qr_transfer_provider.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/language/app_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:expense_management/features/transaction/presentation/widgets/add_transaction/add_transaction_shimmer.dart';
import 'package:expense_management/features/transaction/presentation/widgets/add_transaction/transaction_amount_card.dart';
import 'package:expense_management/features/transaction/presentation/widgets/add_transaction/transaction_recipient_card.dart';
import 'package:expense_management/features/transaction/presentation/widgets/add_transaction/transaction_category_selector.dart';
import 'package:expense_management/features/transaction/presentation/widgets/add_transaction/transaction_date_wallet_row.dart';
import 'package:expense_management/features/transaction/presentation/widgets/add_transaction/transaction_attachment_section.dart';
import 'package:expense_management/features/transaction/presentation/widgets/add_transaction/transaction_wallet_picker_sheet.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? qrData;
  const AddTransactionScreen({super.key, this.qrData});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _titleController = TextEditingController();
  final _payeeController = TextEditingController();

  CategoryDto? _selectedParentCategory;
  CategoryDto? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  WalletEntity? _selectedWallet;
  File? _imageFile;
  bool _isLoading = false;

  bool _isClassifying = false;
  Timer? _classificationDebounce;

  String? _recipientWalletName;
  String? _toWalletId;
  String? _payeeUserId;
  String? _payeeId;
  bool _isLoadingRecipientWallet = false;

  late CurrencyTextInputFormatter _formatter;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onTextChanged);
    _notesController.addListener(_onTextChanged);
    _formatter = CurrencyTextInputFormatter.currency(
      locale: 'vi',
      decimalDigits: 0,
      symbol: 'đ',
    );
    try {
      final user = ref.read(currentUserProvider);
      final tzName = user?.timezone ?? 'Asia/Ho_Chi_Minh';
      final location = tz.getLocation(tzName);
      _selectedDate = tz.TZDateTime.now(location);
    } catch (_) {
      _selectedDate = DateTime.now();
    }

    if (widget.qrData != null) {
      final qr = widget.qrData!;
      if (qr['amount'] != null) {
        final double amt = double.tryParse(qr['amount'].toString()) ?? 0.0;
        if (amt > 0) {
          final cappedAmt = amt > 500000000.0 ? 500000000.0 : amt;
          _amountController.text = _formatter.formatDouble(cappedAmt);
        }
      }
      if (qr['description'] != null) {
        _notesController.text = qr['description'].toString();
      }
      if (qr['date'] != null && qr['date'] is DateTime) {
        _selectedDate = qr['date'] as DateTime;
      }
      final rawPayeeName = qr['payee_name']?.toString().trim() ?? '';
      final payeeName = (rawPayeeName.isEmpty || rawPayeeName.toUpperCase() == 'UNKNOWN RECIPIENT')
          ? ''
          : rawPayeeName;
      _payeeController.text = payeeName;
      if (qr['title'] != null) {
        _titleController.text = qr['title'].toString();
      } else if (payeeName.isNotEmpty) {
        _titleController.text = payeeName;
      } else if (qr['description'] != null) {
        _titleController.text = qr['description'].toString();
      }

      _recipientWalletName = qr['recipient_wallet_name']?.toString() ?? qr['wallet_name']?.toString() ?? qr['recipient_wallet']?.toString();
      _toWalletId = qr['to_wallet_id']?.toString();
      _payeeUserId = qr['payee_user_id']?.toString();
      _payeeId = qr['payee_id']?.toString();

      final isInternal = qr['type'] == 'internal' || qr['payee_type'] == 'internal';
      if (isInternal && (_recipientWalletName == null || _toWalletId == null)) {
        _isLoadingRecipientWallet = true;
        final identifier = qr['identifier'] ?? qr['account_number'] ?? '';
        if (identifier.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            try {
              final result = await ref.read(qrTransferProvider.notifier).decodeQrCode(identifier.toString());
              if (result != null && mounted) {
                setState(() {
                  _recipientWalletName = result['recipient_wallet_name']?.toString() ?? result['wallet_name']?.toString() ?? result['recipient_wallet']?.toString();
                  _toWalletId = result['to_wallet_id']?.toString();
                  _payeeUserId = result['payee_user_id']?.toString();
                  _payeeId = result['payee_id']?.toString();
                });
              }
            } catch (e) {
              // ignore
            } finally {
              if (mounted) {
                setState(() {
                  _isLoadingRecipientWallet = false;
                });
              }
            }
          });
        } else {
          _isLoadingRecipientWallet = false;
        }
      }
    }
  }

  String _getCurrencySymbol(String? currencyCode) {
    switch (currencyCode) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'VND':
      default:
        return 'đ';
    }
  }

  int _getDecimalDigits(String? currencyCode) {
    if (currencyCode == 'VND') return 0;
    return 2;
  }

  String _getLocale(String? currencyCode) {
    if (currencyCode == 'VND') return 'vi';
    if (currencyCode == 'USD') return 'en_US';
    if (currencyCode == 'EUR') return 'fr_FR';
    return 'en';
  }

  void _updateFormatter(String? currencyCode) {
    final symbol = _getCurrencySymbol(currencyCode);
    final decimals = _getDecimalDigits(currencyCode);
    final locale = _getLocale(currencyCode);
    final double currentAmount = _getAmount();
    
    _formatter = CurrencyTextInputFormatter.currency(
      locale: locale,
      decimalDigits: decimals,
      symbol: symbol,
    );
    
    final text = _amountController.text;
    if (text.isNotEmpty && currentAmount > 0) {
      _amountController.text = _formatter.formatDouble(currentAmount);
    }
  }

  void _onTextChanged() {
    _classificationDebounce?.cancel();
    _classificationDebounce = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        _autoClassifyCategory();
      }
    });
  }

  Future<void> _autoClassifyCategory() async {
    if (!mounted) return;
    final titleText = _titleController.text.trim();
    final notesText = _notesController.text.trim();

    if (titleText.isEmpty && notesText.isEmpty) return;

    var categories = ref.read(categoriesNotifierProvider).value ?? [];
    int retries = 0;
    while (categories.isEmpty && retries < 5) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      categories = ref.read(categoriesNotifierProvider).value ?? [];
      retries++;
    }

    if (categories.isEmpty) return;

    setState(() {
      _isClassifying = true;
    });

    try {
      final type = _isIncome ? 'income' : 'expense';
      final matchedId = await ref.read(categoryRepositoryProvider).classifyCategory(
        title: titleText.isNotEmpty ? titleText : null,
        notes: notesText.isNotEmpty ? notesText : null,
        type: type,
      );

      if (matchedId == null || !mounted) return;

      CategoryDto? matchedCat;
      CategoryDto? matchedParent;

      for (final parent in categories) {
        if (parent.id == matchedId) {
          matchedCat = null;
          matchedParent = parent;
          break;
        }
        final children = parent.children ?? [];
        for (final child in children) {
          if (child.id == matchedId) {
            matchedCat = child;
            matchedParent = parent;
            break;
          }
        }
        if (matchedParent != null) break;
      }

      if (matchedParent != null && mounted) {
        setState(() {
          _selectedParentCategory = matchedParent;
          _selectedCategory = matchedCat;
        });
      }
    } catch (e) {
      debugPrint('AI classification error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isClassifying = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _classificationDebounce?.cancel();
    _amountController.dispose();
    _notesController.dispose();
    _titleController.dispose();
    _payeeController.dispose();
    super.dispose();
  }

  bool get _isIncome => _selectedParentCategory?.type == 'income';

  bool get _showTitleField =>
      _selectedWallet == null || _selectedWallet!.type.toLowerCase() == 'cash';

  double _parseAmountFromString(String text, String? currencyCode) {
    if (text.isEmpty) return 0.0;
    try {
      final code = currencyCode ?? 'VND';
      if (code == 'VND') {
        final cleanString = text.replaceAll(RegExp(r'[^0-9]'), '');
        return double.tryParse(cleanString) ?? 0.0;
      } else {
        final clean = text.replaceAll(RegExp(r'[^0-9.,]'), '');
        if (clean.isEmpty) return 0.0;
        if (code == 'EUR') {
          final normalized = clean.replaceAll('.', '').replaceAll(',', '.');
          return double.tryParse(normalized) ?? 0.0;
        } else {
          final normalized = clean.replaceAll(',', '');
          return double.tryParse(normalized) ?? 0.0;
        }
      }
    } catch (_) {
      return 0.0;
    }
  }

  double _getAmount() {
    final text = _amountController.text;
    if (text.isEmpty) return 0.0;
    
    final formatterDouble = _formatter.getDouble();
    if (formatterDouble > 0) {
      return formatterDouble;
    }
    
    return _parseAmountFromString(text, _selectedWallet?.currencyCode);
  }

  String _formatDate(DateTime date) {
    final user = ref.read(currentUserProvider);
    final tzName = user?.timezone ?? 'Asia/Ho_Chi_Minh';
    try {
      final location = tz.getLocation(tzName);
      final userNow = tz.TZDateTime.now(location);
      final today = DateTime(userNow.year, userNow.month, userNow.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final checkDate = DateTime(date.year, date.month, date.day);

      if (checkDate == today) {
        return '${'today'.trRead(ref)}, ${DateFormat('dd/MM').format(date)}';
      } else if (checkDate == yesterday) {
        return '${'yesterday'.trRead(ref)}, ${DateFormat('dd/MM').format(date)}';
      } else {
        return DateFormat('dd/MM/yyyy').format(date);
      }
    } catch (_) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final checkDate = DateTime(date.year, date.month, date.day);

      if (checkDate == today) {
        return '${'today'.trRead(ref)}, ${DateFormat('dd/MM').format(date)}';
      } else if (checkDate == yesterday) {
        return '${'yesterday'.trRead(ref)}, ${DateFormat('dd/MM').format(date)}';
      } else {
        return DateFormat('dd/MM/yyyy').format(date);
      }
    }
  }

  void _selectDate(BuildContext context) {
    final colors = context.colors;
    showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: colors.primary,
              brightness: Theme.of(context).brightness,
            ),
          ),
          child: child!,
        );
      },
    ).then((date) {
      if (date != null) {
        setState(() {
          try {
            final user = ref.read(currentUserProvider);
            final tzName = user?.timezone ?? 'Asia/Ho_Chi_Minh';
            final location = tz.getLocation(tzName);
            _selectedDate = tz.TZDateTime(
              location,
              date.year,
              date.month,
              date.day,
              _selectedDate.hour,
              _selectedDate.minute,
              _selectedDate.second,
            );
          } catch (_) {
            _selectedDate = date;
          }
        });
      }
    });
  }

  void _showWalletSelector(BuildContext context, List<WalletEntity> wallets) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return TransactionWalletPickerSheet(
          wallets: wallets,
          selectedWallet: _selectedWallet,
          onSelected: (wallet) {
            setState(() {
              _selectedWallet = wallet;
              _updateFormatter(wallet.currencyCode);
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  void _pickImage(BuildContext context) {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'attach_receipt_title'.trRead(ref),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildUploadOption(
                    context,
                    icon: Icons.camera_alt_rounded,
                    label: 'take_photo'.trRead(ref),
                    onTap: () async {
                      Navigator.pop(context);
                      final file = await ImagePicker().pickImage(
                        source: ImageSource.camera,
                        maxWidth: 1024,
                        maxHeight: 1024,
                        imageQuality: 85,
                      );
                      if (file != null) {
                        setState(() {
                          _imageFile = File(file.path);
                        });
                      }
                    },
                  ),
                  _buildUploadOption(
                    context,
                    icon: Icons.photo_library_rounded,
                    label: 'choose_from_gallery'.trRead(ref),
                    onTap: () async {
                      Navigator.pop(context);
                      final file = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 1024,
                        maxHeight: 1024,
                        imageQuality: 85,
                      );
                      if (file != null) {
                        setState(() {
                          _imageFile = File(file.path);
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUploadOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: colors.primary, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _saveTransaction() async {
    if (_isLoading) return;

    final amount = _getAmount();

    if (amount < 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('please_enter_valid_amount'.trRead(ref)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Category selection is now optional (AI auto-classifies on backend if empty)

    if (_selectedWallet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('please_select_wallet'.trRead(ref)),
          backgroundColor: Colors.red,
        ),
      );
      final walletList = ref.read(walletNotifierProvider).value ?? [];
      if (walletList.isEmpty) {
        context.push(RoutePaths.addWallet);
      }
      return;
    }



    final payeeName = _payeeController.text.trim();
    if (_isIncome && _selectedWallet!.type.toLowerCase() != 'cash') {
      if (payeeName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thu nhập của ví ngân hàng/ví điện tử bắt buộc phải có thông tin người chuyển/thụ hưởng!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    String title = '';
    if (_selectedWallet!.type.toLowerCase() == 'cash') {
      title = _titleController.text.trim();
      if (title.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng nhập tiêu đề cho giao dịch ví tiền mặt!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final bool isTransfer = widget.qrData != null &&
        (widget.qrData!['type'] == 'internal' ||
         widget.qrData!['type'] == 'external' ||
         widget.qrData!['payee_type'] == 'internal' ||
         widget.qrData!['payee_type'] == 'external');

    // Nếu là giao dịch chuyển khoản
    if (isTransfer) {
      if (amount > _selectedWallet!.balance) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('insufficient_balance_error'.trRead(ref)),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final qr = widget.qrData!;
      final rawPayeeName = qr['payee_name']?.toString().trim() ?? '';
      final resolvedPayeeName = (rawPayeeName.isEmpty || rawPayeeName.toUpperCase() == 'UNKNOWN RECIPIENT')
          ? 'Không xác định'
          : rawPayeeName;
      final identifier = qr['identifier'] ?? qr['account_number'] ?? '';
      final bankName = qr['bank_name'] ?? '';

      setState(() {
        _isLoading = true;
      });
      try {
        if (mounted) {
          await context.push('/qr-transfer-result', extra: {
            'is_pending_execution': true,
            'from_wallet_id': _selectedWallet!.id,
            'payee_type': qr['type'] ?? qr['payee_type'] ?? 'internal',
            'amount': amount,
            'notes': _notesController.text.isNotEmpty ? _notesController.text : 'QR transfer',
            'payee_user_id': _payeeUserId ?? qr['payee_user_id'],
            'bank_code': qr['bank_code'],
            'account_number': qr['account_number'] ?? qr['identifier'],
            'payee_name': resolvedPayeeName,
            'sender_wallet': _selectedWallet!.name,
            'bank_name': bankName,
            'identifier': identifier,
            'type': qr['type'] ?? qr['payee_type'] ?? 'internal',
            'to_wallet_id': _toWalletId ?? qr['to_wallet_id'],
            'category_id': _selectedCategory?.id,
            'is_qr': qr['is_qr'] ?? true,
          });
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
      return;
    }

    // Xác định loại giao dịch cho backend (income hoặc expense)
    final backendType = _selectedParentCategory?.type ?? 'expense';

    final params = TransactionParams(
      walletId: _selectedWallet!.id,
      walletName: _selectedWallet!.name,
      categoryId: _selectedCategory?.id,
      categoryName: _selectedCategory?.name,
      type: backendType,
      amount: amount,
      title: title,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      transactionDate: _selectedDate.toUtc().toIso8601String(),
      currencyCode: _selectedWallet!.currencyCode,
      exchangeRate: 1.0,
      timezone: ref.read(currentUserProvider)?.timezone ?? 'Asia/Ho_Chi_Minh',
      attachmentPath: _imageFile?.path,
      payeeName: payeeName.isEmpty ? null : payeeName,
      payeeId: _payeeId,
      payeeAccountNumber: null,
      payeeBankName: null,
      sourceType: 'manual',
    );

    setState(() {
      _isLoading = true;
    });
    try {
      if (mounted) {
        await context.push(RoutePaths.transactionResult, extra: params);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final localeCode = ref.watch(localeProvider);

    final categoriesAsync = ref.watch(categoriesNotifierProvider);
    final walletsAsync = ref.watch(walletNotifierProvider);

    // Extract parent categories dynamically
    final allCats = categoriesAsync.value ?? [];
    final bool isTransfer = widget.qrData != null &&  (widget.qrData!['type'] == 'internal' || widget.qrData!['type'] == 'external' ||widget.qrData!['payee_type'] == 'internal' ||
     widget.qrData!['payee_type'] == 'external');
    final parentCategories = allCats.where((c) {
      if (c.parentId != null) return false;
      if (isTransfer && c.type == 'income') return false; // Loại bỏ Thu nhập khi quét QR
      return true;
    }).toList();
    parentCategories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    // Handle default parent selection on load
    if (_selectedParentCategory == null && parentCategories.isNotEmpty) {
      _selectedParentCategory = parentCategories.first;
    }

    // Extract subcategories of selected parent category
    final subCategoryList = _selectedParentCategory?.children ?? [];
    subCategoryList.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final quickSubcategories = subCategoryList.take(4).toList();
    if (_selectedCategory != null &&
        _selectedCategory!.parentId == _selectedParentCategory?.id &&
        !quickSubcategories.any((c) => c.id == _selectedCategory!.id)) {
      quickSubcategories.add(_selectedCategory!);
    }

    // Phân loại ví: Nhập tay -> Tiền mặt; QR -> Ngân hàng/Ví điện tử
    final rawWalletList = walletsAsync.value ?? [];
    final List<WalletEntity> walletList;
    
    if (isTransfer) {
      final isInternal = widget.qrData!['type'] == 'internal';
      walletList = rawWalletList.where((w) {
        if (w.type.toLowerCase() == 'cash') return false;
        if (!isInternal && w.currencyCode != 'VND') return false;
        return !w.isHidden;
      }).toList();
    } else {
      walletList = rawWalletList.where((w) {
        final type = w.type.toLowerCase();
        return type == 'cash' && w.currencyCode == 'VND' && !w.isHidden;
      }).toList();
    }

    if (_selectedWallet == null && walletList.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          if (isTransfer) {
            final prefilledWalletId = widget.qrData!['from_wallet_id'];
            WalletEntity? prefilledWallet;
            if (prefilledWalletId != null) {
              prefilledWallet = walletList.where((w) => w.id == prefilledWalletId).firstOrNull;
            }
            _selectedWallet = prefilledWallet ?? walletList.firstWhere(
              (w) => w.type.toLowerCase() == 'bank',
              orElse: () => walletList.first,
            );
          } else {
            _selectedWallet = walletList.first;
          }
          if (_selectedWallet != null) {
            _updateFormatter(_selectedWallet!.currencyCode);
          }
        });
      });
    }

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colors.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'add_transaction'.tr(ref),
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: categoriesAsync.when(
        loading: () => const AddTransactionShimmer(),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'sync_categories_error'.tr(ref),
                style: TextStyle(color: colors.textPrimary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref
                    .read(categoriesNotifierProvider.notifier)
                    .refreshCategories(),
                child: Text('try_again'.tr(ref)),
              ),
            ],
          ),
        ),
        data: (_) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 💳 1. Amount Display Card
                TransactionAmountCard(
                  amountController: _amountController,
                  formatter: _formatter,
                  currencyCode: _selectedWallet?.currencyCode,
                  isIncome: _isIncome,
                  localeCode: localeCode,
                ),
                const SizedBox(height: 24),

                if (isTransfer) ...[
                  Text(
                    'recipient_info'.tr(ref),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TransactionRecipientCard(
                    qrData: widget.qrData,
                    recipientWalletName: _recipientWalletName,
                    isLoadingRecipientWallet: _isLoadingRecipientWallet,
                  ),
                  const SizedBox(height: 24),
                ],

                // 📁 2 & 3. Category Sections
                TransactionCategorySelector(
                  parentCategories: parentCategories,
                  selectedParentCategory: _selectedParentCategory,
                  selectedCategory: _selectedCategory,
                  quickSubcategories: quickSubcategories,
                  isClassifying: _isClassifying,
                  onParentSelected: (parent) {
                    setState(() {
                      _selectedParentCategory = parent;
                      _selectedCategory = null;
                    });
                  },
                  onCategorySelected: (cat) {
                    setState(() {
                      _selectedCategory = cat;
                    });
                  },
                  onSeeAllPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SubCategorySelectionScreen(
                          parentCategory: _selectedParentCategory!,
                          selectedSubCategory: _selectedCategory,
                        ),
                      ),
                    );
                    if (result != null && result is CategoryDto) {
                      setState(() {
                        _selectedCategory = result;
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),

                // 📅 4. Date & Wallet Row
                TransactionDateWalletRow(
                  selectedDate: _selectedDate,
                  selectedWallet: _selectedWallet,
                  walletList: walletList,
                  onDateTap: () => _selectDate(context),
                  onWalletTap: () {
                    if (walletList.isEmpty) {
                      context.push(RoutePaths.addWallet);
                    } else {
                      _showWalletSelector(context, walletList);
                    }
                  },
                  formatDate: _formatDate,
                ),


                // 📝 5. Optional Title Input
                if (_showTitleField) ...[
                  Text(
                    'transaction_title'.tr(ref),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.authCardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colors.textSecondary.withOpacity(0.06),
                      ),
                    ),
                    child: TextField(
                      controller: _titleController,
                      style: TextStyle(color: colors.textPrimary),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: _selectedCategory != null
                            ? 'transaction_title_default_hint'
                                  .tr(ref)
                                  .replaceAll('{name}', _selectedCategory!.name.tr(ref))
                            : 'transaction_title_hint'.tr(ref),
                        hintStyle: TextStyle(
                          color: colors.textSecondary.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                if (_isIncome) ...[
                  Text(
                    'Người gửi / Người thụ hưởng',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.authCardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colors.textSecondary.withOpacity(0.06),
                      ),
                    ),
                    child: TextField(
                      controller: _payeeController,
                      style: TextStyle(color: colors.textPrimary),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Nhập tên người gửi...',
                        hintStyle: TextStyle(
                          color: colors.textSecondary.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // 📝 6. Notes field
                Text(
                  'notes'.tr(ref),
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colors.authCardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colors.textSecondary.withOpacity(0.06),
                    ),
                  ),
                  child: TextField(
                    controller: _notesController,
                    maxLines: 3,
                    style: TextStyle(color: colors.textPrimary),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'notes_hint'.tr(ref),
                      hintStyle: TextStyle(
                        color: colors.textSecondary.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 📷 7. Attachments
                TransactionAttachmentSection(
                  imageFile: _imageFile,
                  isLoading: _isLoading,
                  onPickImage: () => _pickImage(context),
                  onRemoveImage: () {
                    setState(() {
                      _imageFile = null;
                    });
                  },
                  onOcrResult: (result) {
                    setState(() {
                      if (result['amount'] != null) {
                        _amountController.text =
                            _formatter.formatDouble(result['amount'] as double);
                      }
                      if (result['payee_name'] != null &&
                          result['payee_name'].toString().isNotEmpty) {
                        final payeeStr = result['payee_name'].toString();
                        _payeeController.text = payeeStr;
                        _titleController.text = payeeStr;
                      }
                      if (result['description'] != null &&
                          result['description'].toString().isNotEmpty) {
                        final descStr = result['description'].toString();
                        _notesController.text = descStr;
                        if (_titleController.text.isEmpty) {
                          _titleController.text = descStr;
                        }
                      }
                      if (result['date'] != null && result['date'] is DateTime) {
                        _selectedDate = result['date'] as DateTime;
                      }
                    });
                  },
                ),
                const SizedBox(height: 36),

                // 💾 8. Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveTransaction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981), // Emerald green
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.save_rounded,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'save_transaction'.tr(ref),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}



