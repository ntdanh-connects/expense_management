enum Environment { dev, staging, prod }

class AppConfig {
  static const String _envString = String.fromEnvironment('ENV', defaultValue: 'dev');

  static Environment get environment {
    switch (_envString) {
      case 'prod':
        return Environment.prod;
      case 'staging':
        return Environment.staging;
      default:
        return Environment.dev;
    }
  }

  static String get baseUrl {
    switch (environment) {
      case Environment.prod:
        return 'https://expense-management-api-bw81.onrender.com/'; // Domain Deploy thật
      case Environment.staging:
        return 'https://expense-management-api-bw81.onrender.com/'; // Domain Test
      case Environment.dev:
        //emulator
        return 'https://expense-management-api-bw81.onrender.com/'; 
    }
  }

  static const bool enableLogging = _envString != 'prod'; 
}