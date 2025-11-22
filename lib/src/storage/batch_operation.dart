/// Batch operation types
enum BatchOperationType {
  insert,
  update,
  delete,
}

/// Represents a single batch operation
class BatchOperation<T> {
  final BatchOperationType type;
  final T? entity;
  final String? id;

  const BatchOperation({
    required this.type,
    this.entity,
    this.id,
  });

  /// Create an insert operation
  factory BatchOperation.insert(T entity) {
    return BatchOperation(
      type: BatchOperationType.insert,
      entity: entity,
    );
  }

  /// Create an update operation
  factory BatchOperation.update(T entity) {
    return BatchOperation(
      type: BatchOperationType.update,
      entity: entity,
    );
  }

  /// Create a delete operation
  factory BatchOperation.delete(String id) {
    return BatchOperation(
      type: BatchOperationType.delete,
      id: id,
    );
  }
}

/// Batch executor for performing multiple operations efficiently
class BatchExecutor<T> {
  final List<BatchOperation<T>> _operations = [];

  /// Add an insert operation
  void insert(T entity) {
    _operations.add(BatchOperation.insert(entity));
  }

  /// Add multiple insert operations
  void insertAll(List<T> entities) {
    _operations.addAll(entities.map((e) => BatchOperation.insert(e)));
  }

  /// Add an update operation
  void update(T entity) {
    _operations.add(BatchOperation.update(entity));
  }

  /// Add multiple update operations
  void updateAll(List<T> entities) {
    _operations.addAll(entities.map((e) => BatchOperation.update(e)));
  }

  /// Add a delete operation
  void delete(String id) {
    _operations.add(BatchOperation.delete(id));
  }

  /// Add multiple delete operations
  void deleteAll(List<String> ids) {
    _operations.addAll(ids.map((id) => BatchOperation.delete(id)));
  }

  /// Get all operations
  List<BatchOperation<T>> get operations => List.unmodifiable(_operations);

  /// Get count of operations
  int get count => _operations.length;

  /// Clear all operations
  void clear() {
    _operations.clear();
  }

  /// Check if empty
  bool get isEmpty => _operations.isEmpty;

  /// Check if not empty
  bool get isNotEmpty => _operations.isNotEmpty;
}
