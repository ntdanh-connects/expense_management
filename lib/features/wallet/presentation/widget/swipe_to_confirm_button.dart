import 'package:flutter/material.dart';

class SwipeToConfirmButton extends StatefulWidget {
  final VoidCallback onConfirmed;
  final String text;
  final Color activeColor;

  const SwipeToConfirmButton({
    super.key,
    required this.onConfirmed,
    this.text = 'Trượt để tạo ví',
    required this.activeColor,
  });

  @override
  State<SwipeToConfirmButton> createState() => _SwipeToConfirmButtonState();
}

class _SwipeToConfirmButtonState extends State<SwipeToConfirmButton> {
  double _dragPosition = 0.0;
  bool _isConfirmed = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDrag = constraints.maxWidth - 54.0; // Khớp kích cỡ vòng tròn trượt (50px + border/padding)

        return Container(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.activeColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: widget.activeColor.withOpacity(0.24),
              width: 1.5,
            ),
          ),
          child: Stack(
            children: [
              // 📝 Text hướng dẫn vuốt hiển thị chìm chính giữa
              Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: _dragPosition > (maxDrag / 2) ? 0.2 : 0.8,
                  child: Text(
                    _isConfirmed ? 'Đang thực hiện...' : widget.text,
                    style: TextStyle(
                      color: widget.activeColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              
              // 🕹️ Nút tròn kéo có bo tròn mượt mà và bóng mờ
              Positioned(
                left: _dragPosition + 2,
                top: 2,
                bottom: 2,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_isConfirmed) return;
                    setState(() {
                      _dragPosition += details.delta.dx;
                      if (_dragPosition < 0.0) _dragPosition = 0.0;
                      if (_dragPosition > maxDrag - 4) _dragPosition = maxDrag - 4;
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_isConfirmed) return;
                    if (_dragPosition >= maxDrag - 8) {
                      setState(() {
                        _isConfirmed = true;
                        _dragPosition = maxDrag - 4;
                      });
                      widget.onConfirmed();
                    } else {
                      // Trượt chưa tới đích thì tự đàn hồi nảy về điểm xuất phát
                      setState(() {
                        _dragPosition = 0.0;
                      });
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 50),
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: widget.activeColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.activeColor.withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(1, 2),
                        )
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
