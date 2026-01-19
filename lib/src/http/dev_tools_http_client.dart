import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../dev_tools.dart';

/// HTTP client wrapper that automatically logs all requests to DevTools
class DevToolsHttpClient extends http.BaseClient {
  final http.Client _inner;

  DevToolsHttpClient([http.Client? client]) : _inner = client ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (!kDebugMode) {
      return _inner.send(request);
    }

    final stopwatch = Stopwatch()..start();
    
    // Extract request body if available
    dynamic requestBody;
    if (request is http.Request) {
      try {
        requestBody = jsonDecode(request.body);
      } catch (_) {
        requestBody = request.body;
      }
    }

    // Log the request
    final logId = devTools.network.logRequest(
      method: request.method,
      url: request.url.toString(),
      headers: request.headers,
      body: requestBody,
    );

    try {
      final response = await _inner.send(request);
      stopwatch.stop();

      // Read response body
      final bytes = await response.stream.toBytes();
      final responseBody = utf8.decode(bytes);
      
      dynamic parsedResponse;
      try {
        parsedResponse = jsonDecode(responseBody);
      } catch (_) {
        parsedResponse = responseBody;
      }

      // Log the response
      devTools.network.logResponse(
        id: logId,
        statusCode: response.statusCode,
        responseBody: parsedResponse,
        responseHeaders: response.headers,
        duration: stopwatch.elapsed,
      );

      // Return a new StreamedResponse with the already-read bytes
      return http.StreamedResponse(
        Stream.value(bytes),
        response.statusCode,
        headers: response.headers,
        contentLength: response.contentLength,
        request: response.request,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
      );
    } catch (e) {
      stopwatch.stop();
      
      // Log the error
      devTools.network.logResponse(
        id: logId,
        statusCode: null,
        error: e.toString(),
        duration: stopwatch.elapsed,
      );
      
      rethrow;
    }
  }

  @override
  void close() {
    _inner.close();
  }
}

/// Extension methods for easy HTTP calls with logging
extension DevToolsHttpExtension on http.Client {
  /// Wrap this client with DevTools logging
  DevToolsHttpClient withDevTools() => DevToolsHttpClient(this);
}

/// Convenience methods for making HTTP requests with automatic logging
class DevToolsHttp {
  static final DevToolsHttpClient _client = DevToolsHttpClient();

  /// GET request with automatic logging
  static Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    return _client.get(url, headers: headers);
  }

  /// POST request with automatic logging
  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return _client.post(url, headers: headers, body: body, encoding: encoding);
  }

  /// PUT request with automatic logging
  static Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return _client.put(url, headers: headers, body: body, encoding: encoding);
  }

  /// PATCH request with automatic logging
  static Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return _client.patch(url, headers: headers, body: body, encoding: encoding);
  }

  /// DELETE request with automatic logging
  static Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    return _client.delete(url, headers: headers, body: body, encoding: encoding);
  }
}

