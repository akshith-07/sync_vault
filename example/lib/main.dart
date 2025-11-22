import 'package:flutter/material.dart';
import 'package:sync_vault/sync_vault.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SyncVault Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late SyncVaultDatabase _database;
  late StorageAdapter<Todo> _todoAdapter;
  List<Todo> _todos = [];
  bool _isInitialized = false;
  SyncStatus? _syncStatus;

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    try {
      // Configure SyncVault
      final config = SyncVaultConfig(
        databaseName: 'example_db',
        apiBaseUrl: 'https://api.example.com', // Replace with your API
        enableEncryption: false,
        enableBackgroundSync: false,
        enableAuditLog: true,
        enableLogging: true,
        conflictResolution: ConflictResolutionStrategy.lastWriteWins,
      );

      // Initialize database
      _database = SyncVaultDatabase(config: config);
      await _database.initialize();

      // Create adapter for Todo entities
      _todoAdapter = await _database.createHiveAdapter<Todo>(
        collectionName: 'todos',
        fromJson: Todo.fromJson,
        toJson: (todo) => todo.toJson(),
        getId: (todo) => todo.id,
      );

      // Listen to sync status changes
      _database.syncStatusStream.listen((status) {
        setState(() {
          _syncStatus = status;
        });
      });

      // Load todos
      await _loadTodos();

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Failed to initialize database: $e');
    }
  }

  Future<void> _loadTodos() async {
    final todos = await _todoAdapter.getAll();
    setState(() {
      _todos = todos;
    });
  }

  Future<void> _addTodo(String title) async {
    final todo = Todo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      completed: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _todoAdapter.insert(todo);
    await _database.auditLogger.logCreate(
      entityId: todo.id,
      entityType: 'todos',
      value: todo.toJson(),
    );
    await _loadTodos();
  }

  Future<void> _toggleTodo(Todo todo) async {
    final updated = Todo(
      id: todo.id,
      title: todo.title,
      completed: !todo.completed,
      createdAt: todo.createdAt,
      updatedAt: DateTime.now(),
    );

    await _todoAdapter.update(updated);
    await _database.auditLogger.logUpdate(
      entityId: todo.id,
      entityType: 'todos',
      oldValue: todo.toJson(),
      newValue: updated.toJson(),
    );
    await _loadTodos();
  }

  Future<void> _deleteTodo(String id) async {
    final todo = await _todoAdapter.getById(id);
    await _todoAdapter.delete(id);
    if (todo != null) {
      await _database.auditLogger.logDelete(
        entityId: id,
        entityType: 'todos',
        value: todo.toJson(),
      );
    }
    await _loadTodos();
  }

  Future<void> _syncData() async {
    try {
      await _database.sync();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sync completed')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('SyncVault Example'),
        actions: [
          if (_syncStatus != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: _buildSyncStatusIndicator(),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _syncData,
          ),
        ],
      ),
      body: _todos.isEmpty
          ? const Center(
              child: Text('No todos yet. Add one using the + button.'),
            )
          : ListView.builder(
              itemCount: _todos.length,
              itemBuilder: (context, index) {
                final todo = _todos[index];
                return ListTile(
                  leading: Checkbox(
                    value: todo.completed,
                    onChanged: (_) => _toggleTodo(todo),
                  ),
                  title: Text(
                    todo.title,
                    style: TextStyle(
                      decoration: todo.completed
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteTodo(todo.id),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTodoDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSyncStatusIndicator() {
    switch (_syncStatus!.state) {
      case SyncState.syncing:
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case SyncState.success:
        return const Icon(Icons.cloud_done, color: Colors.green);
      case SyncState.error:
        return const Icon(Icons.cloud_off, color: Colors.red);
      case SyncState.offline:
        return const Icon(Icons.cloud_off, color: Colors.grey);
      case SyncState.idle:
        return const Icon(Icons.cloud_queue, color: Colors.grey);
    }
  }

  void _showAddTodoDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Todo'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter todo title',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                _addTodo(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }
}

// Example Todo model
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
