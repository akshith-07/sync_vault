import 'package:sync_vault/src/query/where_clause.dart';
import 'package:sync_vault/src/query/sort_clause.dart';

/// Type-safe query builder
class QueryBuilder<T> {
  final List<WhereClause<T>> _whereClauses = [];
  final List<SortClause<T>> _sortClauses = [];
  int? _limit;
  int? _offset;
  final Map<String, dynamic> Function(T) _toJson;

  QueryBuilder({
    required Map<String, dynamic> Function(T) toJson,
  }) : _toJson = toJson;

  /// Add a where clause
  QueryBuilder<T> where(WhereClause<T> clause) {
    _whereClauses.add(clause);
    return this;
  }

  /// Add an equals condition
  QueryBuilder<T> whereEquals(String field, dynamic value) {
    return where(WhereClause.equals(field, value));
  }

  /// Add a not equals condition
  QueryBuilder<T> whereNotEquals(String field, dynamic value) {
    return where(WhereClause.notEquals(field, value));
  }

  /// Add a greater than condition
  QueryBuilder<T> whereGreaterThan(String field, dynamic value) {
    return where(WhereClause.greaterThan(field, value));
  }

  /// Add a greater than or equal condition
  QueryBuilder<T> whereGreaterThanOrEqual(String field, dynamic value) {
    return where(WhereClause.greaterThanOrEqual(field, value));
  }

  /// Add a less than condition
  QueryBuilder<T> whereLessThan(String field, dynamic value) {
    return where(WhereClause.lessThan(field, value));
  }

  /// Add a less than or equal condition
  QueryBuilder<T> whereLessThanOrEqual(String field, dynamic value) {
    return where(WhereClause.lessThanOrEqual(field, value));
  }

  /// Add a contains condition (for strings)
  QueryBuilder<T> whereContains(String field, String value) {
    return where(WhereClause.contains(field, value));
  }

  /// Add a starts with condition (for strings)
  QueryBuilder<T> whereStartsWith(String field, String value) {
    return where(WhereClause.startsWith(field, value));
  }

  /// Add an ends with condition (for strings)
  QueryBuilder<T> whereEndsWith(String field, String value) {
    return where(WhereClause.endsWith(field, value));
  }

  /// Add an is in condition
  QueryBuilder<T> whereIn(String field, List<dynamic> values) {
    return where(WhereClause.isIn(field, values));
  }

  /// Add an is not in condition
  QueryBuilder<T> whereNotIn(String field, List<dynamic> values) {
    return where(WhereClause.isNotIn(field, values));
  }

  /// Add an is null condition
  QueryBuilder<T> whereNull(String field) {
    return where(WhereClause.isNull(field));
  }

  /// Add an is not null condition
  QueryBuilder<T> whereNotNull(String field) {
    return where(WhereClause.isNotNull(field));
  }

  /// Add a custom filter
  QueryBuilder<T> whereCustom(bool Function(T) filter) {
    return where(WhereClause.custom(filter));
  }

  /// Add a sort clause
  QueryBuilder<T> orderBy(SortClause<T> clause) {
    _sortClauses.add(clause);
    return this;
  }

  /// Sort by field in ascending order
  QueryBuilder<T> sortBy(String field, {SortDirection direction = SortDirection.ascending}) {
    return orderBy(SortClause(field: field, direction: direction));
  }

  /// Sort by field in ascending order
  QueryBuilder<T> sortAscending(String field) {
    return orderBy(SortClause.ascending(field));
  }

  /// Sort by field in descending order
  QueryBuilder<T> sortDescending(String field) {
    return orderBy(SortClause.descending(field));
  }

  /// Limit the number of results
  QueryBuilder<T> limit(int count) {
    _limit = count;
    return this;
  }

  /// Skip a number of results
  QueryBuilder<T> offset(int count) {
    _offset = count;
    return this;
  }

  /// Execute the query on a list of entities
  List<T> execute(List<T> entities) {
    var results = entities;

    // Apply where clauses
    if (_whereClauses.isNotEmpty) {
      results = results.where((entity) {
        return _whereClauses.every((clause) => clause.evaluate(entity, _toJson));
      }).toList();
    }

    // Apply sorting
    if (_sortClauses.isNotEmpty) {
      results.sort((a, b) {
        for (final sortClause in _sortClauses) {
          final comparison = sortClause.compare(a, b, _toJson);
          if (comparison != 0) {
            return comparison;
          }
        }
        return 0;
      });
    }

    // Apply offset
    if (_offset != null && _offset! > 0) {
      results = results.skip(_offset!).toList();
    }

    // Apply limit
    if (_limit != null && _limit! > 0) {
      results = results.take(_limit!).toList();
    }

    return results;
  }

  /// Create a copy of this query builder
  QueryBuilder<T> copy() {
    final copy = QueryBuilder<T>(toJson: _toJson);
    copy._whereClauses.addAll(_whereClauses);
    copy._sortClauses.addAll(_sortClauses);
    copy._limit = _limit;
    copy._offset = _offset;
    return copy;
  }
}
