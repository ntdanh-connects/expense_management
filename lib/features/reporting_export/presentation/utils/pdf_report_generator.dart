import 'dart:io';
import 'dart:math' show cos, sin, pi;
import 'package:flutter/services.dart' show rootBundle;
import 'package:expense_management/features/transaction/domain/entities/transaction_entity.dart';
import 'package:expense_management/features/analytic/data/models/report_summary_dto.dart';
import 'package:expense_management/features/analytic/data/models/report_category_dto.dart';
import 'package:expense_management/features/budget/data/models/budget_dto.dart';
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
    required List<TransactionEntity> transactions,
    required String userCurrency,
    required dynamic ratesData,
    ReportSummaryDto? previousSummary,
    List<BudgetDto>? budgets,
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
          
          // Group expenses by day for trend
          final Map<String, double> dailySpending = {};
          
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
              
              final catId = tx.categoryId ?? 'uncategorized';
              final catName = tx.categoryName ?? (tr['uncategorized'] ?? 'Chưa phân loại');
              final catColor = tx.categoryColor ?? '#9CA3AF';
              
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

              // Record daily spending
              final dayKey = DateFormat('yyyy-MM-dd').format(tx.transactionDate);
              dailySpending[dayKey] = (dailySpending[dayKey] ?? 0.0) + amt;
            }
          }
          
          final localNet = localIncome - localExpense;
          final savingsRate = localIncome > 0 ? (localNet / localIncome) * 100 : 0.0;

          // Comparison stats
          double? expenseComparePct;
          double? incomeComparePct;
          if (previousSummary != null) {
            if (previousSummary.expense > 0) {
              expenseComparePct = ((localExpense - previousSummary.expense) / previousSummary.expense) * 100;
            }
            if (previousSummary.income > 0) {
              incomeComparePct = ((localIncome - previousSummary.income) / previousSummary.income) * 100;
            }
          }
          
          // Map categories to list and compute percentages
          final List<_LocalCategoryStats> localCategories = localCatMap.values.toList();
          // Sort by amount descending
          localCategories.sort((a, b) => b.amount.compareTo(a.amount));

          // Group spending by week for visual trend
          final Map<String, double> weeklySpending = {
            'Tuần 1': 0.0,
            'Tuần 2': 0.0,
            'Tuần 3': 0.0,
            'Tuần 4': 0.0,
            'Tuần 5+': 0.0,
          };
          for (final tx in transactions) {
            if (tx.type != 'expense' || tx.status != 'completed') continue;
            final diffDays = tx.transactionDate.difference(startDate).inDays;
            final txCurrency = tx.currencyCode ?? 'VND';
            final amt = _convertToUserCurrency(tx.amount, txCurrency, userCurrency, ratesData);
            
            if (diffDays < 7) {
              weeklySpending['Tuần 1'] = weeklySpending['Tuần 1']! + amt;
            } else if (diffDays < 14) {
              weeklySpending['Tuần 2'] = weeklySpending['Tuần 2']! + amt;
            } else if (diffDays < 21) {
              weeklySpending['Tuần 3'] = weeklySpending['Tuần 3']! + amt;
            } else if (diffDays < 28) {
              weeklySpending['Tuần 4'] = weeklySpending['Tuần 4']! + amt;
            } else {
              weeklySpending['Tuần 5+'] = weeklySpending['Tuần 5+']! + amt;
            }
          }

          double maxWeeklySpend = 0.0;
          for (final val in weeklySpending.values) {
            if (val > maxWeeklySpend) maxWeeklySpend = val;
          }
          if (maxWeeklySpend == 0) maxWeeklySpend = 1.0;

          // Get Top 5 Spending Days
          final List<MapEntry<String, double>> sortedDailySpending = dailySpending.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final List<MapEntry<String, double>> topSpendingDays = sortedDailySpending.take(5).toList();

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
            pw.SizedBox(height: 10),

            // 💵 2b. SAVINGS & COMPARATIVE STATS
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    '${tr['pdf_savings_rate'] ?? 'Tỷ lệ tiết kiệm'}: ${savingsRate.toStringAsFixed(1)}%',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: savingsRate >= 0 ? emerald700 : rose700,
                    ),
                  ),
                  if (previousSummary != null) ...[
                    pw.Text(
                      '${tr['pdf_vs_prev'] ?? 'So với kỳ trước'}: '
                      'Thu ${incomeComparePct != null ? (incomeComparePct >= 0 ? '+' : '') + incomeComparePct.toStringAsFixed(1) + '%' : 'N/A'} | '
                      'Chi ${expenseComparePct != null ? (expenseComparePct >= 0 ? '+' : '') + expenseComparePct.toStringAsFixed(1) + '%' : 'N/A'}',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ],
              ),
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
    final headers = [
      tr['pdf_col_date'] ?? 'Ngày',
      tr['pdf_col_title'] ?? 'Tiêu đề',
      tr['pdf_col_category'] ?? 'Danh mục',
      tr['pdf_col_wallet'] ?? 'Ví',
      tr['pdf_col_type'] ?? 'Loại',
      tr['pdf_col_amount'] ?? 'Số tiền',
    ];
    final rows = transactions.map((tx) {
      final txCurrency = tx.currencyCode ?? 'VND';
      final txSymbol = AppConstant.getCurrencySymbol(txCurrency);
      final txAmountStr = '${AppConstant.formatMoney(tx.amount, txCurrency)} $txSymbol';

      return [
        dateFormat.format(tx.transactionDate),
        tx.title,
        tx.categoryName ?? (tr['uncategorized'] ?? 'Chưa phân loại'),
        tx.walletName ?? (tr['pdf_deleted_wallet'] ?? 'Ví đã xóa'),
        tx.type == 'income' ? (tr['pdf_type_income'] ?? 'Thu') : (tr['pdf_type_expense'] ?? 'Chi'),
        txAmountStr,
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

  static pw.Widget _buildBudgetTable(
    List<BudgetDto> budgets,
    String userCurrency,
    dynamic ratesData,
    String userSymbol,
    Map<String, String>? translations,
  ) {
    final tr = translations ?? {};
    final headers = [
      tr['pdf_budget_category'] ?? 'Hạng mục / Danh mục',
      tr['pdf_budget_limit'] ?? 'Hạn mức',
      tr['pdf_budget_spent'] ?? 'Thực chi',
      tr['pdf_budget_percent'] ?? 'Tỷ lệ',
      tr['pdf_budget_status_lbl'] ?? 'Trạng thái',
    ];

    final rows = budgets.map((b) {
      final categoryName = b.categoryId == null 
          ? (tr['pdf_overall_budget'] ?? 'Ngân sách tổng')
          : (b.category?.name ?? (tr['pdf_uncategorized'] ?? 'Không phân mục'));

      final limit = _convertToUserCurrency(b.limitAmount, 'VND', userCurrency, ratesData);
      final spent = _convertToUserCurrency(b.usedAmount, 'VND', userCurrency, ratesData);
      
      final percent = limit > 0 ? (spent / limit) : 0.0;
      final percentText = '${(percent * 100).toStringAsFixed(0)}%';
      
      String statusText = tr['pdf_budget_safe'] ?? 'An toàn';

      if (percent >= 1.0) {
        statusText = tr['pdf_budget_exceeded'] ?? 'Vượt hạn mức';
      } else if (percent >= 0.8) {
        statusText = tr['pdf_budget_warning'] ?? 'Sắp chạm mốc';
      }

      final limitStr = '${AppConstant.formatMoney(limit, userCurrency)} $userSymbol';
      final spentStr = '${AppConstant.formatMoney(spent, userCurrency)} $userSymbol';

      return [
        categoryName,
        limitStr,
        spentStr,
        percentText,
        statusText,
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
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.center,
        4: pw.Alignment.center,
      },
    );
  }

  static pw.Widget _buildTopSpendingDaysTable(
    List<MapEntry<String, double>> topDays,
    String userCurrency,
    String userSymbol,
    Map<String, String>? translations,
  ) {
    final tr = translations ?? {};
    final headers = [
      tr['pdf_col_date'] ?? 'Ngày',
      tr['pdf_col_amount'] ?? 'Số tiền',
      tr['pdf_col_intensity'] ?? 'Mức độ',
    ];

    final maxSpend = topDays.isNotEmpty ? topDays.first.value : 1.0;

    final rows = topDays.map((entry) {
      final date = DateTime.tryParse(entry.key);
      final formattedDate = date != null ? DateFormat('dd/MM/yyyy').format(date) : entry.key;
      final amountStr = '${AppConstant.formatMoney(entry.value, userCurrency)} $userSymbol';
      
      final ratio = maxSpend > 0 ? (entry.value / maxSpend) : 0.0;

      final progressBar = pw.Container(
        width: 80,
        height: 6,
        decoration: const pw.BoxDecoration(
          color: PdfColors.grey200,
          borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
        ),
        alignment: pw.Alignment.centerLeft,
        child: pw.Container(
          width: 80 * ratio,
          height: 6,
          decoration: const pw.BoxDecoration(
            color: PdfColors.indigo600,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
          ),
        ),
      );

      return [
        pw.Text(formattedDate, style: const pw.TextStyle(fontSize: 8)),
        pw.Text(amountStr, style: const pw.TextStyle(fontSize: 8)),
        progressBar,
      ];
    }).toList();

    return pw.Table(
      border: const pw.TableBorder(
        horizontalInside: pw.BorderSide(width: 0.5, color: PdfColors.grey200),
        bottom: pw.BorderSide(width: 1, color: PdfColors.grey300),
        top: pw.BorderSide(width: 1, color: PdfColors.grey300),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(1),
        1: pw.FlexColumnWidth(1.2),
        2: pw.IntrinsicColumnWidth(),
      },
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.indigo50),
          children: headers.map((h) => pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: pw.Text(
              h,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.indigo900),
            ),
          )).toList(),
        ),
        ...rows.map((row) {
          return pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                child: row[0],
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                child: row[1],
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                child: row[2] as pw.Widget,
              ),
            ],
          );
        }),
      ],
    );
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
