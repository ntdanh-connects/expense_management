import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_management/shared/widgets/custom_sliding_bottom_bar.dart';
import 'package:expense_management/features/auth/auth_provider.dart'; // Import provider auth của ní vào

import 'package:expense_management/features/wallet/presentation/provider/wallet_notifier.dart';
import 'package:expense_management/features/transaction/presentation/providers/transaction_provider.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    //PHÁT LỆNH KÍCH NỔ ĐỒNG BỘ PROFILE LẶN NGẦM (BACKGROUND SYNC)
    // Khung xương vừa lên hình là âm thầm bắn API kéo data tươi về đè vào Drift DB
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authNotifierProvider.notifier).syncUserProfileImplicit();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Khi người dùng quay lại app, âm thầm làm mới dữ liệu ví và giao dịch mới nhất từ server
      ref.read(walletNotifierProvider.notifier).refreshWallets();
      ref.read(transactionListProvider.notifier).refreshTransactions(silent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, 
      body: widget.navigationShell,
      bottomNavigationBar: CustomSlidingBottomBar(
        currentIndex: widget.navigationShell.currentIndex,
        onTap: (index) {
          widget.navigationShell.goBranch(
            index,
            initialLocation: index == widget.navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}