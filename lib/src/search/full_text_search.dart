import 'package:sync_vault/src/logging/sync_vault_logger.dart';

/// Search result with relevance score
class SearchResult<T> {
  final T entity;
  final double score;
  final Map<String, List<int>>? highlights;

  const SearchResult({
    required this.entity,
    required this.score,
    this.highlights,
  });
}

/// Full-text search engine
class FullTextSearch<T> {
  final SyncVaultLogger _logger;
  final Map<String, dynamic> Function(T) _toJson;
  final List<String> _searchableFields;
  final Map<String, Map<String, Set<String>>> _index = {};
  bool _isIndexed = false;

  FullTextSearch({
    required SyncVaultLogger logger,
    required Map<String, dynamic> Function(T) toJson,
    required List<String> searchableFields,
  })  : _logger = logger,
        _toJson = toJson,
        _searchableFields = searchableFields;

  /// Index a list of entities
  Future<void> indexEntities(List<T> entities) async {
    _index.clear();

    for (final entity in entities) {
      final json = _toJson(entity);
      final entityId = json['id'] as String;

      for (final field in _searchableFields) {
        final value = _getFieldValue(json, field);
        if (value != null) {
          final tokens = _tokenize(value.toString());
          for (final token in tokens) {
            _index[field] ??= {};
            _index[field]![token] ??= {};
            _index[field]![token]!.add(entityId);
          }
        }
      }
    }

    _isIndexed = true;
    _logger.debug('Indexed ${entities.length} entities for full-text search');
  }

  /// Search entities by query
  Future<List<SearchResult<T>>> search(
    String query,
    List<T> entities, {
    int? limit,
    double minScore = 0.0,
  }) async {
    if (!_isIndexed) {
      await indexEntities(entities);
    }

    final queryTokens = _tokenize(query);
    final scores = <String, double>{};

    // Calculate scores for each entity
    for (final field in _searchableFields) {
      final fieldIndex = _index[field];
      if (fieldIndex == null) continue;

      for (final token in queryTokens) {
        final matchingIds = fieldIndex[token];
        if (matchingIds == null) continue;

        for (final id in matchingIds) {
          scores[id] = (scores[id] ?? 0.0) + 1.0;
        }
      }
    }

    // Filter and sort results
    final results = <SearchResult<T>>[];
    final entityMap = <String, T>{};

    for (final entity in entities) {
      final json = _toJson(entity);
      final id = json['id'] as String;
      entityMap[id] = entity;
    }

    for (final entry in scores.entries) {
      final score = entry.value / queryTokens.length;
      if (score >= minScore) {
        final entity = entityMap[entry.key];
        if (entity != null) {
          results.add(SearchResult(
            entity: entity,
            score: score,
          ));
        }
      }
    }

    results.sort((a, b) => b.score.compareTo(a.score));

    if (limit != null && limit > 0) {
      return results.take(limit).toList();
    }

    return results;
  }

  /// Tokenize text into searchable tokens
  List<String> _tokenize(String text) {
    // Convert to lowercase and split by non-alphanumeric characters
    final normalized = text.toLowerCase();
    final tokens = normalized.split(RegExp(r'[^a-z0-9]+'));

    // Filter out empty strings and common stop words
    return tokens
        .where((token) => token.isNotEmpty && !_isStopWord(token))
        .toList();
  }

  /// Check if a word is a stop word
  bool _isStopWord(String word) {
    const stopWords = {
      'a',
      'an',
      'and',
      'are',
      'as',
      'at',
      'be',
      'by',
      'for',
      'from',
      'has',
      'he',
      'in',
      'is',
      'it',
      'its',
      'of',
      'on',
      'that',
      'the',
      'to',
      'was',
      'will',
      'with',
    };
    return stopWords.contains(word);
  }

  dynamic _getFieldValue(Map<String, dynamic> json, String field) {
    // Support nested fields with dot notation
    final parts = field.split('.');
    dynamic value = json;

    for (final part in parts) {
      if (value is Map) {
        value = value[part];
      } else {
        return null;
      }
    }

    return value;
  }

  /// Clear the search index
  void clearIndex() {
    _index.clear();
    _isIndexed = false;
    _logger.debug('Search index cleared');
  }
}
