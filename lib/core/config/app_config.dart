class AppConfig {
  static const String baseUrl = String.fromEnvironment('BASE_URL', defaultValue: '');

  static const int connectTimeout = int.fromEnvironment('CONNECT_TIMEOUT', defaultValue: 30000);
  static const int receiveTimeout = int.fromEnvironment('RECEIVE_TIMEOUT', defaultValue: 30000);

  static bool enableLogging = baseUrl.contains('-dev') || baseUrl.contains('localhost'); 

  static void validateConfig() {
    if (baseUrl.isEmpty) {
      throw AssertionError(
        'Vui lòng chạy lệnh có kèm flag: --dart-define-from-file=.env.live || dev'
      );
    }
  }
}