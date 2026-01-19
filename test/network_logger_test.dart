import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_debugger/flutter_debugger.dart';

void main() {
  group('NetworkLogger', () {
    late NetworkLogger logger;

    setUp(() {
      logger = NetworkLogger();
      logger.clear();
    });

    test('should start with empty logs', () {
      expect(logger.logs, isEmpty);
      expect(logger.count, 0);
    });

    test('should log a complete request', () {
      logger.logComplete(
        method: 'GET',
        url: 'https://api.example.com/users',
        statusCode: 200,
        responseBody: {'users': []},
        duration: const Duration(milliseconds: 150),
      );

      expect(logger.count, 1);
      expect(logger.logs.first.method, 'GET');
      expect(logger.logs.first.url, 'https://api.example.com/users');
      expect(logger.logs.first.statusCode, 200);
      expect(logger.logs.first.isSuccess, true);
    });

    test('should track success and error counts', () {
      logger.logComplete(
        method: 'GET',
        url: 'https://api.example.com/users',
        statusCode: 200,
      );
      
      logger.logComplete(
        method: 'POST',
        url: 'https://api.example.com/error',
        statusCode: 500,
      );

      expect(logger.successCount, 1);
      expect(logger.errorCount, 1);
    });

    test('should log request and response separately', () {
      final logId = logger.logRequest(
        method: 'POST',
        url: 'https://api.example.com/login',
        headers: {'Content-Type': 'application/json'},
        body: {'email': 'test@example.com'},
      );

      expect(logger.count, 1);
      expect(logger.logs.first.isPending, true);

      logger.logResponse(
        id: logId,
        statusCode: 200,
        responseBody: {'token': 'abc123'},
        duration: const Duration(milliseconds: 100),
      );

      expect(logger.logs.first.statusCode, 200);
      expect(logger.logs.first.isPending, false);
    });

    test('should redact sensitive headers', () {
      logger.redactedHeaders = ['Authorization', 'Cookie'];
      
      logger.logComplete(
        method: 'GET',
        url: 'https://api.example.com/secure',
        requestHeaders: {
          'Authorization': 'Bearer secret-token',
          'Content-Type': 'application/json',
        },
        statusCode: 200,
      );

      final headers = logger.logs.first.requestHeaders!;
      expect(headers['Authorization'], '[REDACTED]');
      expect(headers['Content-Type'], 'application/json');
    });

    test('should limit logs to maxLogs', () {
      logger.maxLogs = 5;

      for (int i = 0; i < 10; i++) {
        logger.logComplete(
          method: 'GET',
          url: 'https://api.example.com/item/$i',
          statusCode: 200,
        );
      }

      expect(logger.count, 5);
    });

    test('should search logs by URL', () {
      logger.logComplete(method: 'GET', url: 'https://api.example.com/users', statusCode: 200);
      logger.logComplete(method: 'GET', url: 'https://api.example.com/posts', statusCode: 200);
      logger.logComplete(method: 'GET', url: 'https://api.example.com/users/1', statusCode: 200);

      final results = logger.search('users');
      expect(results.length, 2);
    });

    test('should filter logs by status', () {
      logger.logComplete(method: 'GET', url: 'url1', statusCode: 200);
      logger.logComplete(method: 'GET', url: 'url2', statusCode: 404);
      logger.logComplete(method: 'GET', url: 'url3', statusCode: 500);

      expect(logger.filterByStatus(NetworkLogStatus.success).length, 1);
      expect(logger.filterByStatus(NetworkLogStatus.error).length, 2);
      expect(logger.filterByStatus(NetworkLogStatus.all).length, 3);
    });

    test('should clear all logs', () {
      logger.logComplete(method: 'GET', url: 'url', statusCode: 200);
      logger.logComplete(method: 'POST', url: 'url', statusCode: 201);

      expect(logger.count, 2);

      logger.clear();

      expect(logger.count, 0);
      expect(logger.logs, isEmpty);
    });
  });

  group('NetworkLog', () {
    test('should parse path from URL', () {
      final log = NetworkLog(
        id: '1',
        method: 'GET',
        url: 'https://api.example.com/users/123?filter=active',
        timestamp: DateTime.now(),
      );

      expect(log.path, '/users/123');
      expect(log.host, 'api.example.com');
    });

    test('should format request body as JSON', () {
      final log = NetworkLog(
        id: '1',
        method: 'POST',
        url: 'https://api.example.com/users',
        requestBody: {'name': 'John', 'email': 'john@example.com'},
        timestamp: DateTime.now(),
      );

      expect(log.formattedRequestBody, contains('name'));
      expect(log.formattedRequestBody, contains('John'));
    });

    test('should determine success status correctly', () {
      expect(
        NetworkLog(id: '1', method: 'GET', url: 'url', statusCode: 200, timestamp: DateTime.now()).isSuccess,
        true,
      );
      expect(
        NetworkLog(id: '1', method: 'GET', url: 'url', statusCode: 299, timestamp: DateTime.now()).isSuccess,
        true,
      );
      expect(
        NetworkLog(id: '1', method: 'GET', url: 'url', statusCode: 300, timestamp: DateTime.now()).isSuccess,
        false,
      );
      expect(
        NetworkLog(id: '1', method: 'GET', url: 'url', statusCode: 404, timestamp: DateTime.now()).isSuccess,
        false,
      );
    });
  });
}

