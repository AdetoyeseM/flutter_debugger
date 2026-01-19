import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Performance metrics snapshot
class PerformanceSnapshot {
  final DateTime timestamp;
  final double fps;
  final int frameCount;
  final Duration frameBuildTime;
  final Duration frameRasterTime;
  final int memoryUsageMB;
  final int widgetRebuildCount;

  PerformanceSnapshot({
    required this.timestamp,
    required this.fps,
    required this.frameCount,
    required this.frameBuildTime,
    required this.frameRasterTime,
    required this.memoryUsageMB,
    required this.widgetRebuildCount,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'fps': fps,
    'frameCount': frameCount,
    'frameBuildTime': frameBuildTime.inMicroseconds,
    'frameRasterTime': frameRasterTime.inMicroseconds,
    'memoryUsageMB': memoryUsageMB,
    'widgetRebuildCount': widgetRebuildCount,
  };
}

/// Frame timing data
class FrameTiming {
  final Duration buildDuration;
  final Duration rasterDuration;
  final Duration totalDuration;
  final bool isJank;

  FrameTiming({
    required this.buildDuration,
    required this.rasterDuration,
    required this.totalDuration,
    required this.isJank,
  });

  /// A frame is considered jank if it takes longer than 16.67ms (60fps threshold)
  static const jankThreshold = Duration(milliseconds: 17);
}

/// Performance monitoring service
class PerformanceMonitor {
  static PerformanceMonitor? _instance;
  
  static PerformanceMonitor get instance {
    _instance ??= PerformanceMonitor._internal();
    return _instance!;
  }

  PerformanceMonitor._internal();

  bool _isMonitoring = false;
  Timer? _sampleTimer;
  
  /// Frame timings buffer (last 120 frames = ~2 seconds at 60fps)
  final Queue<FrameTiming> _frameTimings = Queue();
  static const int maxFrameTimings = 120;

  /// Performance snapshots (sampled every second)
  final List<PerformanceSnapshot> _snapshots = [];
  static const int maxSnapshots = 60; // 1 minute of history

  /// Widget rebuild counter
  int _widgetRebuildCount = 0;

  /// Notifier for UI updates
  final ValueNotifier<int> updateNotifier = ValueNotifier(0);

  /// Current FPS
  double _currentFps = 60.0;
  
  /// Average frame build time
  Duration _avgBuildTime = Duration.zero;
  
  /// Average frame raster time
  Duration _avgRasterTime = Duration.zero;
  
  /// Jank frame count
  int _jankFrameCount = 0;

  // Getters
  bool get isMonitoring => _isMonitoring;
  double get currentFps => _currentFps;
  Duration get avgBuildTime => _avgBuildTime;
  Duration get avgRasterTime => _avgRasterTime;
  int get jankFrameCount => _jankFrameCount;
  int get widgetRebuildCount => _widgetRebuildCount;
  List<PerformanceSnapshot> get snapshots => List.unmodifiable(_snapshots);
  List<FrameTiming> get frameTimings => _frameTimings.toList();

  /// Start monitoring performance
  void start() {
    if (_isMonitoring || !kDebugMode) return;
    
    _isMonitoring = true;
    
    // Add frame callback to track timings
    SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
    
    // Sample metrics every second
    _sampleTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _takeSample();
    });

    updateNotifier.value++;
  }

  /// Stop monitoring
  void stop() {
    if (!_isMonitoring) return;
    
    _isMonitoring = false;
    
    SchedulerBinding.instance.removeTimingsCallback(_onFrameTimings);
    _sampleTimer?.cancel();
    _sampleTimer = null;
    
    updateNotifier.value++;
  }

  /// Clear all collected data
  void clear() {
    _frameTimings.clear();
    _snapshots.clear();
    _widgetRebuildCount = 0;
    _jankFrameCount = 0;
    _currentFps = 60.0;
    _avgBuildTime = Duration.zero;
    _avgRasterTime = Duration.zero;
    updateNotifier.value++;
  }

  /// Increment widget rebuild counter (call from your widgets)
  void trackWidgetRebuild() {
    if (!_isMonitoring) return;
    _widgetRebuildCount++;
  }

  /// Reset widget rebuild counter
  void resetRebuildCounter() {
    _widgetRebuildCount = 0;
    updateNotifier.value++;
  }

  void _onFrameTimings(List<dynamic> timings) {
    for (final timing in timings) {
      final buildDuration = Duration(microseconds: 
          (timing.buildDuration as Duration).inMicroseconds);
      final rasterDuration = Duration(microseconds: 
          (timing.rasterDuration as Duration).inMicroseconds);
      final totalDuration = buildDuration + rasterDuration;
      
      final isJank = totalDuration > FrameTiming.jankThreshold;
      if (isJank) _jankFrameCount++;

      final frameTiming = FrameTiming(
        buildDuration: buildDuration,
        rasterDuration: rasterDuration,
        totalDuration: totalDuration,
        isJank: isJank,
      );

      _frameTimings.addLast(frameTiming);
      while (_frameTimings.length > maxFrameTimings) {
        _frameTimings.removeFirst();
      }
    }

    _calculateMetrics();
    updateNotifier.value++;
  }

  void _calculateMetrics() {
    if (_frameTimings.isEmpty) return;

    // Calculate average FPS from recent frames
    final recentFrames = _frameTimings.toList();
    if (recentFrames.length < 2) return;

    // Sum total time
    var totalTime = Duration.zero;
    var totalBuildTime = Duration.zero;
    var totalRasterTime = Duration.zero;

    for (final frame in recentFrames) {
      totalTime += frame.totalDuration;
      totalBuildTime += frame.buildDuration;
      totalRasterTime += frame.rasterDuration;
    }

    // Calculate averages
    _avgBuildTime = Duration(
        microseconds: totalBuildTime.inMicroseconds ~/ recentFrames.length);
    _avgRasterTime = Duration(
        microseconds: totalRasterTime.inMicroseconds ~/ recentFrames.length);

    // Calculate FPS (frames per second based on average frame time)
    final avgFrameTime = totalTime.inMicroseconds / recentFrames.length;
    if (avgFrameTime > 0) {
      _currentFps = (1000000 / avgFrameTime).clamp(0, 120);
    }
  }

  void _takeSample() {
    final snapshot = PerformanceSnapshot(
      timestamp: DateTime.now(),
      fps: _currentFps,
      frameCount: _frameTimings.length,
      frameBuildTime: _avgBuildTime,
      frameRasterTime: _avgRasterTime,
      memoryUsageMB: _getMemoryUsage(),
      widgetRebuildCount: _widgetRebuildCount,
    );

    _snapshots.add(snapshot);
    while (_snapshots.length > maxSnapshots) {
      _snapshots.removeAt(0);
    }

    // Reset rebuild counter for next sample period
    _widgetRebuildCount = 0;
    
    updateNotifier.value++;
  }

  int _getMemoryUsage() {
    // Note: Accurate memory reading requires platform channels
    // This is a placeholder that returns an estimate
    try {
      // Try to get memory info if available
      return 0; // Placeholder
    } catch (_) {
      return 0;
    }
  }

  /// Get FPS status color
  FpsStatus get fpsStatus {
    if (_currentFps >= 55) return FpsStatus.good;
    if (_currentFps >= 30) return FpsStatus.ok;
    return FpsStatus.bad;
  }

  /// Get jank percentage
  double get jankPercentage {
    if (_frameTimings.isEmpty) return 0;
    final jankCount = _frameTimings.where((f) => f.isJank).length;
    return (jankCount / _frameTimings.length) * 100;
  }

  /// Export performance data as JSON
  String exportAsJson() {
    final data = {
      'currentFps': _currentFps,
      'avgBuildTimeUs': _avgBuildTime.inMicroseconds,
      'avgRasterTimeUs': _avgRasterTime.inMicroseconds,
      'jankFrameCount': _jankFrameCount,
      'jankPercentage': jankPercentage,
      'snapshots': _snapshots.map((s) => s.toJson()).toList(),
    };
    return data.toString();
  }
}

/// FPS status levels
enum FpsStatus {
  good,   // >= 55 fps
  ok,     // >= 30 fps
  bad,    // < 30 fps
}

/// Global instance accessor
PerformanceMonitor get perfMonitor => PerformanceMonitor.instance;

/// Mixin to track widget rebuilds
/// 
/// Usage:
/// ```dart
/// class MyWidget extends StatelessWidget with RebuildTracker {
///   @override
///   Widget build(BuildContext context) {
///     trackRebuild();
///     return Container();
///   }
/// }
/// ```
mixin RebuildTracker {
  void trackRebuild() {
    perfMonitor.trackWidgetRebuild();
  }
}

