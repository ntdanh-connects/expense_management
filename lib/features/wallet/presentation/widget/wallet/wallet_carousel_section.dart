import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/wallet/domain/entities/wallet_entity.dart';
import 'package:expense_management/core/constants/app_constant.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'wallet_card_item.dart';
import '../shared/dashed_border_painter.dart';

class WalletCarouselSection extends ConsumerWidget {
  final List<WalletEntity> displayedWallets;

  const WalletCarouselSection({
    super.key,
    required this.displayedWallets,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: displayedWallets.length + 1,
        itemBuilder: (context, index) {
          if (index < displayedWallets.length) {
            final wallet = displayedWallets[index];
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: WalletCardItem(
                wallet: wallet,
                currencySymbol: AppConstant.getCurrencySymbol(
                  wallet.currencyCode,
                ),
                onTap: () => context.push('/add-wallet', extra: wallet),
              ),
            );
          } else {
            return _buildAddWalletCard(context, colors, ref);
          }
        },
      ),
    );
  }

  Widget _buildAddWalletCard(
    BuildContext context,
    AppColorsExtension colors,
    WidgetRef ref,
  ) {
    return CustomPaint(
      painter: DashedBorderPainter(
        color: colors.primary.withOpacity(0.4),
        borderRadius: 24,
      ),
      child: GestureDetector(
        onTap: () => context.push('/add-wallet'),
        child: Container(
          width: 320,
          height: 180,
          decoration: BoxDecoration(
            color: colors.primary.withOpacity(0.04),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.primary, width: 2.0),
                ),
                child: Icon(Icons.add, color: colors.primary, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                'add_new_wallet'.tr(ref),
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
