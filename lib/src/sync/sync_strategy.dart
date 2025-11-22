/// Strategy for syncing data
enum SyncDirection {
  /// Push local changes to server
  push,

  /// Pull changes from server
  pull,

  /// Bidirectional sync (pull then push)
  bidirectional,
}

/// Sync strategy configuration
class SyncStrategy {
  /// Direction of sync
  final SyncDirection direction;

  /// Whether to sync automatically when online
  final bool autoSync;

  /// Whether to sync on app start
  final bool syncOnStart;

  /// Whether to sync when coming back online
  final bool syncOnReconnect;

  /// Whether to batch sync requests
  final bool batchSync;

  /// Batch size for sync operations
  final int batchSize;

  /// Timeout for sync operations in seconds
  final int timeoutSeconds;

  const SyncStrategy({
    this.direction = SyncDirection.bidirectional,
    this.autoSync = true,
    this.syncOnStart = true,
    this.syncOnReconnect = true,
    this.batchSync = true,
    this.batchSize = 50,
    this.timeoutSeconds = 30,
  });

  SyncStrategy copyWith({
    SyncDirection? direction,
    bool? autoSync,
    bool? syncOnStart,
    bool? syncOnReconnect,
    bool? batchSync,
    int? batchSize,
    int? timeoutSeconds,
  }) {
    return SyncStrategy(
      direction: direction ?? this.direction,
      autoSync: autoSync ?? this.autoSync,
      syncOnStart: syncOnStart ?? this.syncOnStart,
      syncOnReconnect: syncOnReconnect ?? this.syncOnReconnect,
      batchSync: batchSync ?? this.batchSync,
      batchSize: batchSize ?? this.batchSize,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
    );
  }
}
