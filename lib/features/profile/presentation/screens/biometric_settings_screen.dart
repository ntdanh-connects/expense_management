import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/theme/app_colors.dart';

class BiometricSettingsScreen extends ConsumerStatefulWidget {
  const BiometricSettingsScreen({super.key});

  @override
  ConsumerState<BiometricSettingsScreen> createState() => _BiometricSettingsScreenState();
}

class _BiometricSettingsScreenState extends ConsumerState<BiometricSettingsScreen> {
  // Trạng thái bật/tắt các tính năng sinh trắc học (Sẽ kết nối với Local Storage sau)
  bool _isLoginEnabled = false;
  bool _isTransactionEnabled = false;
  bool _isLoading = false;

  // Hàm xử lý mô phỏng khi người dùng bật tính năng (yêu cầu quét vân tay/khuôn mặt)
  void _toggleLoginBiometric(bool value) async {
    if (value) {
      setState(() => _isLoading = true);
      
      // Mô phỏng hiệu ứng chờ quét sinh trắc học của hệ điều hành trong 1.5 giây
      await Future.delayed(const Duration(milliseconds: 1500));
      
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoginEnabled = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã kích hoạt đăng nhập sinh trắc học thành công!'),
          backgroundColor: context.colors.incomeGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() {
        _isLoginEnabled = false;
      });
    }
  }

  void _toggleTransactionBiometric(bool value) async {
    if (value) {
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(milliseconds: 1200));
      
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isTransactionEnabled = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã kích hoạt xác thực giao dịch bằng sinh trắc học!'),
          backgroundColor: context.colors.incomeGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() {
        _isTransactionEnabled = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: colors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Cài đặt sinh trắc học',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                
                // --- 1. KHU VỰC BIỂU TƯỢNG TRUNG TÂM (HEADER ICON) ---
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: colors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.primary.withOpacity(0.2), width: 2),
                        ),
                        child: Icon(
                          Icons.fingerprint_rounded,
                          size: 72,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Xác thực an toàn',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sử dụng vân tay hoặc khuôn mặt để bảo mật ứng dụng',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // --- TỬ ĐỀ MỤC ---
                Text(
                  'CẤU HÌNH TÍNH NĂNG',
                  style: TextStyle(
                    color: colors.textSecondary.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),

                // --- 2. DANH SÁCH TÙY CHỌN BẬT/TẮT (LIST CONFIG) ---
                Container(
                  decoration: BoxDecoration(
                    color: colors.authCardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.textSecondary.withOpacity(0.08)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      // Lựa chọn 1: Đăng nhập nhanh
                      _buildBiometricTile(
                        context: context,
                        icon: Icons.lock_open_rounded,
                        iconColor: colors.profileLimit,
                        title: 'Đăng nhập ứng dụng',
                        subtitle: 'Mở khóa ứng dụng không cần nhập mật khẩu',
                        value: _isLoginEnabled,
                        onChanged: _toggleLoginBiometric,
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Divider(color: colors.textSecondary.withOpacity(0.1), height: 1),
                      ),

                      // Lựa chọn 2: Xác thực giao dịch quan trọng
                      _buildBiometricTile(
                        context: context,
                        icon: Icons.gpp_good_rounded,
                        iconColor: colors.incomeGreen,
                        title: 'Xác thực giao dịch',
                        subtitle: 'Yêu cầu vân tay khi luân chuyển ví, hũ',
                        value: _isTransactionEnabled,
                        onChanged: _toggleTransactionBiometric,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // --- 3. KHU VỰC HƯỚNG DẪN & LƯU Ý BẢO MẬT ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? colors.surface.withOpacity(0.4) : Colors.amber.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? colors.textSecondary.withOpacity(0.1) : Colors.amber.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded, 
                        color: isDark ? colors.textSecondary : Colors.amber[800], 
                        size: 20
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lưu ý bảo mật',
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ứng dụng sử dụng trực tiếp dữ liệu sinh trắc học được cấu hình sẵn trên thiết bị của bạn. Chúng tôi tuyệt đối không lưu trữ thông tin nhận diện này trên hệ thống máy chủ bên ngoài.',
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- 4. HIỆU ỨNG KHÓA MÀN HÌNH KHI ĐANG QUÉT SINH TRẮC HỌC (LOADING OVERLAY) ---
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: colors.primary,
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Đang xác thực thiết bị...',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Widget con phụ trách vẽ từng dòng cấu hình bật/tắt chuyên nghiệp
  Widget _buildBiometricTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colors.textSecondary.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: colors.primary,
            activeTrackColor: colors.primary.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}