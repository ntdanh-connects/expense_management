import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/utils/app_logger.dart';
import 'package:expense_management/features/wallet/presentation/provider/qr_transfer_provider.dart';
import 'package:expense_management/core/router/app_route.dart';

class ScanTab extends ConsumerStatefulWidget {
  final bool isCameraActive;

  const ScanTab({
    super.key,
    required this.isCameraActive,
  });

  @override
  ConsumerState<ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends ConsumerState<ScanTab> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _isLoadingDecode = false;
  bool _isProcessingQr = false;
  final String _loadingMsg = 'Đang giải mã QR...';

  @override
  void initState() {
    super.initState();
    if (!widget.isCameraActive) {
      _scannerController.stop();
    }
  }

  @override
  void didUpdateWidget(covariant ScanTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCameraActive != oldWidget.isCameraActive) {
      if (widget.isCameraActive) {
        _scannerController.start();
      } else {
        _scannerController.stop();
      }
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _onQrDetect(BarcodeCapture capture) async {
    if (_isProcessingQr || _isLoadingDecode) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawValue = barcodes.first.rawValue;
    if (rawValue != null) {
      await _decodeQrString(rawValue);
    }
  }

  Future<void> _decodeQrString(String qrString) async {
    if (_isProcessingQr || _isLoadingDecode) return;
    _isProcessingQr = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isLoadingDecode = true;
        });
      }
    });

    try {
      await _scannerController.stop();
    } catch (e) {
      AppLogger.warning("Không thể dừng camera: $e");
    }

    AppLogger.info("🔍 [QR-Scan] Bắt đầu giải mã chuỗi QR: $qrString");

    final result = await ref.read(qrTransferProvider.notifier).decodeQrCode(qrString);

    if (result != null && mounted) {
      final resultWithQrFlag = Map<String, dynamic>.from(result)..['is_qr'] = true;
      await context.push('/add-transaction', extra: resultWithQrFlag);

      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (mounted) {
            setState(() {
              _isLoadingDecode = false;
            });
            _isProcessingQr = false;
            try {
              await _scannerController.start();
            } catch (e) {
              AppLogger.error("Không thể khởi động lại camera: $e");
            }
          }
        });
      }
    } else {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (mounted) {
            setState(() {
              _isLoadingDecode = false;
            });
            _isProcessingQr = false;
            AppLogger.error("🚨 [QR-Scan] Lỗi giải mã QR hoặc mã QR không hợp lệ!");
            ElegantNotification.error(
              title: Text('error'.tr(ref), style: const TextStyle(fontWeight: FontWeight.bold)),
              description: const Text('Mã QR không đúng định dạng hoặc có lỗi xảy ra!'),
            ).show(context);

            try {
              await _scannerController.start();
            } catch (e) {
              AppLogger.error("Không thể khởi động lại camera: $e");
            }
          }
        });
      }
    }
  }

  Future<void> _scanFromGallery() async {
    if (_isProcessingQr || _isLoadingDecode) return;
    _isProcessingQr = true;

    try {
      try {
        await _scannerController.stop();
      } catch (_) {}

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) {
        _isProcessingQr = false;
        try {
          await _scannerController.start();
        } catch (_) {}
        return;
      }

      final BarcodeCapture? capture = await _scannerController.analyzeImage(image.path);
      final bool hasBarcodes = capture != null && capture.barcodes.isNotEmpty;
      if (hasBarcodes) {
        final String? rawValue = capture.barcodes.first.rawValue;
        if (rawValue != null) {
          await _decodeQrString(rawValue);
        } else {
          _isProcessingQr = false;
        }
      } else {
        _isProcessingQr = false;
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: context.colors.surface,
                  title: Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: context.colors.primary),
                      const SizedBox(width: 8),
                      Text('Quét OCR Hóa Đơn', style: TextStyle(color: context.colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  content: Text(
                    'Không tìm thấy mã QR trong ảnh được chọn. Bạn có muốn chuyển sang chế độ quét chữ (OCR) trên hóa đơn để tự động điền giao dịch thủ công không?',
                    style: TextStyle(color: context.colors.textSecondary, fontSize: 14),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _scannerController.start();
                      },
                      child: Text('Hủy', style: TextStyle(color: context.colors.textSecondary)),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final result = await context.push(
                          RoutePaths.ocrHelper,
                          extra: image.path,
                        );
                        if (result != null &&
                            result is Map<String, dynamic> &&
                            mounted) {
                          final qrData = {
                            'amount': result['amount'],
                            'description': result['description'],
                            'payee_name': result['payee_name'],
                            'date': result['date'],
                            'title': result['payee_name'] ?? result['description'],
                            'is_qr': false,
                          };
                          context.push(RoutePaths.addTransaction, extra: qrData);
                        }
                        try {
                          await _scannerController.start();
                        } catch (_) {}
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Đọc hóa đơn'),
                    ),
                  ],
                ),
              );
            }
          });
        }
      }
    } catch (e) {
      _isProcessingQr = false;
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ElegantNotification.error(
              title: Text('error'.tr(ref), style: const TextStyle(fontWeight: FontWeight.bold)),
              description: Text('Có lỗi xảy ra: $e'),
            ).show(context);
          }
        });
      }
      try {
        await _scannerController.start();
      } catch (_) {}
    }
  }

  Future<void> _scanReceiptOcr() async {
    if (_isProcessingQr || _isLoadingDecode) return;
    _isProcessingQr = true;

    try {
      try {
        await _scannerController.stop();
      } catch (_) {}

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 95,
      );
      if (image == null) {
        _isProcessingQr = false;
        try {
          await _scannerController.start();
        } catch (_) {}
        return;
      }

      if (mounted) {
        final result = await context.push(
          RoutePaths.ocrHelper,
          extra: image.path,
        );
        if (result != null && result is Map<String, dynamic> && mounted) {
          final qrData = {
            'amount': result['amount'],
            'description': result['description'],
            'payee_name': result['payee_name'],
            'date': result['date'],
            'title': result['payee_name'] ?? result['description'],
            'is_qr': false,
          };
          context.push(RoutePaths.addTransaction, extra: qrData);
        }
      }
    } catch (e) {
      if (mounted) {
        ElegantNotification.error(
          title: Text('error'.tr(ref), style: const TextStyle(fontWeight: FontWeight.bold)),
          description: Text('Có lỗi xảy ra: $e'),
        ).show(context);
      }
    } finally {
      _isProcessingQr = false;
      try {
        await _scannerController.start();
      } catch (_) {}
    }
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

  @override
  Widget build(BuildContext context) {
    final color = context.colors;
    return Stack(
      children: [
        if (widget.isCameraActive)
          MobileScanner(
            controller: _scannerController,
            onDetect: _onQrDetect,
          ),

        _buildScannerOverlay(context, color),

        Positioned(
          bottom: 30,
          left: 0,
          right: 0,
          child: SafeArea(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const SizedBox(width: 16),
                  IconButton(
                    style: IconButton.styleFrom(backgroundColor: Colors.black54, padding: const EdgeInsets.all(12)),
                    icon: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 28),
                    onPressed: () => _scannerController.toggleTorch(),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    style: IconButton.styleFrom(backgroundColor: Colors.black54, padding: const EdgeInsets.all(12)),
                    icon: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 28),
                    onPressed: _scanFromGallery,
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    style: IconButton.styleFrom(backgroundColor: Colors.black54, padding: const EdgeInsets.all(12)),
                    icon: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 28),
                    onPressed: _scanReceiptOcr,
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),
        ),

        if (_isLoadingDecode)
          Container(
            color: Colors.black54,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    _loadingMsg,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
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

    path.moveTo(topLeft.dx + borderRadius, topLeft.dy);
    path.lineTo(topLeft.dx + borderRadius + borderLength, topLeft.dy);
    path.moveTo(topLeft.dx, topLeft.dy + borderRadius);
    path.lineTo(topLeft.dx, topLeft.dy + borderRadius + borderLength);

    path.moveTo(topRight.dx - borderRadius, topRight.dy);
    path.lineTo(topRight.dx - borderRadius - borderLength, topRight.dy);
    path.moveTo(topRight.dx, topRight.dy + borderRadius);
    path.lineTo(topRight.dx, topRight.dy + borderRadius + borderLength);

    path.moveTo(bottomLeft.dx + borderRadius, bottomLeft.dy);
    path.lineTo(bottomLeft.dx + borderRadius + borderLength, bottomLeft.dy);
    path.moveTo(bottomLeft.dx, bottomLeft.dy - borderRadius);
    path.lineTo(bottomLeft.dx, bottomLeft.dy - borderRadius - borderLength);

    path.moveTo(bottomRight.dx - borderRadius, bottomRight.dy);
    path.lineTo(bottomRight.dx - borderRadius - borderLength, bottomRight.dy);
    path.moveTo(bottomRight.dx, bottomRight.dy - borderRadius);
    path.lineTo(bottomRight.dx, bottomRight.dy - borderRadius - borderLength);

    canvas.drawPath(path, borderPaint);
  }

  @override
  ShapeBorder scale(double t) => this;
}
