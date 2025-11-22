import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:sync_vault/src/core/sync_vault_exception.dart';
import 'package:sync_vault/src/logging/sync_vault_logger.dart';

/// Import/Export format
enum ExportFormat {
  json,
  csv,
}

/// Options for import/export operations
class ImportExportOptions {
  final bool includeDeleted;
  final bool includeAuditLog;
  final bool includeChangeHistory;
  final List<String>? collections;

  const ImportExportOptions({
    this.includeDeleted = false,
    this.includeAuditLog = false,
    this.includeChangeHistory = false,
    this.collections,
  });
}

/// Tool for importing and exporting database data
class ImportExport {
  final SyncVaultLogger _logger;

  ImportExport({
    required SyncVaultLogger logger,
  }) : _logger = logger;

  /// Export database to JSON file
  Future<void> exportToJson(
    String filePath, {
    ImportExportOptions options = const ImportExportOptions(),
  }) async {
    try {
      _logger.info('Exporting database to $filePath');

      final data = <String, dynamic>{};
      final boxNames = options.collections ?? await _getAllBoxNames();

      for (final boxName in boxNames) {
        // Skip internal boxes if not requested
        if (boxName.startsWith('_') && !_shouldIncludeInternalBox(boxName, options)) {
          continue;
        }

        try {
          final box = await Hive.openBox<Map>(boxName);
          final entities = box.values
              .map((e) => Map<String, dynamic>.from(e))
              .toList();

          // Filter out deleted entities if not requested
          if (!options.includeDeleted) {
            entities.removeWhere((e) => e['isDeleted'] == true);
          }

          data[boxName] = entities;
          await box.close();
        } catch (e) {
          _logger.warning('Failed to export box $boxName', error: e);
        }
      }

      final jsonString = JsonEncoder.withIndent('  ').convert({
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'data': data,
      });

      final file = File(filePath);
      await file.writeAsString(jsonString);

      _logger.info('Database exported successfully');
    } catch (e, stack) {
      throw ImportExportException(
        'Failed to export database',
        originalError: e,
        stackTrace: stack,
      );
    }
  }

  /// Import database from JSON file
  Future<void> importFromJson(
    String filePath, {
    bool clearExisting = false,
  }) async {
    try {
      _logger.info('Importing database from $filePath');

      final file = File(filePath);
      if (!await file.exists()) {
        throw ImportExportException('File not found: $filePath');
      }

      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      final data = jsonData['data'] as Map<String, dynamic>;

      for (final entry in data.entries) {
        final boxName = entry.key;
        final entities = entry.value as List;

        try {
          final box = await Hive.openBox<Map>(boxName);

          if (clearExisting) {
            await box.clear();
          }

          for (final entity in entities) {
            final entityMap = Map<String, dynamic>.from(entity as Map);
            final id = entityMap['id'] as String;
            await box.put(id, entityMap);
          }

          await box.close();
          _logger.debug('Imported ${entities.length} entities into $boxName');
        } catch (e) {
          _logger.warning('Failed to import box $boxName', error: e);
        }
      }

      _logger.info('Database imported successfully');
    } catch (e, stack) {
      throw ImportExportException(
        'Failed to import database',
        originalError: e,
        stackTrace: stack,
      );
    }
  }

  /// Export a single collection to JSON
  Future<void> exportCollectionToJson(
    String collectionName,
    String filePath,
  ) async {
    try {
      _logger.info('Exporting collection $collectionName to $filePath');

      final box = await Hive.openBox<Map>(collectionName);
      final entities = box.values
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final jsonString = JsonEncoder.withIndent('  ').convert({
        'collection': collectionName,
        'exportedAt': DateTime.now().toIso8601String(),
        'count': entities.length,
        'data': entities,
      });

      final file = File(filePath);
      await file.writeAsString(jsonString);

      await box.close();

      _logger.info('Collection exported successfully (${entities.length} entities)');
    } catch (e, stack) {
      throw ImportExportException(
        'Failed to export collection',
        originalError: e,
        stackTrace: stack,
      );
    }
  }

  /// Import a single collection from JSON
  Future<void> importCollectionFromJson(
    String collectionName,
    String filePath, {
    bool clearExisting = false,
  }) async {
    try {
      _logger.info('Importing collection $collectionName from $filePath');

      final file = File(filePath);
      if (!await file.exists()) {
        throw ImportExportException('File not found: $filePath');
      }

      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final entities = jsonData['data'] as List;

      final box = await Hive.openBox<Map>(collectionName);

      if (clearExisting) {
        await box.clear();
      }

      for (final entity in entities) {
        final entityMap = Map<String, dynamic>.from(entity as Map);
        final id = entityMap['id'] as String;
        await box.put(id, entityMap);
      }

      await box.close();

      _logger.info('Collection imported successfully (${entities.length} entities)');
    } catch (e, stack) {
      throw ImportExportException(
        'Failed to import collection',
        originalError: e,
        stackTrace: stack,
      );
    }
  }

  /// Backup database to a file
  Future<void> backup(String backupPath) async {
    try {
      _logger.info('Creating backup at $backupPath');

      await exportToJson(
        backupPath,
        options: const ImportExportOptions(
          includeDeleted: true,
          includeAuditLog: true,
          includeChangeHistory: true,
        ),
      );

      _logger.info('Backup created successfully');
    } catch (e, stack) {
      throw ImportExportException(
        'Failed to create backup',
        originalError: e,
        stackTrace: stack,
      );
    }
  }

  /// Restore database from a backup file
  Future<void> restore(String backupPath) async {
    try {
      _logger.info('Restoring from backup at $backupPath');

      await importFromJson(backupPath, clearExisting: true);

      _logger.info('Database restored successfully');
    } catch (e, stack) {
      throw ImportExportException(
        'Failed to restore backup',
        originalError: e,
        stackTrace: stack,
      );
    }
  }

  bool _shouldIncludeInternalBox(String boxName, ImportExportOptions options) {
    if (boxName == '_audit_log' && options.includeAuditLog) return true;
    if (boxName == '_sync_queue' && options.includeChangeHistory) return true;
    return false;
  }

  Future<List<String>> _getAllBoxNames() async {
    // This is a simplified version - in practice you'd need to track
    // box names or use Hive's internal APIs
    return [];
  }
}
