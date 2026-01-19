import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dev_tools_config.dart';
import 'loggers/network_logger.dart';
import 'loggers/console_logger.dart';

/// Main DevTools singleton class
class DevTools {
  static DevTools? _instance;
  
  /// Get the singleton instance
  static DevTools get instance {
    _instance ??= DevTools._internal();
    return _instance!;
  }

  /// Private constructor
  DevTools._internal();

  /// Initialize with custom config
  static void init({DevToolsConfig? config}) {
    instance._config = config ?? const DevToolsConfig();
    instance._isInitialized = true;
  }

  DevToolsConfig _config = const DevToolsConfig();
  bool _isInitialized = false;
  bool _isPanelOpen = false;
  PackageInfo? _packageInfo;
  Map<String, dynamic>? _deviceInfo;

  /// Get the current configuration
  DevToolsConfig get config => _config;

  /// Check if DevTools is initialized
  bool get isInitialized => _isInitialized;

  /// Check if the panel is currently open
  bool get isPanelOpen => _isPanelOpen;

  /// Check if DevTools should be active
  bool get isEnabled => _config.enabled && kDebugMode;

  /// Network logger instance
  final NetworkLogger network = NetworkLogger();

  /// Console logger instance
  final ConsoleLogger console = ConsoleLogger();

  /// Notifier for panel state changes
  final ValueNotifier<bool> panelStateNotifier = ValueNotifier(false);

  /// Open the DevTools panel
  void openPanel() {
    _isPanelOpen = true;
    panelStateNotifier.value = true;
  }

  /// Close the DevTools panel
  void closePanel() {
    _isPanelOpen = false;
    panelStateNotifier.value = false;
  }

  /// Toggle the DevTools panel
  void togglePanel() {
    if (_isPanelOpen) {
      closePanel();
    } else {
      openPanel();
    }
  }

  /// Get package info
  Future<PackageInfo> getPackageInfo() async {
    _packageInfo ??= await PackageInfo.fromPlatform();
    return _packageInfo!;
  }

  /// Get device info
  Future<Map<String, dynamic>> getDeviceInfo() async {
    if (_deviceInfo != null) return _deviceInfo!;

    final deviceInfoPlugin = DeviceInfoPlugin();
    
    if (defaultTargetPlatform == TargetPlatform.android) {
      final info = await deviceInfoPlugin.androidInfo;
      _deviceInfo = {
        'platform': 'Android',
        'brand': info.brand,
        'model': info.model,
        'device': info.device,
        'androidVersion': info.version.release,
        'sdkInt': info.version.sdkInt,
        'manufacturer': info.manufacturer,
        'isPhysicalDevice': info.isPhysicalDevice,
      };
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final info = await deviceInfoPlugin.iosInfo;
      _deviceInfo = {
        'platform': 'iOS',
        'name': info.name,
        'model': info.model,
        'systemName': info.systemName,
        'systemVersion': info.systemVersion,
        'isPhysicalDevice': info.isPhysicalDevice,
        'utsname': info.utsname.machine,
      };
    } else if (defaultTargetPlatform == TargetPlatform.macOS) {
      final info = await deviceInfoPlugin.macOsInfo;
      _deviceInfo = {
        'platform': 'macOS',
        'computerName': info.computerName,
        'model': info.model,
        'osRelease': info.osRelease,
        'activeCPUs': info.activeCPUs,
        'memorySize': info.memorySize,
      };
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      final info = await deviceInfoPlugin.windowsInfo;
      _deviceInfo = {
        'platform': 'Windows',
        'computerName': info.computerName,
        'productName': info.productName,
        'buildNumber': info.buildNumber,
        'numberOfCores': info.numberOfCores,
        'systemMemoryInMegabytes': info.systemMemoryInMegabytes,
      };
    } else if (defaultTargetPlatform == TargetPlatform.linux) {
      final info = await deviceInfoPlugin.linuxInfo;
      _deviceInfo = {
        'platform': 'Linux',
        'name': info.name,
        'version': info.version,
        'prettyName': info.prettyName,
      };
    } else {
      final info = await deviceInfoPlugin.webBrowserInfo;
      _deviceInfo = {
        'platform': 'Web',
        'browserName': info.browserName.name,
        'userAgent': info.userAgent,
        'vendor': info.vendor,
        'language': info.language,
      };
    }

    return _deviceInfo!;
  }

  /// Clear all logs
  void clearAllLogs() {
    network.clear();
    console.clear();
  }

  /// Update configuration
  void updateConfig(DevToolsConfig config) {
    _config = config;
  }

  /// Log a debug message
  void log(String message, {String? tag, LogLevel level = LogLevel.debug}) {
    console.log(message, tag: tag, level: level);
  }

  /// Log an error
  void logError(String message, {dynamic error, StackTrace? stackTrace, String? tag}) {
    console.logError(message, error: error, stackTrace: stackTrace, tag: tag);
  }

  /// Log a warning
  void logWarning(String message, {String? tag}) {
    console.log(message, tag: tag, level: LogLevel.warning);
  }

  /// Log an info message
  void logInfo(String message, {String? tag}) {
    console.log(message, tag: tag, level: LogLevel.info);
  }
}

/// Shorthand accessor for DevTools instance
DevTools get devTools => DevTools.instance;

