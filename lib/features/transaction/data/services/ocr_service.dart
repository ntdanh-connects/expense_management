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

    // Các từ khóa gợi ý tổng hóa đơn / số tiền giao dịch
    final totalKeywords = [
      'tổng cộng', 'tong cong', 'thành tiền', 'thanh tien', 'tổng thanh toán', 'tong thanh toan',
      'tổng tiền', 'tong tien', 'tiền cần thanh toán', 'số tiền', 'so tien', 'số tiền gd', 'cộng', 'cong tiền', 
      'total', 'grand total', 'amount due', 'amount', 'cash', 'tiền mặt', 'tien mat', 'đã thanh toán', 'tong tien hang', 'tổng tiền hàng'
    ];

    // Các từ khóa chỉ mã số / hotline / nhân viên / đơn hàng (BỎ QUA KHÔNG BẮT SỐ TIỀN Ở CÁC DÒNG NÀY)
    final ignoreLineKeywords = [
      'nv:', 'nv ', 'nhân viên', 'nhan vien', 'mst', 'mã cqt', 'ma cqt', 'hotline',
      'mã xác thực', 'ma xac thuc', 'msch:', 'ptt:', 'sđt', 'tel:', 'phút', '024', 'so ', 'so:', 'sđh'
    ];

    final numberRegExp = RegExp(r'\b\d{1,3}(?:[.,\s]\d{3})*(?:\s?đ|\s?VND|\s?VNĐ)?\b', caseSensitive: false);
    final cleanNumberRegExp = RegExp(r'\b\d{4,9}\b'); // Tìm các số liền nhau từ 4 đến 9 chữ số (ví dụ: 150000)

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].toLowerCase();
      
      // Bỏ qua dòng chứa mã nhân viên, mã xác thực, hotline
      if (ignoreLineKeywords.any((k) => line.contains(k))) {
        continue;
      }

      bool hasTotalKeyword = totalKeywords.any((keyword) => line.contains(keyword));
      bool hasCurrencySymbol = line.contains('đ') || line.contains('vnd') || line.contains('vnđ') || line.contains('k');

      // Nếu dòng chứa từ khóa tổng tiền -> Tìm số LỚN NHẤT trên dòng đó (tránh bắt nhầm tiền giảm giá/khuyến mãi đứng trước)
      if (hasTotalKeyword) {
        double lineMax = 0.0;
        final matches = numberRegExp.allMatches(lines[i]);
        for (var match in matches) {
          final val = _parseNumber(match.group(0)!);
          if (val != null && val >= 1000 && val <= 500000000) {
            if (val > lineMax) lineMax = val;
          }
        }
        final cleanMatches = cleanNumberRegExp.allMatches(lines[i]);
        for (var match in cleanMatches) {
          final val = double.tryParse(match.group(0)!);
          if (val != null && val >= 1000 && val <= 500000000) {
            if (val > lineMax) lineMax = val;
          }
        }

        // Nếu dòng chứa từ khóa nhưng số tổng nằm ở dòng kế tiếp
        if (lineMax == 0.0 && i + 1 < lines.length) {
          final nextLine = lines[i + 1];
          final nextMatches = numberRegExp.allMatches(nextLine);
          for (var match in nextMatches) {
            final val = _parseNumber(match.group(0)!);
            if (val != null && val >= 1000 && val > lineMax) lineMax = val;
          }
          final nextCleanMatches = cleanNumberRegExp.allMatches(nextLine);
          for (var match in nextCleanMatches) {
            final val = double.tryParse(match.group(0)!);
            if (val != null && val >= 1000 && val > lineMax) lineMax = val;
          }
        }

        if (lineMax > 0.0) {
          return lineMax;
        }
      }

      // Quét các số có dấu phân cách hàng nghìn (dành cho dòng bình thường)
      final matches = numberRegExp.allMatches(lines[i]);
      for (var match in matches) {
        final rawNum = match.group(0)!;
        final val = _parseNumber(rawNum);
        if (val != null && val >= 1000 && val <= 500000000) {
          if (hasCurrencySymbol || rawNum.contains('.') || rawNum.contains(',')) {
            if (val > maxAmount) {
              maxAmount = val;
            }
          }
        }
      }

      // Quét các số viết liền không dấu phân cách (dành cho dòng bình thường)
      if (hasCurrencySymbol) {
        final cleanMatches = cleanNumberRegExp.allMatches(lines[i]);
        for (var cleanMatch in cleanMatches) {
          final rawNum = cleanMatch.group(0)!;
          final val = double.tryParse(rawNum);
          if (val != null && val >= 1000 && val <= 500000000) {
            if (val > maxAmount) {
              maxAmount = val;
            }
          }
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
    String clean = raw.replaceAll(RegExp(r'[^\d.,]'), '').trim();
    if (clean.isEmpty) return null;

    if (clean.contains('.') && clean.contains(',')) {
      if (clean.indexOf(',') < clean.indexOf('.')) {
        clean = clean.replaceAll(',', '');
      } else {
        clean = clean.replaceAll('.', '').replaceAll(',', '.');
      }
    } else if (clean.contains('.')) {
      final parts = clean.split('.');
      if (parts.last.length == 3 || parts.length > 2) {
        clean = clean.replaceAll('.', '');
      }
    } else if (clean.contains(',')) {
      final parts = clean.split(',');
      if (parts.last.length == 3 || parts.length > 2) {
        clean = clean.replaceAll(',', '');
      } else {
        clean = clean.replaceAll(',', '.');
      }
    }

    return double.tryParse(clean);
  }

  /// Trích xuất ngày tháng & giờ từ hóa đơn
  static DateTime? _extractDate(List<String> lines) {
    // Regex tìm ngày tháng: dd/MM/yyyy, dd.MM.yyyy, dd-MM-yyyy, yyyy-MM-dd, yyyy/MM/dd
    final dateRegExp = RegExp(
      r'\b(?:(\d{1,2})[/\.\-](\d{1,2})[/\.\-](\d{2,4}))|(?:(\d{4})[/\.\-](\d{1,2})[/\.\-](\d{1,2}))\b',
    );
    // Regex xử lý lỗi OCR dính chữ/số năm (ví dụ "18/0712026" hay "18/07l2026")
    final mergedDateRegExp = RegExp(
      r'\b(\d{1,2})[/\.\-]0?(\d{1,2})[1l\s]?([2][0-9]{3})\b',
    );
    // Regex tìm định dạng tiếng Việt: "Ngày 23 tháng 07 năm 2026"
    final vnDateRegExp = RegExp(
      r'ngày\s+(\d{1,2})\s+tháng\s+(\d{1,2})\s+năm\s+(\d{2,4})',
      caseSensitive: false,
    );
    // Regex tìm giờ: 17:05, 17.05, 17:05:58
    final timeRegExp = RegExp(r'\b([01]?\d|2[0-3])[:\.]?([0-5]\d)(?:[:\.]?([0-5]\d))?\b');

    for (var line in lines) {
      int? hour, minute;
      
      // Thử tìm giờ trên cùng dòng
      final timeMatch = timeRegExp.firstMatch(line);
      if (timeMatch != null && line.contains(':')) {
        try {
          hour = int.parse(timeMatch.group(1)!);
          minute = int.parse(timeMatch.group(2)!);
        } catch (_) {}
      }

      final vnMatch = vnDateRegExp.firstMatch(line);
      if (vnMatch != null) {
        try {
          final day = int.parse(vnMatch.group(1)!);
          final month = int.parse(vnMatch.group(2)!);
          int year = int.parse(vnMatch.group(3)!);
          if (year < 100) year += 2000;
          if (day > 0 && day <= 31 && month > 0 && month <= 12 && year > 2000 && year < 2100) {
            return DateTime(year, month, day, hour ?? 0, minute ?? 0);
          }
        } catch (_) {}
      }

      final match = dateRegExp.firstMatch(line);
      if (match != null) {
        try {
          if (match.group(1) != null) {
            final day = int.parse(match.group(1)!);
            final month = int.parse(match.group(2)!);
            int year = int.parse(match.group(3)!);
            if (year < 100) year += 2000;
            if (day > 0 && day <= 31 && month > 0 && month <= 12 && year > 2000 && year < 2100) {
              return DateTime(year, month, day, hour ?? 0, minute ?? 0);
            }
          } else if (match.group(4) != null) {
            final year = int.parse(match.group(4)!);
            final month = int.parse(match.group(5)!);
            final day = int.parse(match.group(6)!);
            if (day > 0 && day <= 31 && month > 0 && month <= 12 && year > 2000 && year < 2100) {
              return DateTime(year, month, day, hour ?? 0, minute ?? 0);
            }
          }
        } catch (_) {}
      }

      final mergedMatch = mergedDateRegExp.firstMatch(line);
      if (mergedMatch != null) {
        try {
          final day = int.parse(mergedMatch.group(1)!);
          final month = int.parse(mergedMatch.group(2)!);
          final year = int.parse(mergedMatch.group(3)!);
          if (day > 0 && day <= 31 && month > 0 && month <= 12 && year > 2000 && year < 2100) {
            return DateTime(year, month, day, hour ?? 0, minute ?? 0);
          }
        } catch (_) {}
      }
    }
    return null;
  }

  /// Trích xuất tên người nhận / tên cửa hàng từ hóa đơn hoặc chuyển khoản
  static String? _extractPayee(List<String> lines) {
    if (lines.isEmpty) return null;

    // 0. Danh sách các thương hiệu phổ biến (Ưu tiên số 1)
    final popularBrands = [
      'winmart', 'vinmart', 'jollibee', 'jollibe', 'highlands', 'starbucks', 'circle k', 
      'lotteria', 'kfc', 'mcdonald', 'phúc long', 'phuclong', 'co.opmart', 'coopmart', 
      'gong cha', '7-eleven', 'bsmart', 'ministop', 'familymart', 'haidilao', 
      'lotte mart', 'aeon', 'shopee food', 'shopeefood', 'grab', 'gojek', 'baemin'
    ];

    for (var line in lines) {
      final lineLower = line.toLowerCase();
      for (var brand in popularBrands) {
        if (lineLower.contains(brand)) {
          if (brand == 'vinmart' || brand == 'winmart') return 'WinMart';
          return line.trim();
        }
      }
    }

    final payeeTriggerKeywords = [
      'tên người nhận', 'người nhận', 'tài khoản nhận', 'bên nhận', 'đơn vị bán hàng', 
      'nhà cung cấp', 'cửa hàng', 'tên cửa hàng', 'công ty', 'merchant'
    ];

    // 1. Tìm theo từ khóa gợi ý tên người nhận (dành cho biên lai chuyển khoản / hóa đơn điện tử)
    for (int i = 0; i < lines.length; i++) {
      final lineLower = lines[i].toLowerCase();
      for (var trigger in payeeTriggerKeywords) {
        if (lineLower.contains(trigger)) {
          if (lines[i].contains(':')) {
            final parts = lines[i].split(':');
            if (parts.length > 1 && parts[1].trim().length >= 3) {
              return parts[1].trim();
            }
          }
          if (i + 1 < lines.length && lines[i + 1].trim().length >= 3) {
            return lines[i + 1].trim();
          }
        }
      }
    }

    // 2. Fallback: Duyệt qua các dòng đầu tiên của hóa đơn cửa hàng
    final ignoreKeywords = [
      'hóa đơn', 'hoa don', 'phiếu', 'phieu', 'biên lai', 'bien lai', 'giấy', 'giay',
      'địa chỉ', 'dia chi', 'tel', 'phone', 'sđt', 'tax', 'mst', 'ngày', 'ngay', 'khách hàng', 
      'khach hang', 'stt', 'mã', 'code', 'order', 'menu', 'store', 'phiếu tính tiền', 'phieu tinh tien'
    ];

    final scanLimit = lines.length < 6 ? lines.length : 6;
    for (int i = 0; i < scanLimit; i++) {
      final line = lines[i].trim();
      final lowerLine = line.toLowerCase();

      // Kiểm tra xem dòng có phải mã code/mã tem (ví dụ "SPF-93883", "UJ070 OL143003", "09070-021493883")
      bool isCodeOrSerial = RegExp(r'^[A-Z0-9\-_]{5,}$', caseSensitive: false).hasMatch(line) ||
                            RegExp(r'^\d+[\-_\s]?\d+$').hasMatch(line) ||
                            RegExp(r'^[A-Z]{2,4}\d+').hasMatch(line);
      
      bool shouldIgnore = ignoreKeywords.any((k) => lowerLine.contains(k)) || 
                           line.length < 3 || 
                           line.length > 40 ||
                           isCodeOrSerial ||
                           RegExp(r'^\d+$').hasMatch(line);

      if (!shouldIgnore) {
        return line;
      }
    }

    return null;
  }
}
