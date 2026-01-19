// ignore_for_file: deprecated_member_use

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../dev_tools.dart';
import '../dev_tools_config.dart';
import '../loggers/network_logger.dart';
import '../loggers/console_logger.dart';
import '../storage/prefs_viewer.dart';
import '../performance/performance_monitor.dart';

/// DevTools overlay that provides panel access via FAB and edge swipe
class DevToolsOverlay extends StatefulWidget {
  const DevToolsOverlay({
    super.key,
    required this.child,
    this.config,
  });

  final Widget child;
  final DevToolsConfig? config;

  @override
  State<DevToolsOverlay> createState() => _DevToolsOverlayState();
}

class _DevToolsOverlayState extends State<DevToolsOverlay> {
  bool _isOpen = false;
  double _dragOffset = 0;

  DevToolsConfig get _config => widget.config ?? devTools.config;
  double get _panelWidth => _config.panelWidth;
  double get _edgeWidth => 20;

  bool get _isRightEdge => _config.swipeEdge == DevToolsEdge.right;

  @override
  void initState() {
    super.initState();
    // Listen to programmatic panel open/close calls
    devTools.panelStateNotifier.addListener(_onPanelStateChanged);
  }

  @override
  void dispose() {
    devTools.panelStateNotifier.removeListener(_onPanelStateChanged);
    super.dispose();
  }

  void _onPanelStateChanged() {
    final shouldOpen = devTools.panelStateNotifier.value;
    if (shouldOpen && !_isOpen) {
      setState(() {
        _isOpen = true;
        _dragOffset = _panelWidth;
      });
    } else if (!shouldOpen && _isOpen) {
      setState(() {
        _isOpen = false;
        _dragOffset = 0;
      });
    }
  }

  void _openPanel() {
    setState(() {
      _isOpen = true;
      _dragOffset = _panelWidth;
    });
    devTools.openPanel();
  }

  void _closePanel() {
    setState(() {
      _isOpen = false;
      _dragOffset = 0;
    });
    devTools.closePanel();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_isOpen) {
      final delta = _isRightEdge ? details.delta.dx : -details.delta.dx;
      final newOffset = _dragOffset + delta;
      setState(() {
        _dragOffset = newOffset.clamp(0, _panelWidth);
      });
    } else {
      final delta = _isRightEdge ? -details.delta.dx : details.delta.dx;
      final newOffset = _dragOffset + delta;
      if (newOffset > 0) {
        setState(() {
          _dragOffset = newOffset.clamp(0, _panelWidth);
        });
      }
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_dragOffset > _panelWidth / 2) {
      _openPanel();
    } else {
      _closePanel();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode || !_config.enabled) {
      return widget.child;
    }

    return Stack(
      children: [
        // Main app content
        widget.child,

        // Edge swipe detector
        if (_config.enableEdgeSwipe)
          Positioned(
            left: _isRightEdge ? null : 0,
            right: _isRightEdge ? 0 : null,
            top: 0,
            bottom: 0,
            width: _edgeWidth,
            child: GestureDetector(
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
              onHorizontalDragEnd: _onHorizontalDragEnd,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),

        // Dark overlay when panel is open
        if (_dragOffset > 0)
          Positioned.fill(
            child: GestureDetector(
              onTap: _closePanel,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: (_dragOffset / _panelWidth) * 0.5,
                child: Container(color: Colors.black),
              ),
            ),
          ),

        // Sliding panel
        Positioned(
          left: _isRightEdge ? null : -_panelWidth + _dragOffset,
          right: _isRightEdge ? -_panelWidth + _dragOffset : null,
          top: 0,
          bottom: 0,
          width: _panelWidth,
          child: GestureDetector(
            onHorizontalDragUpdate: _onHorizontalDragUpdate,
            onHorizontalDragEnd: _onHorizontalDragEnd,
            child: DevToolsPanel(
              config: _config,
              onClose: _closePanel,
            ),
          ),
        ),

        // Floating action button
        if (_config.showFab)
          Positioned(
            left: _config.fabPosition == DevToolsFabPosition.topLeft ||
                    _config.fabPosition == DevToolsFabPosition.bottomLeft
                ? 16
                : null,
            right: _config.fabPosition == DevToolsFabPosition.topRight ||
                    _config.fabPosition == DevToolsFabPosition.bottomRight
                ? 16
                : null,
            top: _config.fabPosition == DevToolsFabPosition.topLeft ||
                    _config.fabPosition == DevToolsFabPosition.topRight
                ? 100
                : null,
            bottom: _config.fabPosition == DevToolsFabPosition.bottomLeft ||
                    _config.fabPosition == DevToolsFabPosition.bottomRight
                ? 100
                : null,
            child: ValueListenableBuilder<int>(
              valueListenable: devTools.network.logCountNotifier,
              builder: (context, count, _) {
                return _DevToolsFab(
                  config: _config,
                  logCount: count,
                  onTap: _openPanel,
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Floating action button widget
class _DevToolsFab extends StatelessWidget {
  const _DevToolsFab({
    required this.config,
    required this.logCount,
    required this.onTap,
  });

  final DevToolsConfig config;
  final int logCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: config.primaryColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.developer_mode, color: Colors.white, size: 24),
            if (logCount > 0)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    logCount > 99 ? '99+' : logCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Main DevTools panel widget
class DevToolsPanel extends StatefulWidget {
  const DevToolsPanel({
    super.key,
    required this.config,
    this.onClose,
  });

  final DevToolsConfig config;
  final VoidCallback? onClose;

  @override
  State<DevToolsPanel> createState() => _DevToolsPanelState();
}

class _DevToolsPanelState extends State<DevToolsPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedNetworkLogId;
  String _searchQuery = '';
  NetworkLogStatus _networkFilter = NetworkLogStatus.all;
  LogLevel? _consoleFilter;
  List<PrefsEntry> _prefsEntries = [];
  bool _isLoadingPrefs = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    setState(() => _isLoadingPrefs = true);
    try {
      _prefsEntries = await prefsViewer.getAll();
    } catch (_) {
      _prefsEntries = [];
    }
    setState(() => _isLoadingPrefs = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: widget.config.backgroundColor,
      child: SafeArea(
        left: false,
        right: false,
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildNetworkTab(),
                  _buildConsoleTab(),
                  _buildAppInfoTab(),
                  // TODO: Re-enable these tabs later
                  // _buildStorageTab(),
                  // _buildPerformanceTab(),
                  // _buildSettingsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.config.primaryColor,
        border: const Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.developer_mode, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          const Text(
            'Dev Tools',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (widget.config.environment != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                widget.config.environment!.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 8),
          if (widget.onClose != null)
            GestureDetector(
              onTap: widget.onClose,
              child: const Icon(Icons.close, color: Colors.white70, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: const Color(0xFF252526),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: widget.config.primaryColor,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        tabs: [
          _buildTab('Network', devTools.network.count),
          _buildTab('Log', devTools.console.count),
          const Tab(text: 'Info'),
          // TODO: Re-enable these tabs later
          // _buildTab('Prefs', _prefsEntries.length),
          // const Tab(text: 'Perf'),
          // const Tab(text: '⚙️'),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int count) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: widget.config.primaryColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: const TextStyle(
                  fontSize: 7,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================================
  // NETWORK TAB
  // ============================================================================

  Widget _buildNetworkTab() {
    return ValueListenableBuilder<int>(
      valueListenable: devTools.network.logCountNotifier,
      builder: (context, _, __) {
        final allLogs = devTools.network.logs;

        // Check if we're showing detail view
        if (_selectedNetworkLogId != null) {
          final selectedLog =
              allLogs.where((l) => l.id == _selectedNetworkLogId).firstOrNull;
          if (selectedLog != null) {
            return _NetworkLogDetail(
              log: selectedLog,
              onBack: () => setState(() => _selectedNetworkLogId = null),
            );
          }
        }

        // Apply filters
        var logs = devTools.network.filterByStatus(_networkFilter);
        if (_searchQuery.isNotEmpty) {
          logs = devTools.network.search(_searchQuery);
        }

        return Column(
          children: [
            _buildNetworkToolbar(allLogs.length),
            Expanded(
              child: logs.isEmpty
                  ? const Center(
                      child: Text(
                        'No network requests yet',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    )
                  : ListView.builder(
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        return _NetworkLogItem(
                          log: log,
                          onTap: () =>
                              setState(() => _selectedNetworkLogId = log.id),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNetworkToolbar(int totalCount) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: const Color(0xFF333333),
      child: Column(
        children: [
          // Search bar
          TextField(
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Search requests...',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
              prefixIcon:
                  const Icon(Icons.search, color: Colors.white38, size: 16),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              isDense: true,
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 8),
          // Filter chips and actions
          Row(
            children: [
              _FilterChip(
                label: 'All',
                isSelected: _networkFilter == NetworkLogStatus.all,
                onTap: () =>
                    setState(() => _networkFilter = NetworkLogStatus.all),
              ),
              _FilterChip(
                label: 'Success',
                isSelected: _networkFilter == NetworkLogStatus.success,
                color: Colors.green,
                onTap: () =>
                    setState(() => _networkFilter = NetworkLogStatus.success),
              ),
              _FilterChip(
                label: 'Error',
                isSelected: _networkFilter == NetworkLogStatus.error,
                color: Colors.red,
                onTap: () =>
                    setState(() => _networkFilter = NetworkLogStatus.error),
              ),
              const Spacer(),
              // Export button
              GestureDetector(
                onTap: () => _exportNetworkLogs(),
                child: const Icon(Icons.share, color: Colors.white54, size: 16),
              ),
              const SizedBox(width: 12),
              // Clear button
              GestureDetector(
                onTap: () {
                  devTools.network.clear();
                  setState(() {});
                },
                child: const Icon(Icons.delete_outline,
                    color: Colors.red, size: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _exportNetworkLogs() {
    final json = devTools.network.exportAsJson();
    Share.share(json, subject: 'Network Logs Export');
  }

  // ============================================================================
  // CONSOLE TAB
  // ============================================================================

  Widget _buildConsoleTab() {
    return ValueListenableBuilder<int>(
      valueListenable: devTools.console.logCountNotifier,
      builder: (context, _, __) {
        var logs = devTools.console.filterByLevel(_consoleFilter);
        if (_searchQuery.isNotEmpty) {
          logs = devTools.console.search(_searchQuery);
        }

        return Column(
          children: [
            _buildConsoleToolbar(),
            Expanded(
              child: logs.isEmpty
                  ? const Center(
                      child: Text(
                        'No console logs yet',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    )
                  : ListView.builder(
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        return _ConsoleLogItem(log: log);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConsoleToolbar() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: const Color(0xFF333333),
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            isSelected: _consoleFilter == null,
            onTap: () => setState(() => _consoleFilter = null),
          ),
          _FilterChip(
            label: 'Error',
            isSelected: _consoleFilter == LogLevel.error,
            color: Colors.red,
            onTap: () => setState(() => _consoleFilter = LogLevel.error),
          ),
          _FilterChip(
            label: 'Warn',
            isSelected: _consoleFilter == LogLevel.warning,
            color: Colors.orange,
            onTap: () => setState(() => _consoleFilter = LogLevel.warning),
          ),
          _FilterChip(
            label: 'Info',
            isSelected: _consoleFilter == LogLevel.info,
            color: Colors.blue,
            onTap: () => setState(() => _consoleFilter = LogLevel.info),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _exportConsoleLogs(),
            child: const Icon(Icons.share, color: Colors.white54, size: 16),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              devTools.console.clear();
              setState(() {});
            },
            child:
                const Icon(Icons.delete_outline, color: Colors.red, size: 16),
          ),
        ],
      ),
    );
  }

  void _exportConsoleLogs() {
    final text = devTools.console.exportAsText();
    Share.share(text, subject: 'Console Logs Export');
  }

  // ============================================================================
  // STORAGE TAB (SharedPreferences)
  // ============================================================================

  // ignore: unused_element
  Widget _buildStorageTab() {
    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.all(8),
          color: const Color(0xFF333333),
          child: Row(
            children: [
              Text(
                '${_prefsEntries.length} entries',
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _loadPrefs,
                child: const Icon(Icons.refresh, color: Colors.white54, size: 16),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () async {
                  await prefsViewer.clear();
                  _loadPrefs();
                },
                child: const Icon(Icons.delete_outline, color: Colors.red, size: 16),
              ),
            ],
          ),
        ),
        // List
        Expanded(
          child: _isLoadingPrefs
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : _prefsEntries.isEmpty
                  ? const Center(
                      child: Text(
                        'No stored preferences',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _prefsEntries.length,
                      itemBuilder: (context, index) {
                        final entry = _prefsEntries[index];
                        return _PrefsEntryItem(
                          entry: entry,
                          onDelete: () async {
                            await prefsViewer.remove(entry.key);
                            _loadPrefs();
                          },
                        );
                      },
                    ),
        ),
      ],
    );
  }

  // ============================================================================
  // PERFORMANCE TAB
  // ============================================================================

  // ignore: unused_element
  Widget _buildPerformanceTab() {
    return ValueListenableBuilder<int>(
      valueListenable: perfMonitor.updateNotifier,
      builder: (context, _, __) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Monitor toggle
              _InfoCard(
                title: 'Performance Monitor',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          perfMonitor.isMonitoring ? 'Monitoring...' : 'Stopped',
                          style: TextStyle(
                            color: perfMonitor.isMonitoring ? Colors.green : Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (perfMonitor.isMonitoring) {
                            perfMonitor.stop();
                          } else {
                            perfMonitor.start();
                          }
                          setState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: perfMonitor.isMonitoring 
                                ? Colors.red.withOpacity(0.2) 
                                : Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            perfMonitor.isMonitoring ? 'Stop' : 'Start',
                            style: TextStyle(
                              color: perfMonitor.isMonitoring ? Colors.red : Colors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // FPS Meter
              _InfoCard(
                title: 'Frame Rate',
                children: [
                  Row(
                    children: [
                      _FpsMeter(fps: perfMonitor.currentFps, status: perfMonitor.fpsStatus),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _InfoRow('Build Time', '${perfMonitor.avgBuildTime.inMicroseconds}μs'),
                            _InfoRow('Raster Time', '${perfMonitor.avgRasterTime.inMicroseconds}μs'),
                            _InfoRow('Jank Frames', '${perfMonitor.jankPercentage.toStringAsFixed(1)}%'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Stats
              _InfoCard(
                title: 'Statistics',
                children: [
                  _InfoRow('Total Jank Frames', perfMonitor.jankFrameCount.toString()),
                  _InfoRow('Widget Rebuilds', perfMonitor.widgetRebuildCount.toString()),
                  _InfoRow('Samples Collected', perfMonitor.snapshots.length.toString()),
                ],
              ),
              const SizedBox(height: 12),
              // Actions
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.refresh,
                      label: 'Reset Stats',
                      color: Colors.orange,
                      onTap: () {
                        perfMonitor.clear();
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================================
  // APP INFO TAB
  // ============================================================================

  Widget _buildAppInfoTab() {
    return FutureBuilder(
      future: Future.wait([
        devTools.getPackageInfo(),
        devTools.getDeviceInfo(),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        final packageInfo = snapshot.data![0] as dynamic;
        final deviceInfo = snapshot.data![1] as Map<String, dynamic>;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoCard(
                title: 'App',
                children: [
                  _InfoRow('Name', widget.config.appName ?? packageInfo.appName),
                  _InfoRow('Package', packageInfo.packageName),
                  _InfoRow('Version', packageInfo.version),
                  _InfoRow('Build', packageInfo.buildNumber),
                ],
              ),
              const SizedBox(height: 12),
              _InfoCard(
                title: 'Device',
                children: deviceInfo.entries
                    .map((e) => _InfoRow(e.key, e.value.toString()))
                    .toList(),
              ),
              const SizedBox(height: 12),
              if (widget.config.environment != null)
                _InfoCard(
                  title: 'Environment',
                  children: [
                    _InfoRow('Mode', widget.config.environment!),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================================
  // SETTINGS TAB
  // ============================================================================

  // ignore: unused_element
  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoCard(
            title: 'Actions',
            children: [
              _ActionButton(
                icon: Icons.delete_sweep,
                label: 'Clear All Logs',
                color: Colors.red,
                onTap: () {
                  devTools.clearAllLogs();
                  setState(() {});
                },
              ),
              const SizedBox(height: 8),
              _ActionButton(
                icon: Icons.share,
                label: 'Export All Logs',
                color: Colors.blue,
                onTap: _exportAllLogs,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'Statistics',
            children: [
              _InfoRow('Network Requests', devTools.network.count.toString()),
              _InfoRow(
                  'Successful Requests', devTools.network.successCount.toString()),
              _InfoRow('Failed Requests', devTools.network.errorCount.toString()),
              _InfoRow('Console Logs', devTools.console.count.toString()),
              _InfoRow('Error Logs',
                  devTools.console.getCountByLevel(LogLevel.error).toString()),
            ],
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'Configuration',
            children: [
              _InfoRow('Max Network Logs',
                  widget.config.maxNetworkLogs.toString()),
              _InfoRow(
                  'Max Console Logs', widget.config.maxConsoleLogs.toString()),
              _InfoRow('Redacted Headers',
                  widget.config.redactedHeaders.join(', ')),
            ],
          ),
        ],
      ),
    );
  }

  void _exportAllLogs() {
    final buffer = StringBuffer();
    buffer.writeln('=== NETWORK LOGS ===\n');
    buffer.writeln(devTools.network.exportAsJson());
    buffer.writeln('\n\n=== CONSOLE LOGS ===\n');
    buffer.writeln(devTools.console.exportAsText());
    Share.share(buffer.toString(), subject: 'All DevTools Logs Export');
  }
}

// ============================================================================
// HELPER WIDGETS
// ============================================================================

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (color ?? Colors.white).withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? (color ?? Colors.white) : Colors.white24,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? (color ?? Colors.white) : Colors.white54,
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _NetworkLogItem extends StatelessWidget {
  const _NetworkLogItem({required this.log, required this.onTap});

  final NetworkLog log;
  final VoidCallback onTap;

  Color get _statusColor {
    if (log.error != null) return Colors.red;
    if (log.statusCode == null) return Colors.orange;
    if (log.statusCode! >= 200 && log.statusCode! < 300) return Colors.green;
    if (log.statusCode! >= 400) return Colors.red;
    return Colors.orange;
  }

  Color get _methodColor {
    switch (log.method) {
      case 'GET':
        return Colors.blue;
      case 'POST':
        return Colors.green;
      case 'PUT':
      case 'PATCH':
        return Colors.orange;
      case 'DELETE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white10)),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 32,
              decoration: BoxDecoration(
                color: _statusColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: _methodColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                log.method,
                style: TextStyle(
                  color: _methodColor,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.path,
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 8,
                    runSpacing: 2,
                    children: [
                      Text(
                        log.statusText,
                        style: TextStyle(
                          color: _statusColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (log.duration != null)
                        Text(
                          '${log.duration!.inMilliseconds}ms',
                          style:
                              const TextStyle(color: Colors.white38, fontSize: 9),
                        ),
                      if (log.responseSize != null)
                        Text(
                          log.formattedResponseSize,
                          style:
                              const TextStyle(color: Colors.white38, fontSize: 9),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }
}

class _NetworkLogDetail extends StatelessWidget {
  const _NetworkLogDetail({required this.log, required this.onBack});

  final NetworkLog log;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          color: const Color(0xFF333333),
          child: Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back_ios, color: Colors.white70, size: 14),
                    SizedBox(width: 4),
                    Text('Back',
                        style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: log.url));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('URL copied'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: const Icon(Icons.copy, color: Colors.white54, size: 14),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailSection(title: 'URL', content: log.url, isCode: false),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _DetailBadge(
                      label: 'Status',
                      value: log.statusText,
                      color: log.isSuccess ? Colors.green : Colors.red,
                    ),
                    if (log.duration != null)
                      _DetailBadge(
                        label: 'Duration',
                        value: '${log.duration!.inMilliseconds}ms',
                        color: Colors.blue,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (log.requestHeaders != null && log.requestHeaders!.isNotEmpty)
                  _DetailSection(
                    title: 'Request Headers',
                    content: log.requestHeaders!.entries
                        .map((e) => '${e.key}: ${e.value}')
                        .join('\n'),
                    isCode: true,
                  ),
                const SizedBox(height: 12),
                _DetailSection(
                  title: 'Request Body',
                  content: log.formattedRequestBody,
                  isCode: true,
                ),
                const SizedBox(height: 12),
                _DetailSection(
                  title: 'Response Body',
                  content: log.formattedResponseBody,
                  isCode: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.content,
    required this.isCode,
  });

  final String title;
  final String content;
  final bool isCode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: content));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$title copied'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              child: const Icon(Icons.copy, color: Colors.white38, size: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isCode
                ? const Color(0xFF1A1A1A)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white10),
          ),
          child: SelectableText(
            content,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: isCode ? 9 : 10,
              fontFamily: isCode ? 'monospace' : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailBadge extends StatelessWidget {
  const _DetailBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 9),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsoleLogItem extends StatelessWidget {
  const _ConsoleLogItem({required this.log});

  final ConsoleLog log;

  Color get _levelColor {
    switch (log.level) {
      case LogLevel.verbose:
        return Colors.grey;
      case LogLevel.debug:
        return Colors.white;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: _levelColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  log.levelString,
                  style: TextStyle(
                    color: _levelColor,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                log.formattedTime,
                style: const TextStyle(color: Colors.white38, fontSize: 9),
              ),
              if (log.tag != null)
                Text(
                  '[${log.tag}]',
                  style: const TextStyle(color: Colors.white54, fontSize: 9),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            log.message,
            style: TextStyle(color: _levelColor, fontSize: 11),
          ),
          if (log.error != null) ...[
            const SizedBox(height: 4),
            Text(
              'Error: ${log.error}',
              style: const TextStyle(color: Colors.red, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF252526),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 10),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// SharedPreferences entry item widget
class _PrefsEntryItem extends StatelessWidget {
  const _PrefsEntryItem({
    required this.entry,
    required this.onDelete,
  });

  final PrefsEntry entry;
  final VoidCallback onDelete;

  Color get _typeColor {
    switch (entry.type) {
      case 'String':
        return Colors.green;
      case 'int':
        return Colors.blue;
      case 'double':
        return Colors.cyan;
      case 'bool':
        return Colors.orange;
      case 'List<String>':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: _typeColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              entry.type,
              style: TextStyle(
                color: _typeColor,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.displayValue,
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: entry.fullValue));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Value copied'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.copy, color: Colors.white38, size: 14),
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.delete_outline, color: Colors.red, size: 14),
            ),
          ),
        ],
      ),
    );
  }
}

/// FPS meter widget
class _FpsMeter extends StatelessWidget {
  const _FpsMeter({
    required this.fps,
    required this.status,
  });

  final double fps;
  final FpsStatus status;

  Color get _color {
    switch (status) {
      case FpsStatus.good:
        return Colors.green;
      case FpsStatus.ok:
        return Colors.orange;
      case FpsStatus.bad:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _color, width: 3),
        color: _color.withOpacity(0.1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            fps.toStringAsFixed(0),
            style: TextStyle(
              color: _color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'FPS',
            style: TextStyle(
              color: _color.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

