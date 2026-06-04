class ApiEndpoints {
  static const String login = 'api/login';
  static const String refreshToken = 'api/refresh-token';
  static const String register = 'api/register';
  static const String profile = 'api/user/profile';
  static const String updateProfile = 'api/user/profile';
  static const String updateAvatar = 'api/user/avatar';
  static const String socialLogin = 'api/auth/social';
  static const String linkSocial = 'api/auth/link-social';
  static const String wallets = 'api/wallets';
  static const String logout = 'api/logout';
  static const String logoutAll = 'api/logout-all';
  static const String changePassword = 'api/user/change-password';
  static const String deleteAccount = 'api/user';
  static const String forgotPassword = 'api/auth/forgot-password';
  static const String transfer = 'api/wallets/transfer';
  static const String transfers = 'api/wallets/transfers';
  static const String preferenceOptions = 'api/user/preferences/options';
  static const String exchangeRates = 'api/exchange-rates';
  static const String categories = 'api/categories';
  static const String categoryIcons = 'api/categories/icons';
  static const String mergeCategories = 'api/categories/merge';
  static const String updateCategory = 'api/categories/{id}';
  static const String deleteCategory = 'api/categories/{id}';
  static const String transactions = 'api/transactions';
  static const String showTransactions = 'api/transactions';
}