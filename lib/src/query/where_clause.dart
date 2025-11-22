/// Comparison operators for where clauses
enum ComparisonOperator {
  equals,
  notEquals,
  greaterThan,
  greaterThanOrEqual,
  lessThan,
  lessThanOrEqual,
  contains,
  startsWith,
  endsWith,
  isIn,
  isNotIn,
  isNull,
  isNotNull,
}

/// Logical operators for combining where clauses
enum LogicalOperator {
  and,
  or,
}

/// Represents a where clause for filtering data
class WhereClause<T> {
  final String? field;
  final ComparisonOperator? operator;
  final dynamic value;
  final bool Function(T)? customFilter;
  final List<WhereClause<T>>? children;
  final LogicalOperator? logicalOperator;

  const WhereClause._({
    this.field,
    this.operator,
    this.value,
    this.customFilter,
    this.children,
    this.logicalOperator,
  });

  /// Create an equals where clause
  factory WhereClause.equals(String field, dynamic value) {
    return WhereClause._(
      field: field,
      operator: ComparisonOperator.equals,
      value: value,
    );
  }

  /// Create a not equals where clause
  factory WhereClause.notEquals(String field, dynamic value) {
    return WhereClause._(
      field: field,
      operator: ComparisonOperator.notEquals,
      value: value,
    );
  }

  /// Create a greater than where clause
  factory WhereClause.greaterThan(String field, dynamic value) {
    return WhereClause._(
      field: field,
      operator: ComparisonOperator.greaterThan,
      value: value,
    );
  }

  /// Create a greater than or equal where clause
  factory WhereClause.greaterThanOrEqual(String field, dynamic value) {
    return WhereClause._(
      field: field,
      operator: ComparisonOperator.greaterThanOrEqual,
      value: value,
    );
  }

  /// Create a less than where clause
  factory WhereClause.lessThan(String field, dynamic value) {
    return WhereClause._(
      field: field,
      operator: ComparisonOperator.lessThan,
      value: value,
    );
  }

  /// Create a less than or equal where clause
  factory WhereClause.lessThanOrEqual(String field, dynamic value) {
    return WhereClause._(
      field: field,
      operator: ComparisonOperator.lessThanOrEqual,
      value: value,
    );
  }

  /// Create a contains where clause (for strings)
  factory WhereClause.contains(String field, String value) {
    return WhereClause._(
      field: field,
      operator: ComparisonOperator.contains,
      value: value,
    );
  }

  /// Create a starts with where clause (for strings)
  factory WhereClause.startsWith(String field, String value) {
    return WhereClause._(
      field: field,
      operator: ComparisonOperator.startsWith,
      value: value,
    );
  }

  /// Create an ends with where clause (for strings)
  factory WhereClause.endsWith(String field, String value) {
    return WhereClause._(
      field: field,
      operator: ComparisonOperator.endsWith,
      value: value,
    );
  }

  /// Create an is in where clause
  factory WhereClause.isIn(String field, List<dynamic> values) {
    return WhereClause._(
      field: field,
      operator: ComparisonOperator.isIn,
      value: values,
    );
  }

  /// Create an is not in where clause
  factory WhereClause.isNotIn(String field, List<dynamic> values) {
    return WhereClause._(
      field: field,
      operator: ComparisonOperator.isNotIn,
      value: values,
    );
  }

  /// Create an is null where clause
  factory WhereClause.isNull(String field) {
    return WhereClause._(
      field: field,
      operator: ComparisonOperator.isNull,
    );
  }

  /// Create an is not null where clause
  factory WhereClause.isNotNull(String field) {
    return WhereClause._(
      field: field,
      operator: ComparisonOperator.isNotNull,
    );
  }

  /// Create a custom filter where clause
  factory WhereClause.custom(bool Function(T) filter) {
    return WhereClause._(
      customFilter: filter,
    );
  }

  /// Combine clauses with AND
  factory WhereClause.and(List<WhereClause<T>> clauses) {
    return WhereClause._(
      children: clauses,
      logicalOperator: LogicalOperator.and,
    );
  }

  /// Combine clauses with OR
  factory WhereClause.or(List<WhereClause<T>> clauses) {
    return WhereClause._(
      children: clauses,
      logicalOperator: LogicalOperator.or,
    );
  }

  /// Evaluate the where clause against an entity
  bool evaluate(T entity, Map<String, dynamic> Function(T) toJson) {
    // Custom filter
    if (customFilter != null) {
      return customFilter!(entity);
    }

    // Logical operators
    if (children != null && logicalOperator != null) {
      if (logicalOperator == LogicalOperator.and) {
        return children!.every((child) => child.evaluate(entity, toJson));
      } else {
        return children!.any((child) => child.evaluate(entity, toJson));
      }
    }

    // Field comparison
    if (field != null && operator != null) {
      final json = toJson(entity);
      final fieldValue = _getFieldValue(json, field!);

      return _compareValues(fieldValue, operator!, value);
    }

    return true;
  }

  dynamic _getFieldValue(Map<String, dynamic> json, String field) {
    // Support nested fields with dot notation
    final parts = field.split('.');
    dynamic value = json;

    for (final part in parts) {
      if (value is Map) {
        value = value[part];
      } else {
        return null;
      }
    }

    return value;
  }

  bool _compareValues(dynamic fieldValue, ComparisonOperator op, dynamic compareValue) {
    switch (op) {
      case ComparisonOperator.equals:
        return fieldValue == compareValue;

      case ComparisonOperator.notEquals:
        return fieldValue != compareValue;

      case ComparisonOperator.greaterThan:
        return fieldValue != null && fieldValue is Comparable && fieldValue.compareTo(compareValue) > 0;

      case ComparisonOperator.greaterThanOrEqual:
        return fieldValue != null && fieldValue is Comparable && fieldValue.compareTo(compareValue) >= 0;

      case ComparisonOperator.lessThan:
        return fieldValue != null && fieldValue is Comparable && fieldValue.compareTo(compareValue) < 0;

      case ComparisonOperator.lessThanOrEqual:
        return fieldValue != null && fieldValue is Comparable && fieldValue.compareTo(compareValue) <= 0;

      case ComparisonOperator.contains:
        return fieldValue != null && fieldValue is String && fieldValue.contains(compareValue as String);

      case ComparisonOperator.startsWith:
        return fieldValue != null && fieldValue is String && fieldValue.startsWith(compareValue as String);

      case ComparisonOperator.endsWith:
        return fieldValue != null && fieldValue is String && fieldValue.endsWith(compareValue as String);

      case ComparisonOperator.isIn:
        return compareValue is List && compareValue.contains(fieldValue);

      case ComparisonOperator.isNotIn:
        return compareValue is List && !compareValue.contains(fieldValue);

      case ComparisonOperator.isNull:
        return fieldValue == null;

      case ComparisonOperator.isNotNull:
        return fieldValue != null;
    }
  }
}
