/// Enterprise-grade offline-first database solution with automatic background sync
/// and conflict resolution for Flutter applications.
library sync_vault;

// Core
export 'src/core/sync_vault_config.dart';
export 'src/core/sync_vault_database.dart';
export 'src/core/sync_vault_entity.dart';
export 'src/core/sync_vault_exception.dart';

// Models
export 'src/models/change_record.dart';
export 'src/models/conflict.dart';
export 'src/models/sync_status.dart';
export 'src/models/pagination.dart';
export 'src/models/audit_entry.dart';

// Sync
export 'src/sync/sync_engine.dart';
export 'src/sync/sync_queue.dart';
export 'src/sync/conflict_resolver.dart';
export 'src/sync/sync_strategy.dart';

// Query
export 'src/query/query_builder.dart';
export 'src/query/where_clause.dart';
export 'src/query/sort_clause.dart';

// Storage
export 'src/storage/storage_adapter.dart';
export 'src/storage/hive_adapter.dart';
export 'src/storage/transaction.dart';
export 'src/storage/batch_operation.dart';

// Migrations
export 'src/migrations/migration.dart';
export 'src/migrations/migration_manager.dart';

// Encryption
export 'src/encryption/encryption_service.dart';

// Logging
export 'src/logging/sync_vault_logger.dart';

// Network
export 'src/network/network_monitor.dart';
export 'src/network/api_client.dart';

// Relationships
export 'src/relationships/relationship.dart';
export 'src/relationships/relationship_manager.dart';

// Search
export 'src/search/full_text_search.dart';

// Audit
export 'src/audit/audit_logger.dart';

// Tools
export 'src/core/database_inspector.dart';
export 'src/core/import_export.dart';
