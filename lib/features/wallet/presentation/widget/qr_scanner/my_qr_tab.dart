import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_notifier.dart';
import 'package:expense_management/features/wallet/presentation/provider/qr_transfer_provider.dart';
import 'package:expense_management/features/wallet/domain/entities/wallet_entity.dart';

final myQrCacheProvider = StateProvider<Map<String, Map<String, dynamic>>>((ref) => {});

class MyQrTab extends ConsumerStatefulWidget {
  const MyQrTab({super.key});

  @override
  ConsumerState<MyQrTab> createState() => _MyQrTabState();
}

class _MyQrTabState extends ConsumerState<MyQrTab> {
  Timer? _debounceTimer;
  WalletEntity? _selectedWallet;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  Map<String, dynamic>? _generatedQrData;
  bool _isLoadingMyQr = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rawWallets = ref.read(walletNotifierProvider).value ?? [];
      final wallets = rawWallets.where((w) {
        final type = w.type.toLowerCase();
        return !w.isHidden &&
               (type == 'bank' || type == 'e-wallet' || type == 'e_wallet' || type == 'ewallet') &&
               w.currencyCode == 'VND';
      }).toList();
      if (wallets.isNotEmpty) {
        setState(() {
          _selectedWallet = wallets.firstWhere(
            (w) => w.type == 'bank',
            orElse: () => wallets.first,
          );
        });
        _generateMyQrCode();
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onQrFieldsChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      _generateMyQrCode();
    });
  }

  Future<void> _generateMyQrCode() async {
    final amountText = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(amountText);
    final desc = _descController.text.trim();

    final isDefault = amount == null && desc.isEmpty;
    final walletId = _selectedWallet?.id;

    if (isDefault && walletId != null) {
      final cache = ref.read(myQrCacheProvider);
      if (cache.containsKey(walletId)) {
        setState(() {
          _generatedQrData = cache[walletId];
          _isLoadingMyQr = false;
        });
        return;
      }
    }

    setState(() {
      _isLoadingMyQr = true;
    });

    final result = await ref.read(qrTransferProvider.notifier).generateMyQrCode(
      walletId: walletId,
      amount: amount,
      description: desc.isNotEmpty ? desc : null,
    );

    if (mounted) {
      setState(() {
        _generatedQrData = result;
        _isLoadingMyQr = false;
        if (isDefault && walletId != null && result != null) {
          ref.read(myQrCacheProvider.notifier).update((state) => {
            ...state,
            walletId: result,
          });
        }
      });
    }
  }

  Widget _buildMyQrShimmer(AppColorsExtension color, bool isDark) {
    final baseColor = isDark ? Colors.grey[900]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: const Duration(milliseconds: 1500),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 250,
            width: 250,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 130,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 180,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<AsyncValue<List<WalletEntity>>>(walletNotifierProvider, (previous, next) {
      if (next.hasValue && _selectedWallet == null) {
        final rawWallets = next.value ?? [];
        final wallets = rawWallets.where((w) {
          final type = w.type.toLowerCase();
          return !w.isHidden &&
                 (type == 'bank' || type == 'e-wallet' || type == 'e_wallet' || type == 'ewallet') &&
                 w.currencyCode == 'VND';
        }).toList();
        if (wallets.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedWallet = wallets.firstWhere(
                  (w) => w.type == 'bank',
                  orElse: () => wallets.first,
                );
              });
              _generateMyQrCode();
            }
          });
        }
      }
    });

    final walletsAsync = ref.watch(walletNotifierProvider);
    final rawWallets = walletsAsync.value ?? [];
    final wallets = rawWallets.where((w) {
      final type = w.type.toLowerCase();
      return !w.isHidden &&
             (type == 'bank' || type == 'e-wallet' || type == 'e_wallet' || type == 'ewallet') &&
             w.currencyCode == 'VND';
    }).toList();

    if (wallets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_scanner_rounded, size: 80, color: color.textSecondary.withOpacity(0.3)),
              const SizedBox(height: 16),
              Text(
                'qr_receive_no_wallet_warning'.tr(ref),
                textAlign: TextAlign.center,
                style: TextStyle(color: color.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? color.surface.withOpacity(0.4) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: color.textSecondary.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 15, offset: const Offset(0, 8))
              ],
            ),
            child: Column(
              children: [
                if (_isLoadingMyQr && _generatedQrData == null)
                  _buildMyQrShimmer(color, isDark)
                else if (_generatedQrData != null) ...[
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: _isLoadingMyQr ? 0.4 : 1.0,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: _generatedQrData!['qr_image'] ?? '',
                            height: 250,
                            width: 250,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const SizedBox(
                              height: 250,
                              width: 250,
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => const SizedBox(
                              height: 250,
                              width: 250,
                              child: Icon(Icons.qr_code_2_rounded, size: 120),
                            ),
                          ),
                        ),
                      ),
                      if (_isLoadingMyQr)
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(color.primary),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _generatedQrData!['type'] == 'external' ? 'VietQR chuẩn Napas' : 'Mã QR nội bộ P2P',
                    style: TextStyle(color: color.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _generatedQrData!['identifier'] ?? '',
                        style: TextStyle(color: color.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _generatedQrData!['qr_code'] ?? ''));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã sao chép chuỗi mã QR')),
                          );
                        },
                      ),
                    ],
                  ),
                ] else
                  const SizedBox(
                    height: 250,
                    child: Center(child: Icon(Icons.qr_code_2_rounded, size: 100, color: Colors.grey)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'choose_wallet_to_receive'.tr(ref),
            style: TextStyle(color: color.textSecondary, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: color.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.textSecondary.withOpacity(0.15)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<WalletEntity>(
                value: _selectedWallet,
                dropdownColor: color.surface,
                hint: const Text('Chọn ví nhận tiền...'),
                items: wallets.map((w) {
                  return DropdownMenuItem<WalletEntity>(
                     value: w,
                     child: Row(
                       children: [
                         Icon(
                           w.type == 'bank' ? Icons.account_balance_rounded : Icons.account_balance_wallet_rounded,
                           color: color.primary,
                         ),
                         const SizedBox(width: 12),
                         Text(w.name, style: TextStyle(color: color.textPrimary)),
                       ],
                     ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedWallet = val;
                    final cache = ref.read(myQrCacheProvider);
                    if (val != null && !cache.containsKey(val.id)) {
                      _generatedQrData = null;
                    }
                  });
                  _generateMyQrCode();
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: color.textPrimary),
            decoration: InputDecoration(
              labelText: '${'amount'.tr(ref)} (${'optional'.tr(ref)})',
              labelStyle: TextStyle(color: color.textSecondary),
              hintText: '0đ',
              hintStyle: TextStyle(color: color.textSecondary.withOpacity(0.5)),
              prefixIcon: Icon(Icons.attach_money_rounded, color: color.textSecondary),
              filled: true,
              fillColor: color.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
            onChanged: (_) => _onQrFieldsChanged(),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _descController,
            style: TextStyle(color: color.textPrimary),
            decoration: InputDecoration(
              labelText: '${'description'.tr(ref)} (${'optional'.tr(ref)})',
              labelStyle: TextStyle(color: color.textSecondary),
              hintText: 'Nhập mô tả nhận tiền...',
              hintStyle: TextStyle(color: color.textSecondary.withOpacity(0.5)),
              prefixIcon: Icon(Icons.notes_rounded, color: color.textSecondary),
              filled: true,
              fillColor: color.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
            onChanged: (_) => _onQrFieldsChanged(),
          ),
        ],
      ),
    );
  }
}
