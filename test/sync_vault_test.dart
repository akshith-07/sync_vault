import 'package:flutter_test/flutter_test.dart';
import 'package:sync_vault/sync_vault.dart';

void main() {
  group('SyncVaultConfig', () {
    test('creates config with default values', () {
      final config = SyncVaultConfig(
        databaseName: 'test_db',
      );

      expect(config.databaseName, 'test_db');
      expect(config.enableEncryption, false);
      expect(config.enableBackgroundSync, false);
      expect(config.conflictResolution, ConflictResolutionStrategy.lastWriteWins);
    });

    test('creates config with custom values', () {
      final config = SyncVaultConfig(
        databaseName: 'test_db',
        apiBaseUrl: 'https://api.test.com',
        enableEncryption: true,
        enableBackgroundSync: true,
        conflictResolution: ConflictResolutionStrategy.serverWins,
      );

      expect(config.apiBaseUrl, 'https://api.test.com');
      expect(config.enableEncryption, true);
      expect(config.enableBackgroundSync, true);
      expect(config.conflictResolution, ConflictResolutionStrategy.serverWins);
    });

    test('copyWith creates new config with modified values', () {
      final config = SyncVaultConfig(
        databaseName: 'test_db',
        enableEncryption: false,
      );

      final newConfig = config.copyWith(
        enableEncryption: true,
      );

      expect(config.enableEncryption, false);
      expect(newConfig.enableEncryption, true);
      expect(newConfig.databaseName, 'test_db');
    });
  });

  group('QueryBuilder', () {
    test('creates simple query', () {
      final query = QueryBuilder<Map<String, dynamic>>(
        toJson: (map) => map,
      ).whereEquals('status', 'active');

      final data = [
        {'id': '1', 'status': 'active'},
        {'id': '2', 'status': 'inactive'},
        {'id': '3', 'status': 'active'},
      ];

      final results = query.execute(data);
      expect(results.length, 2);
      expect(results[0]['id'], '1');
      expect(results[1]['id'], '3');
    });

    test('executes complex query with multiple conditions', () {
      final query = QueryBuilder<Map<String, dynamic>>(
        toJson: (map) => map,
      )
          .whereEquals('type', 'user')
          .whereGreaterThan('age', 18)
          .sortDescending('age')
          .limit(2);

      final data = [
        {'id': '1', 'type': 'user', 'age': 25},
        {'id': '2', 'type': 'user', 'age': 30},
        {'id': '3', 'type': 'user', 'age': 20},
        {'id': '4', 'type': 'admin', 'age': 35},
      ];

      final results = query.execute(data);
      expect(results.length, 2);
      expect(results[0]['age'], 30);
      expect(results[1]['age'], 25);
    });

    test('handles pagination', () {
      final query = QueryBuilder<Map<String, dynamic>>(
        toJson: (map) => map,
      ).offset(2).limit(2);

      final data = List.generate(
        10,
        (i) => {'id': '$i', 'value': i},
      );

      final results = query.execute(data);
      expect(results.length, 2);
      expect(results[0]['id'], '2');
      expect(results[1]['id'], '3');
    });
  });

  group('PaginationParams', () {
    test('calculates offset correctly', () {
      final page1 = PaginationParams(page: 1, limit: 10);
      final page2 = PaginationParams(page: 2, limit: 10);
      final page3 = PaginationParams(page: 3, limit: 20);

      expect(page1.offset, 0);
      expect(page2.offset, 10);
      expect(page3.offset, 40);
    });

    test('creates next page', () {
      final page1 = PaginationParams(page: 1, limit: 10);
      final page2 = page1.nextPage();

      expect(page2.page, 2);
      expect(page2.limit, 10);
    });

    test('creates previous page', () {
      final page2 = PaginationParams(page: 2, limit: 10);
      final page1 = page2.previousPage();

      expect(page1.page, 1);
      expect(page1.limit, 10);
    });

    test('does not go below page 1', () {
      final page1 = PaginationParams(page: 1, limit: 10);
      final previous = page1.previousPage();

      expect(previous.page, 1);
    });
  });

  group('PaginatedResult', () {
    test('calculates total pages correctly', () {
      final result1 = PaginatedResult(
        items: [],
        page: 1,
        limit: 10,
        totalItems: 25,
      );

      expect(result1.totalPages, 3);
    });

    test('detects first and last pages', () {
      final firstPage = PaginatedResult(
        items: [],
        page: 1,
        limit: 10,
        totalItems: 25,
      );

      final lastPage = PaginatedResult(
        items: [],
        page: 3,
        limit: 10,
        totalItems: 25,
      );

      expect(firstPage.isFirstPage, true);
      expect(firstPage.isLastPage, false);
      expect(lastPage.isFirstPage, false);
      expect(lastPage.isLastPage, true);
    });

    test('detects next and previous pages', () {
      final middlePage = PaginatedResult(
        items: [],
        page: 2,
        limit: 10,
        totalItems: 30,
      );

      expect(middlePage.hasNextPage, true);
      expect(middlePage.hasPreviousPage, true);
    });
  });

  group('SyncStatus', () {
    test('creates idle status', () {
      final status = SyncStatus.idle();

      expect(status.state, SyncState.idle);
      expect(status.isOnline, true);
    });

    test('creates syncing status', () {
      final status = SyncStatus.syncing(
        pendingChanges: 5,
        progress: 0.5,
      );

      expect(status.state, SyncState.syncing);
      expect(status.pendingChanges, 5);
      expect(status.progress, 0.5);
    });

    test('creates error status', () {
      final status = SyncStatus.error(
        errorMessage: 'Network error',
        pendingChanges: 3,
      );

      expect(status.state, SyncState.error);
      expect(status.errorMessage, 'Network error');
      expect(status.pendingChanges, 3);
    });

    test('creates offline status', () {
      final status = SyncStatus.offline(pendingChanges: 2);

      expect(status.state, SyncState.offline);
      expect(status.isOnline, false);
      expect(status.pendingChanges, 2);
    });
  });

  group('ConflictResolver', () {
    test('server wins strategy', () {
      final resolver = ConflictResolver<String>(
        strategy: ConflictResolutionStrategy.serverWins,
      );

      final conflict = Conflict<String>(
        localVersion: 'local',
        serverVersion: 'server',
        entityId: '1',
        entityType: 'test',
        detectedAt: DateTime.now(),
      );

      final resolution = resolver.resolve(conflict);
      expect(resolution.resolved, 'server');
    });

    test('client wins strategy', () {
      final resolver = ConflictResolver<String>(
        strategy: ConflictResolutionStrategy.clientWins,
      );

      final conflict = Conflict<String>(
        localVersion: 'local',
        serverVersion: 'server',
        entityId: '1',
        entityType: 'test',
        detectedAt: DateTime.now(),
      );

      final resolution = resolver.resolve(conflict);
      expect(resolution.resolved, 'local');
    });

    test('custom resolver', () {
      final resolver = ConflictResolver<String>(
        strategy: ConflictResolutionStrategy.custom,
        customResolver: (conflict) => 'custom',
      );

      final conflict = Conflict<String>(
        localVersion: 'local',
        serverVersion: 'server',
        entityId: '1',
        entityType: 'test',
        detectedAt: DateTime.now(),
      );

      final resolution = resolver.resolve(conflict);
      expect(resolution.resolved, 'custom');
    });
  });

  group('WhereClause', () {
    test('equals clause', () {
      final clause = WhereClause<Map<String, dynamic>>.equals('status', 'active');

      final entity = {'status': 'active', 'name': 'Test'};
      expect(clause.evaluate(entity, (e) => e), true);

      final entity2 = {'status': 'inactive', 'name': 'Test'};
      expect(clause.evaluate(entity2, (e) => e), false);
    });

    test('greater than clause', () {
      final clause = WhereClause<Map<String, dynamic>>.greaterThan('age', 18);

      final entity1 = {'age': 25};
      expect(clause.evaluate(entity1, (e) => e), true);

      final entity2 = {'age': 15};
      expect(clause.evaluate(entity2, (e) => e), false);
    });

    test('contains clause', () {
      final clause = WhereClause<Map<String, dynamic>>.contains('name', 'John');

      final entity1 = {'name': 'John Doe'};
      expect(clause.evaluate(entity1, (e) => e), true);

      final entity2 = {'name': 'Jane Doe'};
      expect(clause.evaluate(entity2, (e) => e), false);
    });

    test('is in clause', () {
      final clause = WhereClause<Map<String, dynamic>>.isIn('status', ['active', 'pending']);

      final entity1 = {'status': 'active'};
      expect(clause.evaluate(entity1, (e) => e), true);

      final entity2 = {'status': 'completed'};
      expect(clause.evaluate(entity2, (e) => e), false);
    });
  });

  group('BatchExecutor', () {
    test('adds operations', () {
      final batch = BatchExecutor<Map<String, dynamic>>();

      batch.insert({'id': '1'});
      batch.update({'id': '2'});
      batch.delete('3');

      expect(batch.count, 3);
      expect(batch.operations[0].type, BatchOperationType.insert);
      expect(batch.operations[1].type, BatchOperationType.update);
      expect(batch.operations[2].type, BatchOperationType.delete);
    });

    test('clears operations', () {
      final batch = BatchExecutor<Map<String, dynamic>>();

      batch.insert({'id': '1'});
      batch.insert({'id': '2'});

      expect(batch.count, 2);

      batch.clear();

      expect(batch.count, 0);
      expect(batch.isEmpty, true);
    });
  });
}
