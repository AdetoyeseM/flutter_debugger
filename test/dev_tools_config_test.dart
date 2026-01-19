import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_debugger/flutter_debugger.dart';

void main() {
  group('DevToolsConfig', () {
    test('should have correct default values', () {
      const config = DevToolsConfig();

      expect(config.enabled, true);
      expect(config.maxNetworkLogs, 100);
      expect(config.maxConsoleLogs, 500);
      expect(config.showFab, true);
      expect(config.fabPosition, DevToolsFabPosition.bottomRight);
      expect(config.enableShakeToOpen, false);
      expect(config.enableEdgeSwipe, true);
      expect(config.swipeEdge, DevToolsEdge.right);
      expect(config.panelWidth, 340);
      expect(config.appName, null);
      expect(config.environment, null);
      expect(config.redactedHeaders, ['Authorization', 'Cookie', 'X-Api-Key']);
    });

    test('should allow custom values', () {
      const config = DevToolsConfig(
        enabled: false,
        maxNetworkLogs: 50,
        maxConsoleLogs: 200,
        primaryColor: Colors.blue,
        showFab: false,
        fabPosition: DevToolsFabPosition.topLeft,
        enableEdgeSwipe: false,
        swipeEdge: DevToolsEdge.left,
        panelWidth: 400,
        appName: 'Test App',
        environment: 'staging',
        redactedHeaders: ['X-Custom-Token'],
      );

      expect(config.enabled, false);
      expect(config.maxNetworkLogs, 50);
      expect(config.maxConsoleLogs, 200);
      expect(config.primaryColor, Colors.blue);
      expect(config.showFab, false);
      expect(config.fabPosition, DevToolsFabPosition.topLeft);
      expect(config.enableEdgeSwipe, false);
      expect(config.swipeEdge, DevToolsEdge.left);
      expect(config.panelWidth, 400);
      expect(config.appName, 'Test App');
      expect(config.environment, 'staging');
      expect(config.redactedHeaders, ['X-Custom-Token']);
    });

    test('should copy with modified values', () {
      const original = DevToolsConfig(
        appName: 'Original',
        maxNetworkLogs: 100,
      );

      final copied = original.copyWith(
        appName: 'Copied',
        maxNetworkLogs: 50,
      );

      expect(original.appName, 'Original');
      expect(original.maxNetworkLogs, 100);
      expect(copied.appName, 'Copied');
      expect(copied.maxNetworkLogs, 50);
      
      // Unchanged values should be preserved
      expect(copied.enabled, original.enabled);
      expect(copied.primaryColor, original.primaryColor);
    });

    test('copyWith should preserve unchanged values', () {
      const original = DevToolsConfig(
        appName: 'Test',
        environment: 'dev',
        maxNetworkLogs: 75,
      );

      final copied = original.copyWith(environment: 'prod');

      expect(copied.appName, 'Test');
      expect(copied.environment, 'prod');
      expect(copied.maxNetworkLogs, 75);
    });
  });

  group('DevToolsFabPosition', () {
    test('should have all expected values', () {
      expect(DevToolsFabPosition.values.length, 4);
      expect(DevToolsFabPosition.values, contains(DevToolsFabPosition.topLeft));
      expect(DevToolsFabPosition.values, contains(DevToolsFabPosition.topRight));
      expect(DevToolsFabPosition.values, contains(DevToolsFabPosition.bottomLeft));
      expect(DevToolsFabPosition.values, contains(DevToolsFabPosition.bottomRight));
    });
  });

  group('DevToolsEdge', () {
    test('should have all expected values', () {
      expect(DevToolsEdge.values.length, 2);
      expect(DevToolsEdge.values, contains(DevToolsEdge.left));
      expect(DevToolsEdge.values, contains(DevToolsEdge.right));
    });
  });
}

