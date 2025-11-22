import 'package:hive/hive.dart';

part 'change_record.g.dart';

/// Types of changes that can be tracked
enum ChangeType {
  create,
  update,
  delete,
}

/// Record of a change made to an entity
@HiveType(typeId: 1)
class ChangeRecord extends HiveObject {
  /// Unique ID for this change record
  @HiveField(0)
  String id;

  /// ID of the entity that was changed
  @HiveField(1)
  String entityId;

  /// Type of entity (collection/table name)
  @HiveField(2)
  String entityType;

  /// Type of change
  @HiveField(3)
  ChangeType changeType;

  /// Timestamp when the change occurred
  @HiveField(4)
  DateTime timestamp;

  /// Entity data as JSON
  @HiveField(5)
  Map<String, dynamic> data;

  /// Whether this change has been synced to the server
  @HiveField(6)
  bool isSynced;

  /// Number of retry attempts for syncing this change
  @HiveField(7)
  int retryCount;

  /// Last error message if sync failed
  @HiveField(8)
  String? lastError;

  /// User who made the change (for audit purposes)
  @HiveField(9)
  String? userId;

  ChangeRecord({
    required this.id,
    required this.entityId,
    required this.entityType,
    required this.changeType,
    required this.timestamp,
    required this.data,
    this.isSynced = false,
    this.retryCount = 0,
    this.lastError,
    this.userId,
  });

  /// Create from JSON
  factory ChangeRecord.fromJson(Map<String, dynamic> json) {
    return ChangeRecord(
      id: json['id'] as String,
      entityId: json['entityId'] as String,
      entityType: json['entityType'] as String,
      changeType: ChangeType.values.firstWhere(
        (e) => e.toString() == 'ChangeType.${json['changeType']}',
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      data: Map<String, dynamic>.from(json['data'] as Map),
      isSynced: json['isSynced'] as bool? ?? false,
      retryCount: json['retryCount'] as int? ?? 0,
      lastError: json['lastError'] as String?,
      userId: json['userId'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entityId': entityId,
      'entityType': entityType,
      'changeType': changeType.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
      'isSynced': isSynced,
      'retryCount': retryCount,
      'lastError': lastError,
      'userId': userId,
    };
  }

  /// Mark as synced
  void markAsSynced() {
    isSynced = true;
    lastError = null;
  }

  /// Increment retry count
  void incrementRetry({String? error}) {
    retryCount++;
    lastError = error;
  }
}
