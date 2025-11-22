# Migration Guide

This guide helps you migrate between different versions of SyncVault.

## Table of Contents

- [Version 1.0.0 (Initial Release)](#version-100-initial-release)
- [General Migration Tips](#general-migration-tips)
- [Breaking Changes](#breaking-changes)

## Version 1.0.0 (Initial Release)

This is the initial release of SyncVault. No migration needed!

### Getting Started

1. Install the package:
   ```yaml
   dependencies:
     sync_vault: ^1.0.0
   ```

2. Initialize your database:
   ```dart
   final config = SyncVaultConfig(
     databaseName: 'my_app',
     apiBaseUrl: 'https://api.example.com',
   );

   final db = SyncVaultDatabase(config: config);
   await db.initialize();
   ```

3. Create adapters for your models:
   ```dart
   final adapter = await db.createHiveAdapter<MyModel>(
     collectionName: 'my_models',
     fromJson: MyModel.fromJson,
     toJson: (model) => model.toJson(),
     getId: (model) => model.id,
   );
   ```

## General Migration Tips

### Backing Up Your Data

Before any major migration, always backup your data:

```dart
final importExport = ImportExport(logger: database.logger);
await importExport.backup('/path/to/backup.json');
```

### Database Migrations

When your schema changes, use the migration system:

```dart
class AddFieldMigration extends BaseMigration {
  @override
  int get version => 2;

  @override
  String get description => 'Add new field to model';

  @override
  Future<void> up() async {
    // Migration logic
  }

  @override
  Future<void> down() async {
    // Rollback logic
  }
}

database.migrationManager.registerMigration(AddFieldMigration());
await database.migrationManager.migrate(targetVersion: 2);
```

### Testing Migrations

Always test migrations on a copy of your production data:

1. Export production data
2. Create a test environment
3. Run migration
4. Verify data integrity
5. Test application functionality
6. Deploy to production

## Breaking Changes

### Future Versions

Breaking changes will be documented here when new versions are released.

Current version: 1.0.0 - No breaking changes

## Migration Checklist

- [ ] Review changelog for breaking changes
- [ ] Backup current database
- [ ] Update pubspec.yaml
- [ ] Run `flutter pub get`
- [ ] Update code for breaking changes
- [ ] Test thoroughly
- [ ] Deploy to production

## Need Help?

If you encounter issues during migration:

1. Check the [changelog](CHANGELOG.md)
2. Review the [documentation](README.md)
3. Search [GitHub issues](https://github.com/yourusername/sync_vault/issues)
4. Create a new issue if needed

## Best Practices

1. **Always backup before migrating**
2. **Test migrations in development first**
3. **Read the full changelog**
4. **Update dependencies incrementally**
5. **Monitor for errors after deployment**
