import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error, network }

class LogEntry {
  final String id;
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? tag;
  final dynamic details;
  final StackTrace? stackTrace;

  LogEntry({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.message,
    this.tag,
    this.details,
    this.stackTrace,
  });

  String get levelName => level.name.toUpperCase();

  @override
  String toString() {
    final timeStr = "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}";
    final tagStr = tag != null ? "[$tag]" : "";
    return "[$timeStr] [$levelName]$tagStr $message";
  }
}

class AppLogger {
  static const int maxLogs = 500;
  static final ValueNotifier<List<LogEntry>> logsNotifier = ValueNotifier<List<LogEntry>>([]);

  // Cấu hình chung cho floating bubble console
  static final ValueNotifier<bool> isConsoleOverlayVisible = ValueNotifier<bool>(false);

  static void debug(String message, {String? tag, dynamic details}) {
    _log(LogLevel.debug, message, tag: tag, details: details);
  }

  static void info(String message, {String? tag, dynamic details}) {
    _log(LogLevel.info, message, tag: tag, details: details);
  }

  static void warning(String message, {String? tag, dynamic details}) {
    _log(LogLevel.warning, message, tag: tag, details: details);
  }

  static void error(String message, {String? tag, dynamic details, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, tag: tag, details: details, stackTrace: stackTrace);
  }

  static void network(String message, {String? tag, dynamic details}) {
    _log(LogLevel.network, message, tag: tag, details: details);
  }

  static void clear() {
    logsNotifier.value = [];
  }

  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    dynamic details,
    StackTrace? stackTrace,
  }) {
    final entry = LogEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      level: level,
      message: message,
      tag: tag,
      details: details,
      stackTrace: stackTrace,
    );

    // Lưu vào ValueNotifier để UI update real-time
    final currentList = List<LogEntry>.from(logsNotifier.value);
    currentList.add(entry);

    if (currentList.length > maxLogs) {
      currentList.removeAt(0); // Xoá log cũ nhất để tránh rò rỉ bộ nhớ
    }
    logsNotifier.value = currentList;

    // Xuất ra Terminal Console với màu sắc (ANSI escape codes) để dev dễ quan sát
    final colorCode = _getAnsiColor(level);
    final tagPart = tag != null ? "[$tag]" : "";
    final logText = "$colorCode[EM-LOG] [${entry.levelName}]$tagPart $message\x1B[0m";

    if (level == LogLevel.error) {
      dev.log(message, name: 'EM-LOG', error: message, stackTrace: stackTrace, level: 1000);
      debugPrint(logText);
      if (stackTrace != null) {
        debugPrint("$colorCode$stackTrace\x1B[0m");
      }
    } else {
      dev.log(message, name: 'EM-LOG', level: _getDevLogLevel(level));
      debugPrint(logText);
    }
  }

  static String _getAnsiColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return "\x1B[37m"; // Grey
      case LogLevel.info:
        return "\x1B[36m"; // Cyan
      case LogLevel.warning:
        return "\x1B[33m"; // Yellow
      case LogLevel.error:
        return "\x1B[31m"; // Red
      case LogLevel.network:
        return "\x1B[35m"; // Magenta/Purple
    }
  }

  static int _getDevLogLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
      case LogLevel.network:
        return 700;
    }
  }

  static String exportAllLogs() {
    final buffer = StringBuffer();
    buffer.writeln("=== EXPENSE MANAGEMENT APP LOG EXPORT ===");
    buffer.writeln("Exported at: ${DateTime.now().toIso8601String()}");
    buffer.writeln("Total logs: ${logsNotifier.value.length}");
    buffer.writeln("=========================================\n");

    for (final entry in logsNotifier.value) {
      buffer.writeln(entry.toString());
      if (entry.details != null) {
        buffer.writeln("Details: ${entry.details}");
      }
      if (entry.stackTrace != null) {
        buffer.writeln("StackTrace:\n${entry.stackTrace}");
      }
      buffer.writeln("-" * 40);
    }
    return buffer.toString();
  }
}
