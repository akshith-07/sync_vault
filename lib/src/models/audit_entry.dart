import 'package:hive/hive.dart';

part 'audit_entry.g.dart';

/// Types of actions that can be audited
enum AuditAction {
  create,
  read,
  update,
  delete,
  sync,
  import,
  export,
  migrate,
}

/// Entry in the audit log
@HiveType(typeId: 2)
class AuditEntry extends HiveObject {
  /// Unique ID for this audit entry
  @HiveField(0)
  String id;

  /// Type of action performed
  @HiveField(1)
  AuditAction action;

  /// Entity ID that was affected
  @HiveField(2)
  String? entityId;

  /// Entity type (collection/table name)
  @HiveField(3)
  String? entityType;

  /// User who performed the action
  @HiveField(4)
  String? userId;

  /// Username for display
  @HiveField(5)
  String? username;

  /// Timestamp when the action occurred
  @HiveField(6)
  DateTime timestamp;

  /// Additional metadata about the action
  @HiveField(7)
  Map<String, dynamic>? metadata;

  /// Old value (for updates)
  @HiveField(8)
  Map<String, dynamic>? oldValue;

  /// New value (for creates/updates)
  @HiveField(9)
  Map<String, dynamic>? newValue;

  /// IP address or device identifier
  @HiveField(10)
  String? source;

  /// Whether the action was successful
  @HiveField(11)
  bool success;

  /// Error message if action failed
  @HiveField(12)
  String? errorMessage;

  AuditEntry({
    required this.id,
    required this.action,
    this.entityId,
    this.entityType,
    this.userId,
    this.username,
    required this.timestamp,
    this.metadata,
    this.oldValue,
    this.newValue,
    this.source,
    this.success = true,
    this.errorMessage,
  });

  /// Create from JSON
  factory AuditEntry.fromJson(Map<String, dynamic> json) {
    return AuditEntry(
      id: json['id'] as String,
      action: AuditAction.values.firstWhere(
        (e) => e.toString() == 'AuditAction.${json['action']}',
      ),
      entityId: json['entityId'] as String?,
      entityType: json['entityType'] as String?,
      userId: json['userId'] as String?,
      username: json['username'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
      oldValue: json['oldValue'] != null
          ? Map<String, dynamic>.from(json['oldValue'] as Map)
          : null,
      newValue: json['newValue'] != null
          ? Map<String, dynamic>.from(json['newValue'] as Map)
          : null,
      source: json['source'] as String?,
      success: json['success'] as bool? ?? true,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action.toString().split('.').last,
      'entityId': entityId,
      'entityType': entityType,
      'userId': userId,
      'username': username,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
      'oldValue': oldValue,
      'newValue': newValue,
      'source': source,
      'success': success,
      'errorMessage': errorMessage,
    };
  }

  @override
  String toString() {
    return 'AuditEntry(action: $action, entityType: $entityType, '
        'entityId: $entityId, user: $username, time: $timestamp)';
  }
}
