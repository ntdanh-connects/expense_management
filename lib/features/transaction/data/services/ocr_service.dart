import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrResult {
  final double? amount;
  final DateTime? date;
  final String? payeeName;
  final List<String> rawLines;

  OcrResult({
    this.amount,
    this.date,
    this.payeeName,
    required this.rawLines,
  });
}

class OcrService {
  /// Thực hiện nhận dạng văn bản trên tệp ảnh hóa đơn và phân tích dữ liệu
  static Future<OcrResult> parseReceipt(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      return OcrResult(rawLines: []);
    }

    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    
    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      final List<String> rawLines = [];
      
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          final text = line.text.trim();
          if (text.isNotEmpty) {
            rawLines.add(text);
          }
        }
      }

      final amount = _extractAmount(rawLines);
      final date = _extractDate(rawLines);
      final payeeName = _extractPayee(rawLines);

      return OcrResult(
        amount: amount,
        date: date,
        payeeName: payeeName,
        rawLines: rawLines,
      );
    } catch (e) {
      // Log lỗi nếu có
      return OcrResult(rawLines: []);
    } finally {
      textRecognizer.close();
    }
  }

  /// Trích xuất số tiền lớn nhất hoặc số tiền đi kèm từ khóa tổng cộng
  static double? _extractAmount(List<String> lines) {
    double? detectedAmount;
    double maxAmount = 0.0;

    // Các từ khóa gợi ý tổng hóa đơn
    final totalKeywords = [
      'tổng cộng', 'tong cong', 'thanh toán', 'thanh toan', 'tổng tiền', 'tong tien',
      'cộng', 'cong tiền', 'total', 'grand total', 'amount due', 'cash', 'tiền mặt', 'tien mat'
    ];

    final numberRegExp = RegExp(r'\b\d{1,3}(?:[.,]\d{3})*(?:\s?đ|\s?VND|\s?VND)?\b', caseSensitive: false);
    final cleanNumberRegExp = RegExp(r'\b\d{4,9}\b'); // Tìm các số liền nhau từ 4 đến 9 chữ số (ví dụ: 150000)

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toLowerCase();
      
      // Kiểm tra xem dòng có chứa từ khóa tổng tiền hay không
      bool hasTotalKeyword = totalKeywords.any((keyword) => line.contains(keyword));

      // Quét các số có dấu phân cách hàng nghìn (ví dụ 150.000 hoặc 150,000)
      final matches = numberRegExp.allMatches(lines[i]);
      for (var match in matches) {
        final rawNum = match.group(0)!;
        final val = _parseNumber(rawNum);
        if (val != null && val >= 1000 && val <= 500000000) {
          if (hasTotalKeyword) {
            // Ưu tiên dòng có từ khóa tổng cộng
            return val;
          }
          if (val > maxAmount) {
            maxAmount = val;
          }
        }
      }

      // Quét các số viết liền không dấu phân cách (ví dụ 150000)
      final cleanMatches = cleanNumberRegExp.allMatches(lines[i]);
      for (var cleanMatch in cleanMatches) {
        final rawNum = cleanMatch.group(0)!;
        final val = double.tryParse(rawNum);
        if (val != null && val >= 1000 && val <= 500000000) {
          if (hasTotalKeyword) {
            return val;
          }
          if (val > maxAmount) {
            maxAmount = val;
          }
        }
      }

      // Nếu dòng chứa từ khóa tổng cộng nhưng số nằm ở dòng tiếp theo
      if (hasTotalKeyword && i + 1 < lines.length) {
        final nextLine = lines[i + 1];
        // Thử tìm số ở dòng tiếp theo
        final nextMatches = numberRegExp.allMatches(nextLine);
        if (nextMatches.isNotEmpty) {
          final val = _parseNumber(nextMatches.first.group(0)!);
          if (val != null) return val;
        }
        final nextCleanMatches = cleanNumberRegExp.allMatches(nextLine);
        if (nextCleanMatches.isNotEmpty) {
          final val = double.tryParse(nextCleanMatches.first.group(0)!);
          if (val != null) return val;
        }
      }
    }

    if (maxAmount > 0.0) {
      detectedAmount = maxAmount;
    }

    return detectedAmount;
  }

  /// Phân tích cú pháp chuỗi số thành kiểu double (ví dụ: "150.000 đ" -> 150000.0)
  static double? _parseNumber(String raw) {
    // Loại bỏ các ký tự không phải số và dấu chấm/dấu phẩy
    String clean = raw.replaceAll(RegExp(r'[^\d.,]'), '').trim();
    if (clean.isEmpty) return null;

    // Xác định dấu phân cách hàng nghìn
    // Nếu có cả dấu chấm và dấu phẩy (ví dụ: 1,500.00 hoặc 1.500,00)
    if (clean.contains('.') && clean.contains(',')) {
      if (clean.indexOf(',') < clean.indexOf('.')) {
        // Định dạng 1,500.00
        clean = clean.replaceAll(',', '');
      } else {
        // Định dạng 1.500,00
        clean = clean.replaceAll('.', '').replaceAll(',', '.');
      }
    } else if (clean.contains('.')) {
      // Chỉ chứa dấu chấm. Trong hóa đơn VN, dấu chấm thường là phân cách hàng nghìn (150.000)
      // trừ khi nó là số thập phân kiểu USD (1.50).
      // Heuristic: Nếu phần sau dấu chấm có đúng 3 chữ số, coi là phân cách hàng nghìn.
      final parts = clean.split('.');
      if (parts.last.length == 3) {
        clean = clean.replaceAll('.', '');
      } else {
        // Coi dấu chấm là dấu thập phân
      }
    } else if (clean.contains(',')) {
      // Chỉ chứa dấu phẩy.
      final parts = clean.split(',');
      if (parts.last.length == 3) {
        clean = clean.replaceAll(',', '');
      } else {
        clean = clean.replaceAll(',', '.');
      }
    }

    return double.tryParse(clean);
  }

  /// Trích xuất ngày tháng từ hóa đơn
  static DateTime? _extractDate(List<String> lines) {
    // Regex tìm ngày tháng định dạng dd/MM/yyyy, dd-MM-yyyy, yyyy-MM-dd, dd/MM/yy
    final dateRegExp = RegExp(
      r'\b(?:(\d{1,2})[/\-](\d{1,2})[/\-](\d{2,4}))|(?:(\d{4})[/\-](\d{1,2})[/\-](\d{1,2}))\b',
    );

    for (var line in lines) {
      final match = dateRegExp.firstMatch(line);
      if (match != null) {
        try {
          if (match.group(1) != null) {
            // Định dạng dd/MM/yyyy hoặc dd/MM/yy
            final day = int.parse(match.group(1)!);
            final month = int.parse(match.group(2)!);
            int year = int.parse(match.group(3)!);
            if (year < 100) {
              year += 2000; // yy -> 20yy
            }
            if (day > 0 && day <= 31 && month > 0 && month <= 12 && year > 2000 && year < 2100) {
              return DateTime(year, month, day);
            }
          } else if (match.group(4) != null) {
            // Định dạng yyyy-MM-dd
            final year = int.parse(match.group(4)!);
            final month = int.parse(match.group(5)!);
            final day = int.parse(match.group(6)!);
            if (day > 0 && day <= 31 && month > 0 && month <= 12 && year > 2000 && year < 2100) {
              return DateTime(year, month, day);
            }
          }
        } catch (_) {
          // Bỏ qua lỗi parsing ngày tháng sai
        }
      }
    }
    return null;
  }

  /// Trích xuất tên người nhận / tên cửa hàng (thường ở 3 dòng đầu tiên)
  static String? _extractPayee(List<String> lines) {
    if (lines.isEmpty) return null;

    final ignoreKeywords = [
      'hóa đơn', 'hoa don', 'phiếu', 'phieu', 'biên lai', 'bien lai', 'giấy', 'giay',
      'địa chỉ', 'dia chi', 'tel', 'phone', 'sđt', 'tax', 'mst', 'ngày', 'ngay', 'khách hàng', 'khach hang'
    ];

    // Duyệt qua tối đa 4 dòng đầu tiên để tìm tên cửa hàng phù hợp
    final scanLimit = lines.length < 4 ? lines.length : 4;
    for (int i = 0; i < scanLimit; i++) {
      final line = lines[i].trim();
      final lowerLine = line.toLowerCase();
      
      // Bỏ qua các dòng chứa từ khóa không liên quan hoặc quá ngắn/quá dài
      bool shouldIgnore = ignoreKeywords.any((k) => lowerLine.contains(k)) || 
                           line.length < 3 || 
                           line.length > 40 ||
                           RegExp(r'^\d+$').hasMatch(line); // chỉ có số

      if (!shouldIgnore) {
        return line;
      }
    }

    return null;
  }
}
