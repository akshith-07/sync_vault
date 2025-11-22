/// Represents a database migration
abstract class Migration {
  /// Migration version number
  int get version;

  /// Description of what this migration does
  String get description;

  /// Upgrade database to this version
  Future<void> up();

  /// Downgrade database from this version
  Future<void> down();
}

/// Base migration class with helper methods
abstract class BaseMigration implements Migration {
  @override
  String toString() => 'Migration v$version: $description';
}
