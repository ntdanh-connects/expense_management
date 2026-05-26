import 'package:expense_management/shared/widgets/custom_sliding_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShellScreen extends StatelessWidget {
  // 1. Ní hứng lấy kiểu dữ liệu StatefulNavigationShell từ GoRouter truyền sang
  final StatefulNavigationShell navigationShell;

  const MainShellScreen({
    super.key,
    required this.navigationShell, // <-- Bắt buộc phải truyền vào khi gọi Class này
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 2. Thả nguyên cục navigationShell làm body (nó tự biết vẽ màn hình con của Tab đó lên)
      body: navigationShell, 
      
      bottomNavigationBar: CustomSlidingBottomBar(
        // 3. Chọc vào bên trong nó lấy index hiện tại (0, 1, 2, 3) để tô màu nút BottomBar
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          // 4. Gọi lệnh bẻ lái chuyển Tab lặn ngầm mà không mất State cũ
          navigationShell.goBranch(index);
        },
      ),
    );
  }
}