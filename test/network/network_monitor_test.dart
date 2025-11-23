import 'package:flutter_test/flutter_test.dart';
import 'package:sync_vault/src/network/network_monitor.dart';
import 'package:sync_vault/src/logging/sync_vault_logger.dart';

void main() {
  late NetworkMonitor networkMonitor;
  late SyncVaultLogger logger;

  setUp(() {
    logger = SyncVaultLogger(enabled: false);
    networkMonitor = NetworkMonitor(logger: logger);
  });

  tearDown(() async {
    await networkMonitor.dispose();
  });

  group('NetworkMonitor', () {
    test('should initialize successfully', () async {
      // Act
      await networkMonitor.initialize();

      // Assert
      expect(networkMonitor.isOnline, isA<bool>());
    });

    test('should emit connectivity changes', () async {
      // Arrange
      await networkMonitor.initialize();
      final changes = <bool>[];

      // Act
      final subscription = networkMonitor.onConnectivityChanged.listen(changes.add);
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      // The stream should emit at least one value
      expect(changes, isNotEmpty);

      await subscription.cancel();
    });

    test('should handle multiple listeners', () async {
      // Arrange
      await networkMonitor.initialize();
      final changes1 = <bool>[];
      final changes2 = <bool>[];

      // Act
      final sub1 = networkMonitor.onConnectivityChanged.listen(changes1.add);
      final sub2 = networkMonitor.onConnectivityChanged.listen(changes2.add);
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      expect(changes1.length, changes2.length);

      await sub1.cancel();
      await sub2.cancel();
    });

    test('should dispose properly', () async {
      // Arrange
      await networkMonitor.initialize();

      // Act
      await networkMonitor.dispose();

      // Assert - should not throw
      expect(() => networkMonitor.isOnline, returnsNormally);
    });
  });
}
