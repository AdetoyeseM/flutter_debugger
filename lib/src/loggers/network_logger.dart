import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Represents a single network request log entry
class NetworkLog {
  final String id;
  final String method;
  final String url;
  final Map<String, String>? requestHeaders;
  final dynamic requestBody;
  final int? statusCode;
  final dynamic responseBody;
  final Map<String, String>? responseHeaders;
  final DateTime timestamp;
  final DateTime? completedAt;
  final Duration? duration;
  final String? error;
  final int? requestSize;
  final int? responseSize;

  NetworkLog({
    required this.id,
    required this.method,
    required this.url,
    this.requestHeaders,
    this.requestBody,
    this.statusCode,
    this.responseBody,
    this.responseHeaders,
    required this.timestamp,
    this.completedAt,
    this.duration,
    this.error,
    this.requestSize,
    this.responseSize,
  });

  /// Whether the request was successful
  bool get isSuccess => statusCode != null && statusCode! >= 200 && statusCode! < 300;

  /// Whether the request is still pending
  bool get isPending => statusCode == null && error == null;

  /// Whether the request failed
  bool get isError => error != null || (statusCode != null && statusCode! >= 400);

  /// Returns the path portion of the URL
  String get path {
    try {
      final uri = Uri.parse(url);
      return uri.path.isEmpty ? '/' : uri.path;
    } catch (_) {
      return url;
    }
  }

  /// Returns the host portion of the URL
  String get host {
    try {
      return Uri.parse(url).host;
    } catch (_) {
      return '';
    }
  }

  /// Returns query parameters as a map
  Map<String, String> get queryParams {
    try {
      return Uri.parse(url).queryParameters;
    } catch (_) {
      return {};
    }
  }

  /// Returns formatted request body as JSON string
  String get formattedRequestBody {
    if (requestBody == null) return 'No body';
    try {
      if (requestBody is String) {
        final decoded = jsonDecode(requestBody);
        return const JsonEncoder.withIndent('  ').convert(decoded);
      }
      return const JsonEncoder.withIndent('  ').convert(requestBody);
    } catch (_) {
      return requestBody.toString();
    }
  }

  /// Returns formatted response body as JSON string
  String get formattedResponseBody {
    if (responseBody == null) return error ?? 'No response';
    try {
      if (responseBody is String) {
        final decoded = jsonDecode(responseBody);
        return const JsonEncoder.withIndent('  ').convert(decoded);
      }
      return const JsonEncoder.withIndent('  ').convert(responseBody);
    } catch (_) {
      return responseBody.toString();
    }
  }

  /// Returns a color-coded status text
  String get statusText {
    if (error != null) return 'ERROR';
    if (statusCode == null) return 'PENDING';
    return statusCode.toString();
  }

  /// Get request size as formatted string
  String get formattedRequestSize {
    if (requestSize == null) return '-';
    return _formatBytes(requestSize!);
  }

  /// Get response size as formatted string
  String get formattedResponseSize {
    if (responseSize == null) return '-';
    return _formatBytes(responseSize!);
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Create a copy with updated values
  NetworkLog copyWith({
    int? statusCode,
    dynamic responseBody,
    Map<String, String>? responseHeaders,
    DateTime? completedAt,
    Duration? duration,
    String? error,
    int? responseSize,
  }) {
    return NetworkLog(
      id: id,
      method: method,
      url: url,
      requestHeaders: requestHeaders,
      requestBody: requestBody,
      statusCode: statusCode ?? this.statusCode,
      responseBody: responseBody ?? this.responseBody,
      responseHeaders: responseHeaders ?? this.responseHeaders,
      timestamp: timestamp,
      completedAt: completedAt ?? this.completedAt,
      duration: duration ?? this.duration,
      error: error ?? this.error,
      requestSize: requestSize,
      responseSize: responseSize ?? this.responseSize,
    );
  }

  /// Convert to map for export
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'method': method,
      'url': url,
      'requestHeaders': requestHeaders,
      'requestBody': requestBody,
      'statusCode': statusCode,
      'responseBody': responseBody,
      'responseHeaders': responseHeaders,
      'timestamp': timestamp.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'duration': duration?.inMilliseconds,
      'error': error,
      'requestSize': requestSize,
      'responseSize': responseSize,
    };
  }
}

/// Service that logs all network requests
class NetworkLogger {
  /// Maximum number of logs to keep
  int maxLogs = 100;

  /// List of network logs
  final List<NetworkLog> _logs = [];

  /// Headers to redact from logs
  List<String> redactedHeaders = ['Authorization', 'Cookie', 'X-Api-Key'];

  /// Notifier for UI updates
  final ValueNotifier<int> logCountNotifier = ValueNotifier(0);

  /// Get all logs (most recent first)
  List<NetworkLog> get logs => List.unmodifiable(_logs.reversed);

  /// Get total log count
  int get count => _logs.length;

  /// Get successful request count
  int get successCount => _logs.where((l) => l.isSuccess).length;

  /// Get failed request count
  int get errorCount => _logs.where((l) => l.isError).length;

  /// Get pending request count
  int get pendingCount => _logs.where((l) => l.isPending).length;

  /// Clear all logs
  void clear() {
    _logs.clear();
    logCountNotifier.value = 0;
  }

  /// Start logging a request (returns request ID)
  String logRequest({
    required String method,
    required String url,
    Map<String, String>? headers,
    dynamic body,
  }) {
    if (!kDebugMode) return '';

    final id = '${DateTime.now().millisecondsSinceEpoch}_${_logs.length}';
    
    // Redact sensitive headers
    final safeHeaders = headers != null ? _redactHeaders(headers) : null;

    // Calculate request size
    int? requestSize;
    if (body != null) {
      try {
        final bodyString = body is String ? body : jsonEncode(body);
        requestSize = bodyString.length;
      } catch (_) {}
    }

    final log = NetworkLog(
      id: id,
      method: method.toUpperCase(),
      url: url,
      requestHeaders: safeHeaders,
      requestBody: body,
      timestamp: DateTime.now(),
      requestSize: requestSize,
    );

    _addLog(log);
    return id;
  }

  /// Complete a request with response data
  void logResponse({
    required String id,
    required int? statusCode,
    dynamic responseBody,
    Map<String, String>? responseHeaders,
    Duration? duration,
    String? error,
  }) {
    if (!kDebugMode) return;

    final index = _logs.indexWhere((log) => log.id == id);
    if (index == -1) return;

    // Calculate response size
    int? responseSize;
    if (responseBody != null) {
      try {
        final bodyString = responseBody is String ? responseBody : jsonEncode(responseBody);
        responseSize = bodyString.length;
      } catch (_) {}
    }

    final existingLog = _logs[index];
    final updatedLog = existingLog.copyWith(
      statusCode: statusCode,
      responseBody: responseBody,
      responseHeaders: responseHeaders != null ? _redactHeaders(responseHeaders) : null,
      completedAt: DateTime.now(),
      duration: duration,
      error: error,
      responseSize: responseSize,
    );

    _logs[index] = updatedLog;
    logCountNotifier.value = _logs.length;
  }

  /// Add a complete log entry (request + response in one call)
  void logComplete({
    required String method,
    required String url,
    Map<String, String>? requestHeaders,
    dynamic requestBody,
    int? statusCode,
    dynamic responseBody,
    Map<String, String>? responseHeaders,
    Duration? duration,
    String? error,
  }) {
    if (!kDebugMode) return;

    // Calculate sizes
    int? requestSize;
    int? responseSize;
    
    if (requestBody != null) {
      try {
        final bodyString = requestBody is String ? requestBody : jsonEncode(requestBody);
        requestSize = bodyString.length;
      } catch (_) {}
    }
    
    if (responseBody != null) {
      try {
        final bodyString = responseBody is String ? responseBody : jsonEncode(responseBody);
        responseSize = bodyString.length;
      } catch (_) {}
    }

    final log = NetworkLog(
      id: '${DateTime.now().millisecondsSinceEpoch}_${_logs.length}',
      method: method.toUpperCase(),
      url: url,
      requestHeaders: requestHeaders != null ? _redactHeaders(requestHeaders) : null,
      requestBody: requestBody,
      statusCode: statusCode,
      responseBody: responseBody,
      responseHeaders: responseHeaders != null ? _redactHeaders(responseHeaders) : null,
      timestamp: DateTime.now(),
      completedAt: DateTime.now(),
      duration: duration,
      error: error,
      requestSize: requestSize,
      responseSize: responseSize,
    );

    _addLog(log);
  }

  /// Export all logs as JSON
  String exportAsJson() {
    final data = _logs.map((l) => l.toJson()).toList();
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Search logs by URL or method
  List<NetworkLog> search(String query) {
    final lowerQuery = query.toLowerCase();
    return _logs.where((log) {
      return log.url.toLowerCase().contains(lowerQuery) ||
          log.method.toLowerCase().contains(lowerQuery) ||
          log.statusText.toLowerCase().contains(lowerQuery);
    }).toList().reversed.toList();
  }

  /// Filter logs by status
  List<NetworkLog> filterByStatus(NetworkLogStatus status) {
    switch (status) {
      case NetworkLogStatus.success:
        return logs.where((l) => l.isSuccess).toList();
      case NetworkLogStatus.error:
        return logs.where((l) => l.isError).toList();
      case NetworkLogStatus.pending:
        return logs.where((l) => l.isPending).toList();
      case NetworkLogStatus.all:
        return logs;
    }
  }

  Map<String, String> _redactHeaders(Map<String, String> headers) {
    final result = <String, String>{};
    headers.forEach((key, value) {
      if (redactedHeaders.any((h) => h.toLowerCase() == key.toLowerCase())) {
        result[key] = '[REDACTED]';
      } else {
        result[key] = value;
      }
    });
    return result;
  }

  void _addLog(NetworkLog log) {
    _logs.add(log);

    // Remove oldest logs if we exceed max
    while (_logs.length > maxLogs) {
      _logs.removeAt(0);
    }

    logCountNotifier.value = _logs.length;
  }
}

/// Filter options for network logs
enum NetworkLogStatus {
  all,
  success,
  error,
  pending,
}

