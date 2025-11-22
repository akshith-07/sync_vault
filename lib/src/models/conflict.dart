/// Represents a conflict between local and server data
class Conflict<T> {
  /// Local version of the entity
  final T localVersion;

  /// Server version of the entity
  final T serverVersion;

  /// Entity ID
  final String entityId;

  /// Entity type
  final String entityType;

  /// When the conflict was detected
  final DateTime detectedAt;

  /// Local update timestamp
  final DateTime? localUpdatedAt;

  /// Server update timestamp
  final DateTime? serverUpdatedAt;

  /// Local version number
  final int? localVersion;

  /// Server version number
  final int? serverVersion;

  const Conflict({
    required this.localVersion,
    required this.serverVersion,
    required this.entityId,
    required this.entityType,
    required this.detectedAt,
    this.localUpdatedAt,
    this.serverUpdatedAt,
    this.localVersion,
    this.serverVersion,
  });

  /// Whether this is a timestamp-based conflict
  bool get isTimestampConflict =>
      localUpdatedAt != null && serverUpdatedAt != null;

  /// Whether this is a version-based conflict
  bool get isVersionConflict => localVersion != null && serverVersion != null;

  @override
  String toString() {
    return 'Conflict(entityId: $entityId, entityType: $entityType, '
        'local: ${localUpdatedAt ?? localVersion}, '
        'server: ${serverUpdatedAt ?? serverVersion})';
  }
}

/// Result of conflict resolution
class ConflictResolution<T> {
  /// The resolved entity
  final T resolved;

  /// Whether the resolution was automatic or manual
  final bool isAutomatic;

  /// Description of how the conflict was resolved
  final String? resolutionDescription;

  const ConflictResolution({
    required this.resolved,
    required this.isAutomatic,
    this.resolutionDescription,
  });
}
