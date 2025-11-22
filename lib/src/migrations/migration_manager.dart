import 'package:hive/hive.dart';
import 'package:sync_vault/src/migrations/migration.dart';
import 'package:sync_vault/src/core/sync_vault_exception.dart';
import 'package:sync_vault/src/logging/sync_vault_logger.dart';

/// Manages database migrations
class MigrationManager {
  static const String _versionBoxName = '_migration_version';
  static const String _versionKey = 'current_version';

  final SyncVaultLogger _logger;
  final List<Migration> _migrations = [];
  Box? _versionBox;

  MigrationManager({
    required SyncVaultLogger logger,
  }) : _logger = logger;

  /// Register a migration
  void registerMigration(Migration migration) {
    _migrations.add(migration);
    _migrations.sort((a, b) => a.version.compareTo(b.version));
    _logger.debug('Registered migration v${migration.version}: ${migration.description}');
  }

  /// Register multiple migrations
  void registerMigrations(List<Migration> migrations) {
    for (final migration in migrations) {
      registerMigration(migration);
    }
  }

  /// Initialize migration manager
  Future<void> initialize() async {
    try {
      _versionBox = await Hive.openBox(_versionBoxName);
      _logger.info('Migration manager initialized');
    } catch (e, stack) {
      throw MigrationException(
        'Failed to initialize migration manager',
        originalError: e,
        stackTrace: stack,
      );
    }
  }

  /// Get current database version
  Future<int> getCurrentVersion() async {
    if (_versionBox == null) {
      throw MigrationException('Migration manager not initialized');
    }
    return _versionBox!.get(_versionKey, defaultValue: 0) as int;
  }

  /// Set current database version
  Future<void> _setCurrentVersion(int version) async {
    if (_versionBox == null) {
      throw MigrationException('Migration manager not initialized');
    }
    await _versionBox!.put(_versionKey, version);
  }

  /// Run pending migrations to reach target version
  Future<void> migrate({int? targetVersion}) async {
    try {
      final currentVersion = await getCurrentVersion();
      final target = targetVersion ?? _getLatestVersion();

      if (currentVersion == target) {
        _logger.info('Database is already at version $target');
        return;
      }

      if (currentVersion > target) {
        await _downgrade(currentVersion, target);
      } else {
        await _upgrade(currentVersion, target);
      }

      _logger.info('Migration completed: v$currentVersion -> v$target');
    } catch (e, stack) {
      throw MigrationException(
        'Migration failed',
        originalError: e,
        stackTrace: stack,
      );
    }
  }

  /// Upgrade from current to target version
  Future<void> _upgrade(int currentVersion, int targetVersion) async {
    final migrationsToRun = _migrations
        .where((m) => m.version > currentVersion && m.version <= targetVersion)
        .toList()
      ..sort((a, b) => a.version.compareTo(b.version));

    for (final migration in migrationsToRun) {
      _logger.info('Running migration v${migration.version}: ${migration.description}');
      await migration.up();
      await _setCurrentVersion(migration.version);
      _logger.info('Migration v${migration.version} completed');
    }
  }

  /// Downgrade from current to target version
  Future<void> _downgrade(int currentVersion, int targetVersion) async {
    final migrationsToRun = _migrations
        .where((m) => m.version <= currentVersion && m.version > targetVersion)
        .toList()
      ..sort((a, b) => b.version.compareTo(a.version));

    for (final migration in migrationsToRun) {
      _logger.info('Reverting migration v${migration.version}: ${migration.description}');
      await migration.down();
      await _setCurrentVersion(migration.version - 1);
      _logger.info('Migration v${migration.version} reverted');
    }
  }

  /// Get latest migration version
  int _getLatestVersion() {
    if (_migrations.isEmpty) return 0;
    return _migrations.map((m) => m.version).reduce((a, b) => a > b ? a : b);
  }

  /// Check if there are pending migrations
  Future<bool> hasPendingMigrations() async {
    final currentVersion = await getCurrentVersion();
    final latestVersion = _getLatestVersion();
    return currentVersion < latestVersion;
  }

  /// Get list of pending migrations
  Future<List<Migration>> getPendingMigrations() async {
    final currentVersion = await getCurrentVersion();
    return _migrations.where((m) => m.version > currentVersion).toList()
      ..sort((a, b) => a.version.compareTo(b.version));
  }

  /// Close migration manager
  Future<void> close() async {
    await _versionBox?.close();
    _logger.info('Migration manager closed');
  }
}
