import 'package:freezed_annotation/freezed_annotation.dart';
part 'network_failure.freezed.dart';

@freezed
class NetworkFailure with _$NetworkFailure{
  const factory NetworkFailure.serverError({required int code, required String message}) = _ServerError;
  const factory NetworkFailure.noInternet() = _NoInternet;
  const factory NetworkFailure.timeout() = _Timeout;
  const factory NetworkFailure.unauthorized() = _Unauthorized;
  const factory NetworkFailure.unknown({required String message}) = _Unknown;
}
