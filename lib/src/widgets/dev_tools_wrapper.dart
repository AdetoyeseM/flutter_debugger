import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../dev_tools.dart';
import '../dev_tools_config.dart';
import 'dev_tools_overlay.dart';

/// A widget that wraps your app and provides DevTools functionality
/// 
/// Usage:
/// ```dart
/// MaterialApp(
///   builder: (context, child) {
///     return DevToolsWrapper(child: child!);
///   },
///   // ... other properties
/// )
/// ```
class DevToolsWrapper extends StatefulWidget {
  const DevToolsWrapper({
    super.key,
    required this.child,
    this.config,
  });

  /// The child widget (your app)
  final Widget child;

  /// Optional custom configuration
  final DevToolsConfig? config;

  @override
  State<DevToolsWrapper> createState() => _DevToolsWrapperState();
}

class _DevToolsWrapperState extends State<DevToolsWrapper> {
  @override
  void initState() {
    super.initState();
    // Initialize DevTools with config if provided
    if (widget.config != null) {
      DevTools.init(config: widget.config);
    } else if (!devTools.isInitialized) {
      DevTools.init();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only enable in debug mode
    if (!kDebugMode || !devTools.isEnabled) {
      return widget.child;
    }

    return DevToolsOverlay(
      config: widget.config ?? devTools.config,
      child: widget.child,
    );
  }
}

/// A simpler wrapper that just provides the FAB button to open DevTools
/// 
/// Useful when you want more control over where the overlay appears
class DevToolsFab extends StatelessWidget {
  const DevToolsFab({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode || !devTools.isEnabled) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder<int>(
      valueListenable: devTools.network.logCountNotifier,
      builder: (context, count, _) {
        return _buildFab(context, count);
      },
    );
  }

  Widget _buildFab(BuildContext context, int logCount) {
    final config = devTools.config;
    
    return FloatingActionButton.small(
      heroTag: 'dev_tools_fab',
      backgroundColor: config.primaryColor,
      onPressed: () => _showDevToolsPanel(context),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.developer_mode, color: Colors.white, size: 20),
          if (logCount > 0)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                child: Text(
                  logCount > 99 ? '99+' : logCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showDevToolsPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DevToolsPanel(config: devTools.config),
    );
  }
}

