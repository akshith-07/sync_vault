/// Base class for all entities stored in SyncVault
abstract class SyncVaultEntity {
  /// Unique identifier
  String get id;

  /// Timestamp when the entity was created locally
  DateTime get createdAt;

  /// Timestamp when the entity was last updated locally
  DateTime get updatedAt;

  /// Server-side timestamp (for conflict resolution)
  DateTime? get serverUpdatedAt;

  /// Whether the entity has been synced to the server
  bool get isSynced;

  /// Whether the entity is marked for deletion
  bool get isDeleted;

  /// Version number for optimistic locking
  int get version;

  /// Convert entity to JSON
  Map<String, dynamic> toJson();

  /// Create entity from JSON
  /// This should be implemented by each entity class
  // factory SyncVaultEntity.fromJson(Map<String, dynamic> json);
}

/// Mixin for entities to provide common functionality
mixin SyncVaultEntityMixin {
  late String _id;
  late DateTime _createdAt;
  late DateTime _updatedAt;
  DateTime? _serverUpdatedAt;
  bool _isSynced = false;
  bool _isDeleted = false;
  int _version = 1;

  String get id => _id;
  DateTime get createdAt => _createdAt;
  DateTime get updatedAt => _updatedAt;
  DateTime? get serverUpdatedAt => _serverUpdatedAt;
  bool get isSynced => _isSynced;
  bool get isDeleted => _isDeleted;
  int get version => _version;

  set id(String value) => _id = value;
  set createdAt(DateTime value) => _createdAt = value;
  set updatedAt(DateTime value) => _updatedAt = value;
  set serverUpdatedAt(DateTime? value) => _serverUpdatedAt = value;
  set isSynced(bool value) => _isSynced = value;
  set isDeleted(bool value) => _isDeleted = value;
  set version(int value) => _version = value;

  /// Initialize entity with default values
  void initializeEntity({String? id}) {
    _id = id ?? _generateId();
    final now = DateTime.now();
    _createdAt = now;
    _updatedAt = now;
    _isSynced = false;
    _isDeleted = false;
    _version = 1;
  }

  /// Update the timestamp
  void touch() {
    _updatedAt = DateTime.now();
    _version++;
    _isSynced = false;
  }

  /// Mark as synced
  void markAsSynced({DateTime? serverTimestamp}) {
    _isSynced = true;
    _serverUpdatedAt = serverTimestamp ?? DateTime.now();
  }

  /// Mark for deletion
  void markAsDeleted() {
    _isDeleted = true;
    _updatedAt = DateTime.now();
    _isSynced = false;
  }

  String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_randomString(8)}';
  }

  String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().microsecondsSinceEpoch;
    return List.generate(
      length,
      (index) => chars[(random + index) % chars.length],
    ).join();
  }
}
