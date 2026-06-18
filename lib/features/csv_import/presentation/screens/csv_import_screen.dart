import 'dart:io';
import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/core/language/app_language.dart';
import 'package:expense_management/features/csv_import/data/models/csv_import_dto.dart';
import 'package:expense_management/features/csv_import/presentation/providers/csv_import_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:elegant_notification/elegant_notification.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:expense_management/core/utils/app_logger.dart';

class CsvImportScreen extends ConsumerStatefulWidget {
  const CsvImportScreen({super.key});

  @override
  ConsumerState<CsvImportScreen> createState() => _CsvImportScreenState();
}

class _CsvImportScreenState extends ConsumerState<CsvImportScreen> {
  File? _selectedFile;
  String? _fileName;
  String? _fileSizeStr;
  bool _isUploading = false;

  // New state variables for mapping
  List<String> _csvHeaders = [];
  String _delimiter = ',';
  final Map<String, String?> _columnMapping = {
    'transaction_date': null,
    'type': null,
    'amount': null,
    'wallet': null,
    'category': null,
    'title': null,
    'notes': null,
    'currency_code': null,
  };

  final List<Map<String, dynamic>> _targetFields = [
    {
      'id': 'transaction_date',
      'label': 'Ngày giao dịch',
      'required': true,
      'synonyms': ['ngày', 'ngày giao dịch', 'date', 'transaction_date', 'thời gian', 'time', 'timestamp'],
    },
    {
      'id': 'type',
      'label': 'Loại giao dịch (Thu/Chi)',
      'required': true,
      'synonyms': ['loại', 'loại giao dịch', 'type', 'nhóm giao dịch'],
    },
    {
      'id': 'amount',
      'label': 'Số tiền',
      'required': true,
      'synonyms': ['số tiền', 'tiền', 'amount', 'chi phí', 'giá trị', 'value', 'money'],
    },
    {
      'id': 'title',
      'label': 'Tiêu đề giao dịch',
      'required': true,
      'synonyms': ['tiêu đề', 'tên', 'title', 'nội dung', 'diễn giải', 'description'],
    },
    {
      'id': 'wallet',
      'label': 'Ví tài khoản',
      'required': false,
      'synonyms': ['ví', 'wallet', 'wallet_id', 'tài khoản', 'account'],
    },
    {
      'id': 'category',
      'label': 'Danh mục chi tiêu',
      'required': false,
      'synonyms': ['danh mục', 'category', 'category_id', 'nhóm', 'phân loại', 'group'],
    },
    {
      'id': 'notes',
      'label': 'Ghi chú',
      'required': false,
      'synonyms': ['ghi chú', 'notes', 'note', 'chi tiết', 'details'],
    },
    {
      'id': 'currency_code',
      'label': 'Đơn vị tiền tệ',
      'required': false,
      'synonyms': ['đơn vị', 'tiền tệ', 'currency', 'currency_code', 'loại tiền'],
    },
  ];

  List<String> _parseCsvRow(String line, String delimiter) {
    final List<String> result = [];
    StringBuffer sb = StringBuffer();
    bool inQuotes = false;
    
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          sb.write('"');
          i++; 
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == delimiter && !inQuotes) {
        result.add(sb.toString().trim());
        sb.clear();
      } else {
        sb.write(char);
      }
    }
    result.add(sb.toString().trim());
    return result;
  }

  Future<void> _pickCsvFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final file = File(path);
        final lines = await file.readAsLines();
        if (lines.isEmpty) {
          throw Exception('File CSV rỗng.');
        }

        final firstLine = lines.first;
        final delimiter = (firstLine.contains(';') && ';'.allMatches(firstLine).length > ','.allMatches(firstLine).length) ? ';' : ',';
        
        final headers = _parseCsvRow(firstLine, delimiter);
        final sizeBytes = await file.length();
        final sizeKb = sizeBytes / 1024;
        
        setState(() {
          _selectedFile = file;
          _fileName = result.files.single.name;
          _fileSizeStr = sizeKb > 1024 
              ? '${(sizeKb / 1024).toStringAsFixed(1)} MB'
              : '${sizeKb.toStringAsFixed(1)} KB';
          _csvHeaders = headers;
          _delimiter = delimiter;

          // Auto-match headers based on synonyms
          for (final field in _targetFields) {
            final fieldId = field['id'] as String;
            final synonyms = field['synonyms'] as List<String>;
            
            String? matchedHeader;
            for (final header in headers) {
              final cleanHeader = header.toLowerCase().trim();
              if (synonyms.contains(cleanHeader)) {
                matchedHeader = header;
                break;
              }
            }
            _columnMapping[fieldId] = matchedHeader;
          }
        });
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Lỗi chọn tệp CSV',
        details: e,
        stackTrace: stackTrace,
        tag: 'CsvImport',
      );
      if (mounted) {
        ElegantNotification.error(
          title: Text('error'.tr(ref), style: const TextStyle(fontWeight: FontWeight.bold)),
          description: const Text('Không thể truy cập thư mục chọn tệp.'),
        ).show(context);
      }
    }
  }

  void _clearSelectedFile() {
    setState(() {
      _selectedFile = null;
      _fileName = null;
      _fileSizeStr = null;
      _csvHeaders = [];
      for (final key in _columnMapping.keys) {
        _columnMapping[key] = null;
      }
    });
  }
  Future<void> _handleUpload() async {
    if (_selectedFile == null || _isUploading) return;

    // Validate required fields mapping
    for (final field in _targetFields) {
      if (field['required'] == true) {
        final id = field['id'] as String;
        if (_columnMapping[id] == null) {
          ElegantNotification.info(
            title: const Text('Thiếu cột bắt buộc', style: TextStyle(fontWeight: FontWeight.bold)),
            description: Text('Vui lòng khớp cột cho "${field['label']}"'),
          ).show(context);
          return;
        }
      }
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final lines = await _selectedFile!.readAsLines();
      if (lines.length < 2) {
        throw Exception('File CSV không chứa dòng dữ liệu.');
      }

      final Map<String, int> indexMap = {};
      for (final key in _columnMapping.keys) {
        final mappedHeader = _columnMapping[key];
        if (mappedHeader != null) {
          indexMap[key] = _csvHeaders.indexOf(mappedHeader);
        }
      }

      final sb = StringBuffer();
      // Write target standard header row
      sb.writeln('transaction_date,type,amount,wallet,category,title,notes,currency_code');

      // Process each row (skip header row)
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i];
        if (line.trim().isEmpty) continue;

        final row = _parseCsvRow(line, _delimiter);
        
        String getRowVal(String key, String def) {
          final idx = indexMap[key];
          if (idx == null || idx >= row.length) return def;
          return row[idx];
        }

        // Clean amount
        var amountStr = getRowVal('amount', '0');
        amountStr = amountStr.replaceAll(RegExp(r'[^\d\.\-]'), '');
        if (amountStr.isEmpty) amountStr = '0';
        
        // Clean date
        final dateStr = getRowVal('transaction_date', '');

        // Clean type
        var typeStr = getRowVal('type', 'expense').toLowerCase().trim();
        if (typeStr.contains('thu') || typeStr.contains('income') || typeStr.contains('in')) {
          typeStr = 'income';
        } else {
          typeStr = 'expense';
        }

        final walletStr = getRowVal('wallet', 'Ví chính');
        final categoryStr = getRowVal('category', '');
        final titleStr = getRowVal('title', 'Giao dịch CSV');
        final notesStr = getRowVal('notes', '');
        final currencyStr = getRowVal('currency_code', 'VND');

        String escapeField(String f) {
          final escaped = f.replaceAll('"', '""');
          return '"$escaped"';
        }

        final mappedRow = [
          dateStr,
          typeStr,
          amountStr,
          escapeField(walletStr),
          escapeField(categoryStr),
          escapeField(titleStr),
          escapeField(notesStr),
          currencyStr,
        ].join(',');

        sb.writeln(mappedRow);
      }

      // Write rewritten CSV content to a temp file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/mapped_import.csv');
      await tempFile.writeAsString(sb.toString());

      final repo = ref.read(csvImportRepositoryProvider);
      await repo.importCsv(tempFile);

      if (mounted) {
        ElegantNotification.success(
          title: Text('success'.tr(ref), style: const TextStyle(fontWeight: FontWeight.bold)),
          description: const Text('File tải lên thành công và đã được xếp vào hàng đợi xử lý!'),
        ).show(context);
        
        _clearSelectedFile();
        ref.invalidate(csvImportHistoryProvider);
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Lỗi khớp cột và tải file CSV lên',
        details: e,
        stackTrace: stackTrace,
        tag: 'CsvImport',
      );
      if (mounted) {
        ElegantNotification.error(
          title: Text('error'.tr(ref), style: const TextStyle(fontWeight: FontWeight.bold)),
          description: Text('Lỗi tải file lên: $e'),
        ).show(context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final historyAsync = ref.watch(csvImportHistoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'import_csv'.tr(ref),
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 📑 Guideline Card
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.015),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.help_outline_rounded, color: colors.primary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'csv_guide_title'.tr(ref),
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'csv_guide_desc'.tr(ref),
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: colors.background,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Text(
                      'csv_guide_columns'.tr(ref),
                      style: TextStyle(
                        fontFamily: 'Courier',
                        color: colors.textPrimary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 📂 Picker area
            Text(
              'select_csv_file'.tr(ref),
              style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _selectedFile != null ? null : _pickCsvFile,
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(
                    color: _selectedFile != null 
                        ? colors.primary.withOpacity(0.3)
                        : colors.textSecondary.withOpacity(0.12),
                    width: 2.0,
                    style: _selectedFile != null ? BorderStyle.solid : BorderStyle.solid,
                  ),
                ),
                child: _selectedFile != null
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14.0),
                              decoration: BoxDecoration(
                                color: colors.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                              child: Icon(Icons.description_rounded, color: colors.primary, size: 32),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _fileName ?? '',
                                    style: TextStyle(
                                      color: colors.textPrimary,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _fileSizeStr ?? '',
                                    style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _clearSelectedFile,
                              icon: Icon(Icons.cancel_rounded, color: colors.textSecondary.withOpacity(0.6)),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload_file_rounded, color: colors.textSecondary.withOpacity(0.4), size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'tap_to_select_file'.tr(ref),
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'max_file_size_hint'.tr(ref),
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Submit Button
            if (_selectedFile != null) ...[
              _buildMappingSection(colors),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isUploading ? null : _handleUpload,
                  icon: _isUploading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.cloud_upload_outlined, color: Colors.white),
                  label: Text(
                    _isUploading ? 'uploading_msg'.tr(ref) : 'upload_and_process'.tr(ref),
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 1,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 📜 Import History Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'csv_import_history_title'.tr(ref),
                  style: TextStyle(color: colors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => ref.invalidate(csvImportHistoryProvider),
                  icon: Icon(Icons.refresh_rounded, color: colors.primary, size: 20),
                )
              ],
            ),
            const SizedBox(height: 8),

            historyAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                    child: Center(
                      child: Text(
                        'no_recent_imports'.tr(ref),
                        style: TextStyle(color: colors.textSecondary, fontSize: 13.5),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return _buildHistoryItem(item);
                  },
                );
              },
              loading: () => const _CsvImportHistoryShimmer(),
              error: (err, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Center(
                  child: Text(
                    'load_history_error'.tr(ref) + err.toString(),
                    style: TextStyle(color: colors.expenseRed, fontSize: 13.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(CsvImportDto item) {
    final colors = context.colors;
    
    // Status parsing
    Color statusColor;
    String statusText;
    IconData iconData;
    
    switch (item.status) {
      case 'pending':
        statusColor = colors.profileNotification;
        statusText = 'import_status_pending'.tr(ref);
        iconData = Icons.schedule_rounded;
        break;
      case 'processing':
        statusColor = colors.profileInfo;
        statusText = 'import_status_processing'.tr(ref);
        iconData = Icons.loop_rounded;
        break;
      case 'completed':
        statusColor = colors.incomeGreen;
        statusText = 'import_status_completed'
            .tr(ref)
            .replaceAll('{success}', item.successRows.toString())
            .replaceAll('{total}', item.totalRows.toString());
        iconData = Icons.check_circle_outline_rounded;
        break;
      case 'failed':
      default:
        statusColor = colors.expenseRed;
        statusText = 'import_status_failed'.tr(ref);
        iconData = Icons.error_outline_rounded;
        break;
    }

    final dateStr = DateFormat('dd/MM/yyyy, HH:mm').format(
      DateTime.tryParse(item.createdAt)?.toLocal() ?? DateTime.now(),
    );

    final fileName = item.fileUrl.split('/').last.split('\\').last;

    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.textSecondary.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconData, color: statusColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: TextStyle(color: colors.textPrimary, fontSize: 13.5, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$dateStr • $statusText',
                  style: TextStyle(color: colors.textSecondary, fontSize: 11.5),
                ),
              ],
            ),
          ),
          if (item.status == 'failed' && item.errorFileUrl != null && item.errorFileUrl!.isNotEmpty)
            IconButton(
              icon: Icon(Icons.info_outline, color: colors.expenseRed, size: 20),
              onPressed: () {
                // Show failure message dialog or help
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: colors.surface,
                    title: Text('Chi tiết lỗi nhập file'.tr(ref), style: const TextStyle(fontWeight: FontWeight.bold)),
                    content: Text(
                      'Bản ghi lỗi có thể tải tại đây:\n${item.errorFileUrl}',
                      style: TextStyle(color: colors.textPrimary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Đóng'.tr(ref)),
                      ),
                    ],
                  ),
                );
              },
            ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: colors.expenseRed, size: 20),
            onPressed: () {
              // Delete history item with confirmation dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: colors.surface,
                  title: const Text('Xóa lịch sử nhập', style: TextStyle(fontWeight: FontWeight.bold)),
                  content: const Text('Bạn có chắc chắn muốn xóa bản ghi lịch sử nhập này không?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Hủy', style: TextStyle(color: colors.textSecondary)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ref.read(csvImportHistoryProvider.notifier).deleteImport(item.id);
                      },
                      child: Text('Xóa', style: TextStyle(color: colors.expenseRed, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMappingSection(colors) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.textSecondary.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.alt_route_rounded, color: colors.primary, size: 22),
              const SizedBox(width: 8),
              const Text(
                'Khớp cột dữ liệu CSV',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Hãy ghép các cột từ file CSV của bạn vào các trường tương ứng của ứng dụng. Các cột khớp tự động được điền sẵn dựa trên từ đồng nghĩa.',
            style: TextStyle(color: colors.textSecondary, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 14),
          Divider(color: colors.textSecondary.withOpacity(0.08), height: 1),
          const SizedBox(height: 14),
          ..._targetFields.map((field) {
            final fieldId = field['id'] as String;
            final isRequired = field['required'] as bool;
            final label = field['label'] as String;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 4,
                    child: RichText(
                      text: TextSpan(
                        text: label,
                        style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                        children: [
                          if (isRequired)
                            const TextSpan(
                              text: ' *',
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: colors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.textSecondary.withOpacity(0.1)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _columnMapping[fieldId],
                          hint: Text(
                            isRequired ? 'Chọn cột...' : 'Bỏ qua / Mặc định',
                            style: TextStyle(color: colors.textSecondary, fontSize: 12),
                          ),
                          isExpanded: true,
                          style: TextStyle(color: colors.textPrimary, fontSize: 13),
                          items: [
                            if (!isRequired)
                              DropdownMenuItem<String>(
                                value: null,
                                child: Text('Bỏ qua / Mặc định', style: TextStyle(color: colors.textSecondary, fontSize: 12.5)),
                              ),
                            ..._csvHeaders.map((header) {
                              return DropdownMenuItem<String>(
                                value: header,
                                child: Text(header, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5)),
                              );
                            }),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _columnMapping[fieldId] = val;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CsvImportHistoryShimmer extends StatelessWidget {
  const _CsvImportHistoryShimmer();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[900]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[800]! : Colors.grey[100]!,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10.0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 140,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 180,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
