# Flutter Debugger

A comprehensive in-app developer tools package for Flutter. Inspect network requests, view console logs, monitor performance, browse SharedPreferences, and more — all without leaving your app.

![Flutter Debugger](https://via.placeholder.com/800x400?text=Flutter+Debugger+Screenshot)

## Features

✅ **Network Inspector** — View all HTTP requests with headers, body, response, status codes, and timing  
✅ **Console Logger** — Capture and filter logs by level (verbose, debug, info, warning, error)  
✅ **SharedPreferences Viewer** — Browse, search, edit, and delete stored preferences  
✅ **Performance Monitor** — Track FPS, frame timing, jank detection, and widget rebuilds  
✅ **App & Device Info** — View package info, device details, and environment  
✅ **Dio Support** — Built-in interceptor for Dio HTTP client  
✅ **Export Logs** — Share network and console logs for debugging  
✅ **Configurable UI** — Customize colors, position, and behavior  
✅ **Multiple Access Methods** — FAB button, edge swipe, or programmatic  
✅ **Debug-Only** — Automatically disabled in release builds  

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_debugger: ^1.0.0
```

Then run:

```bash
flutter pub get
```

## Quick Start

### 1. Wrap your app

```dart
import 'package:flutter_debugger/flutter_debugger.dart';

void main() {
  // Optional: Initialize with custom config
  DevTools.init(
    config: DevToolsConfig(
      appName: 'My App',
      environment: 'DEV',
      primaryColor: Colors.orange,
    ),
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) {
        // Wrap with DevToolsWrapper
        return DevToolsWrapper(child: child!);
      },
      home: const HomeScreen(),
    );
  }
}
```

### 2. Log network requests

#### Option A: Use the built-in HTTP client

```dart
import 'package:flutter_debugger/flutter_debugger.dart';

// Use DevToolsHttp for automatic logging
final response = await DevToolsHttp.get(Uri.parse('https://api.example.com/users'));

// Or wrap your existing client
final client = http.Client().withDevTools();
```

#### Option B: Log manually

```dart
// Log complete request + response
devTools.network.logComplete(
  method: 'GET',
  url: 'https://api.example.com/users',
  statusCode: 200,
  responseBody: {'users': []},
  duration: Duration(milliseconds: 150),
);

// Or log request and response separately
final logId = devTools.network.logRequest(
  method: 'POST',
  url: 'https://api.example.com/login',
  headers: {'Content-Type': 'application/json'},
  body: {'email': 'user@example.com'},
);

// Later, when response arrives:
devTools.network.logResponse(
  id: logId,
  statusCode: 200,
  responseBody: {'token': 'abc123'},
  duration: Duration(milliseconds: 200),
);
```

### 3. Log to console

```dart
// Simple logging
devTools.log('User logged in', tag: 'AUTH');

// Different levels
devTools.logInfo('Loading data...');
devTools.logWarning('Cache miss');
devTools.logError('Failed to fetch', error: e, stackTrace: stackTrace);

// Or use the console logger directly
devTools.console.debug('Debug message');
devTools.console.info('Info message');
devTools.console.warning('Warning message');
devTools.console.error('Error message', err: e);
```

## Accessing Dev Tools

### Floating Action Button
A floating button appears (bottom-right by default) that opens the panel when tapped.

### Edge Swipe
Swipe from the right edge of the screen to open the panel.

### Programmatic
```dart
devTools.openPanel();
devTools.closePanel();
devTools.togglePanel();
```

## Configuration

```dart
DevTools.init(
  config: DevToolsConfig(
    // General
    enabled: true,  // Set to false to disable entirely
    appName: 'My App',
    environment: 'DEV',
    
    // Limits
    maxNetworkLogs: 100,
    maxConsoleLogs: 500,
    
    // UI
    primaryColor: Colors.orange,
    backgroundColor: Color(0xFF1E1E1E),
    panelWidth: 340,
    
    // FAB
    showFab: true,
    fabPosition: DevToolsFabPosition.bottomRight,
    
    // Gestures
    enableEdgeSwipe: true,
    swipeEdge: DevToolsEdge.right,
    enableShakeToOpen: false,
    
    // Security
    redactedHeaders: ['Authorization', 'Cookie', 'X-Api-Key'],
  ),
);
```

## API Reference

### DevTools

```dart
// Access the singleton
final devTools = DevTools.instance;
// Or use the shorthand
devTools.network.logs;  // Get network logs
devTools.console.logs;  // Get console logs

// Control panel
devTools.openPanel();
devTools.closePanel();
devTools.togglePanel();

// Clear logs
devTools.clearAllLogs();

// Get app info
await devTools.getPackageInfo();
await devTools.getDeviceInfo();
```

### NetworkLogger

```dart
devTools.network.logs;            // Get all logs (most recent first)
devTools.network.count;           // Total count
devTools.network.successCount;    // Successful requests
devTools.network.errorCount;      // Failed requests
devTools.network.clear();         // Clear all logs
devTools.network.search('users'); // Search by URL/method
devTools.network.filterByStatus(NetworkLogStatus.error);
devTools.network.exportAsJson();  // Export as JSON
```

### ConsoleLogger

```dart
devTools.console.logs;                  // Get all logs
devTools.console.count;                 // Total count
devTools.console.clear();               // Clear all logs
devTools.console.search('error');       // Search logs
devTools.console.filterByLevel(LogLevel.error);
devTools.console.exportAsJson();        // Export as JSON
devTools.console.exportAsText();        // Export as plain text
```

## Security

- **Debug-Only**: All logging is automatically disabled in release builds
- **Header Redaction**: Sensitive headers (Authorization, Cookie, etc.) are automatically redacted
- **No Persistence**: Logs are stored in memory only and cleared when the app closes

## Example

See the [example](example/) folder for a complete sample app.

## Contributing

Contributions are welcome! Please read our [contributing guidelines](CONTRIBUTING.md) first.

## License

MIT License - see [LICENSE](LICENSE) for details.

