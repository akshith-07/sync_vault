/// Advanced SyncVault Example demonstrating all features
///
/// This example showcases:
/// - Complete CRUD operations
/// - Real API sync (with mock server)
/// - Search functionality
/// - Pagination
/// - Relationships (one-to-many)
/// - Conflict resolution
/// - Encryption
/// - Background sync
/// - Audit logging

import 'package:flutter/material.dart';
import 'package:sync_vault/sync_vault.dart';

void main() {
  runApp(const AdvancedExampleApp());
}

class AdvancedExampleApp extends StatelessWidget {
  const AdvancedExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SyncVault Advanced Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const DatabaseInitializer(),
    );
  }
}

class DatabaseInitializer extends StatefulWidget {
  const DatabaseInitializer({super.key});

  @override
  State<DatabaseInitializer> createState() => _DatabaseInitializerState();
}

class _DatabaseInitializerState extends State<DatabaseInitializer> {
  late SyncVaultDatabase _database;
  late StorageAdapter<Task> _taskAdapter;
  late StorageAdapter<Project> _projectAdapter;
  late StorageAdapter<Tag> _tagAdapter;
  bool _isInitialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    try {
      // Configure SyncVault with all features enabled
      final config = SyncVaultConfig(
        databaseName: 'advanced_example_db',
        apiBaseUrl: 'https://jsonplaceholder.typicode.com', // Demo API
        enableEncryption: true, // Enable encryption
        enableBackgroundSync: true, // Enable background sync
        backgroundSyncInterval: 15, // Sync every 15 minutes
        enableAuditLog: true, // Track who changed what
        enableLogging: true,
        enableFullTextSearch: true, // Enable search
        conflictResolution: ConflictResolutionStrategy.lastWriteWins,
        userId: 'user123', // For multi-user support
        apiHeaders: {
          'Authorization': 'Bearer demo-token',
          'Content-Type': 'application/json',
        },
      );

      _database = SyncVaultDatabase(config: config);
      await _database.initialize();

      // Create adapters for different entity types
      _projectAdapter = await _database.createHiveAdapter<Project>(
        collectionName: 'projects',
        fromJson: Project.fromJson,
        toJson: (p) => p.toJson(),
        getId: (p) => p.id,
      );

      _taskAdapter = await _database.createHiveAdapter<Task>(
        collectionName: 'tasks',
        fromJson: Task.fromJson,
        toJson: (t) => t.toJson(),
        getId: (t) => t.id,
      );

      _tagAdapter = await _database.createHiveAdapter<Tag>(
        collectionName: 'tags',
        fromJson: Tag.fromJson,
        toJson: (t) => t.toJson(),
        getId: (t) => t.id,
      );

      // Set up relationships
      _database.relationshipManager.defineOneToMany<Project, Task>(
        'Project',
        'tasks',
        foreignKey: 'projectId',
      );

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $_error'),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                  });
                  _initializeDatabase();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing SyncVault...'),
            ],
          ),
        ),
      );
    }

    return MainDashboard(
      database: _database,
      taskAdapter: _taskAdapter,
      projectAdapter: _projectAdapter,
      tagAdapter: _tagAdapter,
    );
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _database.close();
    }
    super.dispose();
  }
}

class MainDashboard extends StatefulWidget {
  final SyncVaultDatabase database;
  final StorageAdapter<Task> taskAdapter;
  final StorageAdapter<Project> projectAdapter;
  final StorageAdapter<Tag> tagAdapter;

  const MainDashboard({
    super.key,
    required this.database,
    required this.taskAdapter,
    required this.projectAdapter,
    required this.tagAdapter,
  });

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _selectedIndex = 0;
  SyncStatus? _syncStatus;

  @override
  void initState() {
    super.initState();

    // Listen to sync status
    widget.database.syncStatusStream.listen((status) {
      setState(() {
        _syncStatus = status;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      TaskListScreen(
        database: widget.database,
        taskAdapter: widget.taskAdapter,
        projectAdapter: widget.projectAdapter,
      ),
      ProjectListScreen(
        database: widget.database,
        projectAdapter: widget.projectAdapter,
        taskAdapter: widget.taskAdapter,
      ),
      SearchScreen(
        taskAdapter: widget.taskAdapter,
        projectAdapter: widget.projectAdapter,
      ),
      SettingsScreen(database: widget.database),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('SyncVault Advanced Example'),
        actions: [
          // Sync status indicator
          _buildSyncStatusIndicator(),
          // Manual sync button
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () => widget.database.sync(),
            tooltip: 'Manual Sync',
          ),
        ],
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.task_alt),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder),
            label: 'Projects',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildSyncStatusIndicator() {
    if (_syncStatus == null) {
      return const SizedBox.shrink();
    }

    IconData icon;
    Color color;
    String tooltip;

    if (_syncStatus!.isSyncing) {
      icon = Icons.cloud_sync;
      color = Colors.blue;
      tooltip = 'Syncing...';
    } else if (_syncStatus!.isSuccess) {
      icon = Icons.cloud_done;
      color = Colors.green;
      tooltip = 'Synced';
    } else if (_syncStatus!.isError) {
      icon = Icons.cloud_off;
      color = Colors.red;
      tooltip = 'Sync Error';
    } else if (_syncStatus!.isOffline) {
      icon = Icons.cloud_off;
      color = Colors.orange;
      tooltip = 'Offline';
    } else {
      icon = Icons.cloud_queue;
      color = Colors.grey;
      tooltip = 'Idle';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: IconButton(
        icon: Icon(icon, color: color),
        tooltip: tooltip,
        onPressed: () {
          if (_syncStatus!.pendingChanges > 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${_syncStatus!.pendingChanges} pending changes'),
              ),
            );
          }
        },
      ),
    );
  }
}

// Task List Screen
class TaskListScreen extends StatefulWidget {
  final SyncVaultDatabase database;
  final StorageAdapter<Task> taskAdapter;
  final StorageAdapter<Project> projectAdapter;

  const TaskListScreen({
    super.key,
    required this.database,
    required this.taskAdapter,
    required this.projectAdapter,
  });

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> _tasks = [];
  int _currentPage = 1;
  static const int _pageSize = 20;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _loading = true;
    });

    try {
      // Use pagination
      final query = QueryBuilder<Task>()
          .sortBy((task) => task.createdAt, descending: true)
          .offset((_currentPage - 1) * _pageSize)
          .limit(_pageSize);

      final tasks = await widget.taskAdapter.query(query);

      setState(() {
        _tasks = tasks;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading tasks: $e')),
        );
      }
    }
  }

  Future<void> _addTask() async {
    final title = await _showTaskDialog();
    if (title == null || title.isEmpty) return;

    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: '',
      completed: false,
      priority: TaskPriority.medium,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await widget.taskAdapter.insert(task);
    await _loadTasks();

    // Log the audit entry
    await widget.database.auditLogger.logAction(
      entityType: 'Task',
      entityId: task.id,
      action: AuditAction.create,
      newData: task.toJson(),
    );
  }

  Future<String?> _showTaskDialog([Task? task]) async {
    final controller = TextEditingController(text: task?.title ?? '');

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task == null ? 'Add Task' : 'Edit Task'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Task Title',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _tasks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.task_alt, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No tasks yet', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _addTask,
              icon: const Icon(Icons.add),
              label: const Text('Add First Task'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _tasks.length,
            itemBuilder: (context, index) {
              final task = _tasks[index];
              return TaskListTile(
                task: task,
                onToggle: () async {
                  final updated = Task(
                    id: task.id,
                    title: task.title,
                    description: task.description,
                    completed: !task.completed,
                    priority: task.priority,
                    projectId: task.projectId,
                    createdAt: task.createdAt,
                    updatedAt: DateTime.now(),
                  );
                  await widget.taskAdapter.update(task.id, updated);
                  await _loadTasks();
                },
                onDelete: () async {
                  await widget.taskAdapter.delete(task.id);
                  await _loadTasks();
                },
              );
            },
          ),
        ),
        // Pagination controls
        if (_tasks.length >= _pageSize)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _currentPage > 1
                      ? () {
                    setState(() {
                      _currentPage--;
                    });
                    _loadTasks();
                  }
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('Page $_currentPage'),
                IconButton(
                  onPressed: _tasks.length >= _pageSize
                      ? () {
                    setState(() {
                      _currentPage++;
                    });
                    _loadTasks();
                  }
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class TaskListTile extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const TaskListTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: task.completed,
        onChanged: (_) => onToggle(),
      ),
      title: Text(
        task.title,
        style: task.completed
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      ),
      subtitle: Text(
        'Priority: ${task.priority.name} • ${_formatDate(task.createdAt)}',
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: onDelete,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inMinutes}m ago';
    }
  }
}

// Project List Screen (simplified for brevity)
class ProjectListScreen extends StatelessWidget {
  final SyncVaultDatabase database;
  final StorageAdapter<Project> projectAdapter;
  final StorageAdapter<Task> taskAdapter;

  const ProjectListScreen({
    super.key,
    required this.database,
    required this.projectAdapter,
    required this.taskAdapter,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Projects Screen - Similar to Tasks'),
    );
  }
}

// Search Screen demonstrating full-text search
class SearchScreen extends StatefulWidget {
  final StorageAdapter<Task> taskAdapter;
  final StorageAdapter<Project> projectAdapter;

  const SearchScreen({
    super.key,
    required this.taskAdapter,
    required this.projectAdapter,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  List<Task> _results = [];

  void _search(String query) async {
    if (query.isEmpty) {
      setState(() {
        _results = [];
      });
      return;
    }

    // Use query builder for search
    final queryBuilder = QueryBuilder<Task>()
        .where((task) => task.title.toLowerCase().contains(query.toLowerCase()))
        .sortBy((task) => task.createdAt, descending: true)
        .limit(50);

    final results = await widget.taskAdapter.query(queryBuilder);

    setState(() {
      _results = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search tasks...',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _search('');
                },
              )
                  : null,
            ),
            onChanged: _search,
          ),
        ),
        Expanded(
          child: _results.isEmpty
              ? const Center(
            child: Text('No results found'),
          )
              : ListView.builder(
            itemCount: _results.length,
            itemBuilder: (context, index) {
              final task = _results[index];
              return ListTile(
                leading: Icon(
                  task.completed ? Icons.check_circle : Icons.radio_button_unchecked,
                ),
                title: Text(task.title),
                subtitle: Text('Priority: ${task.priority.name}'),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Settings Screen
class SettingsScreen extends StatelessWidget {
  final SyncVaultDatabase database;

  const SettingsScreen({super.key, required this.database});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          title: const Text('Network Status'),
          subtitle: Text(database.isOnline ? 'Online' : 'Offline'),
          leading: Icon(
            database.isOnline ? Icons.cloud_done : Icons.cloud_off,
            color: database.isOnline ? Colors.green : Colors.red,
          ),
        ),
        ListTile(
          title: const Text('Manual Sync'),
          subtitle: const Text('Sync data with server'),
          leading: const Icon(Icons.sync),
          onTap: () async {
            try {
              await database.sync();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sync completed')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Sync failed: $e')),
                );
              }
            }
          },
        ),
      ],
    );
  }
}

// Data Models
class Task {
  final String id;
  final String title;
  final String description;
  final bool completed;
  final TaskPriority priority;
  final String? projectId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.completed,
    required this.priority,
    this.projectId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      completed: json['completed'] as bool? ?? false,
      priority: TaskPriority.values.firstWhere(
            (p) => p.name == (json['priority'] as String? ?? 'medium'),
        orElse: () => TaskPriority.medium,
      ),
      projectId: json['projectId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'completed': completed,
      'priority': priority.name,
      'projectId': projectId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

enum TaskPriority { low, medium, high, urgent }

class Project {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class Tag {
  final String id;
  final String name;
  final String color;

  Tag({required this.id, required this.name, required this.color});

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
    };
  }
}
