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
}