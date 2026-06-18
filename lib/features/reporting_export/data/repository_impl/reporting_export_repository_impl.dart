import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:expense_management/features/reporting_export/data/datasource/remote/reporting_export_api_service.dart';
import 'package:expense_management/features/reporting_export/data/models/report_export_dto.dart';
import 'package:expense_management/features/reporting_export/domain/repositories/reporting_export_repository.dart';
import 'package:expense_management/features/analytic/domain/repository/report_repository.dart';
import 'package:expense_management/features/transaction/domain/repositories/transaction_repository.dart';
import 'package:expense_management/features/reporting_export/presentation/utils/pdf_report_generator.dart';
import 'package:expense_management/features/budget/domain/repositories/budget_repository.dart';
import 'package:expense_management/features/budget/data/models/budget_dto.dart';
import 'package:expense_management/features/analytic/data/models/report_summary_dto.dart';
import 'package:intl/intl.dart';

class ReportingExportRepositoryImpl implements ReportingExportRepository {
  final ReportingExportApiService apiService;
  final ReportRepository reportRepository;
  final TransactionRepository transactionRepository;
  final BudgetRepository budgetRepository;

  ReportingExportRepositoryImpl({
    required this.apiService,
    required this.reportRepository,
    required this.transactionRepository,
    required this.budgetRepository,
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
    // 1. Calculate Previous Period Date Range and fetch summary
    final duration = dateRange.end.difference(dateRange.start);
    final prevStart = dateRange.start.subtract(duration);
    final prevEnd = dateRange.start.subtract(const Duration(microseconds: 1));

    ReportSummaryDto? previousSummary;
    try {
      previousSummary = await reportRepository.getSummary(
        startDate: prevStart,
        endDate: prevEnd,
        walletId: walletId,
      );
    } catch (_) {
      // Fallback: allow generation even if previous stats are unavailable
    }

    // 2. Fetch budgets for the current period
    List<BudgetDto>? budgets;
    try {
      budgets = await budgetRepository.getBudgets(
        dateRange.start.month,
        dateRange.start.year,
      );
    } catch (_) {
      // Fallback: allow generation even if budget query fails
    }

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
      transactions: transactionsResult.items,
      userCurrency: userCurrency,
      ratesData: ratesData,
      previousSummary: previousSummary,
      budgets: budgets,
      translations: translations,
    );

    return file;
  }

  @override
  Future<File> generateLocalCsvReport({
    required DateTimeRange dateRange,
    String? walletId,
    String? categoryId,
    String? transactionType,
    bool isRaw = false,
  }) async {
    // 1. Fetch Transactions list
    final transactionsResult = await transactionRepository.getTransactions(
      startDate: DateFormat('yyyy-MM-dd').format(dateRange.start),
      endDate: DateFormat('yyyy-MM-dd').format(dateRange.end),
      walletId: walletId,
      categoryId: categoryId,
      type: transactionType,
      perPage: 2000, // Fetch up to 2000 transactions to fit all history in CSV
    );

    final transactions = transactionsResult.items;

    // 2. Build CSV Content
    final sb = StringBuffer();

    String escapeField(String? f) {
      if (f == null) return '';
      final escaped = f.replaceAll('"', '""');
      return '"$escaped"';
    }

    if (isRaw) {
      // Raw format matching import format
      sb.writeln('transaction_date,type,amount,wallet,category,title,notes,currency_code');
      for (final tx in transactions) {
        final dateStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(tx.transactionDate);
        final row = [
          dateStr,
          tx.type,
          tx.amount.toString(),
          escapeField(tx.walletName ?? 'Ví chính'),
          escapeField(tx.categoryName ?? ''),
          escapeField(tx.title),
          escapeField(tx.notes ?? ''),
          tx.currencyCode ?? 'VND',
        ].join(',');
        sb.writeln(row);
      }
    } else {
      // Localized format
      sb.writeln('Mã Giao Dịch,Ngày Giao Dịch,Loại Giao Dịch,Số Tiền,Đơn Vị,Ví,Danh Mục,Tiêu Đề,Ghi Chú,Trạng Thái');
      for (final tx in transactions) {
        final dateStr = tx.transactionDate.toIso8601String().replaceAll('T', ' ');
        final typeStr = tx.type == 'income' ? 'Thu nhập' : 'Chi tiêu';
        final row = [
          tx.id,
          dateStr,
          typeStr,
          tx.amount.toString(),
          tx.currencyCode ?? 'VND',
          escapeField(tx.walletName ?? 'Ví đã xóa'),
          escapeField(tx.categoryName ?? 'Không phân mục'),
          escapeField(tx.title),
          escapeField(tx.notes ?? ''),
          tx.status ?? 'completed'
        ].join(',');
        sb.writeln(row);
      }
    }

    // 3. Save to Local file in exports directory
    final dir = await PdfReportGenerator.getExportDirectory();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final startStr = DateFormat('yyyyMMdd').format(dateRange.start);
    final endStr = DateFormat('yyyyMMdd').format(dateRange.end);
    final filename = isRaw ? 'gd_raw_${startStr}_to_$endStr.csv' : 'gd_${startStr}_to_$endStr.csv';
    final file = File('${dir.path}/$filename');

    // UTF-8 with BOM to support Excel Vietnamese characters encoding out-of-the-box!
    await file.writeAsBytes([0xEF, 0xBB, 0xBF, ...utf8.encode(sb.toString())]);

    return file;
  }

  @override
  Future<List<File>> getLocalPdfHistory() async {
    final dir = await PdfReportGenerator.getExportDirectory();
    if (!await dir.exists()) return [];

    final list = dir.listSync();
    final localFiles = <File>[];
    for (var entity in list) {
      if (entity is File && (entity.path.endsWith('.pdf') || entity.path.endsWith('.csv'))) {
        localFiles.add(entity);
      }
    }
    // Sort by modified date descending
    localFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return localFiles;
  }

  @override
  Future<void> deleteLocalPdf(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
