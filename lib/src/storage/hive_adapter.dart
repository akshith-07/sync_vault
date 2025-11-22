import 'dart:async';
import 'package:hive/hive.dart';
import 'package:sync_vault/src/storage/storage_adapter.dart';
import 'package:sync_vault/src/query/query_builder.dart';
import 'package:sync_vault/src/models/pagination.dart';
import 'package:sync_vault/src/core/sync_vault_exception.dart';

/// Hive implementation of storage adapter
class HiveAdapter<T> implements StorageAdapter<T> {
  @override
  final String collectionName;

  final T Function(Map<String, dynamic>) _fromJsonFunc;
  final Map<String, dynamic> Function(T) _toJsonFunc;
  final String Function(T) _getIdFunc;

  Box<Map>? _box;
  final StreamController<List<T>> _watchController = StreamController<List<T>>.broadcast();

  HiveAdapter({
    required this.collectionName,
    required T Function(Map<String, dynamic>) fromJson,
    required Map<String, dynamic> Function(T) toJson,
    required String Function(T) getId,
  })  : _fromJsonFunc = fromJson,
        _toJsonFunc = toJson,
        _getIdFunc = getId;

  @override
  Future<void> initialize() async {
    try {
      _box = await Hive.openBox<Map>(collectionName);
    } catch (e, stack) {
      throw DatabaseException(
        'Failed to initialize Hive adapter for $collectionName',
        originalError: e,
        stackTrace: stack,
      );
    }
  }

  void _ensureInitialized() {
    if (_box == null) {
      throw DatabaseException('HiveAdapter for $collectionName not initialized');
    }
  }

  @override
  Future<void> insert(T entity) async {
    _ensureInitialized();
    try {
      final id = _getIdFunc(entity);
      final json = _toJsonFunc(entity);
      await _box!.put(id, json);
      _notifyWatchers();
    } catch (e, stack) {
      throw DatabaseException(
        'Failed to insert entity in $collectionName',
        originalError: e,
        stackTrace: stack,
      );
    }
  }

  @override
  Future<void> insertAll(List<T> entities) async {
    _ensureInitialized();
    try {
      final Map<String, Map<String, dynamic>> entries = {};
      for (final entity in entities) {
        final id = _getIdFunc(entity);
        final json = _toJsonFunc(entity);
        entries[id] = json;
      }
      await _box!.putAll(entries);
      _notifyWatchers();
    } catch (e, stack) {
      throw DatabaseException(
        'Failed to insert entities in $collectionName',
        originalError: e,
        stackTrace: stack,
      );
    }
  }

  @override
  Future<void> update(T entity) async {
    _ensureInitialized();
    try {
      final id = _getIdFunc(entity);
      if (!_box!.containsKey(id)) {
        throw DatabaseException('Entity with id $id not found in $collectionName');
      }
      final json = _toJsonFunc(entity);
      await _box!.put(id, json);
      _notifyWatchers();
    } catch (e, stack) {
      throw DatabaseException(
        'Failed to update entity in $collectionName',
        originalError: e,
        stackTrace: stack,
      );
    }
  }

  @override
  Future<void> delete(String id) async {
    _ensureInitialized();
    try {
      await _box!.delete(id);
      _notifyWatchers();
    } catch (e, stack) {
      throw DatabaseException(
        'Failed to delete entity in $collectionName',
        originalError: e,
        stackTrace: stack,
      );
    }
  }

  @override
  Future<void> deleteAll(List<String> ids) async {
    _ensureInitialized();
    try {
      await _box!.deleteAll(ids);
      _notifyWatchers();
    } catch (e, stack) {
      throw DatabaseException(
        'Failed to delete entities in $collectionName',
        originalError: e,
        stackTrace: stack,
      );
    }
  }

  @override
  Future<T?> getById(String id) async {
    _ensureInitialized();
    try {
      final json = _box!.get(id);
      if (json == null) return null;
      return _fromJsonFunc(Map<String, dynamic>.from(json));
    } catch (e, stack) {
      throw DatabaseException(
        'Failed to get entity by id in $collectionName',
        originalError: e,
        stackTrace: stack,
      );
    }
  }

  @override
  Future<List<T>> getAll() async {
    _ensureInitialized();
    try {
      return _box!.values
          .map((json) => _fromJsonFunc(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e, stack) {
      throw DatabaseException(
        'Failed to get all entities in $collectionName',
        originalError: e,
        stackTrace: stack,
      );
    }
  }

  @override
  Future<List<T>> query(QueryBuilder<T> query) async {
    final allEntities = await getAll();
    return query.execute(allEntities);
  }

  @override
  Future<PaginatedResult<T>> queryPaginated(
    QueryBuilder<T> query,
    PaginationParams pagination,
  ) async {
    final allEntities = await getAll();
    final filtered = query.execute(allEntities);
    final totalItems = filtered.length;

    final startIndex = pagination.offset;
    final endIndex = startIndex + pagination.limit;

    final items = filtered.sublist(
      startIndex,
      endIndex > totalItems ? totalItems : endIndex,
    );

    return PaginatedResult(
      items: items,
      page: pagination.page,
      limit: pagination.limit,
      totalItems: totalItems,
    );
  }

  @override
  Future<int> count() async {
    _ensureInitialized();
    return _box!.length;
  }

  @override
  Future<int> countWhere(QueryBuilder<T> query) async {
    final result = await this.query(query);
    return result.length;
  }

  @override
  Future<bool> exists(String id) async {
    _ensureInitialized();
    return _box!.containsKey(id);
  }

  @override
  Future<void> clear() async {
    _ensureInitialized();
    try {
      await _box!.clear();
      _notifyWatchers();
    } catch (e, stack) {
      throw DatabaseException(
        'Failed to clear $collectionName',
        originalError: e,
        stackTrace: stack,
      );
    }
  }

  @override
  Stream<List<T>> watch(QueryBuilder<T>? query) {
    return _watchController.stream;
  }

  @override
  Stream<T?> watchById(String id) {
    return _watchController.stream.map((entities) {
      try {
        return entities.firstWhere((e) => _getIdFunc(e) == id);
      } catch (_) {
        return null;
      }
    });
  }

  void _notifyWatchers() {
    getAll().then((entities) {
      _watchController.add(entities);
    });
  }

  @override
  Future<void> close() async {
    await _watchController.close();
    await _box?.close();
  }

  @override
  T fromJson(Map<String, dynamic> json) => _fromJsonFunc(json);

  @override
  Map<String, dynamic> toJson(T entity) => _toJsonFunc(entity);

  @override
  String getId(T entity) => _getIdFunc(entity);
}
