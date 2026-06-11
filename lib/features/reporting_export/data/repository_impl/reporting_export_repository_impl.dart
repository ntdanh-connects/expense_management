import 'dart:io';
import 'package:flutter/material.dart';
import 'package:expense_management/features/reporting_export/data/datasource/remote/reporting_export_api_service.dart';
import 'package:expense_management/features/reporting_export/data/models/report_export_dto.dart';
import 'package:expense_management/features/reporting_export/domain/repositories/reporting_export_repository.dart';
import 'package:expense_management/features/analytic/domain/repository/report_repository.dart';
import 'package:expense_management/features/transaction/domain/repositories/transaction_repository.dart';
import 'package:expense_management/features/reporting_export/presentation/utils/pdf_report_generator.dart';
import 'package:intl/intl.dart';

class ReportingExportRepositoryImpl implements ReportingExportRepository {
  final ReportingExportApiService apiService;
  final ReportRepository reportRepository;
  final TransactionRepository transactionRepository;

  ReportingExportRepositoryImpl({
    required this.apiService,
    required this.reportRepository,
    required this.transactionRepository,
  });

  @override
  Future<void> triggerRemoteExport({
    required String startDate,
    required String endDate,
    String? walletId,
    String? categoryId,
    String? transactionType,
  }) async {
    await apiService.requestExport(
      startDate: startDate,
      endDate: endDate,
      walletId: walletId,
      categoryId: categoryId,
      transactionType: transactionType,
    );
  }

  @override
  Future<List<ReportExportDto>> fetchRemoteExports({int page = 1}) async {
    final response = await apiService.listExports(page: page);
    final data = response['data'] as List;
    return data.map((json) => ReportExportDto.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<File> generateLocalPdfReport({
    required String title,
    required DateTimeRange dateRange,
    String? walletId,
    String? categoryId,
    String? transactionType,
    required String userCurrency,
    required dynamic ratesData,
    Map<String, String>? translations,
  }) async {
    // 1. Fetch Statistics Summary
    final summary = await reportRepository.getSummary(
      startDate: dateRange.start,
      endDate: dateRange.end,
      walletId: walletId,
    );

    // 2. Fetch Category statistics
    final expenseCategories = await reportRepository.getCategories(
      startDate: dateRange.start,
      endDate: dateRange.end,
      type: 'expense',
    );

    // 3. Fetch Transactions list
    final transactionsResult = await transactionRepository.getTransactions(
      startDate: DateFormat('yyyy-MM-dd').format(dateRange.start),
      endDate: DateFormat('yyyy-MM-dd').format(dateRange.end),
      walletId: walletId,
      categoryId: categoryId,
      type: transactionType,
      perPage: 100, // Fetch top 100 transactions to display in PDF cleanly
    );

    // 4. Generate the PDF Document
    final file = await PdfReportGenerator.generate(
      title: title,
      startDate: dateRange.start,
      endDate: dateRange.end,
      summary: summary,
      expenseCategories: expenseCategories,
      transactions: transactionsResult.items,
      userCurrency: userCurrency,
      ratesData: ratesData,
      translations: translations,
    );

    return file;
  }

  @override
  Future<List<File>> getLocalPdfHistory() async {
    final dir = await PdfReportGenerator.getExportDirectory();
    if (!await dir.exists()) return [];

    final list = dir.listSync();
    final pdfFiles = <File>[];
    for (var entity in list) {
      if (entity is File && entity.path.endsWith('.pdf')) {
        pdfFiles.add(entity);
      }
    }
    // Sort by modified date descending
    pdfFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return pdfFiles;
  }

  @override
  Future<void> deleteLocalPdf(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
