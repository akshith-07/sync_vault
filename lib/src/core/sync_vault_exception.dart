/// Base exception for SyncVault errors
class SyncVaultException implements Exception {
  final String message;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const SyncVaultException(
    this.message, {
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    if (originalError != null) {
      return 'SyncVaultException: $message\nOriginal error: $originalError';
    }
    return 'SyncVaultException: $message';
  }
}

/// Exception thrown when database operations fail
class DatabaseException extends SyncVaultException {
  const DatabaseException(
    super.message, {
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() => 'DatabaseException: $message';
}

/// Exception thrown when sync operations fail
class SyncException extends SyncVaultException {
  const SyncException(
    super.message, {
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() => 'SyncException: $message';
}

/// Exception thrown when network operations fail
class NetworkException extends SyncVaultException {
  const NetworkException(
    super.message, {
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() => 'NetworkException: $message';
}

/// Exception thrown when encryption/decryption fails
class EncryptionException extends SyncVaultException {
  const EncryptionException(
    super.message, {
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() => 'EncryptionException: $message';
}

/// Exception thrown when migration fails
class MigrationException extends SyncVaultException {
  const MigrationException(
    super.message, {
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() => 'MigrationException: $message';
}

/// Exception thrown when query building fails
class QueryException extends SyncVaultException {
  const QueryException(
    super.message, {
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() => 'QueryException: $message';
}

/// Exception thrown when relationship operations fail
class RelationshipException extends SyncVaultException {
  const RelationshipException(
    super.message, {
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() => 'RelationshipException: $message';
}

/// Exception thrown when conflict resolution fails
class ConflictException extends SyncVaultException {
  const ConflictException(
    super.message, {
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() => 'ConflictException: $message';
}

/// Exception thrown when import/export operations fail
class ImportExportException extends SyncVaultException {
  const ImportExportException(
    super.message, {
    super.originalError,
    super.stackTrace,
  });

  @override
  String toString() => 'ImportExportException: $message';
}
