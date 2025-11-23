import 'package:flutter_test/flutter_test.dart';
import 'package:sync_vault/src/sync/conflict_resolver.dart';
import 'package:sync_vault/src/models/conflict.dart';

void main() {
  group('ConflictResolver', () {
    late Conflict<Map<String, dynamic>> conflict;

    setUp(() {
      final now = DateTime.now();
      conflict = Conflict(
        entityId: 'entity1',
        entityType: 'Todo',
        localVersion: {'title': 'Local Title', 'completed': false},
        serverVersion: {'title': 'Server Title', 'completed': true},
        localTimestamp: now.subtract(const Duration(hours: 1)),
        serverTimestamp: now,
      );
    });

    test('serverWins strategy should choose server version', () async {
      // Arrange
      final resolver = ConflictResolver(ConflictResolutionStrategy.serverWins);

      // Act
      final resolution = await resolver.resolve(conflict);

      // Assert
      expect(resolution.resolvedData, conflict.serverVersion);
      expect(resolution.resolvedData?['title'], 'Server Title');
      expect(resolution.resolvedData?['completed'], true);
    });

    test('clientWins strategy should choose local version', () async {
      // Arrange
      final resolver = ConflictResolver(ConflictResolutionStrategy.clientWins);

      // Act
      final resolution = await resolver.resolve(conflict);

      // Assert
      expect(resolution.resolvedData, conflict.localVersion);
      expect(resolution.resolvedData?['title'], 'Local Title');
      expect(resolution.resolvedData?['completed'], false);
    });

    test('lastWriteWins strategy should choose newer version', () async {
      // Arrange
      final resolver = ConflictResolver(ConflictResolutionStrategy.lastWriteWins);

      // Act
      final resolution = await resolver.resolve(conflict);

      // Assert
      // Server version is newer
      expect(resolution.resolvedData, conflict.serverVersion);
      expect(resolution.resolvedData?['title'], 'Server Title');
    });

    test('lastWriteWins with older server should choose local', () async {
      // Arrange
      final now = DateTime.now();
      final olderConflict = Conflict(
        entityId: 'entity1',
        entityType: 'Todo',
        localVersion: {'title': 'Local Title', 'completed': false},
        serverVersion: {'title': 'Server Title', 'completed': true},
        localTimestamp: now,
        serverTimestamp: now.subtract(const Duration(hours: 1)),
      );

      final resolver = ConflictResolver(ConflictResolutionStrategy.lastWriteWins);

      // Act
      final resolution = await resolver.resolve(olderConflict);

      // Assert
      expect(resolution.resolvedData, olderConflict.localVersion);
    });

    test('merge strategy should merge both versions', () async {
      // Arrange
      final resolver = ConflictResolver(ConflictResolutionStrategy.merge);

      // Act
      final resolution = await resolver.resolve(conflict);

      // Assert
      expect(resolution.resolvedData, isNotNull);
      expect(resolution.resolvedData, isA<Map<String, dynamic>>());
      // Should contain keys from both versions
      expect(resolution.resolvedData?['title'], isNotNull);
      expect(resolution.resolvedData?['completed'], isNotNull);
    });

    test('custom strategy with callback should use callback result', () async {
      // Arrange
      final customResolver = ConflictResolver(
        ConflictResolutionStrategy.custom,
        customResolver: (conflict) async {
          // Custom logic: prefer local title but server completed status
          return ConflictResolution(
            resolvedData: {
              'title': conflict.localVersion['title'],
              'completed': conflict.serverVersion['completed'],
            },
          );
        },
      );

      // Act
      final resolution = await customResolver.resolve(conflict);

      // Assert
      expect(resolution.resolvedData?['title'], 'Local Title');
      expect(resolution.resolvedData?['completed'], true);
    });

    test('manual strategy should require manual resolution', () async {
      // Arrange
      final resolver = ConflictResolver(ConflictResolutionStrategy.manual);

      // Act
      final resolution = await resolver.resolve(conflict);

      // Assert
      expect(resolution.requiresManualResolution, true);
      expect(resolution.resolvedData, isNull);
    });

    test('should handle null values in conflict', () async {
      // Arrange
      final nullConflict = Conflict(
        entityId: 'entity1',
        entityType: 'Todo',
        localVersion: {'title': 'Local', 'description': null},
        serverVersion: {'title': 'Server', 'description': 'Has description'},
        localTimestamp: DateTime.now(),
        serverTimestamp: DateTime.now(),
      );

      final resolver = ConflictResolver(ConflictResolutionStrategy.merge);

      // Act
      final resolution = await resolver.resolve(nullConflict);

      // Assert
      expect(resolution.resolvedData, isNotNull);
      expect(resolution.resolvedData?['title'], isNotNull);
    });

    test('should handle nested objects in conflict', () async {
      // Arrange
      final nestedConflict = Conflict(
        entityId: 'entity1',
        entityType: 'User',
        localVersion: {
          'name': 'John',
          'profile': {'age': 30, 'city': 'NYC'},
        },
        serverVersion: {
          'name': 'John Doe',
          'profile': {'age': 31, 'city': 'LA'},
        },
        localTimestamp: DateTime.now(),
        serverTimestamp: DateTime.now(),
      );

      final resolver = ConflictResolver(ConflictResolutionStrategy.merge);

      // Act
      final resolution = await resolver.resolve(nestedConflict);

      // Assert
      expect(resolution.resolvedData, isNotNull);
      expect(resolution.resolvedData?['name'], isNotNull);
      expect(resolution.resolvedData?['profile'], isA<Map>());
    });
  });
}
