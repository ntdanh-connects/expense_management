import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/wallet/domain/entities/wallet_entity.dart';
import 'package:expense_management/features/wallet/data/models/create_wallet_request.dart';
import 'package:expense_management/features/wallet/domain/di/domain_providers.dart';
import 'package:expense_management/core/constants/app_constant.dart';
import 'package:expense_management/features/profile/presentation/providers/user_provider.dart';
import 'package:expense_management/core/language/app_language.dart';
import '../widget/shared/wallet_constants.dart';
import '../widget/qr_transfer/swipe_to_confirm_button.dart';
import '../widget/wallet/wallet_preview_card.dart';
import '../widget/add_wallet/add_wallet_type_selector.dart';
import '../widget/add_wallet/add_wallet_icon_grid.dart';
import '../widget/add_wallet/add_wallet_color_picker.dart';
import '../widget/add_wallet/add_wallet_switches.dart';

class AddWalletScreen extends ConsumerStatefulWidget {
  final WalletEntity? walletToEdit;
  const AddWalletScreen({super.key, this.walletToEdit});

  @override
  ConsumerState<AddWalletScreen> createState() => _AddWalletScreenState();
}

class _AddWalletScreenState extends ConsumerState<AddWalletScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController();

  String _walletName = 'Ví mới của tôi';
  double _initialBalance = 0;

  String _selectedType = 'cash'; // cash, bank, e-wallet
  String _selectedIcon = 'wallet';
  String _selectedColor = '#4C4DDC';
  bool _isLoading = false;
  bool _isHidden = false;
  bool _isDefaultReceiving = false;
  String _selectedCurrency = 'VND';

  @override
  void initState() {
    super.initState();
    if (widget.walletToEdit != null) {
      _walletName = widget.walletToEdit!.name;
      _nameController.text = widget.walletToEdit!.name;
      _initialBalance = widget.walletToEdit!.balance;
      _balanceController.text = widget.walletToEdit!.balance.toStringAsFixed(0);
      _selectedType = widget.walletToEdit!.type;
      _selectedIcon = widget.walletToEdit!.icon;
      _selectedColor = widget.walletToEdit!.color;
      _isHidden = widget.walletToEdit!.isHidden;
      _selectedCurrency = widget.walletToEdit!.currencyCode;
      _isDefaultReceiving = widget.walletToEdit!.isDefaultReceiving;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _walletName = 'my_new_wallet'.tr(ref);
            _selectedCurrency = 'VND';
          });
        }
      });
    }

    _nameController.addListener(() {
      setState(() {
        _walletName = _nameController.text.trim().isEmpty
            ? (widget.walletToEdit != null
                ? widget.walletToEdit!.name
                : 'my_new_wallet'.tr(ref))
            : _nameController.text.trim();
      });
    });
    _balanceController.addListener(() {
      setState(() {
        _initialBalance = double.tryParse(_balanceController.text.trim()) ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: colors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: colors.textPrimary,
                size: 20,
              ),
              onPressed: () => context.pop(),
            ),
            title: Text(
              widget.walletToEdit != null
                  ? 'edit_wallet'.tr(ref)
                  : 'add_new_wallet'.tr(ref),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 💳 1. THÈ VÍ LIVE CARD PREVIEW
                WalletPreviewCard(
                  walletName: _walletName,
                  balance: _initialBalance,
                  selectedIcon: _selectedIcon,
                  selectedColor: _selectedColor,
                  primaryColor: colors.primary,
                  currencySymbol:
                      AppConstant.getCurrencySymbol(_selectedCurrency),
                ),
                const SizedBox(height: 28),

                // ✍️ 2. Ô NHẬP TÊN VÍ
                Text(
                  'wallet_name'.tr(ref),
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.04)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: _nameController,
                    style: TextStyle(color: colors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'enter_wallet_name_hint'.tr(ref),
                      hintStyle: TextStyle(
                        color: colors.textSecondary.withOpacity(0.6),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 💰 3. Ô NHẬP SỐ DƯ BAN ĐẦU
                if (widget.walletToEdit != null) ...[
                  Text(
                    'initial_balance'.tr(ref),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.02)
                          : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: _balanceController,
                      enabled: false,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        color: colors.textSecondary.withOpacity(0.8),
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: TextStyle(
                          color: colors.textSecondary.withOpacity(0.6),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        suffixIcon: Container(
                          alignment: Alignment.centerRight,
                          width: 40,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(
                                Icons.lock_rounded,
                                size: 14,
                                color: colors.textSecondary.withOpacity(0.6),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                AppConstant.getCurrencySymbol(
                                  ref.watch(
                                    currentUserProvider
                                        .select((u) => u?.currency),
                                  ),
                                ),
                                style: TextStyle(
                                  color: colors.textSecondary.withOpacity(0.8),
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // 📁 4. CHỌN LOẠI VÍ
                AddWalletTypeSelector(
                  selectedType: _selectedType,
                  onTypeSelected: (val) {
                    setState(() {
                      _selectedType = val;
                    });
                  },
                ),
                const SizedBox(height: 24),

                // 🎨 5. CHỌN BIỂU TƯỢNG
                AddWalletIconGrid(
                  selectedIcon: _selectedIcon,
                  onIconSelected: (val) {
                    setState(() {
                      _selectedIcon = val;
                    });
                  },
                ),
                const SizedBox(height: 24),

                // 🔴 6. CHỌN MÀU SẮC
                AddWalletColorPicker(
                  selectedColor: _selectedColor,
                  onColorSelected: (val) {
                    setState(() {
                      _selectedColor = val;
                    });
                  },
                ),
                const SizedBox(height: 36),

                // 👁️ 6.5 & 6.6. SWITCH ẨN VÍ & ĐẶT LÀM MẶC ĐỊNH
                AddWalletSwitches(
                  isHidden: _isHidden,
                  isDefaultReceiving: _isDefaultReceiving,
                  walletToEdit: widget.walletToEdit,
                  selectedType: _selectedType,
                  onHiddenChanged: (val) {
                    setState(() {
                      _isHidden = val;
                    });
                  },
                  onSetDefaultReceiving: () =>
                      _executeSetDefaultReceiving(colors),
                ),
                const SizedBox(height: 28),

                // 🚀 7. NÚT SUBMIT
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => _handleCreateWallet(colors),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.walletToEdit != null
                              ? '${'save_changes'.tr(ref)} '
                              : '${'create_wallet'.tr(ref)} ',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(
                          widget.walletToEdit != null
                              ? Icons.save_rounded
                              : Icons.add_circle_outline_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        if (_isLoading)
          AbsorbPointer(
            child: Container(
              color: Colors.black.withOpacity(0.45),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1E1E1E)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.walletToEdit != null
                            ? 'updating_wallet'.tr(ref)
                            : 'creating_wallet'.tr(ref),
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _handleCreateWallet(AppColorsExtension colors) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showSnackBar('please_enter_wallet_name'.tr(ref), isError: true);
      return;
    }
    _showAndroidConfirmSheet(context, colors);
  }

  void _showAndroidConfirmSheet(
    BuildContext context,
    AppColorsExtension colors,
  ) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding:
              const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 32),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Icon(
                    widget.walletToEdit != null
                        ? Icons.edit_note_rounded
                        : Icons.security_rounded,
                    color: colors.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.walletToEdit != null
                        ? 'confirm_edit'.tr(ref)
                        : 'confirm_security'.tr(ref),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                widget.walletToEdit != null
                    ? 'swipe_to_save_desc'.tr(ref).replaceAll(
                          '{name}',
                          _walletName,
                        )
                    : 'swipe_to_create_desc'
                        .tr(ref)
                        .replaceAll('{name}', _walletName)
                        .replaceAll(
                          '{balance}',
                          '${_formatMoney(_initialBalance, _selectedCurrency)} ${AppConstant.getCurrencySymbol(_selectedCurrency)}',
                        ),
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              SwipeToConfirmButton(
                text: widget.walletToEdit != null
                    ? 'swipe_to_save'.tr(ref)
                    : 'swipe_to_create'.tr(ref),
                activeColor: colors.primary,
                onConfirmed: () async {
                  HapticFeedback.vibrate();
                  await Future.delayed(const Duration(milliseconds: 300));
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  _executeCreateWallet(colors);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _executeCreateWallet(AppColorsExtension colors) async {
    final name = _nameController.text.trim();
    setState(() {
      _isLoading = true;
    });

    try {
      final request = CreateWalletRequest(
        name: name,
        type: _selectedType,
        icon: _selectedIcon,
        color: _selectedColor,
        isHidden: _isHidden,
        availableBalance: null,
        currencyCode: _selectedCurrency,
      );

      if (widget.walletToEdit != null) {
        await ref
            .read(updateWalletUseCaseProvider)
            .execute(widget.walletToEdit!.id, request);
      } else {
        await ref.read(createWalletUseCaseProvider).execute(request);
      }

      setState(() {
        _isLoading = false;
      });

      if (!context.mounted) return;
      context.pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.walletToEdit != null
                ? 'update_wallet_success'.tr(ref)
                : 'create_wallet_success'.tr(ref),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: colors.incomeGreen,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog(e.toString(), colors);
    }
  }

  void _executeSetDefaultReceiving(AppColorsExtension colors) async {
    setState(() {
      _isLoading = true;
    });
    try {
      await ref
          .read(setDefaultReceivingWalletUseCaseProvider)
          .execute(widget.walletToEdit!.id);
      setState(() {
        _isDefaultReceiving = true;
        _isLoading = false;
      });
      if (!mounted) return;
      _showSnackBar('set_default_receiving_success'.tr(ref), isError: false);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      _showErrorDialog(e.toString(), colors);
    }
  }

  void _showErrorDialog(String error, AppColorsExtension colors) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: colors.expenseRed,
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                widget.walletToEdit != null
                    ? 'edit_wallet_error'.tr(ref)
                    : 'create_wallet_error'.tr(ref),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            widget.walletToEdit != null
                ? 'edit_wallet_error_desc'.tr(ref).replaceAll('{error}', error)
                : 'create_wallet_error_desc'
                    .tr(ref)
                    .replaceAll('{error}', error),
            style: const TextStyle(height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'ok'.tr(ref),
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String msg, {required bool isError}) {
    final colors = context.colors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isError ? colors.expenseRed : colors.incomeGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _formatMoney(double value, [String? currencyCode]) {
    return AppConstant.formatMoney(value, currencyCode ?? _selectedCurrency);
  }
}
