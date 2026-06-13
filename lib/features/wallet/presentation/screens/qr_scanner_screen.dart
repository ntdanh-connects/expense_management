import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/utils/app_logger.dart';
import 'package:expense_management/features/wallet/presentation/provider/wallet_notifier.dart';
import 'package:expense_management/features/wallet/presentation/provider/qr_transfer_provider.dart';
import 'package:expense_management/features/wallet/domain/entities/wallet_entity.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:shimmer/shimmer.dart';

final myQrCacheProvider = StateProvider<Map<String, Map<String, dynamic>>>((ref) => {});

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  
  // Debounce timer for QR generation
  Timer? _debounceTimer;
  
  // Scanning state
  bool _isLoadingDecode = false;
  bool _isCameraActive = true;

  // My QR Tab State
  WalletEntity? _selectedWallet;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  Map<String, dynamic>? _generatedQrData;
  bool _isLoadingMyQr = false;

  // Payees Tab State
  List<dynamic> _payees = [];
  bool _isLoadingPayees = false;
  final TextEditingController _searchPayeeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    
    // Listen to wallet changes to set default selection
    Future.microtask(() {
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
      _fetchPayees();
    });
  }

  void _handleTabChange() {
    setState(() {
      // Pause camera when not on tab 0 to save battery and resources
      _isCameraActive = _tabController.index == 0;
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _scannerController.dispose();
    _amountController.dispose();
    _descController.dispose();
    _searchPayeeController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // --- TAB 1: SCAN QR CODE LOGIC ---
  Future<void> _onQrDetect(BarcodeCapture capture) async {
    if (_isLoadingDecode) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    
    final String? rawValue = barcodes.first.rawValue;
    if (rawValue != null) {
      await _decodeQrString(rawValue);
    }
  }

  Future<void> _decodeQrString(String qrString) async {
    if (_isLoadingDecode) return;
    setState(() {
      _isLoadingDecode = true;
    });
    
    // Tạm dừng camera quét đè nhiều lần
    try {
      await _scannerController.stop();
    } catch (e) {
      AppLogger.warning("Không thể dừng camera: $e");
    }
    
    AppLogger.info("🔍 [QR-Scan] Bắt đầu giải mã chuỗi QR: $qrString");
    
    final result = await ref.read(qrTransferProvider.notifier).decodeQrCode(qrString);

    if (result != null && mounted) {
      AppLogger.info("✅ [QR-Scan] Giải mã thành công! Điều hướng đến màn hình xác nhận...");
      await context.push('/qr-transfer-confirm', extra: result);
      
      // Khi quay lại từ màn hình xác nhận, khởi động lại camera và reset trạng thái loading
      if (mounted) {
        setState(() {
          _isLoadingDecode = false;
        });
        try {
          await _scannerController.start();
        } catch (e) {
          AppLogger.error("Không thể khởi động lại camera: $e");
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoadingDecode = false;
        });
        AppLogger.error("🚨 [QR-Scan] Lỗi giải mã QR hoặc mã QR không hợp lệ!");
        ElegantNotification.error(
          title: Text('error'.tr(ref), style: const TextStyle(fontWeight: FontWeight.bold)),
          description: const Text('Mã QR không đúng định dạng hoặc có lỗi xảy ra!'),
        ).show(context);
        
        // Khởi động lại camera để cho phép quét tiếp
        try {
          await _scannerController.start();
        } catch (e) {
          AppLogger.error("Không thể khởi động lại camera: $e");
        }
      }
    }
  }

  Future<void> _scanFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final BarcodeCapture? capture = await _scannerController.analyzeImage(image.path);
      final bool hasBarcodes = capture != null && capture.barcodes.isNotEmpty;
      if (hasBarcodes) {
        final String? rawValue = capture.barcodes.first.rawValue;
        if (rawValue != null) {
          await _decodeQrString(rawValue);
        }
      } else {
        if (mounted) {
          ElegantNotification.error(
            title: Text('error'.tr(ref), style: const TextStyle(fontWeight: FontWeight.bold)),
            description: const Text('Không tìm thấy mã QR trong ảnh được chọn!'),
          ).show(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ElegantNotification.error(
          title: Text('error'.tr(ref), style: const TextStyle(fontWeight: FontWeight.bold)),
          description: Text('Có lỗi xảy ra: $e'),
        ).show(context);
      }
    }
  }

  // --- TAB 2: MY QR LOGIC ---
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

  // --- TAB 3: SAVED PAYEES LOGIC ---
  Future<void> _fetchPayees({String? search}) async {
    setState(() {
      _isLoadingPayees = true;
    });

    final result = await ref.read(qrTransferProvider.notifier).fetchPayees(
      search: search,
      perPage: 30,
    );

    if (mounted) {
      setState(() {
        _payees = result?['data'] ?? [];
        _isLoadingPayees = false;
      });
    }
  }

  Future<void> _deletePayee(String id) async {
    final success = await ref.read(qrTransferProvider.notifier).removePayee(id);
    if (success && mounted) {
      ElegantNotification.success(
        title: Text('success'.tr(ref), style: const TextStyle(fontWeight: FontWeight.bold)),
        description: const Text('Đã xóa khỏi danh bạ người nhận.'),
      ).show(context);
      _fetchPayees(search: _searchPayeeController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Listen to wallet changes to set default selection when wallets load asynchronously
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
          setState(() {
            _selectedWallet = wallets.firstWhere(
              (w) => w.type == 'bank',
              orElse: () => wallets.first,
            );
          });
          _generateMyQrCode();
        }
      }
    });

    return Scaffold(
      backgroundColor: color.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: color.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'qr_transfer'.tr(ref),
          style: TextStyle(color: color.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: color.primary,
          unselectedLabelColor: color.textSecondary,
          indicatorColor: color.primary,
          tabs: [
            Tab(text: 'scan_qr'.tr(ref)),
            Tab(text: 'my_qr'.tr(ref)),
            Tab(text: 'payee_list'.tr(ref)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // Prevent sliding conflict with camera
        children: [
          _buildScanTab(color, isDark),
          _buildMyQrTab(color, isDark),
          _buildPayeesTab(color, isDark),
        ],
      ),
    );
  }

  // --- TAB 1 WIDGET BUILDER ---
  Widget _buildScanTab(AppColorsExtension color, bool isDark) {
    return Stack(
      children: [
        if (_isCameraActive)
          MobileScanner(
            controller: _scannerController,
            onDetect: _onQrDetect,
          ),
        
        // Scan Window overlay
        _buildScannerOverlay(context, color),

        // Controls (Flashlight, Album)
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                style: IconButton.styleFrom(backgroundColor: Colors.black54, padding: const EdgeInsets.all(12)),
                icon: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 28),
                onPressed: () => _scannerController.toggleTorch(),
              ),
              IconButton(
                style: IconButton.styleFrom(backgroundColor: Colors.black54, padding: const EdgeInsets.all(12)),
                icon: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 28),
                onPressed: _scanFromGallery,
              ),
            ],
          ),
        ),

        if (_isLoadingDecode)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Đang giải mã QR...',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildScannerOverlay(BuildContext context, AppColorsExtension color) {
    final double scanArea = MediaQuery.of(context).size.width * 0.7;
    return Container(
      decoration: ShapeDecoration(
        shape: QrScannerOverlayShape(
          borderColor: color.primary,
          borderRadius: 24,
          borderLength: 40,
          borderWidth: 8,
          cutOutSize: scanArea,
        ),
      ),
    );
  }

  // --- TAB 2 WIDGET BUILDER ---
  Widget _buildMyQrTab(AppColorsExtension color, bool isDark) {
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
          // Glassmorphic QR Box
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
                          child: Image.network(
                            _generatedQrData!['qr_image'] ?? '',
                            height: 250,
                            width: 250,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const SizedBox(
                              height: 250,
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

          // Dropdown Wallet Selection
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
                    // Reset QR image if not cached to show shimmer instantly
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

          // Optional Amount Field
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: color.textPrimary),
            decoration: InputDecoration(
              labelText: 'amount'.tr(ref) + ' (${'optional'.tr(ref)})',
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

          // Description Field
          TextField(
            controller: _descController,
            style: TextStyle(color: color.textPrimary),
            decoration: InputDecoration(
              labelText: 'description'.tr(ref) + ' (${'optional'.tr(ref)})',
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

  Widget _buildPayeesShimmer(AppColorsExtension color, bool isDark) {
    final baseColor = isDark ? Colors.grey[900]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[800]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: const Duration(milliseconds: 1500),
      child: ListView.builder(
        itemCount: 5,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          return Card(
            color: color.surface,
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const CircleAvatar(radius: 20),
              title: Container(
                width: 150,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              subtitle: Container(
                width: 100,
                height: 12,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
            ),
          );
        },
      ),
    );
  }

  // --- TAB 3 WIDGET BUILDER ---
  Widget _buildPayeesTab(AppColorsExtension color, bool isDark) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchPayeeController,
            style: TextStyle(color: color.textPrimary),
            decoration: InputDecoration(
              hintText: 'search_payee_hint'.tr(ref),
              hintStyle: TextStyle(color: color.textSecondary.withOpacity(0.5)),
              prefixIcon: Icon(Icons.search_rounded, color: color.textSecondary),
              filled: true,
              fillColor: color.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
            onChanged: (val) => _fetchPayees(search: val),
          ),
        ),
        Expanded(
          child: _isLoadingPayees
              ? _buildPayeesShimmer(color, isDark)
              : _payees.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.contact_phone_outlined, size: 60, color: color.textSecondary.withOpacity(0.5)),
                          const SizedBox(height: 12),
                          Text(
                            'no_payee_found'.tr(ref),
                            style: TextStyle(color: color.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _payees.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final payee = _payees[index];
                        final isInternal = payee['payee_type'] == 'internal';

                        return Card(
                          color: color.surface,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            leading: isInternal
                                ? CircleAvatar(
                                    backgroundImage: payee['avatar_url'] != null ? NetworkImage(payee['avatar_url']) : null,
                                    child: payee['avatar_url'] == null ? const Icon(Icons.person) : null,
                                  )
                                : Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
                                    child: const Icon(Icons.account_balance_rounded, color: Colors.blue),
                                  ),
                            title: Text(
                              () {
                                final name = payee['payee_name']?.toString().trim() ?? '';
                                return (name.isEmpty || name.toUpperCase() == 'UNKNOWN RECIPIENT')
                                    ? 'Không xác định'
                                    : name;
                              }(),
                              style: TextStyle(color: color.textPrimary, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              isInternal ? payee['identifier'] : "${payee['bank_name']} - ${payee['identifier']}",
                              style: TextStyle(color: color.textSecondary, fontSize: 12),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                                  onPressed: () => _deletePayee(payee['id']),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                              ],
                            ),
                            onTap: () {
                              final mappedPayee = {
                                'payee_id': payee['id'],
                                'type': payee['payee_type'],
                                'payee_user_id': payee['payee_user_id'],
                                'identifier': payee['identifier'],
                                'payee_name': payee['payee_name'],
                                'bank_code': payee['bank_code'],
                                'bank_name': payee['bank_name'],
                                'account_number': payee['identifier'],
                                'amount': null,
                                'description': null,
                              };
                              context.push('/qr-transfer-confirm', extra: mappedPayee);
                            },
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

// Custom overlay shape for camera window
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final double borderLength;
  final double borderRadius;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 1.0,
    this.borderLength = 20.0,
    this.borderRadius = 0.0,
    this.cutOutSize = 250.0,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRect(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    
    final paintBg = Paint()..color = Colors.black.withOpacity(0.65);
    final boxRect = Rect.fromCenter(
      center: Offset(width / 2, height / 2),
      width: cutOutSize,
      height: cutOutSize,
    );
    
    // Draw background with cut out scan window using PathOperation.difference
    final Path backgroundPath = Path()..addRect(rect);
    final Path cutoutPath = Path()..addRRect(RRect.fromRectAndRadius(boxRect, Radius.circular(borderRadius)));
    final Path combinedPath = Path.combine(PathOperation.difference, backgroundPath, cutoutPath);
    canvas.drawPath(combinedPath, paintBg);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final path = Path();
    final halfWidth = cutOutSize / 2;
    final center = Offset(width / 2, height / 2);

    final topLeft = Offset(center.dx - halfWidth, center.dy - halfWidth);
    final topRight = Offset(center.dx + halfWidth, center.dy - halfWidth);
    final bottomLeft = Offset(center.dx - halfWidth, center.dy + halfWidth);
    final bottomRight = Offset(center.dx + halfWidth, center.dy + halfWidth);

    // Top Left Border Corner
    path.moveTo(topLeft.dx + borderRadius, topLeft.dy);
    path.lineTo(topLeft.dx + borderRadius + borderLength, topLeft.dy);
    path.moveTo(topLeft.dx, topLeft.dy + borderRadius);
    path.lineTo(topLeft.dx, topLeft.dy + borderRadius + borderLength);

    // Top Right Border Corner
    path.moveTo(topRight.dx - borderRadius, topRight.dy);
    path.lineTo(topRight.dx - borderRadius - borderLength, topRight.dy);
    path.moveTo(topRight.dx, topRight.dy + borderRadius);
    path.lineTo(topRight.dx, topRight.dy + borderRadius + borderLength);

    // Bottom Left Border Corner
    path.moveTo(bottomLeft.dx + borderRadius, bottomLeft.dy);
    path.lineTo(bottomLeft.dx + borderRadius + borderLength, bottomLeft.dy);
    path.moveTo(bottomLeft.dx, bottomLeft.dy - borderRadius);
    path.lineTo(bottomLeft.dx, bottomLeft.dy - borderRadius - borderLength);

    // Bottom Right Border Corner
    path.moveTo(bottomRight.dx - borderRadius, bottomRight.dy);
    path.lineTo(bottomRight.dx - borderRadius - borderLength, bottomRight.dy);
    path.moveTo(bottomRight.dx, bottomRight.dy - borderRadius);
    path.lineTo(bottomRight.dx, bottomRight.dy - borderRadius - borderLength);

    canvas.drawPath(path, borderPaint);
  }

  @override
  ShapeBorder scale(double t) => this;
}
