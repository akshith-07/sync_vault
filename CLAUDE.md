Create an enterprise-grade Flutter package called "sync_vault" - an offline-first database solution with automatic background sync and conflict resolution.

Features:
- Wrapper around Hive or Isar for local storage
- Automatic background sync with REST API
- Conflict resolution strategies (last-write-wins, server-wins, client-wins, merge, custom)
- Change tracking (track all CRUD operations)
- Sync queue with retry logic
- Query builder with type-safe syntax
- Relationships (one-to-one, one-to-many, many-to-many)
- Database migrations system
- Encrypted storage using flutter_secure_storage
- Transaction support
- Full-text search
- Reactive queries (streams that update on data changes)
- Batch operations for performance
- Import/export database
- Database inspection tools
- Comprehensive logging
- Network status detection
- Sync status indicators
- Pagination support
- Audit log (who changed what and when)
- Multiple database support (per-user databases)
- Works with Firebase, Supabase, custom REST APIs

Tech Stack:
- Flutter 3.x
- Hive or Isar for local database
- Dio for HTTP requests
- flutter_secure_storage for encryption
- connectivity_plus for network detection
- workmanager for background sync

Provide complete production-ready package with proper pubspec.yaml, comprehensive README with API examples, migration guides, example app demonstrating all features, unit tests, integration tests, and publishing guide to pub.dev.
