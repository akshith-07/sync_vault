/// Types of relationships between entities
enum RelationshipType {
  oneToOne,
  oneToMany,
  manyToMany,
}

/// Represents a relationship between two entities
class Relationship<TSource, TTarget> {
  /// Name of the relationship
  final String name;

  /// Type of relationship
  final RelationshipType type;

  /// Source entity type name
  final String sourceType;

  /// Target entity type name
  final String targetType;

  /// Foreign key field name in source (for one-to-one and many-to-one)
  final String? foreignKeyField;

  /// Foreign key field name in target (for one-to-many)
  final String? inverseForeignKeyField;

  /// Junction table name (for many-to-many)
  final String? junctionTable;

  /// Source key field in junction table
  final String? junctionSourceKey;

  /// Target key field in junction table
  final String? junctionTargetKey;

  const Relationship({
    required this.name,
    required this.type,
    required this.sourceType,
    required this.targetType,
    this.foreignKeyField,
    this.inverseForeignKeyField,
    this.junctionTable,
    this.junctionSourceKey,
    this.junctionTargetKey,
  });

  /// Create a one-to-one relationship
  factory Relationship.oneToOne({
    required String name,
    required String sourceType,
    required String targetType,
    required String foreignKeyField,
  }) {
    return Relationship(
      name: name,
      type: RelationshipType.oneToOne,
      sourceType: sourceType,
      targetType: targetType,
      foreignKeyField: foreignKeyField,
    );
  }

  /// Create a one-to-many relationship
  factory Relationship.oneToMany({
    required String name,
    required String sourceType,
    required String targetType,
    required String inverseForeignKeyField,
  }) {
    return Relationship(
      name: name,
      type: RelationshipType.oneToMany,
      sourceType: sourceType,
      targetType: targetType,
      inverseForeignKeyField: inverseForeignKeyField,
    );
  }

  /// Create a many-to-many relationship
  factory Relationship.manyToMany({
    required String name,
    required String sourceType,
    required String targetType,
    required String junctionTable,
    required String junctionSourceKey,
    required String junctionTargetKey,
  }) {
    return Relationship(
      name: name,
      type: RelationshipType.manyToMany,
      sourceType: sourceType,
      targetType: targetType,
      junctionTable: junctionTable,
      junctionSourceKey: junctionSourceKey,
      junctionTargetKey: junctionTargetKey,
    );
  }

  @override
  String toString() {
    return 'Relationship($name: $sourceType -> $targetType, type: $type)';
  }
}
