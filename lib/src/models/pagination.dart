/// Pagination parameters for queries
class PaginationParams {
  /// Page number (starting from 1)
  final int page;

  /// Number of items per page
  final int limit;

  /// Offset (calculated from page and limit)
  int get offset => (page - 1) * limit;

  const PaginationParams({
    this.page = 1,
    this.limit = 20,
  }) : assert(page > 0, 'Page must be greater than 0'),
       assert(limit > 0, 'Limit must be greater than 0');

  /// Create pagination for next page
  PaginationParams nextPage() {
    return PaginationParams(
      page: page + 1,
      limit: limit,
    );
  }

  /// Create pagination for previous page
  PaginationParams previousPage() {
    return PaginationParams(
      page: page > 1 ? page - 1 : 1,
      limit: limit,
    );
  }

  @override
  String toString() => 'PaginationParams(page: $page, limit: $limit)';
}

/// Result of a paginated query
class PaginatedResult<T> {
  /// List of items in this page
  final List<T> items;

  /// Current page number
  final int page;

  /// Items per page
  final int limit;

  /// Total number of items across all pages
  final int totalItems;

  /// Total number of pages
  int get totalPages => (totalItems / limit).ceil();

  /// Whether there is a next page
  bool get hasNextPage => page < totalPages;

  /// Whether there is a previous page
  bool get hasPreviousPage => page > 1;

  /// Whether this is the first page
  bool get isFirstPage => page == 1;

  /// Whether this is the last page
  bool get isLastPage => page >= totalPages;

  const PaginatedResult({
    required this.items,
    required this.page,
    required this.limit,
    required this.totalItems,
  });

  /// Create an empty paginated result
  factory PaginatedResult.empty({
    int page = 1,
    int limit = 20,
  }) {
    return PaginatedResult(
      items: [],
      page: page,
      limit: limit,
      totalItems: 0,
    );
  }

  @override
  String toString() {
    return 'PaginatedResult(page: $page/$totalPages, '
        'items: ${items.length}, total: $totalItems)';
  }
}
