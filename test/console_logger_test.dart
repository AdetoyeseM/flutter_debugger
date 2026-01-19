import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dev_tools/flutter_dev_tools.dart';

void main() {
  group('ConsoleLogger', () {
    late ConsoleLogger logger;

    setUp(() {
      logger = ConsoleLogger();
      logger.clear();
    });

    test('should start with empty logs', () {
      expect(logger.logs, isEmpty);
      expect(logger.count, 0);
    });

    test('should log messages with different levels', () {
      logger.verbose('Verbose message');
      logger.debug('Debug message');
      logger.info('Info message');
      logger.warning('Warning message');
      logger.error('Error message');

      expect(logger.count, 5);
      expect(logger.getCountByLevel(LogLevel.verbose), 1);
      expect(logger.getCountByLevel(LogLevel.debug), 1);
      expect(logger.getCountByLevel(LogLevel.info), 1);
      expect(logger.getCountByLevel(LogLevel.warning), 1);
      expect(logger.getCountByLevel(LogLevel.error), 1);
    });

    test('should log message with tag', () {
      logger.log('Test message', tag: 'TEST_TAG');

      expect(logger.logs.first.tag, 'TEST_TAG');
      expect(logger.logs.first.message, 'Test message');
    });

    test('should log error with error object and stack trace', () {
      final error = Exception('Test error');
      final stackTrace = StackTrace.current;

      logger.logError('Error occurred', error: error, stackTrace: stackTrace);

      expect(logger.logs.first.error, error);
      expect(logger.logs.first.stackTrace, stackTrace);
      expect(logger.logs.first.level, LogLevel.error);
    });

    test('should limit logs to maxLogs', () {
      logger.maxLogs = 5;

      for (int i = 0; i < 10; i++) {
        logger.log('Message $i');
      }

      expect(logger.count, 5);
    });

    test('should filter logs by level', () {
      logger.info('Info 1');
      logger.info('Info 2');
      logger.error('Error 1');
      logger.warning('Warning 1');

      final errorLogs = logger.filterByLevel(LogLevel.error);
      final infoLogs = logger.filterByLevel(LogLevel.info);
      final allLogs = logger.filterByLevel(null);

      expect(errorLogs.length, 1);
      expect(infoLogs.length, 2);
      expect(allLogs.length, 4);
    });

    test('should search logs', () {
      logger.log('User logged in', tag: 'AUTH');
      logger.log('User logged out', tag: 'AUTH');
      logger.log('Data fetched', tag: 'API');

      final authResults = logger.search('AUTH');
      final loginResults = logger.search('logged');

      expect(authResults.length, 2);
      expect(loginResults.length, 2);
    });

    test('should clear all logs', () {
      logger.log('Message 1');
      logger.log('Message 2');

      expect(logger.count, 2);

      logger.clear();

      expect(logger.count, 0);
      expect(logger.logs, isEmpty);
    });

    test('should export as JSON', () {
      logger.log('Test message', tag: 'TEST');

      final json = logger.exportAsJson();

      expect(json, contains('Test message'));
      expect(json, contains('TEST'));
    });

    test('should export as text', () {
      logger.log('Test message', tag: 'TEST');

      final text = logger.exportAsText();

      expect(text, contains('Test message'));
      expect(text, contains('TEST'));
    });
  });

  group('ConsoleLog', () {
    test('should format timestamp correctly', () {
      final log = ConsoleLog(
        id: '1',
        message: 'Test',
        level: LogLevel.debug,
        timestamp: DateTime(2024, 1, 15, 10, 30, 45, 123),
      );

      expect(log.formattedTime, '10:30:45.123');
    });

    test('should provide level string', () {
      final log = ConsoleLog(
        id: '1',
        message: 'Test',
        level: LogLevel.warning,
        timestamp: DateTime.now(),
      );

      expect(log.levelString, 'WARNING');
    });

    test('should format full output', () {
      final log = ConsoleLog(
        id: '1',
        message: 'Test message',
        tag: 'TAG',
        level: LogLevel.info,
        timestamp: DateTime(2024, 1, 15, 10, 30, 45, 123),
      );

      final formatted = log.formatted;

      expect(formatted, contains('10:30:45.123'));
      expect(formatted, contains('INFO'));
      expect(formatted, contains('TAG'));
      expect(formatted, contains('Test message'));
    });
  });
}

