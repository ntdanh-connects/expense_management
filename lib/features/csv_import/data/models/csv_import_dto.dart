import 'package:freezed_annotation/freezed_annotation.dart';

part 'csv_import_dto.freezed.dart';
part 'csv_import_dto.g.dart';

@freezed
abstract class CsvImportDto with _$CsvImportDto {
  @JsonSerializable(fieldRename: FieldRename.snake, checked: true)
  const factory CsvImportDto({
    required String id,
    required String userId,
    required String fileUrl,
    required String status,
    required int totalRows,
    required int successRows,
    required int failedRows,
    String? errorFileUrl,
    required String createdAt,
    required String updatedAt,
  }) = _CsvImportDto;

  factory CsvImportDto.fromJson(Map<String, dynamic> json) =>
      _$CsvImportDtoFromJson(json);
}
