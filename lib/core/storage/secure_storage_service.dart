import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage();

  Future<void> save({required String key, required String value}) async {
    return await _storage.write(key: key, value: value);
  }

  Future<String?> get({required String key}) async {
    return await _storage.read(key: key);
  }

  Future<void> delete({required String key}) async {
    return _storage.delete(key: key);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});
