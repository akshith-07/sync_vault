import 'dart:async';
import 'package:hive/hive.dart';
import 'package:sync_vault/src/models/change_record.dart';
import 'package:sync_vault/src/logging/sync_vault_logger.dart';

/// Queue for managing pending sync operations
class SyncQueue {
  static const String _boxName = '_sync_queue';
  Box<ChangeRecord>? _box;
  final SyncVaultLogger _logger;
  final int maxRetryAttempts;

  SyncQueue({
    required SyncVaultLogger logger,
    this.maxRetryAttempts = 3,
  }) : _logger = logger;

  /// Initialize the sync queue
  Future<void> initialize() async {
    try {
      _box = await Hive.openBox<ChangeRecord>(_boxName);
      _logger.info('Sync queue initialized');
    } catch (e, stack) {
      _logger.error('Failed to initialize sync queue', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Add a change to the sync queue
  Future<void> enqueue(ChangeRecord change) async {
    if (_box == null) {
      throw StateError('SyncQueue not initialized');
    }

    try {
      await _box!.put(change.id, change);
      _logger.debug('Enqueued change: ${change.id}');
    } catch (e, stack) {
      _logger.error('Failed to enqueue change', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Get all pending (unsynced) changes
  List<ChangeRecord> getPending() {
    if (_box == null) {
      throw StateError('SyncQueue not initialized');
    }

    return _box!.values
        .where((change) => !change.isSynced && change.retryCount < maxRetryAttempts)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Get pending changes for a specific entity type
  List<ChangeRecord> getPendingByType(String entityType) {
    return getPending()
        .where((change) => change.entityType == entityType)
        .toList();
  }

  /// Mark a change as synced
  Future<void> markAsSynced(String changeId) async {
    if (_box == null) {
      throw StateError('SyncQueue not initialized');
    }

    try {
      final change = _box!.get(changeId);
      if (change != null) {
        change.markAsSynced();
        await change.save();
        _logger.debug('Marked change as synced: $changeId');
      }
    } catch (e, stack) {
      _logger.error('Failed to mark change as synced', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Remove a change from the queue
  Future<void> remove(String changeId) async {
    if (_box == null) {
      throw StateError('SyncQueue not initialized');
    }

    try {
      await _box!.delete(changeId);
      _logger.debug('Removed change from queue: $changeId');
    } catch (e, stack) {
      _logger.error('Failed to remove change from queue', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Increment retry count for a change
  Future<void> incrementRetry(String changeId, {String? error}) async {
    if (_box == null) {
      throw StateError('SyncQueue not initialized');
    }

    try {
      final change = _box!.get(changeId);
      if (change != null) {
        change.incrementRetry(error: error);
        await change.save();
        _logger.warning('Retry count incremented for change: $changeId (${change.retryCount}/$maxRetryAttempts)');
      }
    } catch (e, stack) {
      _logger.error('Failed to increment retry count', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Get changes that have exceeded max retry attempts
  List<ChangeRecord> getFailedChanges() {
    if (_box == null) {
      throw StateError('SyncQueue not initialized');
    }

    return _box!.values
        .where((change) => !change.isSynced && change.retryCount >= maxRetryAttempts)
        .toList();
  }

  /// Clear all synced changes from the queue
  Future<void> clearSynced() async {
    if (_box == null) {
      throw StateError('SyncQueue not initialized');
    }

    try {
      final syncedKeys = _box!.values
          .where((change) => change.isSynced)
          .map((change) => change.id)
          .toList();

      for (final key in syncedKeys) {
        await _box!.delete(key);
      }

      _logger.info('Cleared ${syncedKeys.length} synced changes from queue');
    } catch (e, stack) {
      _logger.error('Failed to clear synced changes', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Get the count of pending changes
  int get pendingCount {
    if (_box == null) return 0;
    return _box!.values.where((change) => !change.isSynced).length;
  }

  /// Get the count of failed changes
  int get failedCount {
    if (_box == null) return 0;
    return getFailedChanges().length;
  }

  /// Close the sync queue
  Future<void> close() async {
    await _box?.close();
    _logger.info('Sync queue closed');
  }

  /// Clear all changes (use with caution)
  Future<void> clear() async {
    if (_box == null) {
      throw StateError('SyncQueue not initialized');
    }

    try {
      await _box!.clear();
      _logger.warning('Sync queue cleared');
    } catch (e, stack) {
      _logger.error('Failed to clear sync queue', error: e, stackTrace: stack);
      rethrow;
    }
  }
}
