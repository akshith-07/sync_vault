/// Status of synchronization
enum SyncState {
  idle,
  syncing,
  success,
  error,
  offline,
}

/// Detailed sync status information
class SyncStatus {
  /// Current sync state
  final SyncState state;

  /// Last successful sync timestamp
  final DateTime? lastSyncTime;

  /// Number of pending changes to sync
  final int pendingChanges;

  /// Number of conflicts detected
  final int conflicts;

  /// Current error message if any
  final String? errorMessage;

  /// Whether network is available
  final bool isOnline;

  /// Progress (0.0 to 1.0) for current sync operation
  final double? progress;

  /// Total items to sync
  final int? totalItems;

  /// Items synced so far
  final int? syncedItems;

  const SyncStatus({
    required this.state,
    this.lastSyncTime,
    this.pendingChanges = 0,
    this.conflicts = 0,
    this.errorMessage,
    this.isOnline = true,
    this.progress,
    this.totalItems,
    this.syncedItems,
  });

  /// Create an idle status
  factory SyncStatus.idle({
    DateTime? lastSyncTime,
    bool isOnline = true,
  }) {
    return SyncStatus(
      state: SyncState.idle,
      lastSyncTime: lastSyncTime,
      isOnline: isOnline,
    );
  }

  /// Create a syncing status
  factory SyncStatus.syncing({
    required int pendingChanges,
    double? progress,
    int? totalItems,
    int? syncedItems,
  }) {
    return SyncStatus(
      state: SyncState.syncing,
      pendingChanges: pendingChanges,
      progress: progress,
      totalItems: totalItems,
      syncedItems: syncedItems,
    );
  }

  /// Create a success status
  factory SyncStatus.success({
    required DateTime lastSyncTime,
    int conflicts = 0,
  }) {
    return SyncStatus(
      state: SyncState.success,
      lastSyncTime: lastSyncTime,
      conflicts: conflicts,
    );
  }

  /// Create an error status
  factory SyncStatus.error({
    required String errorMessage,
    int pendingChanges = 0,
  }) {
    return SyncStatus(
      state: SyncState.error,
      errorMessage: errorMessage,
      pendingChanges: pendingChanges,
    );
  }

  /// Create an offline status
  factory SyncStatus.offline({
    int pendingChanges = 0,
  }) {
    return SyncStatus(
      state: SyncState.offline,
      isOnline: false,
      pendingChanges: pendingChanges,
    );
  }

  /// Copy with modifications
  SyncStatus copyWith({
    SyncState? state,
    DateTime? lastSyncTime,
    int? pendingChanges,
    int? conflicts,
    String? errorMessage,
    bool? isOnline,
    double? progress,
    int? totalItems,
    int? syncedItems,
  }) {
    return SyncStatus(
      state: state ?? this.state,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      pendingChanges: pendingChanges ?? this.pendingChanges,
      conflicts: conflicts ?? this.conflicts,
      errorMessage: errorMessage ?? this.errorMessage,
      isOnline: isOnline ?? this.isOnline,
      progress: progress ?? this.progress,
      totalItems: totalItems ?? this.totalItems,
      syncedItems: syncedItems ?? this.syncedItems,
    );
  }

  @override
  String toString() {
    return 'SyncStatus(state: $state, pending: $pendingChanges, '
        'conflicts: $conflicts, online: $isOnline)';
  }
}
