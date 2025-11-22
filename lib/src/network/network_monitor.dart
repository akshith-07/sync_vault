import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sync_vault/src/logging/sync_vault_logger.dart';

/// Monitors network connectivity status
class NetworkMonitor {
  final Connectivity _connectivity;
  final SyncVaultLogger _logger;

  StreamController<bool>? _connectivityController;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _isOnline = false;

  NetworkMonitor({
    required SyncVaultLogger logger,
    Connectivity? connectivity,
  })  : _logger = logger,
        _connectivity = connectivity ?? Connectivity();

  /// Get current online status
  bool get isOnline => _isOnline;

  /// Stream of connectivity changes
  Stream<bool> get onConnectivityChanged {
    _connectivityController ??= StreamController<bool>.broadcast();
    return _connectivityController!.stream;
  }

  /// Initialize network monitoring
  Future<void> initialize() async {
    try {
      // Check initial connectivity
      final result = await _connectivity.checkConnectivity();
      _isOnline = _isConnected(result);
      _logger.info('Network status: ${_isOnline ? "Online" : "Offline"}');

      // Listen to connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        (List<ConnectivityResult> results) {
          final wasOnline = _isOnline;
          _isOnline = _isConnected(results);

          if (wasOnline != _isOnline) {
            _logger.info('Network status changed: ${_isOnline ? "Online" : "Offline"}');
            _connectivityController?.add(_isOnline);
          }
        },
        onError: (error) {
          _logger.error('Connectivity monitoring error', error: error);
        },
      );
    } catch (e, stack) {
      _logger.error('Failed to initialize network monitor', error: e, stackTrace: stack);
      rethrow;
    }
  }

  /// Check if connectivity results indicate online status
  bool _isConnected(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;

    // Check if any result indicates connectivity
    return results.any((result) =>
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet ||
        result == ConnectivityResult.vpn);
  }

  /// Wait for network to become available
  Future<void> waitForConnection({Duration? timeout}) async {
    if (_isOnline) return;

    final completer = Completer<void>();
    late StreamSubscription<bool> subscription;

    subscription = onConnectivityChanged.listen((isOnline) {
      if (isOnline && !completer.isCompleted) {
        completer.complete();
        subscription.cancel();
      }
    });

    if (timeout != null) {
      return completer.future.timeout(
        timeout,
        onTimeout: () {
          subscription.cancel();
          throw TimeoutException('Timed out waiting for network connection');
        },
      );
    }

    return completer.future;
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    await _connectivityController?.close();
    _logger.info('Network monitor disposed');
  }
}
