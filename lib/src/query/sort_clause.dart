/// Sort direction
enum SortDirection {
  ascending,
  descending,
}

/// Represents a sort clause for ordering results
class SortClause<T> {
  final String field;
  final SortDirection direction;
  final Comparable? Function(T)? customComparator;

  const SortClause({
    required this.field,
    this.direction = SortDirection.ascending,
    this.customComparator,
  });

  /// Create an ascending sort clause
  factory SortClause.ascending(String field) {
    return SortClause(
      field: field,
      direction: SortDirection.ascending,
    );
  }

  /// Create a descending sort clause
  factory SortClause.descending(String field) {
    return SortClause(
      field: field,
      direction: SortDirection.descending,
    );
  }

  /// Create a custom sort clause
  factory SortClause.custom(
    String field,
    Comparable? Function(T) comparator, {
    SortDirection direction = SortDirection.ascending,
  }) {
    return SortClause(
      field: field,
      direction: direction,
      customComparator: comparator,
    );
  }

  /// Get the comparable value from an entity
  Comparable? getComparableValue(T entity, Map<String, dynamic> Function(T) toJson) {
    if (customComparator != null) {
      return customComparator!(entity);
    }

    final json = toJson(entity);
    final value = _getFieldValue(json, field);

    if (value is Comparable) {
      return value;
    }

    return null;
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

  /// Compare two entities using this sort clause
  int compare(T a, T b, Map<String, dynamic> Function(T) toJson) {
    final aValue = getComparableValue(a, toJson);
    final bValue = getComparableValue(b, toJson);

    if (aValue == null && bValue == null) return 0;
    if (aValue == null) return direction == SortDirection.ascending ? 1 : -1;
    if (bValue == null) return direction == SortDirection.ascending ? -1 : 1;

    final comparison = aValue.compareTo(bValue);
    return direction == SortDirection.ascending ? comparison : -comparison;
  }
}
