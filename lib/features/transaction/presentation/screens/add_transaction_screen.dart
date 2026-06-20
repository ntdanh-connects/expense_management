import 'dart:io';
import 'dart:async';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:expense_management/core/router/app_route.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/profile/category_provider.dart';
import 'package:expense_management/features/profile/data/models/category_dto.dart';
import 'package:expense_management/features/profile/presentation/widgets/category_ui_constants.dart';

import 'package:expense_management/features/profile/user_provider.dart';
import 'package:expense_management/features/transaction/domain/entities/transaction_params.dart';
import 'package:expense_management/features/transaction/presentation/screens/sub_category_selection_screen.dart';
import 'package:expense_management/features/wallet/domain/entities/wallet_entity.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_notifier.dart';
import 'package:expense_management/features/wallet/presentation/provider/qr_transfer_provider.dart';
import 'package:expense_management/core/language/app_language.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timezone/timezone.dart' as tz;

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
  final bool _isLoading = false;

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
          _amountController.text = _formatter.formatDouble(amt);
        }
      }
      if (qr['description'] != null) {
        _notesController.text = qr['description'].toString();
      }
      final rawPayeeName = qr['payee_name']?.toString().trim() ?? '';
      final payeeName = (rawPayeeName.isEmpty || rawPayeeName.toUpperCase() == 'UNKNOWN RECIPIENT')
          ? ''
          : rawPayeeName;
      _payeeController.text = payeeName;

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
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'select_transaction_wallet'.trRead(ref),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (wallets.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'manual_transaction_wallet_warning'.trRead(ref),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: wallets.length,
                    itemBuilder: (context, idx) {
                      final wallet = wallets[idx];
                      final hexColor = wallet.color.replaceAll('#', '');
                      Color itemColor;
                      try {
                        itemColor = hexColor.length == 6
                            ? Color(int.parse('FF$hexColor', radix: 16))
                            : colors.primary;
                      } catch (_) {
                        itemColor = colors.primary;
                      }

                      final isSelected = _selectedWallet?.id == wallet.id;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: itemColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            wallet.type.toLowerCase() == 'cash'
                                ? Icons.payments_rounded
                                : wallet.type.toLowerCase() == 'bank'
                                ? Icons.account_balance_rounded
                                : Icons.credit_card_rounded,
                            color: itemColor,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          wallet.name,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          '${'balance_prefix'.trRead(ref)}${NumberFormat(wallet.currencyCode == 'VND' ? '#,###' : '#,##0.00').format(wallet.balance)} ${_getCurrencySymbol(wallet.currencyCode)}',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle_rounded,
                                color: colors.primary,
                              )
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedWallet = wallet;
                            _updateFormatter(wallet.currencyCode);
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push(RoutePaths.addWallet);
                  },
                  icon: const Icon(Icons.add_card_rounded, color: Colors.white),
                  label: Text(
                    'create_new_wallet'.trRead(ref),
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
    final amount = _getAmount();

    if (amount <= 0) {
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

    // Nếu là giao dịch chuyển khoản từ QR Code
    if (widget.qrData != null) {
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

      context.push('/qr-transfer-result', extra: {
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

    context.push(RoutePaths.transactionResult, extra: params).then((_) {
      if (mounted) {
        // Có thể dọn dẹp hoặc reset UI sau khi quay lại chỉnh sửa
      }
    });
  }


  Widget _buildQrRecipientCard(AppColorsExtension colors) {
    if (widget.qrData == null) return const SizedBox.shrink();
    
    final qr = widget.qrData!;
    final isInternal = qr['type'] == 'internal' || qr['payee_type'] == 'internal';
    final recipientWalletName = _recipientWalletName ?? qr['recipient_wallet_name'] ?? qr['wallet_name'] ?? qr['recipient_wallet'];
    final rawPayeeName = qr['payee_name']?.toString().trim() ?? '';
    final payeeName = (rawPayeeName.isEmpty || rawPayeeName.toUpperCase() == 'UNKNOWN RECIPIENT')
        ? 'Không xác định'
        : rawPayeeName;
    final identifier = qr['identifier'] ?? qr['account_number'] ?? '';
    final bankName = qr['bank_name'] ?? '';
    final bankLogo = qr['bank_logo'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.authCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.textSecondary.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          if (isInternal)
            CircleAvatar(
              radius: 24,
              backgroundImage: qr['avatar_url'] != null ? NetworkImage(qr['avatar_url']) : null,
              child: qr['avatar_url'] == null ? const Icon(Icons.person) : null,
            )
          else
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: bankLogo != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: CachedNetworkImage(
                        imageUrl: bankLogo,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.account_balance_rounded,
                          color: Colors.blue,
                        ),
                      ),
                    )
                  : const Icon(Icons.account_balance_rounded, color: Colors.blue),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payeeName,
                  style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  isInternal ? "ID: $identifier" : "$bankName - $identifier",
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                ),
                if (isInternal) ...[
                  const SizedBox(height: 6),
                  if (_isLoadingRecipientWallet)
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 14,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 6),
                        Shimmer.fromColors(
                          baseColor: colors.textSecondary.withOpacity(0.1),
                          highlightColor: colors.textSecondary.withOpacity(0.05),
                          child: Container(
                            width: 120,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    )
                  else if (recipientWalletName != null)
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 14,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Ví nhận: $recipientWalletName",
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to resolve dynamic parent icons & colors
  Map<String, dynamic> _getParentStyle(
    String parentName,
    AppColorsExtension colors,
  ) {
    switch (parentName) {
      case 'Chi tiêu - sinh hoạt':
      case 'Living Expenses':
        return {
          'icon': Icons.restaurant_rounded,
          'color': const Color(0xFFF97316), // Orange
        };
      case 'Chi phí phát sinh':
      case 'Occasional Expenses':
        return {
          'icon': Icons.shopping_bag_rounded,
          'color': const Color(0xFFEAB308), // Yellow
        };
      case 'Chi phí cố định':
      case 'Fixed Expenses':
        return {
          'icon': Icons.receipt_long_rounded,
          'color': const Color(0xFF3B82F6), // Blue
        };
      case 'Đầu tư - tiết kiệm':
      case 'Investment & Savings':
        return {
          'icon': Icons.savings_rounded,
          'color': const Color(0xFF10B981), // Green
        };
      case 'Thu nhập':
      case 'Income':
        return {
          'icon': Icons.account_balance_rounded,
          'color': const Color(0xFF8B5CF6), // Purple
        };
      default:
        return {'icon': Icons.category_rounded, 'color': colors.primary};
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final categoriesAsync = ref.watch(categoriesNotifierProvider);
    final walletsAsync = ref.watch(walletNotifierProvider);

    // Extract parent categories dynamically
    final allCats = categoriesAsync.value ?? [];
    final bool isQr = widget.qrData != null;
    final parentCategories = allCats.where((c) {
      if (c.parentId != null) return false;
      if (isQr && c.type == 'income') return false; // Loại bỏ Thu nhập khi quét QR
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
    
    if (isQr) {
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
          if (isQr) {
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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: colors.authCardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: colors.textSecondary.withOpacity(0.06),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'transaction_amount'.tr(ref),
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          color: _isIncome
                              ? colors.incomeGreen
                              : colors.expenseRed,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: _selectedWallet != null
                              ? '0 ${_getCurrencySymbol(_selectedWallet!.currencyCode)}'
                              : '0 đ',
                          hintStyle: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            color:
                                (_isIncome
                                        ? colors.incomeGreen
                                        : colors.expenseRed)
                                    .withOpacity(0.4),
                          ),
                        ),
                        inputFormatters: [_formatter],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (widget.qrData != null) ...[
                  Text(
                    'recipient_info'.tr(ref),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildQrRecipientCard(colors),
                  const SizedBox(height: 24),
                ],

                // 📁 2. Parent Category Section
                Text(
                  'parent_category'.tr(ref),
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Horizontal scrolling parents list
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: parentCategories.length,
                    itemBuilder: (context, index) {
                      final parent = parentCategories[index];
                      final style = _getParentStyle(parent.name, colors);
                      final IconData parentIcon = style['icon'];
                      final Color parentColor = style['color'];
                      final isSelected =
                          _selectedParentCategory?.id == parent.id;

                      // Display translations / clean parent name
                      String displayName = parent.name.tr(ref);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedParentCategory = parent;
                            _selectedCategory =
                                null; // Reset subcategory when parent changes
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 90,
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? parentColor.withOpacity(0.12)
                                : colors.authCardBg,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected
                                  ? parentColor
                                  : colors.textSecondary.withOpacity(0.06),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                parentIcon,
                                color: isSelected
                                    ? parentColor
                                    : colors.textSecondary,
                                size: 22,
                              ),
                              const SizedBox(height: 6),
                              FittedBox(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4.0,
                                  ),
                                  child: Text(
                                    displayName,
                                    style: TextStyle(
                                      color: isSelected
                                          ? parentColor
                                          : colors.textPrimary,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // 📂 3. Subcategory Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'subcategory'.tr(ref),
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_isClassifying) ...[
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (_selectedParentCategory != null)
                      TextButton(
                        onPressed: () async {
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
                        child: Text(
                          'see_all'.tr(ref),
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                if (quickSubcategories.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    alignment: Alignment.center,
                    child: Text(
                      'select_parent_category_hint'.tr(ref),
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: quickSubcategories.length,
                      itemBuilder: (context, index) {
                        final category = quickSubcategories[index];
                        final iconData = CategoryUIConstants.getIconData(
                          category.icon,
                        );
                        final catColor = CategoryUIConstants.getColorFromHex(
                          category.color,
                        );
                        final isSelected = _selectedCategory?.id == category.id;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          child: Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: colors.authCardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? catColor
                                    : colors.textSecondary.withOpacity(0.04),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: catColor.withOpacity(
                                      isSelected ? 0.25 : 0.12,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    iconData,
                                    color: catColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4.0,
                                    ),
                                    child: Text(
                                      category.name.tr(ref),
                                      style: TextStyle(
                                        color: isSelected
                                            ? catColor
                                            : colors.textPrimary,
                                        fontSize: 11,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 24),

                // 📅 4. Date & Wallet Row
                Row(
                  children: [
                    // Date picker card
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDate(context),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.authCardBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: colors.textSecondary.withOpacity(0.06),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: colors.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.calendar_month_rounded,
                                  color: colors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'date_label'.tr(ref),
                                      style: TextStyle(
                                        color: colors.textSecondary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatDate(_selectedDate),
                                      style: TextStyle(
                                        color: colors.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Wallet selector card
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (walletList.isEmpty) {
                            context.push(RoutePaths.addWallet);
                          } else {
                            _showWalletSelector(context, walletList);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.authCardBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: colors.textSecondary.withOpacity(0.06),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: colors.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: colors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'wallet_label'.tr(ref),
                                      style: TextStyle(
                                        color: colors.textSecondary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _selectedWallet?.name ??
                                          'select_wallet'.tr(ref),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: colors.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'attach_receipt'.tr(ref),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.textSecondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'optional'.tr(ref),
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Dash Upload Card
                    GestureDetector(
                      onTap: () => _pickImage(context),
                      child: Container(
                        width: 100,
                        height: 120,
                        decoration: BoxDecoration(
                          color: colors.authCardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: colors.primary.withOpacity(0.3),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_outlined,
                              color: colors.primary,
                              size: 24,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'capture_upload'.tr(ref),
                              style: TextStyle(
                                color: colors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_imageFile != null) ...[
                      const SizedBox(width: 16),
                      // Preview Card
                      Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              image: DecorationImage(
                                image: FileImage(_imageFile!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          if (_isLoading)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            right: 4,
                            top: 4,
                            child: GestureDetector(
                              onTap: _isLoading
                                  ? null
                                  : () {
                                      setState(() {
                                        _imageFile = null;
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
                    ],
                  ],
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

class AddTransactionShimmer extends StatelessWidget {
  const AddTransactionShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[900]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: const Duration(milliseconds: 1500),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 💳 1. Amount Display Card Placeholder
            Container(
              width: double.infinity,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            const SizedBox(height: 24),

            // 📁 2. Parent Category Label Placeholder
            Container(
              width: 120,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 12),

            // Horizontal scrolling parents list Placeholders
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                itemBuilder: (context, index) {
                  return Container(
                    width: 90,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // 📂 3. Subcategory Label Placeholder
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 100,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                Container(
                  width: 60,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Quick Subcategories Placeholders
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                itemBuilder: (context, index) {
                  return Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // 🖊️ 4. Form Fields Placeholders
            for (int i = 0; i < 3; i++) ...[
              Container(
                width: double.infinity,
                height: 56,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ],
            const SizedBox(height: 20),

            // 💾 5. Save Button Placeholder
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


