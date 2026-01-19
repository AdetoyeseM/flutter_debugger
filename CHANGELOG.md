# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2026-01-19

### Added
- Initial release
- Network request inspector with full request/response details
- Console logger with log levels (verbose, debug, info, warning, error)
- App and device info viewer
- Export functionality for logs (JSON and text formats)
- Floating action button for quick access
- Edge swipe gesture to open panel
- Configurable UI (colors, position, panel width)
- Header redaction for sensitive data
- Search and filter functionality for logs
- HTTP client wrapper for automatic request logging
- Comprehensive statistics view
- Debug-only mode (automatically disabled in release builds)

### Security
- Automatic header redaction for Authorization, Cookie, and API keys
- In-memory only storage (no persistence)
- Release build protection

