import 'package:sync_vault/src/models/conflict.dart';
import 'package:sync_vault/src/core/sync_vault_exception.dart';

/// Conflict resolution strategies
enum ConflictResolutionStrategy {
  /// Last write wins (based on timestamp)
  lastWriteWins,

  /// Server always wins
  serverWins,

  /// Client always wins
  clientWins,

  /// Merge both versions (requires custom merge function)
  merge,

  /// Custom resolution strategy
  custom,

  /// Manual resolution (throws exception for user to resolve)
  manual,
}

/// Function signature for custom conflict resolution
typedef ConflictResolverFunction<T> = T Function(Conflict<T> conflict);

/// Function signature for custom merge
typedef MergeFunction<T> = T Function(T local, T server);

/// Handles conflict resolution between local and server data
class ConflictResolver<T> {
  final ConflictResolutionStrategy strategy;
  final ConflictResolverFunction<T>? customResolver;
  final MergeFunction<T>? mergeFunction;

  ConflictResolver({
    required this.strategy,
    this.customResolver,
    this.mergeFunction,
  }) {
    if (strategy == ConflictResolutionStrategy.custom && customResolver == null) {
      throw ArgumentError(
        'customResolver must be provided when using custom strategy',
      );
    }
    if (strategy == ConflictResolutionStrategy.merge && mergeFunction == null) {
      throw ArgumentError(
        'mergeFunction must be provided when using merge strategy',
      );
    }
  }

  /// Resolve a conflict based on the configured strategy
  ConflictResolution<T> resolve(Conflict<T> conflict) {
    switch (strategy) {
      case ConflictResolutionStrategy.lastWriteWins:
        return _resolveLastWriteWins(conflict);

      case ConflictResolutionStrategy.serverWins:
        return ConflictResolution(
          resolved: conflict.serverVersion,
          isAutomatic: true,
          resolutionDescription: 'Server version chosen (server wins strategy)',
        );

      case ConflictResolutionStrategy.clientWins:
        return ConflictResolution(
          resolved: conflict.localVersion,
          isAutomatic: true,
          resolutionDescription: 'Client version chosen (client wins strategy)',
        );

      case ConflictResolutionStrategy.merge:
        return _resolveMerge(conflict);

      case ConflictResolutionStrategy.custom:
        return _resolveCustom(conflict);

      case ConflictResolutionStrategy.manual:
        throw ConflictException(
          'Manual conflict resolution required for entity ${conflict.entityId}',
        );
    }
  }

  ConflictResolution<T> _resolveLastWriteWins(Conflict<T> conflict) {
    if (conflict.serverUpdatedAt != null && conflict.localUpdatedAt != null) {
      final chosen = conflict.serverUpdatedAt!.isAfter(conflict.localUpdatedAt!)
          ? conflict.serverVersion
          : conflict.localVersion;

      return ConflictResolution(
        resolved: chosen,
        isAutomatic: true,
        resolutionDescription: chosen == conflict.serverVersion
            ? 'Server version chosen (newer timestamp)'
            : 'Client version chosen (newer timestamp)',
      );
    } else if (conflict.serverVersion != null && conflict.localVersion != null) {
      final chosen = (conflict.serverVersion ?? 0) > (conflict.localVersion ?? 0)
          ? conflict.serverVersion
          : conflict.localVersion;

      return ConflictResolution(
        resolved: chosen,
        isAutomatic: true,
        resolutionDescription: chosen == conflict.serverVersion
            ? 'Server version chosen (higher version number)'
            : 'Client version chosen (higher version number)',
      );
    }

    // Default to server version if we can't determine
    return ConflictResolution(
      resolved: conflict.serverVersion,
      isAutomatic: true,
      resolutionDescription: 'Server version chosen (default)',
    );
  }

  ConflictResolution<T> _resolveMerge(Conflict<T> conflict) {
    try {
      final merged = mergeFunction!(
        conflict.localVersion,
        conflict.serverVersion,
      );

      return ConflictResolution(
        resolved: merged,
        isAutomatic: true,
        resolutionDescription: 'Versions merged using custom merge function',
      );
    } catch (e) {
      throw ConflictException(
        'Failed to merge conflict for entity ${conflict.entityId}',
        originalError: e,
      );
    }
  }

  ConflictResolution<T> _resolveCustom(Conflict<T> conflict) {
    try {
      final resolved = customResolver!(conflict);

      return ConflictResolution(
        resolved: resolved,
        isAutomatic: true,
        resolutionDescription: 'Resolved using custom resolver',
      );
    } catch (e) {
      throw ConflictException(
        'Custom resolver failed for entity ${conflict.entityId}',
        originalError: e,
      );
    }
  }
}

/// Default conflict resolver that uses last-write-wins strategy
class DefaultConflictResolver<T> extends ConflictResolver<T> {
  DefaultConflictResolver()
      : super(strategy: ConflictResolutionStrategy.lastWriteWins);
}
