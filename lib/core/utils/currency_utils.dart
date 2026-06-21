import 'package:intl/intl.dart';

/// Chuyển đổi số tiền VND thành chữ tiếng Việt
String numberToVietnameseWords(double number) {
  if (number == 0) return 'Không đồng';
  
  int value = number.round();
  if (value < 0) {
    return 'Âm ${_convertPositiveNumberToWords(-value)} đồng';
  }
  return '${_convertPositiveNumberToWords(value)} đồng';
}

/// Chuyển đổi số tiền thành chữ tiếng Anh
String numberToEnglishWords(double number) {
  if (number == 0) return 'Zero';
  
  int value = number.round();
  if (value < 0) {
    return 'Minus ${_convertPositiveEnglishWords(-value)}';
  }
  return _convertPositiveEnglishWords(value);
}

final List<String> _englishOnes = [
  '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
  'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'
];

final List<String> _englishTens = [
  '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
];

String _convertPositiveEnglishWords(int number) {
  if (number == 0) return '';
  
  if (number < 20) {
    return _englishOnes[number];
  }
  
  if (number < 100) {
    final ones = number % 10;
    return '${_englishTens[number ~/ 10]}${ones > 0 ? '-${_englishOnes[ones].toLowerCase()}' : ''}';
  }
  
  if (number < 1000) {
    final remaining = number % 100;
    return '${_englishOnes[number ~/ 100]} Hundred${remaining > 0 ? ' and ${_convertPositiveEnglishWords(remaining).toLowerCase()}' : ''}';
  }
  
  final List<String> units = ['', 'Thousand', 'Million', 'Billion'];
  List<int> groups = [];
  int temp = number;
  while (temp > 0) {
    groups.add(temp % 1000);
    temp = temp ~/ 1000;
  }
  
  List<String> groupWords = [];
  for (int i = 0; i < groups.length; i++) {
    int groupValue = groups[i];
    if (groupValue == 0) continue;
    
    String groupText = _convertPositiveEnglishWords(groupValue);
    String unit = units[i];
    
    groupWords.insert(0, '$groupText $unit'.trim());
  }
  
  return groupWords.join(' ').trim();
}

/// Chuyển đổi số tiền thành chữ theo ngôn ngữ (vi hoặc en)
String formatNumberToWords(double number, String localeCode) {
  if (localeCode == 'vi') {
    return numberToVietnameseWords(number);
  } else {
    final words = numberToEnglishWords(number);
    if (words.isEmpty) return 'Zero';
    return '${words[0].toUpperCase()}${words.substring(1)}';
  }
}

final List<String> _vietnameseDigits = [
  'không', 'một', 'hai', 'ba', 'bốn', 'năm', 'sáu', 'bảy', 'tám', 'chín'
];

String _convertPositiveNumberToWords(int number) {
  if (number == 0) return '';

  List<int> groups = [];
  int temp = number;
  while (temp > 0) {
    groups.add(temp % 1000);
    temp = temp ~/ 1000;
  }

  final List<String> units = ['', 'nghìn', 'triệu', 'tỷ'];

  List<String> groupWords = [];
  bool hasAnyNonZeroBelow = false;

  for (int i = 0; i < groups.length; i++) {
    int groupValue = groups[i];
    
    if (groupValue == 0) {
      // Xác định xem có nhóm nào khác 0 ở trên hay không
      bool hasNonZeroAbove = false;
      for (int j = i + 1; j < groups.length; j++) {
        if (groups[j] > 0) {
          hasNonZeroAbove = true;
          break;
        }
      }
      
      // Nếu có nhóm khác 0 ở trên và có nhóm khác 0 ở dưới,
      // ta cần phải đọc nhóm 0 này (ví dụ: 1.000.100 -> Một triệu không trăm nghìn một trăm)
      if (hasNonZeroAbove && hasAnyNonZeroBelow) {
        int unitIndex = i % 4;
        String unit = unitIndex == 0 ? 'tỷ' : units[unitIndex];
        int billionBlocks = i ~/ 4;
        for (int b = 0; b < billionBlocks; b++) {
          unit += ' tỷ';
        }
        groupWords.insert(0, 'không trăm $unit'.trim());
      }
      continue;
    }

    hasAnyNonZeroBelow = true;

    // Chỉ hiển thị "không trăm" nếu không phải nhóm cao nhất
    bool showZeroHundred = i < groups.length - 1;
    String groupText = _convertThreeDigits(groupValue, showZeroHundred);

    String unit = '';
    if (i > 0) {
      int unitIndex = i % 4;
      if (unitIndex == 0) {
        unit = 'tỷ';
      } else {
        unit = units[unitIndex];
      }
      int billionBlocks = i ~/ 4;
      for (int b = 0; b < billionBlocks; b++) {
        unit += ' tỷ';
      }
    }

    groupWords.insert(0, '$groupText $unit'.trim());
  }

  String result = groupWords.join(' ');
  result = result.replaceAll(RegExp(r'\s+'), ' ').trim();
  
  if (result.isNotEmpty) {
    result = result[0].toUpperCase() + result.substring(1);
  }

  return result;
}

String _convertThreeDigits(int number, bool showZeroHundred) {
  int hundred = number ~/ 100;
  int tens = (number % 100) ~/ 10;
  int ones = number % 10;
  
  String result = '';
  
  if (hundred > 0) {
    result += '${_vietnameseDigits[hundred]} trăm';
  } else if (showZeroHundred) {
    result += 'không trăm';
  }
  
  if (tens > 1) {
    result += ' ${_vietnameseDigits[tens]} mươi';
  } else if (tens == 1) {
    result += ' mười';
  } else if (tens == 0 && (hundred > 0 || showZeroHundred)) {
    if (ones > 0) {
      result += ' lẻ';
    }
  }
  
  if (ones > 0) {
    if (ones == 1 && tens > 1) {
      result += ' mốt';
    } else if (ones == 5 && tens > 0) {
      result += ' lăm';
    } else {
      result += ' ${_vietnameseDigits[ones]}';
    }
  }
  
  return result.trim();
}
