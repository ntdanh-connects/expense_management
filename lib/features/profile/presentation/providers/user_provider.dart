import 'package:expense_management/core/config/app_config.dart';
import 'package:expense_management/features/auth/presentation/providers/auth_provider.dart';
import 'package:expense_management/features/profile/domain/di/domain_providers.dart';
export 'package:expense_management/features/profile/domain/di/domain_providers.dart';
import 'package:expense_management/features/profile/data/models/preference_options_dto.dart';
import 'package:expense_management/features/profile/data/models/exchange_rates_dto.dart';
import 'package:expense_management/shared/domain/user_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider cung cấp thông tin người dùng hiện tại từ trạng thái đăng nhập chung.
final currentUserProvider = Provider<UserEntity?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.maybeWhen(
    authenticated: (user) => user,
    orElse: () => null,
  );
});

/// Provider xác định công cụ nhà phát triển có được phép hiển thị/hoạt động hay không
final developerToolsEnabledProvider = Provider<bool>((ref) {
  return AppConfig.enableLogging;
});

final preferenceOptionsProvider = FutureProvider<PreferenceOptionsDto>((ref) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getPreferenceOptions();
});

final exchangeRatesProvider = FutureProvider<ExchangeRatesDto>((ref) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getExchangeRates();
});