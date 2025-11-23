import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:sync_vault/src/sync/sync_engine.dart';
import 'package:sync_vault/src/sync/sync_queue.dart';
import 'package:sync_vault/src/sync/sync_strategy.dart';
import 'package:sync_vault/src/sync/conflict_resolver.dart';
import 'package:sync_vault/src/network/network_monitor.dart';
import 'package:sync_vault/src/network/api_client.dart';
import 'package:sync_vault/src/logging/sync_vault_logger.dart';
import 'package:sync_vault/src/models/change_record.dart';
import 'package:sync_vault/src/models/sync_status.dart';
import 'package:dio/dio.dart';

@GenerateMocks([ApiClient, NetworkMonitor])
import 'sync_engine_integration_test.mocks.dart';

void main() {
  late SyncEngine syncEngine;
  late SyncQueue syncQueue;
  late MockNetworkMonitor networkMonitor;
  late MockApiClient apiClient;
  late SyncVaultLogger logger;

  setUp(() async {
    logger = SyncVaultLogger(enabled: false);
    syncQueue = SyncQueue(logger: logger, maxRetryAttempts: 3);
    await syncQueue.initialize();

    networkMonitor = MockNetworkMonitor();
    apiClient = MockApiClient();

    when(networkMonitor.isOnline).thenReturn(true);
    when(networkMonitor.onConnectivityChanged).thenAnswer((_) => Stream.value(true));

    syncEngine = SyncEngine(
      syncQueue: syncQueue,
      networkMonitor: networkMonitor,
      logger: logger,
      apiClient: apiClient,
      strategy: const SyncStrategy(
        autoSync: false,
        direction: SyncDirection.bidirectional,
      ),
    );

    await syncEngine.initialize();
  });

  tearDown(() async {
    await syncEngine.dispose();
    await syncQueue.close();
  });

  group('SyncEngine Integration Tests', () {
    test('should push pending changes to server', () async {
      // Arrange
      final change = ChangeRecord(
        id: '1',
        entityType: 'Todo',
        entityId: 'todo1',
        changeType: ChangeType.create,
        data: {'title': 'Test Todo', 'completed': false},
        timestamp: DateTime.now(),
        userId: 'user1',
      );

      await syncQueue.add(change);

      when(apiClient.post(any, data: anyNamed('data')))
          .thenAnswer((_) async => <String, dynamic>{});

      // Act
      await syncEngine.sync();

      // Assert
      verify(apiClient.post(any, data: anyNamed('data'))).called(1);
      expect(syncQueue.pendingCount, 0);
    });

    test('should handle sync errors and retry', () async {
      // Arrange
      final change = ChangeRecord(
        id: '1',
        entityType: 'Todo',
        entityId: 'todo1',
        changeType: ChangeType.create,
        data: {'title': 'Test Todo'},
        timestamp: DateTime.now(),
        userId: 'user1',
      );

      await syncQueue.add(change);

      when(apiClient.post(any, data: anyNamed('data')))
          .thenThrow(DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      ));

      // Act
      try {
        await syncEngine.sync();
      } catch (e) {
        // Expected to fail
      }

      // Assert
      expect(syncQueue.pendingCount, 1);
      final pending = syncQueue.getPending();
      expect(pending.first.retryCount, 1);
    });

    test('should emit sync status changes', () async {
      // Arrange
      final statuses = <SyncStatus>[];
      syncEngine.onStatusChanged.listen(statuses.add);

      when(apiClient.get<Map<String, dynamic>>(any, queryParameters: anyNamed('queryParameters')))
          .thenAnswer((_) async => <String, dynamic>{'changes': []});

      // Act
      await syncEngine.sync();
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      expect(statuses.isNotEmpty, true);
      expect(statuses.any((s) => s.isSyncing), true);
      expect(statuses.any((s) => s.isSuccess), true);
    });

    test('should resolve conflicts during pull sync', () async {
      // Arrange
      final serverChange = {
        'entityType': 'Todo',
        'id': 'todo1',
        'data': {'title': 'Server Version', 'completed': true},
        'updatedAt': DateTime.now().toIso8601String(),
        'deleted': false,
      };

      when(apiClient.get<Map<String, dynamic>>(any, queryParameters: anyNamed('queryParameters')))
          .thenAnswer((_) async => {
        'changes': [serverChange]
      });

      final resolver = ConflictResolver(ConflictResolutionStrategy.serverWins);
      syncEngine.registerConflictResolver('Todo', resolver);

      // Act
      await syncEngine.sync();

      // Assert
      verify(apiClient.get<Map<String, dynamic>>(any, queryParameters: anyNamed('queryParameters'))).called(1);
    });

    test('should not sync when offline', () async {
      // Arrange
      when(networkMonitor.isOnline).thenReturn(false);

      // Act
      await syncEngine.sync();

      // Assert
      verifyNever(apiClient.post(any, data: anyNamed('data')));
      verifyNever(apiClient.get<Map<String, dynamic>>(any, queryParameters: anyNamed('queryParameters')));
    });

    test('should batch sync when enabled', () async {
      // Arrange
      for (int i = 0; i < 10; i++) {
        await syncQueue.add(ChangeRecord(
          id: '$i',
          entityType: 'Todo',
          entityId: 'todo$i',
          changeType: ChangeType.create,
          data: {'title': 'Todo $i'},
          timestamp: DateTime.now(),
          userId: 'user1',
        ));
      }

      when(apiClient.post(any, data: anyNamed('data')))
          .thenAnswer((_) async => <String, dynamic>{});

      final batchEngine = SyncEngine(
        syncQueue: syncQueue,
        networkMonitor: networkMonitor,
        logger: logger,
        apiClient: apiClient,
        strategy: const SyncStrategy(
          autoSync: false,
          batchSync: true,
          batchSize: 5,
        ),
      );

      await batchEngine.initialize();

      // Act
      await batchEngine.sync();

      // Assert
      // Should make 2 batch requests (5 + 5)
      verify(apiClient.post('/sync/batch', data: anyNamed('data'))).called(2);

      await batchEngine.dispose();
    });
  });
}
