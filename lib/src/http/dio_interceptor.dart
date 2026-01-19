import 'package:flutter/foundation.dart';

import '../dev_tools.dart';

/// Type definitions for Dio classes to avoid hard dependency
typedef DioError = dynamic;
typedef RequestOptions = dynamic;
typedef Response = dynamic;
typedef RequestInterceptorHandler = dynamic;
typedef ResponseInterceptorHandler = dynamic;
typedef ErrorInterceptorHandler = dynamic;

/// A Dio interceptor that automatically logs all requests to DevTools
/// 
/// Usage:
/// ```dart
/// final dio = Dio();
/// dio.interceptors.add(DevToolsDioInterceptor());
/// ```
/// 
/// Note: This interceptor works with any Dio version that follows the
/// standard interceptor pattern.
class DevToolsDioInterceptor {
  /// Map to store request start times for duration calculation
  final Map<int, DateTime> _requestStartTimes = {};
  
  /// Map to store log IDs for request/response matching
  final Map<int, String> _requestLogIds = {};

  /// Called when a request is about to be sent
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!kDebugMode) {
      handler.next(options);
      return;
    }

    final requestId = options.hashCode;
    _requestStartTimes[requestId] = DateTime.now();

    // Extract headers
    final headers = <String, String>{};
    options.headers.forEach((key, value) {
      headers[key.toString()] = value.toString();
    });

    // Log the request
    final logId = devTools.network.logRequest(
      method: options.method,
      url: options.uri.toString(),
      headers: headers,
      body: options.data,
    );
    
    _requestLogIds[requestId] = logId;
    
    handler.next(options);
  }

  /// Called when a response is received
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (!kDebugMode) {
      handler.next(response);
      return;
    }

    final requestId = response.requestOptions.hashCode;
    final startTime = _requestStartTimes.remove(requestId);
    final logId = _requestLogIds.remove(requestId);

    if (logId != null) {
      final duration = startTime != null 
          ? DateTime.now().difference(startTime) 
          : null;

      // Extract response headers
      final headers = <String, String>{};
      response.headers.forEach((name, values) {
        headers[name] = values.join(', ');
      });

      devTools.network.logResponse(
        id: logId,
        statusCode: response.statusCode,
        responseBody: response.data,
        responseHeaders: headers,
        duration: duration,
      );
    }

    handler.next(response);
  }

  /// Called when an error occurs
  void onError(DioError err, ErrorInterceptorHandler handler) {
    if (!kDebugMode) {
      handler.next(err);
      return;
    }

    final requestId = err.requestOptions.hashCode;
    final startTime = _requestStartTimes.remove(requestId);
    final logId = _requestLogIds.remove(requestId);

    if (logId != null) {
      final duration = startTime != null 
          ? DateTime.now().difference(startTime) 
          : null;

      devTools.network.logResponse(
        id: logId,
        statusCode: err.response?.statusCode,
        responseBody: err.response?.data,
        duration: duration,
        error: err.message ?? err.toString(),
      );
    }

    handler.next(err);
  }
}

/// Helper to create a Dio interceptor callbacks map
/// 
/// Usage with Dio:
/// ```dart
/// import 'package:dio/dio.dart';
/// 
/// final dio = Dio();
/// final devToolsInterceptor = DevToolsDioInterceptor();
/// 
/// dio.interceptors.add(InterceptorsWrapper(
///   onRequest: devToolsInterceptor.onRequest,
///   onResponse: devToolsInterceptor.onResponse,
///   onError: devToolsInterceptor.onError,
/// ));
/// ```

/// Manual logging helper for Dio requests when interceptor can't be used
/// 
/// Usage:
/// ```dart
/// final response = await DioDevTools.request(
///   dio,
///   () => dio.get('https://api.example.com/users'),
/// );
/// ```
class DioDevTools {
  /// Wrap a Dio request with automatic logging
  static Future<T> request<T>(
    dynamic dio,
    Future<T> Function() request, {
    String? method,
    String? url,
  }) async {
    if (!kDebugMode) {
      return request();
    }

    final stopwatch = Stopwatch()..start();
    
    try {
      final response = await request();
      stopwatch.stop();
      
      // Try to extract info from response
      try {
        final reqOptions = (response as dynamic).requestOptions;
        final headers = <String, String>{};
        reqOptions.headers.forEach((key, value) {
          headers[key.toString()] = value.toString();
        });
        
        final respHeaders = <String, String>{};
        (response as dynamic).headers.forEach((name, values) {
          respHeaders[name] = (values as List).join(', ');
        });
        
        devTools.network.logComplete(
          method: method ?? reqOptions.method,
          url: url ?? reqOptions.uri.toString(),
          requestHeaders: headers,
          requestBody: reqOptions.data,
          statusCode: (response as dynamic).statusCode,
          responseBody: (response as dynamic).data,
          responseHeaders: respHeaders,
          duration: stopwatch.elapsed,
        );
      } catch (_) {
        // If we can't extract info, just log what we have
        devTools.network.logComplete(
          method: method ?? 'UNKNOWN',
          url: url ?? 'unknown',
          statusCode: 200,
          duration: stopwatch.elapsed,
        );
      }
      
      return response;
    } catch (e) {
      stopwatch.stop();
      
      // Try to extract error info
      try {
        final reqOptions = (e as dynamic).requestOptions;
        devTools.network.logComplete(
          method: method ?? reqOptions.method,
          url: url ?? reqOptions.uri.toString(),
          statusCode: (e as dynamic).response?.statusCode,
          responseBody: (e as dynamic).response?.data,
          duration: stopwatch.elapsed,
          error: (e as dynamic).message ?? e.toString(),
        );
      } catch (_) {
        devTools.network.logComplete(
          method: method ?? 'UNKNOWN',
          url: url ?? 'unknown',
          duration: stopwatch.elapsed,
          error: e.toString(),
        );
      }
      
      rethrow;
    }
  }
}

