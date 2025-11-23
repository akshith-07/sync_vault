import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';
import 'package:sync_vault/src/core/sync_vault_config.dart';
import 'package:sync_vault/src/storage/storage_adapter.dart';
import 'package:sync_vault/src/storage/hive_adapter.dart';
import 'package:sync_vault/src/sync/sync_engine.dart';
import 'package:sync_vault/src/sync/sync_queue.dart';
import 'package:sync_vault/src/sync/sync_strategy.dart';
import 'package:sync_vault/src/network/network_monitor.dart';
import 'package:sync_vault/src/network/api_client.dart';
import 'package:sync_vault/src/logging/sync_vault_logger.dart';
import 'package:sync_vault/src/encryption/encryption_service.dart';
import 'package:sync_vault/src/migrations/migration_manager.dart';
import 'package:sync_vault/src/relationships/relationship_manager.dart';
import 'package:sync_vault/src/audit/audit_logger.dart';
import 'package:sync_vault/src/models/sync_status.dart';
import 'package:sync_vault/src/core/sync_vault_exception.dart';
import 'package:path_provider/path_provider.dart';

/// Main database class for SyncVault
class SyncVaultDatabase {
  final SyncVaultConfig config;

  late final SyncVaultLogger _logger;
  late final NetworkMonitor _networkMonitor;
  late final SyncQueue _syncQueue;
  late final SyncEngine _syncEngine;
  late final MigrationManager _migrationManager;
  late final RelationshipManager _relationshipManager;
  late final AuditLogger _auditLogger;

  EncryptionService? _encryptionService;
  ApiClient? _apiClient;

  final Map<String, StorageAdapter> _adapters = {};

  bool _isInitialized = false;

  SyncVaultDatabase({
    required this.config,
  });

  /// Initialize the database
  Future<void> initialize() async {
    if (_isInitialized) {
      throw DatabaseException('Database already initialized');
    }

    try {
      // Initialize logger
      _logger = SyncVaultLogger(
        enabled: config.enableLogging,
        minLevel: LogLevel.values[config.logLevel],
      );

      _logger.info('Initializing SyncVault database: ${config.databaseName}');

      // Initialize Hive
      final appDir = await getApplicationDocumentsDirectory();
      await Hive.initFlutter('${appDir.path}/${config.databaseName}');

      _logger.debug('Hive initialized at ${appDir.path}');

      // Initialize encryption if enabled
      if (config.enableEncryption) {
        _encryptionService = EncryptionService(logger: _logger);
        await _encryptionService!.initialize(customKey: config.encryptionKey);
        _logger.info('Encryption enabled');
      }

      // Initialize network monitor
      _networkMonitor = NetworkMonitor(logger: _logger);
      await _networkMonitor.initialize();

      // Initialize sync queue
      _syncQueue = SyncQueue(
        logger: _logger,
        maxRetryAttempts: config.maxRetryAttempts,
      );
      await _syncQueue.initialize();

      // Initialize API client if configured
      if (config.apiBaseUrl != null) {
        _apiClient = ApiClient(
          baseUrl: config.apiBaseUrl!,
          logger: _logger,
          defaultHeaders: config.apiHeaders,
        );
        _logger.info('API client configured: ${config.apiBaseUrl}');
      }

      // Initialize sync engine
      _syncEngine = SyncEngine(
        syncQueue: _syncQueue,
        networkMonitor: _networkMonitor,
        logger: _logger,
        apiClient: _apiClient,
        strategy: SyncStrategy(
          autoSync: config.enableBackgroundSync,
        ),
        maxRetryAttempts: config.maxRetryAttempts,
        retryDelaySeconds: config.retryDelay,
      );
      await _syncEngine.initialize();

      // Initialize migration manager
      _migrationManager = MigrationManager(logger: _logger);
      await _migrationManager.initialize();

      // Run migrations if needed
      if (config.version > 1) {
        await _migrationManager.migrate(targetVersion: config.version);
      }

      // Initialize relationship manager
      _relationshipManager = RelationshipManager(logger: _logger);

      // Initialize audit logger
      _auditLogger = AuditLogger(
        logger: _logger,
        enabled: config.enableAuditLog,
        currentUserId: config.userId,
      );
      await _auditLogger.initialize();

      // Initialize background sync if enabled
      if (config.enableBackgroundSync) {
        await _initializeBackgroundSync();
      }

      _isInitialized = true;
      _logger.info('SyncVault database initialized successfully');
    } catch (e, stack) {
      _logger.error('Failed to initialize database', error: e, stackTrace: stack);
      throw DatabaseException(
        'Failed to initialize database',
        originalError: e,
        stackTrace: stack,
      );
    }
  }

  /// Register a storage adapter for an entity type
  void registerAdapter<T>(
    String collectionName,
    StorageAdapter<T> adapter,
  ) {
    if (_adapters.containsKey(collectionName)) {
      throw DatabaseException('Adapter already registered for $collectionName');
    }
    _adapters[collectionName] = adapter;
    _logger.debug('Registered adapter for $collectionName');
  }

  /// Get a storage adapter for an entity type
  StorageAdapter<T> getAdapter<T>(String collectionName) {
    final adapter = _adapters[collectionName];
    if (adapter == null) {
      throw DatabaseException('No adapter registered for $collectionName');
    }
    return adapter as StorageAdapter<T>;
  }

  /// Create a Hive adapter and register it
  Future<StorageAdapter<T>> createHiveAdapter<T>({
    required String collectionName,
    required T Function(Map<String, dynamic>) fromJson,
    required Map<String, dynamic> Function(T) toJson,
    required String Function(T) getId,
  }) async {
    final adapter = HiveAdapter<T>(
      collectionName: collectionName,
      fromJson: fromJson,
      toJson: toJson,
      getId: getId,
    );

    await adapter.initialize();
    registerAdapter(collectionName, adapter);

    return adapter;
  }

  /// Get the sync engine
  SyncEngine get syncEngine {
    _ensureInitialized();
    return _syncEngine;
  }

  /// Get the migration manager
  MigrationManager get migrationManager {
    _ensureInitialized();
    return _migrationManager;
  }

  /// Get the relationship manager
  RelationshipManager get relationshipManager {
    _ensureInitialized();
    return _relationshipManager;
  }

  /// Get the audit logger
  AuditLogger get auditLogger {
    _ensureInitialized();
    return _auditLogger;
  }

  /// Get the logger
  SyncVaultLogger get logger => _logger;

  /// Get the encryption service (if enabled)
  EncryptionService? get encryptionService => _encryptionService;

  /// Get sync status stream
  Stream<SyncStatus> get syncStatusStream {
    _ensureInitialized();
    return _syncEngine.onStatusChanged;
  }

  /// Perform a manual sync
  Future<void> sync() async {
    _ensureInitialized();
    await _syncEngine.sync();
  }

  /// Check if online
  bool get isOnline => _networkMonitor.isOnline;

  /// Stream of network connectivity changes
  Stream<bool> get onConnectivityChanged => _networkMonitor.onConnectivityChanged;

  Future<void> _initializeBackgroundSync() async {
    try {
      await Workmanager().initialize(
        _callbackDispatcher,
        isInDebugMode: false,
      );

      // Pass configuration to background isolate via inputData
      await Workmanager().registerPeriodicTask(
        'sync_vault_background_sync',
        'syncVaultSync',
        frequency: Duration(minutes: config.backgroundSyncInterval),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
        inputData: {
          'databaseName': config.databaseName,
          'apiBaseUrl': config.apiBaseUrl,
          'apiHeaders': config.apiHeaders,
        },
      );

      _logger.info('Background sync initialized with ${config.backgroundSyncInterval}min interval');
    } catch (e, stack) {
      _logger.error('Failed to initialize background sync', error: e, stackTrace: stack);
    }
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw DatabaseException('Database not initialized. Call initialize() first.');
    }
  }

  /// Close the database and clean up resources
  Future<void> close() async {
    _logger.info('Closing SyncVault database');

    try {
      // Close all adapters
      for (final adapter in _adapters.values) {
        await adapter.close();
      }

      // Close components
      await _syncEngine.dispose();
      await _syncQueue.close();
      await _networkMonitor.dispose();
      await _migrationManager.close();
      await _auditLogger.close();

      // Close Hive
      await Hive.close();

      _isInitialized = false;
      _logger.info('SyncVault database closed');
    } catch (e, stack) {
      _logger.error('Error closing database', error: e, stackTrace: stack);
      rethrow;
    }
  }
}

/// Background sync callback dispatcher
/// This runs in an isolate, so it needs to reinitialize minimal dependencies
@pragma('vm:entry-point')
void _callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      print('[SyncVault] Background sync task started: $task');

      // Extract configuration from inputData
      final databaseName = inputData?['databaseName'] as String?;
      final apiBaseUrl = inputData?['apiBaseUrl'] as String?;
      final apiHeaders = inputData?['apiHeaders'] as Map<String, dynamic>?;

      if (databaseName == null || apiBaseUrl == null) {
        print('[SyncVault] Missing configuration for background sync');
        return Future.value(false);
      }

      // Initialize minimal Hive for background sync
      await Hive.initFlutter(databaseName);

      // Create minimal components needed for sync
      final logger = SyncVaultLogger(enabled: true, minLevel: LogLevel.info);
      final networkMonitor = NetworkMonitor(logger: logger);
      await networkMonitor.initialize();

      // Check if online
      if (!networkMonitor.isOnline) {
        print('[SyncVault] Device offline, skipping background sync');
        await networkMonitor.dispose();
        return Future.value(true); // Success but skipped
      }

      // Initialize sync components
      final syncQueue = SyncQueue(logger: logger, maxRetryAttempts: 3);
      await syncQueue.initialize();

      final apiClient = ApiClient(
        baseUrl: apiBaseUrl,
        logger: logger,
        defaultHeaders: apiHeaders?.cast<String, String>(),
      );

      final syncEngine = SyncEngine(
        syncQueue: syncQueue,
        networkMonitor: networkMonitor,
        logger: logger,
        apiClient: apiClient,
        strategy: const SyncStrategy(
          autoSync: false, // Manual trigger only
          direction: SyncDirection.bidirectional,
        ),
      );

      await syncEngine.initialize();

      // Perform sync
      await syncEngine.sync();

      // Cleanup
      await syncEngine.dispose();
      await syncQueue.close();
      await networkMonitor.dispose();
      await Hive.close();

      print('[SyncVault] Background sync completed successfully');
      return Future.value(true);
    } catch (e, stack) {
      print('[SyncVault] Background sync failed: $e');
      print(stack);
      return Future.value(false);
    }
  });
}
