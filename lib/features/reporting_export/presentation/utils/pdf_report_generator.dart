import 'dart:io';
import 'dart:math' show cos, sin, pi;
import 'package:flutter/services.dart' show rootBundle;
import 'package:expense_management/features/transaction/domain/entities/transaction_entity.dart';
import 'package:expense_management/features/analytic/data/models/report_summary_dto.dart';
import 'package:expense_management/features/analytic/data/models/report_category_dto.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:expense_management/core/constants/app_constant.dart';


class PdfReportGenerator {
  /// Generates the PDF document, saves it to the Downloads (or appropriate local) directory,
  /// and returns the File object.
  static double _convertToUserCurrency(
    double amount,
    String fromCurrency,
    String userCurrency,
    dynamic ratesData,
  ) {
    final from = fromCurrency.toUpperCase();
    final to = userCurrency.toUpperCase();
    if (from == to) return amount;

    const fallbackRates = {
      'USD': 1.0, 'VND': 25400.0, 'EUR': 0.92,
      'GBP': 0.78, 'JPY': 156.0,
    };

    final base = (ratesData?.base ?? 'USD').toUpperCase();
    final rates = ratesData?.rates.map(
      (k, v) => MapEntry(k.toUpperCase(), v.toDouble()),
    ) ?? fallbackRates;

    final fromRate = from == base ? 1.0 : (rates[from] ?? 1.0);
    final toRate   = to == base   ? 1.0 : (rates[to]   ?? 1.0);

    return amount * (toRate / fromRate);
  }

  static Future<File> generate({
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    required ReportSummaryDto summary,
    required ReportCategoryDto expenseCategories,
    required List<TransactionEntity> transactions,
    required String userCurrency,
    required dynamic ratesData,
    Map<String, String>? translations,
  }) async {
    final tr = translations ?? {};
    final fontData = await rootBundle.load('assets/fonts/Arial.ttf');
    final ttf = pw.Font.ttf(fontData);
    final fontBoldData = await rootBundle.load('assets/fonts/Arial-Bold.ttf');
    final ttfBold = pw.Font.ttf(fontBoldData);

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: ttf,
        bold: ttfBold,
      ),
    );

    // Setup Date Formatting
    final dateFormat = DateFormat('dd/MM/yyyy');
    final periodText = '${tr['pdf_period'] ?? 'Thời gian'}: ${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}';

    // Defined local colors
    final emerald600 = PdfColor.fromInt(0xFF059669);
    final rose600 = PdfColor.fromInt(0xFFE11D48);
    final emerald700 = PdfColor.fromInt(0xFF047857);
    final rose700 = PdfColor.fromInt(0xFFBE123C);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          final userSymbol = AppConstant.getCurrencySymbol(userCurrency);

          // Local calculation of summary statistics and category breakdowns in the user's target currency.
          double localIncome = 0.0;
          double localExpense = 0.0;
          
          // Group expenses by category
          final Map<String, _LocalCategoryStats> localCatMap = {};
          
          for (final tx in transactions) {
            if (tx.status != 'completed') continue; // only count completed transactions
            if (tx.sourceType == 'transfer') {
              final hasCounterpart = tx.sourceId != null &&
                  transactions.any((other) =>
                      other.id != tx.id &&
                      other.sourceId == tx.sourceId &&
                      other.walletId != tx.walletId);
              if (hasCounterpart) continue;
            }
            
            final txCurrency = tx.currencyCode ?? 'VND';
            final amt = _convertToUserCurrency(tx.amount, txCurrency, userCurrency, ratesData);
            
            if (tx.type == 'income') {
              localIncome += amt;
            } else if (tx.type == 'expense') {
              localExpense += amt;
              
              final catId = tx.categoryId ?? 'unassigned';
              final catName = tx.categoryName ?? (tr['pdf_uncategorized'] ?? 'Không phân mục');
              final catColor = tx.categoryColor ?? '#4F46E5';
              
              final currentStat = localCatMap[catId] ?? _LocalCategoryStats(
                id: catId,
                name: catName,
                color: catColor,
                amount: 0.0,
              );
              localCatMap[catId] = _LocalCategoryStats(
                id: catId,
                name: catName,
                color: catColor,
                amount: currentStat.amount + amt,
              );
            }
          }
          
          final localNet = localIncome - localExpense;
          
          // Map categories to list and compute percentages
          final List<_LocalCategoryStats> localCategories = localCatMap.values.toList();
          // Sort by amount descending
          localCategories.sort((a, b) => b.amount.compareTo(a.amount));

          final incomeText = '${AppConstant.formatMoney(localIncome, userCurrency)} $userSymbol';
          final expenseText = '${AppConstant.formatMoney(localExpense, userCurrency)} $userSymbol';
          final netText = '${AppConstant.formatMoney(localNet, userCurrency)} $userSymbol';

          return [
            // 🏢 1. HEADER SECTION
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      title.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo700,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      periodText,
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Expense Management',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey800,
                      ),
                    ),
                    pw.Text(
                      '${tr['pdf_created_date'] ?? 'Ngày tạo'}: ${dateFormat.format(DateTime.now())}',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 18),
            pw.Divider(thickness: 1.5, color: PdfColors.grey300),
            pw.SizedBox(height: 18),

            // 💵 2. SUMMARY CARDS
            pw.Row(
              children: [
                _buildSummaryBox(tr['pdf_income'] ?? 'THU NHẬP', incomeText, emerald600),
                pw.SizedBox(width: 12),
                _buildSummaryBox(tr['pdf_expense'] ?? 'CHI TIÊU', expenseText, rose600),
                pw.SizedBox(width: 12),
                _buildSummaryBox(tr['pdf_net_balance'] ?? 'THU NHẬP RÒNG', netText, localNet >= 0 ? emerald700 : rose700),
              ],
            ),
            pw.SizedBox(height: 24),

            // 🍩 3. CATEGORY SPENDING BREAKDOWN (Donut Chart & Legend)
            pw.Text(
              tr['pdf_distribution_title'] ?? 'PHÂN BỔ CHI TIÊU THEO DANH MỤC',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
            ),
            pw.SizedBox(height: 16),
            if (localCategories.isEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 16),
                child: pw.Text(
                  tr['pdf_no_spending_data'] ?? 'Không có dữ liệu chi tiêu trong kỳ này.', 
                  style: const pw.TextStyle(color: PdfColors.grey500, fontSize: 10)
                ),
              )
            else
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // Donut Chart container on the left
                  pw.Container(
                    width: 130,
                    height: 130,
                    child: pw.Stack(
                      alignment: pw.Alignment.center,
                      children: [
                        pw.CustomPaint(
                          size: const PdfPoint(120, 120),
                          painter: (PdfGraphics canvas, PdfPoint size) {
                            final double cx = size.x / 2;
                            final double cy = size.y / 2;
                            final double radius = size.x / 2;
                            final double innerRadius = radius * 0.6;
                            
                            double currentAngle = -pi / 2;
                            
                            for (final cat in localCategories) {
                              final percentage = localExpense > 0 ? (cat.amount / localExpense) : 0.0;
                              if (percentage <= 0) continue;
                              
                              final sweepAngle = percentage * 2 * pi;
                              
                              final hexColor = cat.color.replaceFirst('#', '');
                              final colorInt = int.tryParse(hexColor, radix: 16) ?? 0xFF4F46E5;
                              final pdfColor = PdfColor.fromInt(colorInt | 0xFF000000);
                              
                              _drawSector(canvas, cx, cy, radius, currentAngle, sweepAngle, pdfColor);
                              currentAngle += sweepAngle;
                            }
                            
                            // Draw the inner white circle to create the donut hole
                            canvas.drawEllipse(cx, cy, innerRadius, innerRadius);
                            canvas.setFillColor(PdfColors.white);
                            canvas.fillPath();
                          },
                        ),
                        // Text in the middle of the donut chart
                        pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Text(
                              tr['pdf_expense'] ?? 'CHI TIÊU',
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey500,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              '${AppConstant.formatMoney(localExpense, userCurrency)} $userSymbol',
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 30),
                  // Legend Table on the right
                  pw.Expanded(
                    child: pw.Table(
                      columnWidths: const {
                        0: pw.IntrinsicColumnWidth(),
                        1: pw.FlexColumnWidth(),
                        2: pw.IntrinsicColumnWidth(),
                      },
                      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
                      children: localCategories.map((cat) {
                        final percentage = localExpense > 0 ? (cat.amount / localExpense) * 100 : 0.0;
                        final hexColor = cat.color.replaceFirst('#', '');
                        final colorInt = int.tryParse(hexColor, radix: 16) ?? 0xFF4F46E5;
                        final pdfColor = PdfColor.fromInt(colorInt | 0xFF000000);
                        
                        final catAmountText = '${AppConstant.formatMoney(cat.amount, userCurrency)} $userSymbol';
                        
                        return pw.TableRow(
                          children: [
                            // Color block indicator
                            pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                              child: pw.Container(
                                width: 8,
                                height: 8,
                                decoration: pw.BoxDecoration(
                                  color: pdfColor,
                                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                                ),
                              ),
                            ),
                            // Category name
                            pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              child: pw.Text(
                                cat.name,
                                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                              ),
                            ),
                            // Amount and percentage
                            pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(vertical: 4),
                              child: pw.Text(
                                '$catAmountText (${percentage.toStringAsFixed(1)}%)',
                                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            pw.SizedBox(height: 24),

            // 📋 4. RECENT TRANSACTIONS TABLE
            pw.Text(
              tr['pdf_detail_transactions'] ?? 'DANH SÁCH GIAO DỊCH CHI TIẾT',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
            ),
            pw.SizedBox(height: 12),
            if (transactions.isEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 16),
                child: pw.Text(tr['pdf_no_transactions'] ?? 'Chưa ghi nhận giao dịch nào trong khoảng thời gian này.', style: const pw.TextStyle(color: PdfColors.grey500, fontSize: 10)),
              )
            else
              _buildTransactionsTable(transactions, dateFormat, translations, userCurrency, ratesData),
          ];
        },
      ),
    );


    // Save File logic
    final dir = await getExportDirectory();
    final filenamePrefix = tr['pdf_report_title'] != null 
        ? tr['pdf_report_title']!.toLowerCase().replaceAll(' ', '_')
        : 'bao_cao';
    final filename = '${filenamePrefix}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _buildSummaryBox(String title, String amount, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey50,
          borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
          border: pw.Border.all(color: PdfColors.grey200, width: 1),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 8,
                color: PdfColors.grey500,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              amount,
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }


  static pw.Widget _buildTransactionsTable(
    List<TransactionEntity> transactions,
    DateFormat dateFormat,
    Map<String, String>? translations,
    String userCurrency,
    dynamic ratesData,
  ) {
    final tr = translations ?? {};
    final userSymbol = AppConstant.getCurrencySymbol(userCurrency);
    // Column header: show the user's currency code so it's clear which currency the converted amount is in
    final convertedHeader = '${tr['pdf_col_converted'] ?? 'Quy đổi'} ($userCurrency)';
    final headers = [
      tr['pdf_col_date'] ?? 'Ngày',
      tr['pdf_col_title'] ?? 'Tiêu đề',
      tr['pdf_col_category'] ?? 'Danh mục',
      tr['pdf_col_wallet'] ?? 'Ví',
      tr['pdf_col_type'] ?? 'Loại',
      tr['pdf_col_amount'] ?? 'Số tiền',
      convertedHeader,
    ];
    final rows = transactions.map((tx) {
      final txCurrency = tx.currencyCode ?? 'VND';
      final txSymbol = AppConstant.getCurrencySymbol(txCurrency);
      final txAmountStr = '${AppConstant.formatMoney(tx.amount, txCurrency)} $txSymbol';

      // Converted amount in user's currency
      final convertedAmt = _convertToUserCurrency(tx.amount, txCurrency, userCurrency, ratesData);
      final convertedStr = '${AppConstant.formatMoney(convertedAmt, userCurrency)} $userSymbol';

      return [
        dateFormat.format(tx.transactionDate),
        tx.title,
        tx.categoryName ?? (tr['pdf_uncategorized'] ?? 'Không phân mục'),
        tx.walletName ?? (tr['pdf_deleted_wallet'] ?? 'Ví đã xóa'),
        tx.type == 'income' ? (tr['pdf_type_income'] ?? 'Thu') : (tr['pdf_type_expense'] ?? 'Chi'),
        txAmountStr,
        convertedStr,
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      border: const pw.TableBorder(
        horizontalInside: pw.BorderSide(width: 0.5, color: PdfColors.grey200),
        bottom: pw.BorderSide(width: 1, color: PdfColors.grey300),
        top: pw.BorderSide(width: 1, color: PdfColors.grey300),
      ),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.indigo900),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo50),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellAlignment: pw.Alignment.centerLeft,
      cellAlignments: {
        0: pw.Alignment.center,
        4: pw.Alignment.center,
        5: pw.Alignment.centerRight,
        6: pw.Alignment.centerRight,
      },
    );
  }

  static Future<Directory> getExportDirectory() async {
    if (Platform.isAndroid) {
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        return externalDir;
      }
    }
    
    final downloadsDir = await getDownloadsDirectory();
    if (downloadsDir != null) {
      return downloadsDir;
    }
    return await getApplicationDocumentsDirectory();
  }

  static void _drawSector(
    PdfGraphics canvas, 
    double cx, 
    double cy, 
    double r, 
    double startAngle, 
    double sweepAngle, 
    PdfColor color
  ) {
    if (sweepAngle <= 0) return;
    
    // If it's a full circle (or very close to it), draw a circle directly to avoid arc errors
    if (sweepAngle >= 2 * pi * 0.999) {
      canvas.drawEllipse(cx, cy, r, r);
      canvas.setFillColor(color);
      canvas.fillPath();
      return;
    }
    
    final endAngle = startAngle + sweepAngle;
    final x1 = cx + r * cos(startAngle);
    final y1 = cy + r * sin(startAngle);
    final x2 = cx + r * cos(endAngle);
    final y2 = cy + r * sin(endAngle);
    
    canvas.moveTo(cx, cy);
    canvas.lineTo(x1, y1);
    canvas.bezierArc(x1, y1, r, r, x2, y2, large: sweepAngle > pi, sweep: true);
    canvas.lineTo(cx, cy);
    
    canvas.setFillColor(color);
    canvas.fillPath();
  }
}

class _LocalCategoryStats {
  final String id;
  final String name;
  final String color;
  final double amount;
  
  _LocalCategoryStats({
    required this.id,
    required this.name,
    required this.color,
    required this.amount,
  });
}
