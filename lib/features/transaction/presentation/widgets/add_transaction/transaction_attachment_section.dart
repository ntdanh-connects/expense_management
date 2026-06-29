import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/core/router/app_route.dart';

class TransactionAttachmentSection extends ConsumerWidget {
  final File? imageFile;
  final bool isLoading;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;
  final ValueChanged<Map<String, dynamic>> onOcrResult;

  const TransactionAttachmentSection({
    super.key,
    required this.imageFile,
    required this.isLoading,
    required this.onPickImage,
    required this.onRemoveImage,
    required this.onOcrResult,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              onTap: onPickImage,
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

            if (imageFile != null) ...[
              const SizedBox(width: 16),
              // Preview Card with OCR Helper Button
              Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          image: DecorationImage(
                            image: FileImage(imageFile!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      if (isLoading)
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
                          onTap: isLoading ? null : onRemoveImage,
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
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: isLoading
                        ? null
                        : () async {
                            final result = await context.push(
                              RoutePaths.ocrHelper,
                              extra: imageFile!.path,
                            );
                            if (result != null &&
                                result is Map<String, dynamic>) {
                              onOcrResult(result);
                            }
                          },
                    icon: const Icon(Icons.auto_awesome_rounded, size: 14),
                    label: const Text(
                      'Đọc hóa đơn',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }
}
