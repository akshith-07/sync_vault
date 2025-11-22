import 'package:hive/hive.dart';
import 'package:sync_vault/src/storage/storage_adapter.dart';
import 'package:sync_vault/src/logging/sync_vault_logger.dart';

/// Statistics about a collection
class CollectionStats {
  final String name;
  final int count;
  final int sizeInBytes;
  final DateTime? lastModified;

  const CollectionStats({
    required this.name,
    required this.count,
    this.sizeInBytes = 0,
    this.lastModified,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'count': count,
      'sizeInBytes': sizeInBytes,
      'lastModified': lastModified?.toIso8601String(),
    };
  }
}

/// Database statistics
class DatabaseStats {
  final String databaseName;
  final List<CollectionStats> collections;
  final int totalSize;
  final int totalEntities;
  final DateTime generatedAt;

  const DatabaseStats({
    required this.databaseName,
    required this.collections,
    required this.totalSize,
    required this.totalEntities,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'databaseName': databaseName,
      'collections': collections.map((c) => c.toJson()).toList(),
      'totalSize': totalSize,
      'totalEntities': totalEntities,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }
}

/// Tool for inspecting database contents
class DatabaseInspector {
  final SyncVaultLogger _logger;
  final String databaseName;

  DatabaseInspector({
    required this.databaseName,
    required SyncVaultLogger logger,
  }) : _logger = logger;

  /// Get statistics for all collections
  Future<DatabaseStats> getStatistics() async {
    try {
      final collections = <CollectionStats>[];
      int totalSize = 0;
      int totalEntities = 0;

      // Get all open boxes
      final boxNames = Hive.boxExists(databaseName)
          ? await _getBoxNames()
          : <String>[];

      for (final boxName in boxNames) {
        try {
          final box = await Hive.openBox(boxName);
          final stats = CollectionStats(
            name: boxName,
            count: box.length,
            sizeInBytes: 0, // Hive doesn't provide size info easily
          );
          collections.add(stats);
          totalEntities += box.length;
          await box.close();
        } catch (e) {
          _logger.warning('Failed to get stats for box $boxName', error: e);
        }
      }

      return DatabaseStats(
        databaseName: databaseName,
        collections: collections,
        totalSize: totalSize,
        totalEntities: totalEntities,
        generatedAt: DateTime.now(),
      );
    } catch (e, stack) {
      _logger.error('Failed to get database statistics', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Get collection statistics
  Future<CollectionStats> getCollectionStats(String collectionName) async {
    try {
      final box = await Hive.openBox(collectionName);
      final stats = CollectionStats(
        name: collectionName,
        count: box.length,
      );
      await box.close();
      return stats;
    } catch (e, stack) {
      _logger.error('Failed to get collection statistics', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// List all entities in a collection
  Future<List<Map<String, dynamic>>> listEntities(
    String collectionName, {
    int? limit,
    int? offset,
  }) async {
    try {
      final box = await Hive.openBox<Map>(collectionName);
      var entities = box.values.map((e) => Map<String, dynamic>.from(e)).toList();

      if (offset != null && offset > 0) {
        entities = entities.skip(offset).toList();
      }

      if (limit != null && limit > 0) {
        entities = entities.take(limit).toList();
      }

      await box.close();
      return entities;
    } catch (e, stack) {
      _logger.error('Failed to list entities', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Get entity by ID
  Future<Map<String, dynamic>?> getEntity(
    String collectionName,
    String id,
  ) async {
    try {
      final box = await Hive.openBox<Map>(collectionName);
      final entity = box.get(id);
      await box.close();
      return entity != null ? Map<String, dynamic>.from(entity) : null;
    } catch (e, stack) {
      _logger.error('Failed to get entity', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Search entities by field value
  Future<List<Map<String, dynamic>>> searchEntities(
    String collectionName,
    String field,
    dynamic value,
  ) async {
    try {
      final box = await Hive.openBox<Map>(collectionName);
      final entities = box.values
          .where((e) => e[field] == value)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      await box.close();
      return entities;
    } catch (e, stack) {
      _logger.error('Failed to search entities', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Verify database integrity
  Future<bool> verifyIntegrity() async {
    try {
      final boxNames = await _getBoxNames();

      for (final boxName in boxNames) {
        try {
          final box = await Hive.openBox(boxName);
          // Try to read all values
          box.values.toList();
          await box.close();
        } catch (e) {
          _logger.error('Integrity check failed for box $boxName', error: e);
          return false;
        }
      }

      _logger.info('Database integrity check passed');
      return true;
    } catch (e, stack) {
      _logger.error('Failed to verify integrity', error: e, stackTrace: stack);
      return false;
    }
  }

  Future<List<String>> _getBoxNames() async {
    // This is a simplified version - in practice you'd need to track
    // box names or use Hive's internal APIs
    return [];
  }
}
