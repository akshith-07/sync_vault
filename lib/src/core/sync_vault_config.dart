import 'package:sync_vault/src/sync/conflict_resolver.dart';

/// Configuration for SyncVault database
class SyncVaultConfig {
  /// Database name
  final String databaseName;

  /// API base URL for sync
  final String? apiBaseUrl;

  /// API headers (e.g., for authentication)
  final Map<String, String>? apiHeaders;

  /// Enable encryption
  final bool enableEncryption;

  /// Encryption key (if null, will be generated and stored securely)
  final String? encryptionKey;

  /// Enable automatic background sync
  final bool enableBackgroundSync;

  /// Background sync interval in minutes
  final int backgroundSyncInterval;

  /// Default conflict resolution strategy
  final ConflictResolutionStrategy conflictResolution;

  /// Enable audit logging
  final bool enableAuditLog;

  /// Enable comprehensive logging
  final bool enableLogging;

  /// Log level (0 = verbose, 1 = debug, 2 = info, 3 = warning, 4 = error)
  final int logLevel;

  /// Maximum sync retry attempts
  final int maxRetryAttempts;

  /// Retry delay in seconds
  final int retryDelay;

  /// Enable full-text search indexing
  final bool enableFullTextSearch;

  /// Database version for migrations
  final int version;

  /// Custom user identifier for multi-user support
  final String? userId;

  /// Whether to use Isar instead of Hive (default: false = Hive)
  final bool useIsar;

  const SyncVaultConfig({
    required this.databaseName,
    this.apiBaseUrl,
    this.apiHeaders,
    this.enableEncryption = false,
    this.encryptionKey,
    this.enableBackgroundSync = false,
    this.backgroundSyncInterval = 15,
    this.conflictResolution = ConflictResolutionStrategy.lastWriteWins,
    this.enableAuditLog = false,
    this.enableLogging = true,
    this.logLevel = 2,
    this.maxRetryAttempts = 3,
    this.retryDelay = 5,
    this.enableFullTextSearch = false,
    this.version = 1,
    this.userId,
    this.useIsar = false,
  });

  /// Create a copy with modified values
  SyncVaultConfig copyWith({
    String? databaseName,
    String? apiBaseUrl,
    Map<String, String>? apiHeaders,
    bool? enableEncryption,
    String? encryptionKey,
    bool? enableBackgroundSync,
    int? backgroundSyncInterval,
    ConflictResolutionStrategy? conflictResolution,
    bool? enableAuditLog,
    bool? enableLogging,
    int? logLevel,
    int? maxRetryAttempts,
    int? retryDelay,
    bool? enableFullTextSearch,
    int? version,
    String? userId,
    bool? useIsar,
  }) {
    return SyncVaultConfig(
      databaseName: databaseName ?? this.databaseName,
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      apiHeaders: apiHeaders ?? this.apiHeaders,
      enableEncryption: enableEncryption ?? this.enableEncryption,
      encryptionKey: encryptionKey ?? this.encryptionKey,
      enableBackgroundSync: enableBackgroundSync ?? this.enableBackgroundSync,
      backgroundSyncInterval: backgroundSyncInterval ?? this.backgroundSyncInterval,
      conflictResolution: conflictResolution ?? this.conflictResolution,
      enableAuditLog: enableAuditLog ?? this.enableAuditLog,
      enableLogging: enableLogging ?? this.enableLogging,
      logLevel: logLevel ?? this.logLevel,
      maxRetryAttempts: maxRetryAttempts ?? this.maxRetryAttempts,
      retryDelay: retryDelay ?? this.retryDelay,
      enableFullTextSearch: enableFullTextSearch ?? this.enableFullTextSearch,
      version: version ?? this.version,
      userId: userId ?? this.userId,
      useIsar: useIsar ?? this.useIsar,
    );
  }
}
