import 'package:freezed_annotation/freezed_annotation.dart';

part 'base_response_dto.g.dart';

@JsonSerializable(genericArgumentFactories: true)//Map Json List or Object to Object Dart
class BaseResponseDto<T> {
  final String message;
  final T data;

  BaseResponseDto({required this.message, required this.data});

  factory BaseResponseDto.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$BaseResponseDtoFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) => 
      _$BaseResponseDtoToJson(this, toJsonT);
}
