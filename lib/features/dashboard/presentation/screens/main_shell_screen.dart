import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_management/shared/widgets/custom_sliding_bottom_bar.dart';
import 'package:expense_management/features/auth/presentation/providers/auth_provider.dart'; // Import provider auth của ní vào
import 'package:expense_management/features/analytic/presentation/providers/report_providers.dart';
import 'package:expense_management/features/budget/presentation/provider/budget_provider.dart';
import 'package:expense_management/features/budget/data/models/budget_dto.dart';


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
      // Kích hoạt kiểm tra giới hạn ngân sách ngay lập tức khi vào Main Shell
      ref.read(currentMonthBudgetsProvider.future).catchError((_) => <BudgetDto>[]);
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
      ref.read(filteredTransactionListProvider.notifier).refreshTransactions(silent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          extendBody: true, 
          body: widget.navigationShell,
          bottomNavigationBar: CustomSlidingBottomBar(
            currentIndex: widget.navigationShell.currentIndex,
            onTap: (index) {
              if (index != 2) {
                // Reset sub-tab of Analytics screen back to 'statistics' when switching away
                ref.read(selectedAnalyticTabProvider.notifier).state = 'statistics';
              }
              if (index == 1) {
                // Lịch sử giao dịch tự động làm mới ngầm khi chuyển tab
                ref.read(filteredTransactionListProvider.notifier).refreshTransactions(silent: true);
              }
              widget.navigationShell.goBranch(
                index,
                initialLocation: index == widget.navigationShell.currentIndex,
              );
            },
          ),
        ),
        const FloatingAiButton(),
      ],
    );
  }
}

class FloatingAiButton extends StatefulWidget {
  const FloatingAiButton({super.key});

  @override
  State<FloatingAiButton> createState() => _FloatingAiButtonState();
}

class _FloatingAiButtonState extends State<FloatingAiButton> {
  bool _isInitialized = false;
  Offset offset = Offset.zero;
  bool isDragging = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final mediaQuery = MediaQuery.of(context);
      // Đặt ở cạnh phải màn hình, cách mép dưới khoảng 200px
      offset = Offset(
        mediaQuery.size.width - 72.0,
        mediaQuery.size.height - 200.0,
      );
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;

    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: GestureDetector(
        onPanStart: (_) => setState(() => isDragging = true),
        onPanUpdate: (details) {
          setState(() {
            double newX = offset.dx + details.delta.dx;
            double newY = offset.dy + details.delta.dy;

            // Giới hạn không cho kéo ra ngoài màn hình
            newX = newX.clamp(0.0, size.width - 56.0);
            newY = newY.clamp(
              mediaQuery.padding.top + 10.0,
              size.height - mediaQuery.padding.bottom - 90.0,
            );

            offset = Offset(newX, newY);
          });
        },
        onPanEnd: (_) {
          setState(() => isDragging = false);
          // Hút về cạnh gần nhất (trái hoặc phải)
          final screenWidth = mediaQuery.size.width;
          double targetX = offset.dx < (screenWidth / 2) ? 16.0 : (screenWidth - 72.0);
          
          setState(() {
            offset = Offset(targetX, offset.dy);
          });
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [
                Color(0xFF9C27B0), // Purple
                Color(0xFFE91E63), // Pink
                Color(0xFF00BCD4), // Cyan
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE91E63).withOpacity(0.4),
                blurRadius: isDragging ? 18 : 12,
                spreadRadius: isDragging ? 2 : 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => context.push('/ai-assistant'),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }
}