import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:expense_management/features/transaction/domain/entities/transaction_entity.dart';
import 'package:expense_management/features/analytic/data/models/report_summary_dto.dart';
import 'package:expense_management/features/analytic/data/models/report_category_dto.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class PdfReportGenerator {
  /// Generates the PDF document, saves it to the Downloads (or appropriate local) directory,
  /// and returns the File object.
  static Future<File> generate({
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    required ReportSummaryDto summary,
    required ReportCategoryDto expenseCategories,
    required List<TransactionEntity> transactions,
  }) async {
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
    final numberFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
    final periodText = 'Thời gian: ${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}';

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
                      'Ngày tạo: ${dateFormat.format(DateTime.now())}',
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
                _buildSummaryBox('THU NHẬP', numberFormat.format(summary.income), emerald600),
                pw.SizedBox(width: 12),
                _buildSummaryBox('CHI TIÊU', numberFormat.format(summary.expense), rose600),
                pw.SizedBox(width: 12),
                _buildSummaryBox('THU NHẬP RÒNG', numberFormat.format(summary.net), summary.net >= 0 ? emerald700 : rose700),
              ],
            ),
            pw.SizedBox(height: 24),

            // 🍩 3. CATEGORY SPENDING BREAKDOWN
            pw.Text(
              'PHÂN BỔ CHI TIÊU THEO DANH MỤC',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey800,
              ),
            ),
            pw.SizedBox(height: 12),
            if (expenseCategories.categories.isEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 16),
                child: pw.Text('Không có dữ liệu chi tiêu trong kỳ này.', style: const pw.TextStyle(color: PdfColors.grey500, fontSize: 10)),
              )
            else
              pw.Column(
                children: expenseCategories.categories.map((cat) {
                  // Fallback hex color mapping
                  final hexColor = (cat.categoryColor ?? '#4F46E5').replaceFirst('#', '');
                  final colorInt = int.tryParse(hexColor, radix: 16) ?? 0xFF4F46E5;
                  final pdfColor = PdfColor.fromInt(colorInt | 0xFF000000);

                  return _buildCategoryProgressRow(
                    cat.categoryName,
                    numberFormat.format(cat.amount),
                    cat.percentage,
                    pdfColor,
                  );
                }).toList(),
              ),
            pw.SizedBox(height: 24),

            // 📋 4. RECENT TRANSACTIONS TABLE
            pw.Text(
              'DANH SÁCH GIAO DỊCH CHI TIẾT',
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
                child: pw.Text('Chưa ghi nhận giao dịch nào trong khoảng thời gian này.', style: const pw.TextStyle(color: PdfColors.grey500, fontSize: 10)),
              )
            else
              _buildTransactionsTable(transactions, dateFormat, numberFormat),
          ];
        },
      ),
    );

    // Save File logic
    final dir = await getExportDirectory();
    final filename = 'bao_cao_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
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

  static pw.Widget _buildCategoryProgressRow(String name, String amount, double percentage, PdfColor color) {
    final flexVal = (percentage * 100).round();
    final remainingFlexVal = (10000 - flexVal * 100).clamp(0, 10000);

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                name,
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
              ),
              pw.Text(
                '$amount (${percentage.toStringAsFixed(1)}%)',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Container(
            height: 5,
            width: double.infinity,
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(2.5)),
            ),
            child: pw.Row(
              children: [
                if (flexVal > 0)
                  pw.Expanded(
                    flex: flexVal,
                    child: pw.Container(
                      decoration: pw.BoxDecoration(
                        color: color,
                        borderRadius: pw.BorderRadius.all(pw.Radius.circular(2.5)),
                      ),
                    ),
                  ),
                if (remainingFlexVal > 0)
                  pw.Expanded(
                    flex: remainingFlexVal,
                    child: pw.SizedBox(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTransactionsTable(
    List<TransactionEntity> transactions,
    DateFormat dateFormat,
    NumberFormat numberFormat,
  ) {
    final headers = ['Ngày', 'Tiêu đề', 'Danh mục', 'Ví', 'Loại', 'Số tiền'];
    final rows = transactions.map((tx) {
      return [
        dateFormat.format(tx.transactionDate),
        tx.title,
        tx.categoryName ?? 'Không phân mục',
        tx.walletName ?? 'Ví đã xóa',
        tx.type == 'income' ? 'Thu' : 'Chi',
        numberFormat.format(tx.amount),
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
        5: pw.Alignment.centerRight,
        4: pw.Alignment.center,
        0: pw.Alignment.center,
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
}
