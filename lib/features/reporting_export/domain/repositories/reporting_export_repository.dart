import 'dart:io';
import 'package:flutter/material.dart';
import 'package:expense_management/features/reporting_export/data/models/report_export_dto.dart';

abstract class ReportingExportRepository {
  /// Triggers a background CSV export on the Laravel backend.
  Future<void> triggerRemoteExport({
    required String startDate,
    required String endDate,
    String? walletId,
    String? categoryId,
    String? transactionType,
  });

  /// Fetches the paginated history of reports generated on the backend.
  Future<List<ReportExportDto>> fetchRemoteExports({int page = 1});

  /// Generates a PDF report locally using statistical API endpoints.
  Future<File> generateLocalPdfReport({
    required String title,
    required DateTimeRange dateRange,
    String? walletId,
    String? categoryId,
    String? transactionType,
  });

  /// Reads locally saved PDF reports from device directory.
  Future<List<File>> getLocalPdfHistory();

  /// Deletes a local PDF report file from disk.
  Future<void> deleteLocalPdf(String filePath);
}
