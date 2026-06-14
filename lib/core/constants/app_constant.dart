import 'package:timezone/timezone.dart' as tz;

class AppConstant {
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';

  static const List<String> currencies = ['VND', 'USD', 'EUR', 'JPY', 'GBP'];
  
  static const List<Map<String, String>> timezones = [
    {'value': 'Asia/Ho_Chi_Minh', 'name': 'Asia/Ho_Chi_Minh (UTC+7)'},
    {'value': 'Asia/Singapore', 'name': 'Asia/Singapore (UTC+8)'},
    {'value': 'Asia/Tokyo', 'name': 'Asia/Tokyo (UTC+9)'},
    {'value': 'UTC', 'name': 'UTC (UTC+0)'},
    {'value': 'Europe/London', 'name': 'Europe/London (UTC+0)'},
    {'value': 'America/New_York', 'name': 'America/New_York (UTC-5)'},
    {'value': 'America/Los_Angeles', 'name': 'America/Los_Angeles (UTC-8)'},
  ];

  static String getCurrencySymbol(String? currencyCode) {
    if (currencyCode == null) return 'đ';
    switch (currencyCode.toUpperCase()) {
      case 'VND':
        return 'đ';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'JPY':
        return '¥';
      case 'GBP':
        return '£';
      default:
        return 'đ';
    }
  }

  static String formatMoney(double value, [String? currencyCode]) {
    final String code = (currencyCode ?? 'VND').toUpperCase();
    final int decimals = (code == 'VND' || code == 'JPY') ? 0 : 2;
    final bool isNegative = value < 0;
    final double absValue = value.abs();
    final String sign = isNegative ? '-' : '';
    
    if (decimals == 0) {
      RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
      String mathFunc(Match match) => '${match[1]}.';
      final String formatted = absValue.toStringAsFixed(0).replaceAllMapped(reg, mathFunc);
      return '$sign$formatted';
    } else {
      final parts = absValue.toStringAsFixed(2).split('.');
      final String wholePart = parts[0];
      final String decimalPart = parts[1];
      
      RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
      String mathFunc(Match match) => '${match[1]},';
      final String formattedWhole = wholePart.replaceAllMapped(reg, mathFunc);
      return '$sign$formattedWhole.$decimalPart';
    }
  }

  static DateTime adjustOldTransactionDate(DateTime originalDate, String? timezoneStr, [DateTime? createdAt]) {
    final cutoff = DateTime.utc(2026, 6, 8, 8, 0, 0); // 08:00 UTC (15:00 VN local)
    
    // Chỉ điều chỉnh nếu giao dịch thực sự được tạo trước mốc thời gian sửa lỗi
    final bool shouldAdjust = createdAt != null && createdAt.isBefore(cutoff);
    
    if (shouldAdjust) {
      try {
        final tzName = timezoneStr ?? 'Asia/Ho_Chi_Minh';
        final location = tz.getLocation(tzName);
        
        // Ta tạo TZDateTime từ các thành phần của originalDate trong múi giờ đó
        final tzDateTime = tz.TZDateTime(
          location,
          originalDate.year,
          originalDate.month,
          originalDate.day,
          originalDate.hour,
          originalDate.minute,
          originalDate.second,
          originalDate.millisecond,
          originalDate.microsecond,
        );
        // Trả về UTC của TZDateTime này (đã trừ offset)
        return tzDateTime.toUtc();
      } catch (_) {
        // fallback
      }
    }
    
    // Đối với giao dịch mới (hoặc đã được lưu UTC chính xác có isUtc = true)
    // Nếu nó không phải UTC thì đưa về UTC không thay đổi thành phần giờ phút giây
    if (!originalDate.isUtc) {
      return DateTime.utc(
        originalDate.year,
        originalDate.month,
        originalDate.day,
        originalDate.hour,
        originalDate.minute,
        originalDate.second,
        originalDate.millisecond,
        originalDate.microsecond,
      );
    }
    
    return originalDate;
  }
}