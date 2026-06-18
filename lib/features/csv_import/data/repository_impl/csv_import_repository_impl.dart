import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:expense_management/features/csv_import/data/datasource/remote/csv_import_api_service.dart';
import 'package:expense_management/features/csv_import/data/models/csv_import_dto.dart';
import 'package:expense_management/features/csv_import/domain/repositories/csv_import_repository.dart';

class CsvImportRepositoryImpl implements CsvImportRepository {
  final CsvImportApiService _apiService;

  CsvImportRepositoryImpl(this._apiService);

  @override
  Future<void> importCsv(File file) async {
    final filename = file.path.split('/').last.split('\\').last;
    final multipartFile = await MultipartFile.fromFile(
      file.path,
      filename: filename,
      contentType: MediaType('text', 'csv'),
    );

    await _apiService.importCsv(multipartFile);
  }

  @override
  Future<List<CsvImportDto>> fetchImports({int page = 1}) async {
    final response = await _apiService.listImports(page);
    final dataList = response['data'] as List;
    return dataList
        .map((json) => CsvImportDto.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
