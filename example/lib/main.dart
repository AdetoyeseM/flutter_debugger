import 'package:flutter/material.dart';
import 'package:flutter_debugger/flutter_debugger.dart';

void main() {
  // Initialize DevTools with custom configuration
  DevTools.init(
    config: const DevToolsConfig(
      appName: 'DevTools Example',
      environment: 'DEV',
      primaryColor: Colors.deepOrange,
      showFab: true,
      fabPosition: DevToolsFabPosition.bottomRight,
      enableEdgeSwipe: true,
      maxNetworkLogs: 50,
      maxConsoleLogs: 200,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DevTools Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      builder: (context, child) {
        // Wrap with DevToolsWrapper to enable the dev tools overlay
        return DevToolsWrapper(child: child!);
      },
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DevTools Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Network Requests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _makeGetRequest(),
              icon: const Icon(Icons.download),
              label: const Text('Make GET Request'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _makePostRequest(),
              icon: const Icon(Icons.upload),
              label: const Text('Make POST Request'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _makeFailedRequest(),
              icon: const Icon(Icons.error_outline),
              label: const Text('Make Failed Request'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Console Logs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _logDebug(),
              icon: const Icon(Icons.bug_report),
              label: const Text('Log Debug'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _logInfo(),
              icon: const Icon(Icons.info_outline),
              label: const Text('Log Info'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _logWarning(),
              icon: const Icon(Icons.warning_amber),
              label: const Text('Log Warning'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _logError(),
              icon: const Icon(Icons.error),
              label: const Text('Log Error'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Panel Control',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => devTools.openPanel(),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open DevTools Panel'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => devTools.clearAllLogs(),
              icon: const Icon(Icons.delete_sweep),
              label: const Text('Clear All Logs'),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How to access DevTools:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('• Tap the orange FAB button (bottom right)'),
                  Text('• Swipe left from the right edge of screen'),
                  Text('• Call devTools.openPanel() programmatically'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _makeGetRequest() async {
    devTools.logInfo('Making GET request...', tag: 'HTTP');

    try {
      final response = await DevToolsHttp.get(
        Uri.parse('https://jsonplaceholder.typicode.com/posts/1'),
      );

      devTools.logInfo('GET request completed: ${response.statusCode}', tag: 'HTTP');
    } catch (e) {
      devTools.logError('GET request failed', error: e, tag: 'HTTP');
    }
  }

  void _makePostRequest() async {
    devTools.logInfo('Making POST request...', tag: 'HTTP');

    try {
      final response = await DevToolsHttp.post(
        Uri.parse('https://jsonplaceholder.typicode.com/posts'),
        headers: {'Content-Type': 'application/json'},
        body: '{"title": "Test Post", "body": "This is a test", "userId": 1}',
      );

      devTools.logInfo('POST request completed: ${response.statusCode}', tag: 'HTTP');
    } catch (e) {
      devTools.logError('POST request failed', error: e, tag: 'HTTP');
    }
  }

  void _makeFailedRequest() async {
    devTools.logWarning('Making request to non-existent endpoint...', tag: 'HTTP');

    try {
      final response = await DevToolsHttp.get(
        Uri.parse('https://jsonplaceholder.typicode.com/invalid-endpoint'),
      );

      devTools.logInfo('Request completed: ${response.statusCode}', tag: 'HTTP');
    } catch (e) {
      devTools.logError('Request failed', error: e, tag: 'HTTP');
    }
  }

  void _logDebug() {
    devTools.log('This is a debug message', tag: 'DEBUG');
    devTools.log('User clicked debug button at ${DateTime.now()}');
  }

  void _logInfo() {
    devTools.logInfo('User information loaded successfully', tag: 'INFO');
    devTools.logInfo('Cache hit ratio: 85%');
  }

  void _logWarning() {
    devTools.logWarning('Memory usage is above 80%', tag: 'PERF');
    devTools.logWarning('Deprecated API being used');
  }

  void _logError() {
    try {
      throw Exception('Something went wrong!');
    } catch (e, stackTrace) {
      devTools.logError(
        'An error occurred',
        error: e,
        stackTrace: stackTrace,
        tag: 'ERROR',
      );
    }
  }
}

