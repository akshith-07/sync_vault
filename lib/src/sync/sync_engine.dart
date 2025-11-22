import 'dart:async';
import 'package:workmanager/workmanager.dart';
import 'package:sync_vault/src/models/change_record.dart';
import 'package:sync_vault/src/models/conflict.dart';
import 'package:sync_vault/src/models/sync_status.dart';
import 'package:sync_vault/src/sync/conflict_resolver.dart';
import 'package:sync_vault/src/sync/sync_queue.dart';
import 'package:sync_vault/src/sync/sync_strategy.dart';
import 'package:sync_vault/src/network/network_monitor.dart';
import 'package:sync_vault/src/network/api_client.dart';
import 'package:sync_vault/src/logging/sync_vault_logger.dart';
import 'package:sync_vault/src/core/sync_vault_exception.dart';

/// Callback for handling sync events
typedef SyncCallback = void Function(SyncStatus status);

/// Callback for handling conflicts
typedef ConflictCallback<T> = Future<ConflictResolution<T>> Function(Conflict<T> conflict);

/// Engine that manages data synchronization
class SyncEngine {
  final SyncQueue _syncQueue;
  final NetworkMonitor _networkMonitor;
  final ApiClient? _apiClient;
  final SyncVaultLogger _logger;
  final SyncStrategy strategy;
  final int maxRetryAttempts;
  final int retryDelaySeconds;

  final StreamController<SyncStatus> _statusController = StreamController<SyncStatus>.broadcast();
  final Map<String, ConflictResolver> _conflictResolvers = {};
  final Map<String, ConflictCallback> _conflictCallbacks = {};

  Timer? _syncTimer;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  StreamSubscription<bool>? _networkSubscription;

  SyncEngine({
    required SyncQueue syncQueue,
    required NetworkMonitor networkMonitor,
    required SyncVaultLogger logger,
    ApiClient? apiClient,
    this.strategy = const SyncStrategy(),
    this.maxRetryAttempts = 3,
    this.retryDelaySeconds = 5,
  })  : _syncQueue = syncQueue,
        _networkMonitor = networkMonitor,
        _apiClient = apiClient,
        _logger = logger;

  /// Stream of sync status changes
  Stream<SyncStatus> get onStatusChanged => _statusController.stream;

  /// Current sync status
  SyncStatus get currentStatus {
    if (_isSyncing) {
      return SyncStatus.syncing(
        pendingChanges: _syncQueue.pendingCount,
      );
    } else if (!_networkMonitor.isOnline) {
      return SyncStatus.offline(
        pendingChanges: _syncQueue.pendingCount,
      );
    } else {
      return SyncStatus.idle(
        lastSyncTime: _lastSyncTime,
        isOnline: _networkMonitor.isOnline,
      );
    }
  }

  /// Initialize the sync engine
  Future<void> initialize() async {
    try {
      _logger.info('Initializing sync engine');

      // Listen to network changes
      _networkSubscription = _networkMonitor.onConnectivityChanged.listen((isOnline) {
        if (isOnline && strategy.syncOnReconnect) {
          _logger.info('Network reconnected, triggering sync');
          sync();
        }
        _emitStatus();
      });

      // Initial sync if configured
      if (strategy.syncOnStart && _networkMonitor.isOnline) {
        _logger.info('Performing initial sync');
        await sync();
      }

      _emitStatus();
      _logger.info('Sync engine initialized');
    } catch (e, stack) {
      _logger.error('Failed to initialize sync engine', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Register a conflict resolver for an entity type
  void registerConflictResolver(String entityType, ConflictResolver resolver) {
    _conflictResolvers[entityType] = resolver;
    _logger.debug('Registered conflict resolver for $entityType');
  }

  /// Register a conflict callback for manual resolution
  void registerConflictCallback<T>(String entityType, ConflictCallback<T> callback) {
    _conflictCallbacks[entityType] = callback as ConflictCallback;
    _logger.debug('Registered conflict callback for $entityType');
  }

  /// Start automatic background sync
  void startAutoSync() {
    if (!strategy.autoSync) {
      _logger.warning('Auto sync is disabled in strategy');
      return;
    }

    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(
      Duration(minutes: 15),
      (_) {
        if (_networkMonitor.isOnline && !_isSyncing) {
          _logger.debug('Auto sync triggered');
          sync();
        }
      },
    );

    _logger.info('Auto sync started');
  }

  /// Stop automatic background sync
  void stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _logger.info('Auto sync stopped');
  }

  /// Perform a sync operation
  Future<void> sync() async {
    if (_isSyncing) {
      _logger.warning('Sync already in progress');
      return;
    }

    if (!_networkMonitor.isOnline) {
      _logger.warning('Cannot sync while offline');
      _emitStatus(SyncStatus.offline(pendingChanges: _syncQueue.pendingCount));
      return;
    }

    if (_apiClient == null) {
      _logger.warning('No API client configured, skipping sync');
      return;
    }

    _isSyncing = true;
    _emitStatus(SyncStatus.syncing(pendingChanges: _syncQueue.pendingCount));

    try {
      _logger.info('Starting sync');

      switch (strategy.direction) {
        case SyncDirection.pull:
          await _pullFromServer();
          break;
        case SyncDirection.push:
          await _pushToServer();
          break;
        case SyncDirection.bidirectional:
          await _pullFromServer();
          await _pushToServer();
          break;
      }

      _lastSyncTime = DateTime.now();
      _emitStatus(SyncStatus.success(lastSyncTime: _lastSyncTime!));
      _logger.info('Sync completed successfully');
    } catch (e, stack) {
      _logger.error('Sync failed', error: e, stackTrace: stack);
      _emitStatus(SyncStatus.error(
        errorMessage: e.toString(),
        pendingChanges: _syncQueue.pendingCount,
      ));
      rethrow;
    } finally {
      _isSyncing = false;
    }
  }

  /// Push local changes to server
  Future<void> _pushToServer() async {
    final pendingChanges = _syncQueue.getPending();

    if (pendingChanges.isEmpty) {
      _logger.debug('No pending changes to push');
      return;
    }

    _logger.info('Pushing ${pendingChanges.length} changes to server');

    if (strategy.batchSync) {
      await _pushBatched(pendingChanges);
    } else {
      await _pushIndividual(pendingChanges);
    }
  }

  Future<void> _pushBatched(List<ChangeRecord> changes) async {
    final batches = <List<ChangeRecord>>[];
    for (var i = 0; i < changes.length; i += strategy.batchSize) {
      batches.add(
        changes.sublist(
          i,
          i + strategy.batchSize > changes.length ? changes.length : i + strategy.batchSize,
        ),
      );
    }

    for (final batch in batches) {
      try {
        await _apiClient!.post(
          '/sync/batch',
          data: {
            'changes': batch.map((c) => c.toJson()).toList(),
          },
        );

        for (final change in batch) {
          await _syncQueue.markAsSynced(change.id);
        }
      } catch (e) {
        _logger.error('Failed to push batch', error: e);
        for (final change in batch) {
          await _syncQueue.incrementRetry(change.id, error: e.toString());
        }
      }
    }
  }

  Future<void> _pushIndividual(List<ChangeRecord> changes) async {
    for (final change in changes) {
      try {
        final endpoint = _getEndpoint(change);
        await _sendChange(change, endpoint);
        await _syncQueue.markAsSynced(change.id);
      } catch (e) {
        _logger.error('Failed to push change ${change.id}', error: e);
        await _syncQueue.incrementRetry(change.id, error: e.toString());
      }
    }
  }

  Future<void> _sendChange(ChangeRecord change, String endpoint) async {
    switch (change.changeType) {
      case ChangeType.create:
        await _apiClient!.post(endpoint, data: change.data);
        break;
      case ChangeType.update:
        await _apiClient!.put('$endpoint/${change.entityId}', data: change.data);
        break;
      case ChangeType.delete:
        await _apiClient!.delete('$endpoint/${change.entityId}');
        break;
    }
  }

  String _getEndpoint(ChangeRecord change) {
    // Override this method or provide endpoint mapping
    return '/api/${change.entityType}';
  }

  /// Pull changes from server
  Future<void> _pullFromServer() async {
    _logger.info('Pulling changes from server');
    // Implementation depends on API design
    // This is a placeholder that should be customized
  }

  void _emitStatus([SyncStatus? status]) {
    final currentStatus = status ?? this.currentStatus;
    _statusController.add(currentStatus);
  }

  /// Dispose resources
  Future<void> dispose() async {
    stopAutoSync();
    await _networkSubscription?.cancel();
    await _statusController.close();
    _logger.info('Sync engine disposed');
  }
}
