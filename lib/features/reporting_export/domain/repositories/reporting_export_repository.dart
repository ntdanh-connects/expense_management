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
    required String userCurrency,
    required dynamic ratesData,
    Map<String, String>? translations,
  });

  /// Generates a CSV report locally using transaction details.
  Future<File> generateLocalCsvReport({
    required DateTimeRange dateRange,
    String? walletId,
    String? categoryId,
    String? transactionType,
    bool isRaw = false,
  });

  /// Reads locally saved PDF and CSV reports from device directory.
  Future<List<File>> getLocalPdfHistory();

  /// Deletes a local PDF/CSV report file from disk.
  Future<void> deleteLocalPdf(String filePath);

  /// Deletes a remote report export record and file from the backend.
  Future<void> deleteRemoteExport(String exportId);

  /// Deletes all remote report export records and files from the backend.
  Future<void> clearAllRemoteExports();

  /// Downloads a file from remote server to local path.
  Future<void> downloadFile(String url, String savePath);
}
