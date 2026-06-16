import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expense_management/core/storage/secure_storage_service.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:local_auth/local_auth.dart';
import 'package:expense_management/core/language/app_provider.dart';

class SecurityState {
  final bool isPinEnabled;
  final bool isBiometricEnabled;
  final bool isLocked;

  SecurityState({
    required this.isPinEnabled,
    required this.isBiometricEnabled,
    required this.isLocked,
  });

  SecurityState copyWith({
    bool? isPinEnabled,
    bool? isBiometricEnabled,
    bool? isLocked,
  }) {
    return SecurityState(
      isPinEnabled: isPinEnabled ?? this.isPinEnabled,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}

class SecurityNotifier extends StateNotifier<SecurityState> {
  final SecureStorageService _storage;
  final Ref _ref;
  final LocalAuthentication _localAuth = LocalAuthentication();

  static const String _keyIsPinEnabled = 'security_is_pin_enabled';
  static const String _keyPinCode = 'security_pin_code';
  static const String _keyIsBiometricEnabled = 'security_is_biometric_enabled';

  SecurityNotifier(this._storage, this._ref)
      : super(SecurityState(
          isPinEnabled: false,
          isBiometricEnabled: false,
          isLocked: false,
        )) {
    _init();
  }

  Future<void> _init() async {
    final isPinEnabledStr = await _storage.get(key: _keyIsPinEnabled);
    final isBiometricEnabledStr = await _storage.get(key: _keyIsBiometricEnabled);

    final isPinEnabled = isPinEnabledStr == 'true';
    final isBiometricEnabled = isBiometricEnabledStr == 'true';

    state = SecurityState(
      isPinEnabled: isPinEnabled,
      isBiometricEnabled: isBiometricEnabled,
      isLocked: isPinEnabled, // Nếu đã bật PIN thì lúc khởi động app mặc định là Khóa
    );
  }

  Future<bool> verifyPin(String inputPin) async {
    final savedPin = await _storage.get(key: _keyPinCode);
    if (savedPin == inputPin) {
      state = state.copyWith(isLocked: false);
      return true;
    }
    return false;
  }

  Future<void> enablePin(String pin) async {
    await _storage.save(key: _keyPinCode, value: pin);
    await _storage.save(key: _keyIsPinEnabled, value: 'true');
    state = state.copyWith(isPinEnabled: true, isLocked: false);
  }

  Future<void> disablePin() async {
    await _storage.delete(key: _keyPinCode);
    await _storage.save(key: _keyIsPinEnabled, value: 'false');
    await _storage.save(key: _keyIsBiometricEnabled, value: 'false');
    state = SecurityState(
      isPinEnabled: false,
      isBiometricEnabled: false,
      isLocked: false,
    );
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.save(key: _keyIsBiometricEnabled, value: enabled ? 'true' : 'false');
    state = state.copyWith(isBiometricEnabled: enabled);
  }

  void lock() {
    if (state.isPinEnabled) {
      state = state.copyWith(isLocked: true);
    }
  }

  void unlock() {
    state = state.copyWith(isLocked: false);
  }

  Future<void> clearSecurityData() async {
    await _storage.delete(key: _keyPinCode);
    await _storage.delete(key: _keyIsPinEnabled);
    await _storage.delete(key: _keyIsBiometricEnabled);
    state = SecurityState(
      isPinEnabled: false,
      isBiometricEnabled: false,
      isLocked: false,
    );
  }

  // local_auth helper functions
  Future<bool> checkBiometricSupport() async {
    try {
      final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      return canAuthenticate;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    if (!state.isPinEnabled || !state.isBiometricEnabled) return false;
    try {
      final translations = _ref.read(translationsProvider);
      final localizedReason = translations['unlock_with_biometric'] ?? 'Quét vân tay hoặc FaceID để mở khóa ứng dụng';
      final authenticated = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Cho phép cả mã PIN hệ thống dự phòng nếu FaceID lỗi
        ),
      );
      if (authenticated) {
        unlock();
      }
      return authenticated;
    } catch (_) {
      return false;
    }
  }
}

final securityNotifierProvider = StateNotifierProvider<SecurityNotifier, SecurityState>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  return SecurityNotifier(storage, ref);
});
