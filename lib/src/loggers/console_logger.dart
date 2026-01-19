import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Log severity levels
enum LogLevel {
  verbose,
  debug,
  info,
  warning,
  error,
}

/// Represents a single console log entry
class ConsoleLog {
  final String id;
  final String message;
  final String? tag;
  final LogLevel level;
  final DateTime timestamp;
  final dynamic error;
  final StackTrace? stackTrace;

  ConsoleLog({
    required this.id,
    required this.message,
    this.tag,
    required this.level,
    required this.timestamp,
    this.error,
    this.stackTrace,
  });

  /// Get the log level as a string
  String get levelString => level.name.toUpperCase();

  /// Get formatted timestamp
  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}.'
        '${timestamp.millisecond.toString().padLeft(3, '0')}';
  }

  /// Get full formatted output
  String get formatted {
    final buffer = StringBuffer();
    buffer.write('[$formattedTime]');
    buffer.write(' [${level.name.toUpperCase()}]');
    if (tag != null) buffer.write(' [$tag]');
    buffer.write(': $message');
    if (error != null) buffer.write('\nError: $error');
    if (stackTrace != null) buffer.write('\nStackTrace: $stackTrace');
    return buffer.toString();
  }

  /// Convert to map for export
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'tag': tag,
      'level': level.name,
      'timestamp': timestamp.toIso8601String(),
      'error': error?.toString(),
      'stackTrace': stackTrace?.toString(),
    };
  }
}

/// Service that manages console logs
class ConsoleLogger {
  /// Maximum number of logs to keep
  int maxLogs = 500;

  /// List of console logs
  final List<ConsoleLog> _logs = [];

  /// Notifier for UI updates
  final ValueNotifier<int> logCountNotifier = ValueNotifier(0);

  /// Get all logs (most recent first)
  List<ConsoleLog> get logs => List.unmodifiable(_logs.reversed);

  /// Get total log count
  int get count => _logs.length;

  /// Get counts by level
  int getCountByLevel(LogLevel level) => _logs.where((l) => l.level == level).length;

  /// Clear all logs
  void clear() {
    _logs.clear();
    logCountNotifier.value = 0;
  }

  /// Log a message
  void log(
    String message, {
    String? tag,
    LogLevel level = LogLevel.debug,
  }) {
    if (!kDebugMode) return;

    final log = ConsoleLog(
      id: '${DateTime.now().millisecondsSinceEpoch}_${_logs.length}',
      message: message,
      tag: tag,
      level: level,
      timestamp: DateTime.now(),
    );

    _addLog(log);

    // Also print to console
    if (kDebugMode) {
      debugPrint(log.formatted);
    }
  }

  /// Log an error
  void logError(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    if (!kDebugMode) return;

    final log = ConsoleLog(
      id: '${DateTime.now().millisecondsSinceEpoch}_${_logs.length}',
      message: message,
      tag: tag,
      level: LogLevel.error,
      timestamp: DateTime.now(),
      error: error,
      stackTrace: stackTrace,
    );

    _addLog(log);

    // Also print to console
    if (kDebugMode) {
      debugPrint(log.formatted);
    }
  }

  /// Log verbose message
  void verbose(String message, {String? tag}) => log(message, tag: tag, level: LogLevel.verbose);

  /// Log debug message
  void debug(String message, {String? tag}) => log(message, tag: tag, level: LogLevel.debug);

  /// Log info message
  void info(String message, {String? tag}) => log(message, tag: tag, level: LogLevel.info);

  /// Log warning message
  void warning(String message, {String? tag}) => log(message, tag: tag, level: LogLevel.warning);

  /// Log error message
  void error(String message, {dynamic err, StackTrace? stackTrace, String? tag}) =>
      logError(message, error: err, stackTrace: stackTrace, tag: tag);

  /// Search logs
  List<ConsoleLog> search(String query) {
    final lowerQuery = query.toLowerCase();
    return _logs.where((log) {
      return log.message.toLowerCase().contains(lowerQuery) ||
          (log.tag?.toLowerCase().contains(lowerQuery) ?? false) ||
          log.levelString.toLowerCase().contains(lowerQuery);
    }).toList().reversed.toList();
  }

  /// Filter logs by level
  List<ConsoleLog> filterByLevel(LogLevel? level) {
    if (level == null) return logs;
    return logs.where((l) => l.level == level).toList();
  }

  /// Export all logs as JSON
  String exportAsJson() {
    final data = _logs.map((l) => l.toJson()).toList();
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Export all logs as plain text
  String exportAsText() {
    return _logs.map((l) => l.formatted).join('\n');
  }

  void _addLog(ConsoleLog log) {
    _logs.add(log);

    // Remove oldest logs if we exceed max
    while (_logs.length > maxLogs) {
      _logs.removeAt(0);
    }

    logCountNotifier.value = _logs.length;
  }
}

