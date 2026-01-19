import 'package:flutter/material.dart';

/// Configuration options for DevTools
class DevToolsConfig {
  /// Whether DevTools is enabled (defaults to true in debug mode)
  final bool enabled;

  /// Maximum number of network logs to keep
  final int maxNetworkLogs;

  /// Maximum number of console logs to keep
  final int maxConsoleLogs;

  /// Primary color for the DevTools UI
  final Color primaryColor;

  /// Background color for the DevTools panel
  final Color backgroundColor;

  /// Whether to show the floating action button
  final bool showFab;

  /// Position of the floating action button
  final DevToolsFabPosition fabPosition;

  /// Whether to enable shake-to-open gesture
  final bool enableShakeToOpen;

  /// Whether to enable edge swipe to open
  final bool enableEdgeSwipe;

  /// Which edge to swipe from
  final DevToolsEdge swipeEdge;

  /// Panel width when opened
  final double panelWidth;

  /// Custom app name to display
  final String? appName;

  /// Custom environment label
  final String? environment;

  /// Custom headers to redact from logs (e.g., Authorization)
  final List<String> redactedHeaders;

  const DevToolsConfig({
    this.enabled = true,
    this.maxNetworkLogs = 100,
    this.maxConsoleLogs = 500,
    this.primaryColor = const Color(0xFFFF9800),
    this.backgroundColor = const Color(0xFF1E1E1E),
    this.showFab = true,
    this.fabPosition = DevToolsFabPosition.bottomRight,
    this.enableShakeToOpen = false,
    this.enableEdgeSwipe = true,
    this.swipeEdge = DevToolsEdge.right,
    this.panelWidth = 340,
    this.appName,
    this.environment,
    this.redactedHeaders = const ['Authorization', 'Cookie', 'X-Api-Key'],
  });

  /// Create a copy with modified values
  DevToolsConfig copyWith({
    bool? enabled,
    int? maxNetworkLogs,
    int? maxConsoleLogs,
    Color? primaryColor,
    Color? backgroundColor,
    bool? showFab,
    DevToolsFabPosition? fabPosition,
    bool? enableShakeToOpen,
    bool? enableEdgeSwipe,
    DevToolsEdge? swipeEdge,
    double? panelWidth,
    String? appName,
    String? environment,
    List<String>? redactedHeaders,
  }) {
    return DevToolsConfig(
      enabled: enabled ?? this.enabled,
      maxNetworkLogs: maxNetworkLogs ?? this.maxNetworkLogs,
      maxConsoleLogs: maxConsoleLogs ?? this.maxConsoleLogs,
      primaryColor: primaryColor ?? this.primaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      showFab: showFab ?? this.showFab,
      fabPosition: fabPosition ?? this.fabPosition,
      enableShakeToOpen: enableShakeToOpen ?? this.enableShakeToOpen,
      enableEdgeSwipe: enableEdgeSwipe ?? this.enableEdgeSwipe,
      swipeEdge: swipeEdge ?? this.swipeEdge,
      panelWidth: panelWidth ?? this.panelWidth,
      appName: appName ?? this.appName,
      environment: environment ?? this.environment,
      redactedHeaders: redactedHeaders ?? this.redactedHeaders,
    );
  }
}

/// Position options for the floating action button
enum DevToolsFabPosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

/// Edge options for swipe gesture
enum DevToolsEdge {
  left,
  right,
}
