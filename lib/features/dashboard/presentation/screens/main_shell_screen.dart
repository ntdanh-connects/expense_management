import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_management/shared/widgets/custom_sliding_bottom_bar.dart';
import 'package:expense_management/features/auth/auth_provider.dart'; // Import provider auth của ní vào

class MainShellScreen extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  
  @override
  void initState() {
    super.initState();
    //PHÁT LỆNH KÍCH NỔ ĐỒNG BỘ PROFILE LẶN NGẦM (BACKGROUND SYNC)
    // Khung xương vừa lên hình là âm thầm bắn API kéo data tươi về đè vào Drift DB
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authNotifierProvider.notifier).syncUserProfileImplicit();
    });
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