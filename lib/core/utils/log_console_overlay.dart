import 'package:flutter/material.dart';
import 'app_logger.dart';
import 'log_console_screen.dart';

class LogConsoleOverlay extends StatefulWidget {
  final Widget child;

  const LogConsoleOverlay({super.key, required this.child});

  @override
  State<LogConsoleOverlay> createState() => _LogConsoleOverlayState();
}

class _LogConsoleOverlayState extends State<LogConsoleOverlay> with SingleTickerProviderStateMixin {
  // Toạ độ bong bóng nổi
  double _x = 20.0;
  double _y = 200.0;

  bool _isDragging = false;
  bool _isShowingConsole = false;

  // Kích thước bong bóng nổi
  final double _bubbleSize = 54.0;

  @override
  void initState() {
    super.initState();
    // Đặt toạ độ ban đầu ở góc phải màn hình sau khi dựng khung hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      setState(() {
        _x = size.width - _bubbleSize - 16;
        _y = size.height * 0.75; // 3/4 màn hình
      });
    });
  }

  void _snapToEdge(Size screenSize) {
    setState(() {
      _isDragging = false;
      // Trái hoặc phải tuỳ khoảng cách bên nào gần hơn
      if (_x + (_bubbleSize / 2) < screenSize.width / 2) {
        _x = 16.0; // Snaps to left edge
      } else {
        _x = screenSize.width - _bubbleSize - 16.0; // Snaps to right edge
      }

      // Giới hạn y không bị chìm xuống thanh điều hướng hoặc tai thỏ
      final double topPadding = MediaQuery.of(context).padding.top + 40;
      final double bottomPadding = MediaQuery.of(context).padding.bottom + 60;
      _y = _y.clamp(topPadding, screenSize.height - _bubbleSize - bottomPadding);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          // 1. Ứng dụng chính của người dùng
          widget.child,

          // 2. Toàn bộ màn hình Log Console (hiển thị khi nhấn vào bong bóng)
          if (_isShowingConsole)
            Positioned.fill(
              child: WillPopScope(
                onWillPop: () async {
                  setState(() {
                    _isShowingConsole = false;
                  });
                  return false;
                },
                child: Navigator(
                  onGenerateRoute: (settings) => MaterialPageRoute(
                    builder: (context) => Scaffold(
                      body: Stack(
                        children: [
                          const LogConsoleScreen(),
                          Positioned(
                            top: MediaQuery.of(context).padding.top + 6,
                            left: 10,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.transparent), // Chỉ giữ vị trí
                              onPressed: null,
                            ),
                          ),
                          Positioned(
                            top: MediaQuery.of(context).padding.top + 10,
                            left: 14,
                            child: CircleAvatar(
                              backgroundColor: theme.brightness == Brightness.dark
                                  ? Colors.grey[850]
                                  : Colors.grey[200],
                              radius: 18,
                              child: IconButton(
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                                  size: 18,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isShowingConsole = false;
                                  });
                                },
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // 3. Bong bóng nổi điều khiển (Chỉ hiện khi `AppLogger.isConsoleOverlayVisible` bật)
          ValueListenableBuilder<bool>(
            valueListenable: AppLogger.isConsoleOverlayVisible,
            builder: (context, isVisible, _) {
              if (!isVisible || _isShowingConsole) return const SizedBox.shrink();

              return Positioned(
                left: _x,
                top: _y,
                child: GestureDetector(
                  onPanStart: (_) {
                    setState(() {
                      _isDragging = true;
                    });
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      _x += details.delta.dx;
                      _y += details.delta.dy;

                      // Tránh cho bong bóng văng ra ngoài khung hình trong lúc kéo
                      _x = _x.clamp(0.0, size.width - _bubbleSize);
                      _y = _y.clamp(0.0, size.height - _bubbleSize);
                    });
                  },
                  onPanEnd: (_) => _snapToEdge(size),
                  onTap: () {
                    setState(() {
                      _isShowingConsole = true;
                    });
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: _isDragging ? 0 : 250),
                    curve: Curves.easeOutBack,
                    width: _bubbleSize,
                    height: _bubbleSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF8B5CF6), // Neon Purple
                          Color(0xFF3B82F6), // Neon Blue
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withOpacity(0.4),
                          blurRadius: _isDragging ? 16 : 10,
                          spreadRadius: _isDragging ? 3 : 1,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Biểu tượng Bug/Insect phát sáng nhẹ
                          const Icon(
                            Icons.bug_report_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          // Badge báo hiệu số lượng lỗi hiện tại (nếu có lỗi)
                          ValueListenableBuilder<List<LogEntry>>(
                            valueListenable: AppLogger.logsNotifier,
                            builder: (context, logs, _) {
                              final errorCount = logs.where((e) => e.level == LogLevel.error).length;
                              if (errorCount == 0) return const SizedBox.shrink();

                              return Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEF4444), // Red
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    errorCount > 99 ? "99+" : "$errorCount",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
