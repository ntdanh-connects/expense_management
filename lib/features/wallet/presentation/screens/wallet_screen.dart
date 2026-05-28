import 'package:expense_management/core/theme/theme_provider.dart';
import 'package:expense_management/features/wallet/domain/wallet_notifier.dart';
import 'package:expense_management/features/wallet/presentation/widget/wallet_card_item.dart';
import 'package:expense_management/features/wallet/presentation/widget/wallet_empty_state.dart';
import 'package:expense_management/features/wallet/presentation/widget/wallet_screen_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart'; // Import extension của ní

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 📺 Watch trực tiếp luồng Stream trạng thái danh sách ví sống động
    final walletState = ref.watch(walletNotifierProvider);
    final appColors = context.colors;

    return Scaffold(
      backgroundColor: appColors.background, // ⚡ ĐỒNG BỘ THEME NỀN: Ép húp màu background từ Extension xịn của ní
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Giữ trong suốt để lướt sóng cho đẹp
        elevation: 0,
        title: Text(
          'Tài khoản & Ví',
          style: TextStyle(
            fontSize: 24, 
            fontWeight: FontWeight.bold, 
            color: appColors.textPrimary, // ⚡ ĐỒNG BỘ THEME CHỮ TIÊU ĐỀ
            letterSpacing: 0.5
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(
              Icons.blur_on_rounded, 
              color: appColors.primary, // ⚡ ĐỒNG BỘ THEME ICON: Húp màu primary tím/xanh phát sáng của ní
              size: 28
            ),
            onPressed: () {
              // Nhấn phát bốc đầu test tính năng đổi Theme mượt mà của ní nè!
              ref.read(themeProvider.notifier).toggleTheme();
            }, 
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: walletState.when(
        // 🔮 TRẠNG THÁI 1: CÓ TIỀN THẬT ĐẬP VỀ (RENDER DANH SÁCH VÍ SIÊU MƯỢT)
        data: (walletList) {
          if (walletList.isEmpty) return const WalletEmptyState();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: walletList.length,
            physics: const BouncingScrollPhysics(), 
            itemBuilder: (context, index) {
              final wallet = walletList[index];
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: WalletCardItem(
                  wallet: wallet,
                  onTap: () {
                    // Mốt làm GoRouter bẻ lái lướt chi tiết ví ở đây nhen
                  },
                ),
              );
            },
          );
        },
        // ⏳ TRẠNG THÁI 2: CHỜ ĐỌC ĐĨA LẦN ĐẦU -> KHUNG XƯƠNG SHIMMER QUÉT ÓNG ÁNH CHUẨN KẾ HOẠCH TỐI ƯU
        loading: () => const WalletShimmerLoading(),
        // 🚨 TRẠNG THÁI 3: TOONG PHIM NỔ LỖI MẠNG ĐOÀN TRÀNG
        error: (err, _) => Center(
          child: Text(
            'Lỗi hệ thống: $err', 
            style: TextStyle(color: appColors.expenseRed) // ⚡ ĐỒNG BỘ THEME: Húp màu Đỏ báo lỗi của ní
          ),
        ),
      ),
    );
  }
}