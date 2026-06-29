import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:expense_management/features/transaction/domain/entities/transaction_entity.dart';
import 'package:expense_management/features/profile/data/models/category_dto.dart';
import 'package:expense_management/features/profile/presentation/widgets/category_ui_constants.dart';
import 'package:expense_management/shared/widgets/image_overlay_viewer.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';

class TransactionDetailFields extends ConsumerWidget {
  final TransactionEntity transaction;
  final TextEditingController titleController;
  final TextEditingController notesController;
  final CategoryDto? selectedCategory;
  final List<File> selectedImages;
  final VoidCallback? onCategoryTap;
  final String formattedDateTime;
  final VoidCallback onPickImage;
  final ValueChanged<File> onRemoveLocalImage;

  const TransactionDetailFields({
    super.key,
    required this.transaction,
    required this.titleController,
    required this.notesController,
    required this.selectedCategory,
    required this.selectedImages,
    required this.onCategoryTap,
    required this.formattedDateTime,
    required this.onPickImage,
    required this.onRemoveLocalImage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          controller: titleController,
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
          onTap: transaction.isTransferLocked ? null : onCategoryTap,
          child: Opacity(
            opacity: transaction.isTransferLocked ? 0.6 : 1.0,
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
                    backgroundColor: CategoryUIConstants.getColorFromHex(
                      selectedCategory?.color,
                      categoryName: selectedCategory?.name,
                    ).withOpacity(0.15),
                    child: Icon(
                      CategoryUIConstants.getIconData(
                        selectedCategory?.icon,
                        categoryName: selectedCategory?.name,
                      ),
                      color: CategoryUIConstants.getColorFromHex(
                        selectedCategory?.color,
                        categoryName: selectedCategory?.name,
                      ),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      (selectedCategory?.name ?? transaction.categoryName)
                              ?.tr(ref) ??
                          'uncategorized'.tr(ref),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (!transaction.isTransferLocked)
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: colors.textSecondary.withOpacity(0.6),
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
                  formattedDateTime,
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

        if (transaction.payeeName != null && transaction.payeeName!.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            'qr_transfer_recipient'.tr(ref),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      color: colors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        transaction.payeeName!,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (transaction.payeeAccountNumber != null &&
                    transaction.payeeAccountNumber!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.credit_card_rounded,
                        color: colors.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          transaction.payeeAccountNumber!,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (transaction.payeeBankName != null &&
                    transaction.payeeBankName!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_rounded,
                        color: colors.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          transaction.payeeBankName!,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],

        if (transaction.senderName != null && transaction.senderName!.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            'qr_transfer_sender'.tr(ref),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.person_rounded,
                      color: colors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        transaction.senderName!,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (transaction.senderWalletName != null &&
                    transaction.senderWalletName!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_rounded,
                        color: colors.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          transaction.senderWalletName!,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (transaction.senderIdentifier != null &&
                    transaction.senderIdentifier!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.fingerprint_rounded,
                        color: colors.textSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'ID: ${transaction.senderIdentifier!}',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],

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
          controller: notesController,
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
                onTap: onPickImage,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colors.textSecondary.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo_rounded,
                        color: colors.textSecondary.withOpacity(0.5),
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
              ...transaction.attachmentUrls.map(
                (url) {
                  final heroTag = 'tx_attachment_${transaction.id}_$url';
                  return GestureDetector(
                    onTap: () => ImageOverlayViewer.show(
                      context,
                      imageUrl: url,
                      heroTag: heroTag,
                    ),
                    child: Hero(
                      tag: heroTag,
                      child: Container(
                        width: 120,
                        height: 120,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: colors.textSecondary.withOpacity(0.1),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (context, url, error) {
                              return Container(
                                color: colors.surface,
                                child: Icon(
                                  Icons.broken_image_rounded,
                                  color: colors.textSecondary.withOpacity(0.5),
                                  size: 32,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              ...selectedImages.map(
                (file) {
                  final heroTag = 'tx_local_image_${file.path}';
                  return Stack(
                    children: [
                      GestureDetector(
                        onTap: () => ImageOverlayViewer.show(
                          context,
                          imageFile: file,
                          heroTag: heroTag,
                        ),
                        child: Hero(
                          tag: heroTag,
                          child: Container(
                            width: 120,
                            height: 120,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: colors.textSecondary.withOpacity(0.1),
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
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 14,
                        child: GestureDetector(
                          onTap: () => onRemoveLocalImage(file),
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
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
