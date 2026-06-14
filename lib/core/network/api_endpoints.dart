class ApiEndpoints {
  static const String dashboardSummary = 'api/dashboard/summary';
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
  static const String showTransaction = 'api/transactions/{id}';
  static const String updateTransaction = 'api/transactions/{id}';
  static const String deleteTransaction = 'api/transactions/{id}';
  static const String recurringRules = 'api/recurring-rules';
  static const String recurringRulesCreate = 'api/recurring-rules';
  static const String recurringRulesUpdate = 'api/recurring-rules/{id}';
  static const String recurringRulesDelete = 'api/recurring-rules/{id}';
  static const String recurringRulesToggle = 'api/recurring-rules/{id}/toggle';

  // Module 6: Reports
  static const String reportsSummary = 'api/reports/summary';
  static const String reportsCategories = 'api/reports/categories';
  static const String reportsTrends = 'api/reports/trends';

  // Module 7: Exports
  static const String exportTransactions = 'api/transactions/export';
  static const String listExports = 'api/transactions/exports';

  // QR Transfer & Payees
  static const String qrDecode = 'api/qr/decode';
  static const String qrGenerateMyQr = 'api/qr/generate-my-qr';
  static const String qrTransfer = 'api/qr/transfer';
  static const String payees = 'api/payees';
  static const String deletePayee = 'api/payees';
  // Module 8: Notifications
  static const String notifications = 'api/notifications';
  static const String notificationRead = 'api/notifications/{id}/read';
  static const String notificationReadAll = 'api/notifications/read-all';
  static const String notificationDelete = 'api/notifications/{id}';
  static const String notificationPreferences = 'api/notifications/preferences';
}