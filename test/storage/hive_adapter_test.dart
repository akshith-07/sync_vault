import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sync_vault/src/storage/hive_adapter.dart';
import 'package:sync_vault/src/query/query_builder.dart';
import 'dart:io';

class TestEntity {
  final String id;
  final String name;
  final int age;
  final bool active;

  TestEntity({
    required this.id,
    required this.name,
    required this.age,
    required this.active,
  });

  factory TestEntity.fromJson(Map<String, dynamic> json) {
    return TestEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      age: json['age'] as int,
      active: json['active'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'active': active,
    };
  }
}

void main() {
  late HiveAdapter<TestEntity> adapter;
  late Directory testDir;

  setUp(() async {
    testDir = Directory.systemTemp.createTempSync('sync_vault_test_');
    await Hive.initFlutter(testDir.path);

    adapter = HiveAdapter<TestEntity>(
      collectionName: 'test_entities',
      fromJson: TestEntity.fromJson,
      toJson: (entity) => entity.toJson(),
      getId: (entity) => entity.id,
    );

    await adapter.initialize();
  });

  tearDown(() async {
    await adapter.close();
    await Hive.deleteBoxFromDisk('test_entities');
    testDir.deleteSync(recursive: true);
  });

  group('HiveAdapter CRUD Operations', () {
    test('should insert and retrieve entity', () async {
      // Arrange
      final entity = TestEntity(id: '1', name: 'John', age: 30, active: true);

      // Act
      await adapter.insert(entity);
      final retrieved = await adapter.getById('1');

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.id, '1');
      expect(retrieved.name, 'John');
      expect(retrieved.age, 30);
      expect(retrieved.active, true);
    });

    test('should update existing entity', () async {
      // Arrange
      final entity = TestEntity(id: '1', name: 'John', age: 30, active: true);
      await adapter.insert(entity);

      final updated = TestEntity(id: '1', name: 'Jane', age: 25, active: false);

      // Act
      await adapter.update('1', updated);
      final retrieved = await adapter.getById('1');

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Jane');
      expect(retrieved.age, 25);
      expect(retrieved.active, false);
    });

    test('should delete entity', () async {
      // Arrange
      final entity = TestEntity(id: '1', name: 'John', age: 30, active: true);
      await adapter.insert(entity);

      // Act
      await adapter.delete('1');
      final retrieved = await adapter.getById('1');

      // Assert
      expect(retrieved, isNull);
    });

    test('should get all entities', () async {
      // Arrange
      final entities = [
        TestEntity(id: '1', name: 'John', age: 30, active: true),
        TestEntity(id: '2', name: 'Jane', age: 25, active: false),
        TestEntity(id: '3', name: 'Bob', age: 35, active: true),
      ];

      for (final entity in entities) {
        await adapter.insert(entity);
      }

      // Act
      final all = await adapter.getAll();

      // Assert
      expect(all.length, 3);
    });

    test('should perform batch insert', () async {
      // Arrange
      final entities = List.generate(
        100,
            (i) => TestEntity(id: '$i', name: 'User$i', age: 20 + i, active: i % 2 == 0),
      );

      // Act
      await adapter.insertAll(entities);
      final all = await adapter.getAll();

      // Assert
      expect(all.length, 100);
    });

    test('should perform batch delete', () async {
      // Arrange
      final entities = [
        TestEntity(id: '1', name: 'John', age: 30, active: true),
        TestEntity(id: '2', name: 'Jane', age: 25, active: false),
        TestEntity(id: '3', name: 'Bob', age: 35, active: true),
      ];

      for (final entity in entities) {
        await adapter.insert(entity);
      }

      // Act
      await adapter.deleteAll(['1', '3']);
      final all = await adapter.getAll();

      // Assert
      expect(all.length, 1);
      expect(all.first.id, '2');
    });
  });

  group('HiveAdapter Query Operations', () {
    setUp(() async {
      // Insert test data
      final entities = [
        TestEntity(id: '1', name: 'Alice', age: 25, active: true),
        TestEntity(id: '2', name: 'Bob', age: 30, active: false),
        TestEntity(id: '3', name: 'Charlie', age: 35, active: true),
        TestEntity(id: '4', name: 'David', age: 40, active: false),
        TestEntity(id: '5', name: 'Eve', age: 45, active: true),
      ];

      for (final entity in entities) {
        await adapter.insert(entity);
      }
    });

    test('should filter entities with simple query', () async {
      // Arrange
      final query = QueryBuilder<TestEntity>()
          .where((entity) => entity.active == true);

      // Act
      final results = await adapter.query(query);

      // Assert
      expect(results.length, 3);
      expect(results.every((e) => e.active), true);
    });

    test('should sort entities', () async {
      // Arrange
      final query = QueryBuilder<TestEntity>()
          .sortBy((entity) => entity.age, descending: true);

      // Act
      final results = await adapter.query(query);

      // Assert
      expect(results.length, 5);
      expect(results.first.age, 45);
      expect(results.last.age, 25);
    });

    test('should limit results', () async {
      // Arrange
      final query = QueryBuilder<TestEntity>()
          .limit(2);

      // Act
      final results = await adapter.query(query);

      // Assert
      expect(results.length, 2);
    });

    test('should combine filter, sort, and limit', () async {
      // Arrange
      final query = QueryBuilder<TestEntity>()
          .where((entity) => entity.age >= 30)
          .sortBy((entity) => entity.age)
          .limit(2);

      // Act
      final results = await adapter.query(query);

      // Assert
      expect(results.length, 2);
      expect(results.first.age, 30);
      expect(results.last.age, 35);
    });
  });

  group('HiveAdapter Reactive Streams', () {
    test('should watch for changes', () async {
      // Arrange
      final changes = <List<TestEntity>>[];
      final subscription = adapter.watch().listen(changes.add);

      // Act
      await Future.delayed(const Duration(milliseconds: 50));
      await adapter.insert(TestEntity(id: '1', name: 'John', age: 30, active: true));
      await Future.delayed(const Duration(milliseconds: 50));
      await adapter.insert(TestEntity(id: '2', name: 'Jane', age: 25, active: false));
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert
      expect(changes.length, greaterThan(0));

      await subscription.cancel();
    });

    test('should watch specific entity', () async {
      // Arrange
      final entity = TestEntity(id: '1', name: 'John', age: 30, active: true);
      await adapter.insert(entity);

      final changes = <TestEntity?>[];
      final subscription = adapter.watchById('1').listen(changes.add);

      // Act
      await Future.delayed(const Duration(milliseconds: 50));
      await adapter.update('1', TestEntity(id: '1', name: 'Jane', age: 25, active: false));
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert
      expect(changes.length, greaterThan(0));
      expect(changes.last?.name, 'Jane');

      await subscription.cancel();
    });
  });
}
