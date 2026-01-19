/// A comprehensive in-app developer tools package for Flutter.
///
/// Includes:
/// - Network request inspector
/// - Console/log viewer
/// - App & device info
/// - Shared preferences viewer
/// - Performance monitoring
library flutter_debugger;

// Core
export 'src/dev_tools.dart';
export 'src/dev_tools_config.dart';

// Loggers
export 'src/loggers/network_logger.dart';
export 'src/loggers/console_logger.dart';

// HTTP Client wrapper
export 'src/http/dev_tools_http_client.dart';
export 'src/http/dio_interceptor.dart';

// Storage
export 'src/storage/prefs_viewer.dart';

// Performance
export 'src/performance/performance_monitor.dart';

// Widgets
export 'src/widgets/dev_tools_overlay.dart';
export 'src/widgets/dev_tools_wrapper.dart';

