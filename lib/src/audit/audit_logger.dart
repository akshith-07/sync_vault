import 'package:hive/hive.dart';
import 'package:sync_vault/src/models/audit_entry.dart';
import 'package:sync_vault/src/logging/sync_vault_logger.dart';
import 'package:uuid/uuid.dart';

/// Logger for audit trail
class AuditLogger {
  static const String _boxName = '_audit_log';

  final SyncVaultLogger _logger;
  final bool enabled;
  final String? currentUserId;
  final String? currentUsername;

  Box<AuditEntry>? _box;
  final _uuid = const Uuid();

  AuditLogger({
    required SyncVaultLogger logger,
    this.enabled = true,
    this.currentUserId,
    this.currentUsername,
  }) : _logger = logger;

  /// Initialize the audit logger
  Future<void> initialize() async {
    if (!enabled) {
      _logger.info('Audit logging is disabled');
      return;
    }

    try {
      _box = await Hive.openBox<AuditEntry>(_boxName);
      _logger.info('Audit logger initialized');
    } catch (e, stack) {
      _logger.error('Failed to initialize audit logger', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Log an audit entry
  Future<void> log({
    required AuditAction action,
    String? entityId,
    String? entityType,
    Map<String, dynamic>? metadata,
    Map<String, dynamic>? oldValue,
    Map<String, dynamic>? newValue,
    String? source,
    bool success = true,
    String? errorMessage,
  }) async {
    if (!enabled || _box == null) return;

    try {
      final entry = AuditEntry(
        id: _uuid.v4(),
        action: action,
        entityId: entityId,
        entityType: entityType,
        userId: currentUserId,
        username: currentUsername,
        timestamp: DateTime.now(),
        metadata: metadata,
        oldValue: oldValue,
        newValue: newValue,
        source: source,
        success: success,
        errorMessage: errorMessage,
      );

      await _box!.put(entry.id, entry);
      _logger.debug('Audit logged: ${action.toString().split('.').last} on $entityType:$entityId');
    } catch (e, stack) {
      _logger.error('Failed to log audit entry', error: e, stackTrace: stack);
      // Don't throw - audit logging should not break the app
    }
  }

  /// Log a create action
  Future<void> logCreate({
    required String entityId,
    required String entityType,
    required Map<String, dynamic> value,
    Map<String, dynamic>? metadata,
  }) async {
    await log(
      action: AuditAction.create,
      entityId: entityId,
      entityType: entityType,
      newValue: value,
      metadata: metadata,
    );
  }

  /// Log a read action
  Future<void> logRead({
    required String entityId,
    required String entityType,
    Map<String, dynamic>? metadata,
  }) async {
    await log(
      action: AuditAction.read,
      entityId: entityId,
      entityType: entityType,
      metadata: metadata,
    );
  }

  /// Log an update action
  Future<void> logUpdate({
    required String entityId,
    required String entityType,
    required Map<String, dynamic> oldValue,
    required Map<String, dynamic> newValue,
    Map<String, dynamic>? metadata,
  }) async {
    await log(
      action: AuditAction.update,
      entityId: entityId,
      entityType: entityType,
      oldValue: oldValue,
      newValue: newValue,
      metadata: metadata,
    );
  }

  /// Log a delete action
  Future<void> logDelete({
    required String entityId,
    required String entityType,
    required Map<String, dynamic> value,
    Map<String, dynamic>? metadata,
  }) async {
    await log(
      action: AuditAction.delete,
      entityId: entityId,
      entityType: entityType,
      oldValue: value,
      metadata: metadata,
    );
  }

  /// Get audit entries for an entity
  Future<List<AuditEntry>> getEntriesForEntity(String entityId) async {
    if (_box == null) return [];

    return _box!.values
        .where((entry) => entry.entityId == entityId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get audit entries by action
  Future<List<AuditEntry>> getEntriesByAction(AuditAction action) async {
    if (_box == null) return [];

    return _box!.values
        .where((entry) => entry.action == action)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get audit entries by user
  Future<List<AuditEntry>> getEntriesByUser(String userId) async {
    if (_box == null) return [];

    return _box!.values
        .where((entry) => entry.userId == userId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get audit entries within a time range
  Future<List<AuditEntry>> getEntriesByTimeRange(
    DateTime start,
    DateTime end,
  ) async {
    if (_box == null) return [];

    return _box!.values
        .where((entry) =>
            entry.timestamp.isAfter(start) && entry.timestamp.isBefore(end))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get all audit entries
  Future<List<AuditEntry>> getAllEntries({int? limit}) async {
    if (_box == null) return [];

    final entries = _box!.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (limit != null && limit > 0) {
      return entries.take(limit).toList();
    }

    return entries;
  }

  /// Clear old audit entries (older than the specified duration)
  Future<void> clearOldEntries(Duration retentionPeriod) async {
    if (_box == null) return;

    try {
      final cutoffDate = DateTime.now().subtract(retentionPeriod);
      final entriesToDelete = _box!.values
          .where((entry) => entry.timestamp.isBefore(cutoffDate))
          .map((entry) => entry.id)
          .toList();

      for (final id in entriesToDelete) {
        await _box!.delete(id);
      }

      _logger.info('Cleared ${entriesToDelete.length} old audit entries');
    } catch (e, stack) {
      _logger.error('Failed to clear old audit entries', error: e, stackTrace: stack);
    }
  }

  /// Get count of audit entries
  int get count => _box?.length ?? 0;

  /// Close the audit logger
  Future<void> close() async {
    await _box?.close();
    _logger.info('Audit logger closed');
  }
}
