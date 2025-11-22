import 'package:sync_vault/src/relationships/relationship.dart';
import 'package:sync_vault/src/core/sync_vault_exception.dart';
import 'package:sync_vault/src/logging/sync_vault_logger.dart';

/// Manages relationships between entities
class RelationshipManager {
  final SyncVaultLogger _logger;
  final Map<String, List<Relationship>> _relationships = {};

  RelationshipManager({
    required SyncVaultLogger logger,
  }) : _logger = logger;

  /// Register a relationship
  void registerRelationship(Relationship relationship) {
    final sourceRelationships = _relationships[relationship.sourceType] ?? [];
    sourceRelationships.add(relationship);
    _relationships[relationship.sourceType] = sourceRelationships;

    _logger.debug('Registered relationship: ${relationship.name} '
        '(${relationship.sourceType} -> ${relationship.targetType})');
  }

  /// Get all relationships for an entity type
  List<Relationship> getRelationships(String entityType) {
    return _relationships[entityType] ?? [];
  }

  /// Get a specific relationship by name
  Relationship? getRelationship(String sourceType, String relationshipName) {
    final relationships = getRelationships(sourceType);
    try {
      return relationships.firstWhere((r) => r.name == relationshipName);
    } catch (_) {
      return null;
    }
  }

  /// Get one-to-one relationships for an entity type
  List<Relationship> getOneToOneRelationships(String entityType) {
    return getRelationships(entityType)
        .where((r) => r.type == RelationshipType.oneToOne)
        .toList();
  }

  /// Get one-to-many relationships for an entity type
  List<Relationship> getOneToManyRelationships(String entityType) {
    return getRelationships(entityType)
        .where((r) => r.type == RelationshipType.oneToMany)
        .toList();
  }

  /// Get many-to-many relationships for an entity type
  List<Relationship> getManyToManyRelationships(String entityType) {
    return getRelationships(entityType)
        .where((r) => r.type == RelationshipType.manyToMany)
        .toList();
  }

  /// Check if a relationship exists
  bool hasRelationship(String sourceType, String relationshipName) {
    return getRelationship(sourceType, relationshipName) != null;
  }

  /// Validate relationship configuration
  void validateRelationship(Relationship relationship) {
    switch (relationship.type) {
      case RelationshipType.oneToOne:
        if (relationship.foreignKeyField == null) {
          throw RelationshipException(
            'One-to-one relationship requires foreignKeyField',
          );
        }
        break;

      case RelationshipType.oneToMany:
        if (relationship.inverseForeignKeyField == null) {
          throw RelationshipException(
            'One-to-many relationship requires inverseForeignKeyField',
          );
        }
        break;

      case RelationshipType.manyToMany:
        if (relationship.junctionTable == null ||
            relationship.junctionSourceKey == null ||
            relationship.junctionTargetKey == null) {
          throw RelationshipException(
            'Many-to-many relationship requires junctionTable, '
            'junctionSourceKey, and junctionTargetKey',
          );
        }
        break;
    }
  }

  /// Clear all relationships
  void clear() {
    _relationships.clear();
    _logger.debug('Cleared all relationships');
  }
}
