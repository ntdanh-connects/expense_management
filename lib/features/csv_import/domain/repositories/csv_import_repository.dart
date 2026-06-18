import 'dart:io';
import 'package:expense_management/features/csv_import/data/models/csv_import_dto.dart';

abstract class CsvImportRepository {
  /// Uploads and schedules a CSV file import on the backend.
  Future<void> importCsv(File file);

  /// Fetches history of CSV imports.
  Future<List<CsvImportDto>> fetchImports({int page = 1});
}
