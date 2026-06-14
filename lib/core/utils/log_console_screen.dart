import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import 'app_logger.dart';

class LogConsoleScreen extends StatefulWidget {
  const LogConsoleScreen({super.key});

  @override
  State<LogConsoleScreen> createState() => _LogConsoleScreenState();
}

class _LogConsoleScreenState extends State<LogConsoleScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  bool _newestFirst = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild to update filtered list based on tab
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<LogEntry> _getFilteredLogs(List<LogEntry> allLogs) {
    // 1. Filter by Tab
    List<LogEntry> logs = [];
    switch (_tabController.index) {
      case 0: // ALL
        logs = allLogs;
        break;
      case 1: // NETWORK
        logs = allLogs.where((e) => e.level == LogLevel.network).toList();
        break;
      case 2: // ERROR
        logs = allLogs.where((e) => e.level == LogLevel.error).toList();
        break;
      case 3: // DEBUG
        logs = allLogs.where((e) => e.level == LogLevel.debug).toList();
        break;
      case 4: // WARNING
        logs = allLogs.where((e) => e.level == LogLevel.warning).toList();
        break;
      case 5: // INFO
        logs = allLogs.where((e) => e.level == LogLevel.info).toList();
        break;
    }

    // 2. Filter by Search Query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      logs = logs.where((e) {
        final matchesMsg = e.message.toLowerCase().contains(query);
        final matchesTag = e.tag?.toLowerCase().contains(query) ?? false;
        final matchesDetails = e.details != null && e.details.toString().toLowerCase().contains(query);
        return matchesMsg || matchesTag || matchesDetails;
      }).toList();
    }

    // 3. Sort Order
    if (_newestFirst) {
      return logs.reversed.toList();
    } else {
      return logs;
    }
  }

  Color _getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return const Color(0xFF64748B); // Slate/Grey
      case LogLevel.info:
        return const Color(0xFF3B82F6); // Blue
      case LogLevel.warning:
        return const Color(0xFFF59E0B); // Amber
      case LogLevel.error:
        return const Color(0xFFEF4444); // Red
      case LogLevel.network:
        return const Color(0xFF8B5CF6); // Purple
    }
  }

  IconData _getLevelIcon(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Icons.bug_report_outlined;
      case LogLevel.info:
        return Icons.info_outline;
      case LogLevel.warning:
        return Icons.warning_amber_rounded;
      case LogLevel.error:
        return Icons.error_outline_rounded;
      case LogLevel.network:
        return Icons.swap_calls_rounded;
    }
  }

  void _showSnackBar(String message, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
        backgroundColor: context.colors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "DEV LOG CONSOLE",
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              "Real-time app diagnostics & HTTP logs",
              style: TextStyle(color: colors.textSecondary, fontSize: 11),
            )
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Thứ tự log",
            icon: Icon(
              _newestFirst ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: colors.textPrimary,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _newestFirst = !_newestFirst;
              });
            },
          ),
          IconButton(
            tooltip: "Xuất File Log (Copy)",
            icon: Icon(Icons.share_rounded, color: colors.textPrimary, size: 20),
            onPressed: () {
              final logsText = AppLogger.exportAllLogs();
              Clipboard.setData(ClipboardData(text: logsText));
              _showSnackBar("Đã sao chép toàn bộ log vào clipboard!", context);
            },
          ),
          IconButton(
            tooltip: "Xoá toàn bộ log",
            icon: Icon(Icons.delete_sweep_rounded, color: colors.expenseRed, size: 22),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Xoá sạch log?"),
                  content: const Text("Hành động này sẽ xóa toàn bộ danh sách log trong bộ nhớ hiện tại."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text("HỦY BỎ", style: TextStyle(color: colors.textSecondary)),
                    ),
                    TextButton(
                      onPressed: () {
                        AppLogger.clear();
                        Navigator.pop(ctx);
                        _showSnackBar("Đã xoá sạch log!", context);
                      },
                      child: Text("XÓA SẠCH", style: TextStyle(color: colors.expenseRed, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(98),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.textSecondary.withOpacity(0.12)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: colors.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: "Tìm kiếm url, tag, nội dung...",
                      hintStyle: TextStyle(color: colors.textSecondary.withOpacity(0.6), fontSize: 13),
                      prefixIcon: Icon(Icons.search_rounded, color: colors.textSecondary, size: 18),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: () => _searchController.clear(),
                              child: Icon(Icons.clear_rounded, color: colors.textSecondary, size: 16),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              // Tabs
              TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: colors.primary,
                indicatorWeight: 3,
                labelColor: colors.primary,
                unselectedLabelColor: colors.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                tabs: const [
                  Tab(text: "TẤT CẢ"),
                  Tab(text: "MẠNG (API)"),
                  Tab(text: "LỖI CRASH"),
                  Tab(text: "DEBUG"),
                  Tab(text: "CẢNH BÁO"),
                  Tab(text: "THÔNG TIN"),
                ],
              ),
            ],
          ),
        ),
      ),
      body: ValueListenableBuilder<List<LogEntry>>(
        valueListenable: AppLogger.logsNotifier,
        builder: (context, allLogs, _) {
          final logs = _getFilteredLogs(allLogs);

          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.terminal_rounded, size: 48, color: colors.textSecondary.withOpacity(0.3)),
                  const SizedBox(height: 12),
                  Text(
                    _searchQuery.isNotEmpty ? "Không tìm thấy log phù hợp!" : "Chưa có bản ghi log nào!",
                    style: TextStyle(color: colors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: logs.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final entry = logs[index];
              return _buildLogCard(entry);
            },
          );
        },
      ),
    );
  }

  Widget _buildLogCard(LogEntry entry) {
    final colors = context.colors;
    final levelColor = _getLevelColor(entry.level);
    final icon = _getLevelIcon(entry.level);
    final timeStr = "${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}:${entry.timestamp.second.toString().padLeft(2, '0')}.${entry.timestamp.millisecond.toString().padLeft(3, '0')}";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.textSecondary.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cột dải màu bên trái
              Container(width: 4.5, color: levelColor),
              Expanded(
                child: InkWell(
                  onTap: () => _showLogDetails(entry),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header: Icon + Level + Time + Tag
                        Row(
                          children: [
                            Icon(icon, color: levelColor, size: 14),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: levelColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                entry.levelName,
                                style: TextStyle(
                                  color: levelColor,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            if (entry.tag != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colors.textSecondary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  entry.tag!,
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                            const Spacer(),
                            Text(
                              timeStr,
                              style: TextStyle(
                                color: colors.textSecondary.withOpacity(0.8),
                                fontSize: 10,
                                fontFamily: "monospace",
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(Icons.chevron_right_rounded, color: colors.textSecondary.withOpacity(0.5), size: 16),
                          ],
                        ),
                        const SizedBox(height: 7),
                        // Body log message
                        Text(
                          entry.message,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 12.5,
                            fontFamily: "monospace",
                            fontWeight: entry.level == LogLevel.error ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        // Hiển thị thêm thông tin ngắn nếu là log mạng
                        if (entry.level == LogLevel.network && entry.details != null) ...[
                          const SizedBox(height: 5),
                          _buildNetworkCompactDetails(entry.details),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkCompactDetails(dynamic details) {
    if (details is! Map) return const SizedBox.shrink();
    final colors = context.colors;
    final type = details['type'] as String?;
    final method = details['method'] as String? ?? "GET";
    final url = details['url'] as String? ?? "";
    final statusCode = details['statusCode'];
    final latency = details['latency'] as String? ?? "";

    Color methodBg = colors.primary.withOpacity(0.1);
    Color methodColor = colors.primary;
    if (method == "POST") {
      methodBg = const Color(0xFF10B981).withOpacity(0.1);
      methodColor = const Color(0xFF10B981);
    } else if (method == "DELETE") {
      methodBg = const Color(0xFFEF4444).withOpacity(0.1);
      methodColor = const Color(0xFFEF4444);
    } else if (method == "PUT" || method == "PATCH") {
      methodBg = const Color(0xFFF59E0B).withOpacity(0.1);
      methodColor = const Color(0xFFF59E0B);
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(color: methodBg, borderRadius: BorderRadius.circular(3)),
          child: Text(
            method,
            style: TextStyle(color: methodColor, fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            url,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.textSecondary, fontSize: 10.5),
          ),
        ),
        if (statusCode != null) ...[
          const SizedBox(width: 6),
          Text(
            "$statusCode",
            style: TextStyle(
              color: statusCode >= 200 && statusCode < 300
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
        if (latency.isNotEmpty) ...[
          const SizedBox(width: 6),
          Text(
            latency,
            style: TextStyle(color: colors.textSecondary.withOpacity(0.8), fontSize: 10),
          ),
        ]
      ],
    );
  }

  void _showLogDetails(LogEntry entry) {
    final colors = context.colors;
    final levelColor = _getLevelColor(entry.level);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Thanh kéo modal
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 5),
                  width: 40,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: colors.textSecondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                // Header Sheet
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: levelColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getLevelIcon(entry.level), color: levelColor, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              entry.levelName,
                              style: TextStyle(color: levelColor, fontSize: 10.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (entry.tag != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.textSecondary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            entry.tag!,
                            style: TextStyle(color: colors.textSecondary, fontSize: 10.5, fontWeight: FontWeight.w600),
                          ),
                        ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.copy_rounded, color: colors.primary, size: 20),
                        tooltip: "Sao chép toàn bộ log",
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: entry.toString() + (entry.details != null ? "\nDetails: ${entry.details}" : "") + (entry.stackTrace != null ? "\nStackTrace:\n${entry.stackTrace}" : "")));
                          _showSnackBar("Đã sao chép nội dung log này!", context);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: colors.textSecondary, size: 22),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Divider(color: colors.textSecondary.withOpacity(0.1), height: 1),
                // Content
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      // Thời gian
                      _buildDetailRow("Thời gian xảy ra:", entry.timestamp.toLocal().toString(), context),
                      const SizedBox(height: 12),

                      // Thông điệp Log
                      Text("Thông điệp (Message):", style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colors.textSecondary.withOpacity(0.08)),
                        ),
                        child: SelectableText(
                          entry.message,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 13,
                            fontFamily: "monospace",
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Chi tiết chuyên sâu cho log mạng (Network Details)
                      if (entry.level == LogLevel.network && entry.details != null) ...[
                        _buildNetworkAdvancedDetails(entry.details, context),
                        const SizedBox(height: 16),
                      ],

                      // StackTrace cho log lỗi
                      if (entry.stackTrace != null) ...[
                        Text("Stack Trace:", style: TextStyle(color: colors.expenseRed, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E), // Luôn hiển thị theme tối cho code
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SelectableText(
                            entry.stackTrace.toString(),
                            style: const TextStyle(
                              color: Color(0xFFF8F8F2),
                              fontSize: 11,
                              fontFamily: "monospace",
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Chi tiết đính kèm thông thường
                      if (entry.level != LogLevel.network && entry.details != null) ...[
                        Text("Chi tiết đính kèm (Details):", style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: colors.textSecondary.withOpacity(0.08)),
                          ),
                          child: SelectableText(
                            _formatJsonOrString(entry.details),
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 12.5,
                              fontFamily: "monospace",
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String title, String value, BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(title, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: TextStyle(color: colors.textPrimary, fontSize: 12.5, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkAdvancedDetails(dynamic details, BuildContext context) {
    if (details is! Map) return const SizedBox.shrink();
    final colors = context.colors;

    final url = details['url'] as String? ?? "";
    final method = details['method'] as String? ?? "";
    final statusCode = details['statusCode'];
    final latency = details['latency'] as String? ?? "";
    final queryParams = details['queryParams'] as Map?;
    final requestHeaders = details['headers'] as Map?;
    final body = details['body'];
    final errorMsg = details['error'] as String?;
    final errorType = details['errorType'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text("CHI TIẾT YÊU CẦU MẠNG (HTTP DIAGNOSTICS)", style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        _buildDetailRow("Đường dẫn (URL):", url, context),
        const SizedBox(height: 8),
        _buildDetailRow("Phương thức:", method, context),
        const SizedBox(height: 8),
        if (statusCode != null) ...[
          _buildDetailRow(
            "Trạng thái (Code):",
            "$statusCode",
            context,
          ),
          const SizedBox(height: 8),
        ],
        _buildDetailRow("Độ trễ phản hồi:", latency, context),
        if (errorMsg != null) ...[
          const SizedBox(height: 8),
          _buildDetailRow("Mã lỗi Dio:", errorType ?? "Unknown", context),
          const SizedBox(height: 8),
          _buildDetailRow("Chi tiết lỗi:", errorMsg, context),
        ],
        const SizedBox(height: 16),

        // Request Headers
        if (requestHeaders != null && requestHeaders.isNotEmpty) ...[
          _buildCollapsiblePayload("Headers", _formatJsonOrString(requestHeaders), context),
          const SizedBox(height: 10),
        ],

        // Query parameters
        if (queryParams != null && queryParams.isNotEmpty) ...[
          _buildCollapsiblePayload("Query Parameters", _formatJsonOrString(queryParams), context),
          const SizedBox(height: 10),
        ],

        // Body request / response
        if (body != null) ...[
          _buildCollapsiblePayload(
            statusCode != null ? "Response Body (Phản hồi)" : "Request Body (Yêu cầu gửi đi)",
            _formatJsonOrString(body),
            context,
            isCode: true,
          ),
        ],
      ],
    );
  }

  Widget _buildCollapsiblePayload(String title, String content, BuildContext context, {bool isCode = false}) {
    final colors = context.colors;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.textSecondary.withOpacity(0.08)),
        ),
        child: ExpansionTile(
          title: Text(
            title,
            style: TextStyle(color: colors.textPrimary, fontSize: 12.5, fontWeight: FontWeight.bold),
          ),
          iconColor: colors.primary,
          collapsedIconColor: colors.textSecondary,
          childrenPadding: const EdgeInsets.all(12),
          expandedAlignment: Alignment.topLeft,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: content));
                    _showSnackBar("Đã sao chép $title!", context);
                  },
                  child: Row(
                    children: [
                      Icon(Icons.copy_rounded, color: colors.primary, size: 13),
                      const SizedBox(width: 4),
                      Text("Sao chép", style: TextStyle(color: colors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isCode ? const Color(0xFF1E1E1E) : colors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: colors.textSecondary.withOpacity(0.05)),
              ),
              child: SelectableText(
                content,
                style: TextStyle(
                  color: isCode ? const Color(0xFFF8F8F2) : colors.textPrimary,
                  fontSize: 11.5,
                  fontFamily: "monospace",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatJsonOrString(dynamic body) {
    if (body == null) return "null";
    try {
      if (body is Map || body is List) {
        const encoder = JsonEncoder.withIndent('  ');
        return encoder.convert(body);
      }
      return body.toString();
    } catch (_) {
      return body.toString();
    }
  }
}
