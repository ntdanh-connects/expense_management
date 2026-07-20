import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/transaction/data/services/ocr_service.dart';
import 'package:expense_management/features/transaction/presentation/widgets/ocr_helper/ocr_input_field.dart';
import 'package:expense_management/features/transaction/presentation/widgets/ocr_helper/ocr_raw_line_item.dart';

class OcrHelperScreen extends ConsumerStatefulWidget {
  final String imagePath;

  const OcrHelperScreen({super.key, required this.imagePath});

  @override
  ConsumerState<OcrHelperScreen> createState() => _OcrHelperScreenState();
}

class _OcrHelperScreenState extends ConsumerState<OcrHelperScreen> {
  bool _isLoading = true;
  OcrResult? _ocrResult;

  // Form controllers
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _payeeController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  DateTime? _selectedDate;

  // Active field being selected: 'amount', 'payee', 'desc', 'date'
  String _activeField = 'amount';
  late CurrencyTextInputFormatter _formatter;

  @override
  void initState() {
    super.initState();
    _formatter = CurrencyTextInputFormatter.currency(
      locale: 'vi',
      decimalDigits: 0,
      symbol: 'đ',
    );
    _performOcr();
  }

  Future<void> _performOcr() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await OcrService.parseReceipt(widget.imagePath);
      if (mounted) {
        setState(() {
          _ocrResult = result;
          _isLoading = false;

          // Auto fill detected fields
          if (result.amount != null && result.amount! > 0) {
            _amountController.text = _formatter.formatDouble(result.amount!);
          }
          if (result.payeeName != null) {
            _payeeController.text = result.payeeName!;
            _descController.text = 'Thanh toán tại ${result.payeeName}';
          } else {
            _descController.text = 'Chi tiêu hóa đơn tiền mặt';
          }
          _selectedDate = result.date ?? DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applyExtractedText(String text) {
    setState(() {
      switch (_activeField) {
        case 'amount':
          // Thử parse số tiền từ chuỗi text được nhấn
          final cleanNum = text.replaceAll(RegExp(r'[^\d]'), '');
          final val = double.tryParse(cleanNum);
          if (val != null) {
            _amountController.text = _formatter.formatDouble(val);
          } else {
            _amountController.text = text;
          }
          break;
        case 'payee':
          _payeeController.text = text;
          if (_descController.text.isEmpty || _descController.text == 'Chi tiêu hóa đơn tiền mặt') {
            _descController.text = 'Thanh toán tại $text';
          }
          break;
        case 'desc':
          _descController.text = text;
          break;
        case 'date':
          // Cố gắng phân tích ngày tháng từ chuỗi text
          final dateRegExp = RegExp(r'\b\d{1,2}[/\-]\d{1,2}[/\-]\d{2,4}\b');
          final match = dateRegExp.firstMatch(text);
          if (match != null) {
            try {
              final parts = match.group(0)!.split(RegExp(r'[/\-]'));
              final day = int.parse(parts[0]);
              final month = int.parse(parts[1]);
              int year = int.parse(parts[2]);
              if (year < 100) year += 2000;
              setState(() {
                _selectedDate = DateTime(year, month, day);
              });
            } catch (_) {}
          }
          break;
      }
    });
  }

  void _applyAllSuggestions() {
    if (_ocrResult == null) return;
    setState(() {
      if (_ocrResult!.amount != null) {
        _amountController.text = _formatter.formatDouble(_ocrResult!.amount!);
      }
      if (_ocrResult!.payeeName != null) {
        _payeeController.text = _ocrResult!.payeeName!;
        _descController.text = 'Thanh toán tại ${_ocrResult!.payeeName}';
      }
      if (_ocrResult!.date != null) {
        _selectedDate = _ocrResult!.date;
      }
    });
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: color.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: color.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Đọc hóa đơn tiền mặt',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          if (!_isLoading && _ocrResult != null)
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: color.primary),
              onPressed: _performOcr,
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: color.primary),
                  const SizedBox(height: 20),
                  Text(
                    'Đang phân tích hóa đơn của bạn...',
                    style: TextStyle(color: color.textSecondary, fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // 1. Ảnh hóa đơn (Thu nhỏ, cho phép tương tác zoom)
                Container(
                  height: 180,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.textSecondary.withOpacity(0.1)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        InteractiveViewer(
                          panEnabled: true,
                          boundaryMargin: const EdgeInsets.all(20),
                          minScale: 0.5,
                          maxScale: 4,
                          child: Center(
                            child: Image.file(
                              File(widget.imagePath),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.zoom_in_rounded, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Có thể zoom ảnh',
                                  style: TextStyle(color: Colors.white, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. Form kết quả chỉnh sửa nhanh
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? color.surface : Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Thanh gợi ý thông minh
                        if (_ocrResult != null &&
                            (_ocrResult!.amount != null || _ocrResult!.payeeName != null))
                          Container(
                            margin: const EdgeInsets.all(12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: color.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.auto_awesome_rounded, color: color.primary, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Đã phát hiện tự động một số thông tin trên hóa đơn.',
                                    style: TextStyle(
                                      color: color.textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _applyAllSuggestions,
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Áp dụng hết',
                                    style: TextStyle(color: color.primary, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Form các trường
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              OcrInputField(
                                label: 'Số tiền giao dịch',
                                controller: _amountController,
                                icon: Icons.attach_money_rounded,
                                fieldKey: 'amount',
                                keyboardType: TextInputType.number,
                                isActive: _activeField == 'amount',
                                onTap: () => setState(() => _activeField = 'amount'),
                              ),
                              const SizedBox(height: 8),
                              OcrInputField(
                                label: 'Cửa hàng / Người nhận',
                                controller: _payeeController,
                                icon: Icons.storefront_rounded,
                                fieldKey: 'payee',
                                keyboardType: TextInputType.text,
                                isActive: _activeField == 'payee',
                                onTap: () => setState(() => _activeField = 'payee'),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: OcrInputField(
                                      label: 'Nội dung chi tiêu',
                                      controller: _descController,
                                      icon: Icons.notes_rounded,
                                      fieldKey: 'desc',
                                      keyboardType: TextInputType.text,
                                      isActive: _activeField == 'desc',
                                      onTap: () => setState(() => _activeField = 'desc'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.grey[900] : Colors.grey[50],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: color.textSecondary.withOpacity(0.1),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'Ngày giao dịch (OCR)',
                                                  style: TextStyle(color: color.textSecondary, fontSize: 10),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Icon(Icons.lock_outline_rounded, size: 11, color: color.textSecondary),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _selectedDate == null
                                                ? 'Tự động từ OCR'
                                                : DateFormat('dd/MM/yyyy HH:mm').format(_selectedDate!),
                                            style: TextStyle(
                                              color: color.textPrimary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Hướng dẫn chọn text
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Icon(Icons.touch_app_outlined, color: color.textSecondary, size: 16),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Mẹo: Chọn 1 ô nhập liệu ở trên rồi chạm vào các dòng chữ quét được ở dưới để điền nhanh.',
                                  style: TextStyle(color: color.textSecondary, fontSize: 11, fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 3. Danh sách text trích xuất được
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(top: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _ocrResult == null || _ocrResult!.rawLines.isEmpty
                                ? Center(
                                    child: Text(
                                      'Không trích xuất được chữ nào từ hình ảnh này.',
                                      style: TextStyle(color: color.textSecondary, fontSize: 13),
                                    ),
                                  )
                                : ListView.builder(
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: _ocrResult!.rawLines.length,
                                    itemBuilder: (context, index) {
                                      final lineText = _ocrResult!.rawLines[index];
                                      return OcrRawLineItem(
                                        lineText: lineText,
                                        onTap: () => _applyExtractedText(lineText),
                                      );
                                    },
                                  ),
                          ),
                        ),

                        // Nút Xác nhận
                        SafeArea(
                          top: false,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: ElevatedButton(
                              onPressed: () {
                                final cleanAmtText = _amountController.text.replaceAll(RegExp(r'[^\d]'), '');
                                final finalAmount = double.tryParse(cleanAmtText);
                                
                                Navigator.pop(context, {
                                  'amount': finalAmount,
                                  'payee_name': _payeeController.text.trim(),
                                  'description': _descController.text.trim(),
                                  'date': _selectedDate,
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: color.primary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Xác nhận & Điền vào giao dịch',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
