import 'package:sync_vault/src/models/pagination.dart';
import 'package:sync_vault/src/query/query_builder.dart';

/// Abstract storage adapter interface
abstract class StorageAdapter<T> {
  /// Collection/table name
  String get collectionName;

  /// Initialize the storage adapter
  Future<void> initialize();

  /// Insert an entity
  Future<void> insert(T entity);

  /// Insert multiple entities
  Future<void> insertAll(List<T> entities);

  /// Update an entity
  Future<void> update(T entity);

  /// Delete an entity by ID
  Future<void> delete(String id);

  /// Delete multiple entities by IDs
  Future<void> deleteAll(List<String> ids);

  /// Get entity by ID
  Future<T?> getById(String id);

  /// Get all entities
  Future<List<T>> getAll();

  /// Query entities
  Future<List<T>> query(QueryBuilder<T> query);

  /// Query with pagination
  Future<PaginatedResult<T>> queryPaginated(
    QueryBuilder<T> query,
    PaginationParams pagination,
  );

  /// Count all entities
  Future<int> count();

  /// Count entities matching query
  Future<int> countWhere(QueryBuilder<T> query);

  /// Check if entity exists
  Future<bool> exists(String id);

  /// Clear all data
  Future<void> clear();

  /// Watch for changes (reactive queries)
  Stream<List<T>> watch(QueryBuilder<T>? query);

  /// Watch a single entity by ID
  Stream<T?> watchById(String id);

  /// Close the adapter
  Future<void> close();

  /// Convert from JSON
  T fromJson(Map<String, dynamic> json);

  /// Convert to JSON
  Map<String, dynamic> toJson(T entity);

  /// Get entity ID
  String getId(T entity);
}
