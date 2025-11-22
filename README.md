# SyncVault 🔄

An enterprise-grade offline-first database solution with automatic background sync and conflict resolution for Flutter applications.

[![pub package](https://img.shields.io/pub/v/sync_vault.svg)](https://pub.dev/packages/sync_vault)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

## Features ✨

- **Offline-First Architecture**: Work seamlessly without internet connection
- **Automatic Background Sync**: Keep data synchronized with your backend
- **Conflict Resolution**: Multiple strategies (last-write-wins, server-wins, client-wins, merge, custom)
- **Type-Safe Query Builder**: Intuitive API for querying data
- **Relationships**: Support for one-to-one, one-to-many, and many-to-many relationships
- **Database Migrations**: Easy schema evolution
- **Encryption**: Secure data storage using flutter_secure_storage
- **Transaction Support**: Atomic operations
- **Full-Text Search**: Search across your data efficiently
- **Reactive Queries**: Stream-based data updates
- **Batch Operations**: Optimize performance with bulk operations
- **Import/Export**: Backup and restore your database
- **Database Inspector**: Tools for debugging and monitoring
- **Comprehensive Logging**: Track all operations
- **Network Detection**: Automatic sync when connection is restored
- **Pagination**: Built-in pagination support
- **Audit Log**: Track who changed what and when
- **Multi-User Support**: Per-user databases

## Supported Backends

- Firebase
- Supabase
- Custom REST APIs
- Any backend with REST API support

## Installation 📦

Add to your `pubspec.yaml`:

```yaml
dependencies:
  sync_vault: ^1.0.0
```

Run:

```bash
flutter pub get
```

## Quick Start 🚀

### 1. Define Your Model

```dart
class Todo {
  final String id;
  final String title;
  final bool completed;
  final DateTime createdAt;
  final DateTime updatedAt;

  Todo({
    required this.id,
    required this.title,
    required this.completed,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as String,
      title: json['title'] as String,
      completed: json['completed'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'completed': completed,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
```

### 2. Initialize Database

```dart
final config = SyncVaultConfig(
  databaseName: 'my_app_db',
  apiBaseUrl: 'https://api.example.com',
  apiHeaders: {'Authorization': 'Bearer YOUR_TOKEN'},
  enableEncryption: true,
  enableBackgroundSync: true,
  backgroundSyncInterval: 15, // minutes
  conflictResolution: ConflictResolutionStrategy.lastWriteWins,
  enableAuditLog: true,
);

final database = SyncVaultDatabase(config: config);
await database.initialize();
```

### 3. Create Storage Adapter

```dart
final todoAdapter = await database.createHiveAdapter<Todo>(
  collectionName: 'todos',
  fromJson: Todo.fromJson,
  toJson: (todo) => todo.toJson(),
  getId: (todo) => todo.id,
);
```

### 4. CRUD Operations

```dart
// Create
final todo = Todo(
  id: 'todo_1',
  title: 'Buy groceries',
  completed: false,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);
await todoAdapter.insert(todo);

// Read
final todos = await todoAdapter.getAll();
final todo = await todoAdapter.getById('todo_1');

// Update
final updated = Todo(
  id: 'todo_1',
  title: 'Buy groceries',
  completed: true,
  createdAt: todo.createdAt,
  updatedAt: DateTime.now(),
);
await todoAdapter.update(updated);

// Delete
await todoAdapter.delete('todo_1');
```

### 5. Query Data

```dart
final query = QueryBuilder<Todo>(toJson: (todo) => todo.toJson())
  .whereEquals('completed', false)
  .sortDescending('createdAt')
  .limit(10);

final incompleteTodos = await todoAdapter.query(query);
```

### 6. Sync Data

```dart
// Manual sync
await database.sync();

// Listen to sync status
database.syncStatusStream.listen((status) {
  print('Sync status: ${status.state}');
  if (status.state == SyncState.error) {
    print('Error: ${status.errorMessage}');
  }
});
```

## Advanced Usage 🔧

See the full [README](https://github.com/yourusername/sync_vault) for advanced usage examples including:

- Pagination
- Full-Text Search
- Reactive Queries
- Batch Operations
- Relationships
- Database Migrations
- Encryption
- Audit Logging
- Import/Export
- Database Inspector
- Conflict Resolution

## API Reference 📚

See the [API documentation](https://pub.dev/documentation/sync_vault/latest/) for detailed information.

## Examples 💡

Check out the [example](./example) directory for a complete working application.

## Testing 🧪

```bash
flutter test
```

## License 📄

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support 💬

- 🐛 Issues: [GitHub Issues](https://github.com/yourusername/sync_vault/issues)

## Changelog 📝

See [CHANGELOG.md](./CHANGELOG.md) for release notes.