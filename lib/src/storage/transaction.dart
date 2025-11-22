import 'dart:async';

/// Transaction callback
typedef TransactionCallback<T> = Future<T> Function(Transaction transaction);

/// Represents a database transaction
abstract class Transaction {
  /// Execute an operation within the transaction
  Future<T> execute<T>(Future<T> Function() operation);

  /// Commit the transaction
  Future<void> commit();

  /// Rollback the transaction
  Future<void> rollback();

  /// Whether the transaction is completed
  bool get isCompleted;
}

/// Simple in-memory transaction implementation
class InMemoryTransaction implements Transaction {
  final List<Future<void> Function()> _operations = [];
  final List<Future<void> Function()> _rollbackOperations = [];
  bool _isCompleted = false;

  @override
  bool get isCompleted => _isCompleted;

  @override
  Future<T> execute<T>(Future<T> Function() operation) async {
    if (_isCompleted) {
      throw StateError('Transaction already completed');
    }
    return await operation();
  }

  /// Add an operation to the transaction
  void addOperation(
    Future<void> Function() operation,
    Future<void> Function() rollback,
  ) {
    if (_isCompleted) {
      throw StateError('Transaction already completed');
    }
    _operations.add(operation);
    _rollbackOperations.add(rollback);
  }

  @override
  Future<void> commit() async {
    if (_isCompleted) {
      throw StateError('Transaction already completed');
    }

    try {
      for (final operation in _operations) {
        await operation();
      }
      _isCompleted = true;
    } catch (e) {
      await rollback();
      rethrow;
    }
  }

  @override
  Future<void> rollback() async {
    if (_isCompleted) {
      throw StateError('Transaction already completed');
    }

    for (final rollback in _rollbackOperations.reversed) {
      try {
        await rollback();
      } catch (e) {
        // Log but don't throw during rollback
      }
    }
    _isCompleted = true;
  }
}
