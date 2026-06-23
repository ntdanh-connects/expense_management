import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/language/app_provider.dart';
import 'package:expense_management/features/profile/presentation/providers/category_provider.dart';
import 'package:expense_management/features/profile/data/models/category_dto.dart';
import 'package:expense_management/features/profile/presentation/widgets/category_ui_constants.dart';
import 'package:expense_management/features/wallet/domain/entities/wallet_entity.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_notifier.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:expense_management/core/utils/currency_utils.dart';

class QrTransferConfirmScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> payeeData;

  const QrTransferConfirmScreen({super.key, required this.payeeData});

  @override
  ConsumerState<QrTransferConfirmScreen> createState() => _QrTransferConfirmScreenState();
}

class _QrTransferConfirmScreenState extends ConsumerState<QrTransferConfirmScreen> {
  WalletEntity? _selectedWallet;
  CategoryDto? _selectedCategory;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    
    // Parse payeeData amount & description if pre-filled
    if (widget.payeeData['amount'] != null) {
      final double amt = double.tryParse(widget.payeeData['amount'].toString()) ?? 0.0;
      if (amt > 0) {
        final cappedAmt = amt > 500000000.0 ? 500000000.0 : amt;
        _amountController.text = NumberFormat('#,###', 'vi_VN').format(cappedAmt);
      }
    }
    if (widget.payeeData['description'] != null) {
      _descController.text = widget.payeeData['description'].toString();
    }

    // Set default wallet from filtered list
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final wallets = ref.read(walletNotifierProvider).value ?? [];
      final isInternal = widget.payeeData['type'] == 'internal';
      
      final filtered = wallets.where((w) {
        if (w.type == 'cash') return false;
        if (!isInternal && w.currencyCode != 'VND') return false;
        return true;
      }).toList();

      if (filtered.isNotEmpty) {
        final prefilledWalletId = widget.payeeData['from_wallet_id'];
        WalletEntity? prefilledWallet;
        if (prefilledWalletId != null) {
          prefilledWallet = filtered.where((w) => w.id == prefilledWalletId).firstOrNull;
        }

        setState(() {
          _selectedWallet = prefilledWallet ?? filtered.firstWhere(
            (w) => w.type == 'bank',
            orElse: () => filtered.first,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _executeTransfer() async {
    if (_isProcessing) return;

    final wallets = ref.read(walletNotifierProvider).value ?? [];
    final isInternal = widget.payeeData['type'] == 'internal';
    final filtered = wallets.where((w) {
      if (w.type == 'cash') return false;
      if (!isInternal && w.currencyCode != 'VND') return false;
      return true;
    }).toList();

    if (_selectedWallet == null || !filtered.any((w) => w.id == _selectedWallet!.id)) {
      ElegantNotification.error(
        title: Text('error'.tr(ref), style: const TextStyle(fontWeight: FontWeight.bold)),
        description: const Text('Vui lòng chọn ví hợp lệ để thực hiện chuyển khoản!'),
      ).show(context);
      return;
    }

    if (_selectedCategory == null) {
      ElegantNotification.error(
        title: Text('error'.tr(ref), style: const TextStyle(fontWeight: FontWeight.bold)),
        description: const Text('Vui lòng chọn danh mục chi tiêu cho giao dịch này!'),
      ).show(context);
      return;
    }
    
    final cleanAmountString = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final double? amount = double.tryParse(cleanAmountString);
    
    if (amount == null || amount <= 0) {
      ElegantNotification.error(
        title: Text('error'.tr(ref), style: const TextStyle(fontWeight: FontWeight.bold)),
        description: const Text('Vui lòng nhập số tiền chuyển hợp lệ!'),
      ).show(context);
      return;
    }

    if (amount > _selectedWallet!.balance) {
      ElegantNotification.error(
        title: Text('error'.tr(ref), style: const TextStyle(fontWeight: FontWeight.bold)),
        description: Text('insufficient_balance_error'.tr(ref)),
      ).show(context);
      return;
    }

    final rawPayeeName = widget.payeeData['payee_name']?.toString().trim() ?? '';
    final payeeName = (rawPayeeName.isEmpty || rawPayeeName.toUpperCase() == 'UNKNOWN RECIPIENT')
        ? 'Không xác định'
        : rawPayeeName;

    final identifier = widget.payeeData['identifier'] ?? widget.payeeData['account_number'] ?? '';
    final bankName = widget.payeeData['bank_name'] ?? '';

    setState(() {
      _isProcessing = true;
    });
    try {
      if (mounted) {
        await context.push('/qr-transfer-result', extra: {
          'is_pending_execution': true,
          'from_wallet_id': _selectedWallet!.id,
          'payee_type': widget.payeeData['type'] ?? 'internal',
          'amount': amount,
          'notes': _descController.text.isNotEmpty ? _descController.text : 'QR transfer',
          'payee_user_id': widget.payeeData['payee_user_id'],
          'bank_code': widget.payeeData['bank_code'],
          'account_number': widget.payeeData['account_number'] ?? widget.payeeData['identifier'],
          'payee_name': payeeName,
          'sender_wallet': _selectedWallet?.name ?? '',
          'bank_name': bankName,
          'identifier': identifier,
          'type': widget.payeeData['type'] ?? 'internal',
          'to_wallet_id': widget.payeeData['to_wallet_id'],
          'category_id': _selectedCategory!.id,
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showCategoryPicker(BuildContext context, List<CategoryDto> parents) {
    final color = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: color.background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: color.textSecondary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Chọn danh mục chi tiêu',
                    style: TextStyle(
                      color: color.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: parents.length,
                      itemBuilder: (context, idx) {
                        final parent = parents[idx];
                        final subCats = parent.children ?? [];
                        if (subCats.isEmpty) return const SizedBox.shrink();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                parent.name.tr(ref),
                                style: TextStyle(
                                  color: color.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 8,
                                childAspectRatio: 0.85,
                              ),
                              itemCount: subCats.length,
                              itemBuilder: (context, sIdx) {
                                final subCat = subCats[sIdx];
                                final iconData = CategoryUIConstants.getIconData(subCat.icon);
                                final catColor = CategoryUIConstants.getColorFromHex(subCat.color);
                                final isSelected = _selectedCategory?.id == subCat.id;

                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedCategory = subCat;
                                    });
                                    Navigator.pop(context);
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: catColor.withOpacity(isSelected ? 0.3 : 0.12),
                                          shape: BoxShape.circle,
                                          border: isSelected
                                              ? Border.all(color: catColor, width: 2)
                                              : null,
                                        ),
                                        child: Icon(iconData, color: catColor, size: 22),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        subCat.name.tr(ref),
                                        style: TextStyle(
                                          color: isSelected ? catColor : color.textPrimary,
                                          fontSize: 11,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                          ],
                        );
                      },
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
    final color = context.colors;
    final localeCode = ref.watch(localeProvider);
    final wallets = ref.watch(walletNotifierProvider).value ?? [];
    final isInternal = widget.payeeData['type'] == 'internal';
    final categoriesAsync = ref.watch(categoriesNotifierProvider);
    final allCats = categoriesAsync.value ?? [];
    final parentCategories = allCats.where((c) => c.parentId == null && c.type == 'expense').toList();
    
    final filteredWallets = wallets.where((w) {
      if (w.type == 'cash') return false;
      if (!isInternal && w.currencyCode != 'VND') return false;
      return true;
    }).toList();

    final rawPayeeName = widget.payeeData['payee_name']?.toString().trim() ?? '';
    final payeeName = (rawPayeeName.isEmpty || rawPayeeName.toUpperCase() == 'UNKNOWN RECIPIENT')
        ? 'Không xác định'
        : rawPayeeName;
    final identifier = widget.payeeData['identifier'] ?? widget.payeeData['account_number'] ?? '';
    final bankName = widget.payeeData['bank_name'] ?? '';
    final bankLogo = widget.payeeData['bank_logo'];

    return Scaffold(
      backgroundColor: color.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: color.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Xác nhận chuyển khoản',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. SENDER CARD
                Text(
                  'sender_info'.tr(ref),
                  style: TextStyle(color: color.textSecondary, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.textSecondary.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (filteredWallets.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            isInternal
                                ? 'qr_transfer_internal_no_wallet_warning'.tr(ref)
                                : 'qr_transfer_external_no_wallet_warning'.tr(ref),
                            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                          ),
                        )
                      else
                        DropdownButtonHideUnderline(
                          child: DropdownButton<WalletEntity>(
                            value: filteredWallets.contains(_selectedWallet) ? _selectedWallet : filteredWallets.first,
                            dropdownColor: color.surface,
                            items: filteredWallets.map((w) {
                              return DropdownMenuItem<WalletEntity>(
                                value: w,
                                child: Row(
                                  children: [
                                    Icon(
                                      w.type == 'bank' ? Icons.account_balance_rounded : Icons.account_balance_wallet_rounded,
                                      color: color.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      "${w.name} (${w.currencyCode})",
                                      style: TextStyle(color: color.textPrimary, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedWallet = val;
                              });
                            },
                          ),
                        ),
                      if (_selectedWallet != null) ...[
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'available_balance'.tr(ref),
                              style: TextStyle(color: color.textSecondary, fontSize: 13),
                            ),
                            Text(
                              "${NumberFormat('#,###', 'vi_VN').format(_selectedWallet!.balance)}đ",
                              style: TextStyle(color: color.incomeGreen, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                      ]
                    ],
                  ),
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: CircleAvatar(
                      backgroundColor: Colors.teal,
                      radius: 20,
                      child: Icon(Icons.arrow_downward_rounded, color: Colors.white),
                    ),
                  ),
                ),

                // 2. RECIPIENT CARD
                Text(
                  'recipient_info'.tr(ref),
                  style: TextStyle(color: color.textSecondary, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.textSecondary.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                    ],
                  ),
                  child: Row(
                    children: [
                      if (isInternal)
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: widget.payeeData['avatar_url'] != null ? NetworkImage(widget.payeeData['avatar_url']) : null,
                          child: widget.payeeData['avatar_url'] == null ? const Icon(Icons.person) : null,
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
                              style: TextStyle(color: color.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isInternal ? "ID: $identifier" : "$bankName - $identifier",
                              style: TextStyle(color: color.textSecondary, fontSize: 13),
                            ),
                            if (isInternal && widget.payeeData['recipient_wallet_name'] != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                "Ví nhận: ${widget.payeeData['recipient_wallet_name']}",
                                style: TextStyle(
                                  color: color.primary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 3. INPUT AMOUNT
                Text(
                  'amount'.tr(ref),
                  style: TextStyle(color: color.textSecondary, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: color.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: '0',
                    suffixText: 'đ',
                    suffixStyle: TextStyle(color: color.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                    filled: true,
                    fillColor: color.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  ),
                  onChanged: (val) {
                    if (val.isEmpty) return;
                    final cleanString = val.replaceAll(RegExp(r'[^0-9]'), '');
                    double? amt = double.tryParse(cleanString);
                    if (amt != null) {
                      if (amt > 500000000) {
                        amt = 500000000;
                      }
                      final formatted = NumberFormat('#,###', 'vi_VN').format(amt);
                      _amountController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.fromPosition(TextPosition(offset: formatted.length)),
                      );
                    }
                  },
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _amountController,
                  builder: (context, value, child) {
                    final cleanString = value.text.replaceAll(RegExp(r'[^0-9]'), '');
                    final double? amt = double.tryParse(cleanString);
                    if (amt == null || amt == 0) {
                      return const SizedBox.shrink();
                    }
                    final wordRepresentation = formatNumberToWords(amt, localeCode);
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                      child: Text(
                        '($wordRepresentation)',
                        style: TextStyle(
                          color: color.textSecondary,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                 // 4. DESCRIPTION
                Text(
                  'notes'.tr(ref),
                  style: TextStyle(color: color.textSecondary, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descController,
                  maxLines: 2,
                  style: TextStyle(color: color.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Nhập lời nhắn chuyển tiền...',
                    filled: true,
                    fillColor: color.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),

                // 4.5. CATEGORY SELECTOR
                Text(
                  'category'.tr(ref),
                  style: TextStyle(color: color.textSecondary, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _showCategoryPicker(context, parentCategories),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: color.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _selectedCategory != null 
                            ? CategoryUIConstants.getColorFromHex(_selectedCategory!.color).withOpacity(0.4)
                            : Colors.transparent
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _selectedCategory != null
                                ? CategoryUIConstants.getColorFromHex(_selectedCategory!.color).withOpacity(0.12)
                                : color.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _selectedCategory != null
                                ? CategoryUIConstants.getIconData(_selectedCategory!.icon)
                                : Icons.category_rounded,
                            color: _selectedCategory != null
                                ? CategoryUIConstants.getColorFromHex(_selectedCategory!.color)
                                : color.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            _selectedCategory != null
                                ? _selectedCategory!.name.tr(ref)
                                : 'Chọn danh mục chi tiêu...',
                            style: TextStyle(
                              color: _selectedCategory != null ? color.textPrimary : color.textSecondary.withOpacity(0.8),
                              fontWeight: _selectedCategory != null ? FontWeight.bold : FontWeight.normal,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded, color: color.textSecondary.withOpacity(0.4), size: 14),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // 5. CONFIRM BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _executeTransfer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'confirm_transfer'.tr(ref),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
