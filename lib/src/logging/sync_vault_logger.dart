import 'package:logger/logger.dart';

/// Log levels
enum LogLevel {
  verbose,
  debug,
  info,
  warning,
  error,
  none,
}

/// Logger for SyncVault operations
class SyncVaultLogger {
  final Logger _logger;
  final bool enabled;
  final LogLevel minLevel;

  SyncVaultLogger({
    this.enabled = true,
    this.minLevel = LogLevel.info,
    Logger? logger,
  }) : _logger = logger ??
            Logger(
              printer: PrettyPrinter(
                methodCount: 0,
                errorMethodCount: 5,
                lineLength: 80,
                colors: true,
                printEmojis: true,
                printTime: true,
              ),
            );

  /// Log verbose message
  void verbose(String message, {dynamic error, StackTrace? stackTrace}) {
    if (!enabled || minLevel.index > LogLevel.verbose.index) return;
    _logger.t(message, error: error, stackTrace: stackTrace);
  }

  /// Log debug message
  void debug(String message, {dynamic error, StackTrace? stackTrace}) {
    if (!enabled || minLevel.index > LogLevel.debug.index) return;
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log info message
  void info(String message, {dynamic error, StackTrace? stackTrace}) {
    if (!enabled || minLevel.index > LogLevel.info.index) return;
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log warning message
  void warning(String message, {dynamic error, StackTrace? stackTrace}) {
    if (!enabled || minLevel.index > LogLevel.warning.index) return;
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log error message
  void error(String message, {dynamic error, StackTrace? stackTrace}) {
    if (!enabled || minLevel.index > LogLevel.error.index) return;
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log fatal error message
  void fatal(String message, {dynamic error, StackTrace? stackTrace}) {
    if (!enabled) return;
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  /// Create a logger with custom settings
  static SyncVaultLogger create({
    bool enabled = true,
    LogLevel minLevel = LogLevel.info,
  }) {
    return SyncVaultLogger(
      enabled: enabled,
      minLevel: minLevel,
    );
  }

  /// Create a disabled logger
  static SyncVaultLogger disabled() {
    return SyncVaultLogger(enabled: false);
  }
}
