import 'dart:async';
import 'package:flutter/foundation.dart';

/// Controller for managing search, filter, sort, and pagination state
///
/// Handles both offline and async data sources with proper disposal safety
/// and race condition prevention.
///
/// Example:
/// ```dart
/// final controller = SmartSearchController<String>(
///   searchableFields: (item) => [item],
/// );
///
/// controller.setItems(['Apple', 'Banana', 'Cherry']);
/// controller.search('App');
/// ```
class SmartSearchController<T extends Object> extends ChangeNotifier {
  /// Creates a search controller
  SmartSearchController({
    this.debounceDelay = const Duration(milliseconds: 300),
    required this.searchableFields,
    this.cacheResults = true,
    this.maxCacheSize = 100,
    this.caseSensitive = false,
    this.minSearchLength = 0,
    this.pageSize = 20,
  });

  /// Delay for search debouncing
  final Duration debounceDelay;

  /// Function to extract searchable text from items
  final List<String> Function(T item) searchableFields;

  /// Whether to cache search results
  final bool cacheResults;

  /// Maximum number of cached results
  final int maxCacheSize;

  /// Whether search is case sensitive
  bool caseSensitive;

  /// Minimum characters to trigger search
  int minSearchLength;

  /// Page size for pagination
  final int pageSize;

  // Internal state
  List<T> _allItems = [];
  List<T> _filteredItems = [];
  String _searchQuery = '';
  bool _hasSearched = false;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  Object? _error;
  bool _isDisposed = false;

  // Async management
  Timer? _debounceTimer;
  int _requestId = 0;
  Future<List<T>> Function(String query, {int page, int pageSize})?
      _asyncLoader;

  // Pagination
  int _currentPage = 0;
  bool _hasMorePages = true;

  // Cache
  final Map<String, List<T>> _cache = {};
  final List<String> _cacheKeys = [];

  // Filtering and sorting
  final Map<String, bool Function(T)> _activeFilters = {};
  int Function(T, T)? _currentComparator;

  /// Current filtered and sorted items
  List<T> get items => List.unmodifiable(_filteredItems);

  /// All items (unfiltered)
  List<T> get allItems => List.unmodifiable(_allItems);

  /// Current search query
  String get searchQuery => _searchQuery;

  /// Whether user has performed a search
  bool get hasSearched => _hasSearched;

  /// Whether currently loading
  bool get isLoading => _isLoading;

  /// Whether loading more pages
  bool get isLoadingMore => _isLoadingMore;

  /// Current error, if any
  Object? get error => _error;

  /// Whether there are more pages to load
  bool get hasMorePages => _hasMorePages;

  /// Whether the controller is disposed
  bool get isDisposed => _isDisposed;

  /// Currently active filters
  Map<String, bool Function(T)> get activeFilters =>
      Map.unmodifiable(_activeFilters);

  /// Current sort comparator
  int Function(T, T)? get currentComparator => _currentComparator;

  /// Update case sensitive setting and re-search if needed
  void updateCaseSensitive(bool value) {
    if (_isDisposed || caseSensitive == value) return;

    caseSensitive = value;

    // Clear cache since case sensitivity affects search results
    _clearCache();

    // Re-apply search if we have a current query
    if (_searchQuery.isNotEmpty) {
      _performSearch(_searchQuery);
    } else if (_allItems.isNotEmpty) {
      _applyFiltersAndSort();
      _notifyListeners();
    }
  }

  /// Update minimum search length and re-search if needed
  void updateMinSearchLength(int value) {
    if (_isDisposed || minSearchLength == value) return;

    minSearchLength = value;

    // Clear cache since minimum length affects search behavior
    _clearCache();

    // Re-apply search if we have a current query
    if (_searchQuery.isNotEmpty) {
      _performSearch(_searchQuery);
    }
  }

  /// Set items for offline mode
  void setItems(List<T> items) {
    if (_isDisposed) return;

    _allItems = List.from(items);
    _applyFiltersAndSort();
    _notifyListeners();
  }

  /// Set async data loader
  void setAsyncLoader(
    Future<List<T>> Function(String query, {int page, int pageSize}) loader,
  ) {
    if (_isDisposed) return;
    _asyncLoader = loader;
  }

  /// Perform search with debouncing
  void search(String query) {
    if (_isDisposed) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDelay, () => _performSearch(query));
  }

  Future<void> _performSearch(String query) async {
    if (_isDisposed) return;

    // Check minimum search length
    if (query.isNotEmpty && query.length < minSearchLength) {
      return;
    }

    _searchQuery = query;
    _hasSearched = true;
    _currentPage = 0;
    _hasMorePages = true;
    _setError(null);

    if (_asyncLoader != null) {
      await _loadAsyncData();
    } else {
      _applyFiltersAndSort();
    }

    _notifyListeners();
  }

  Future<void> _loadAsyncData() async {
    if (_isDisposed || _asyncLoader == null) return;

    final cacheKey = _getCacheKey();

    // Check cache first
    if (cacheResults && _cache.containsKey(cacheKey)) {
      _filteredItems = _cache[cacheKey]!;
      return;
    }

    _setLoading(true);

    final currentRequestId = ++_requestId;

    try {
      final results = await _asyncLoader!(
        _searchQuery,
        page: _currentPage,
        pageSize: pageSize,
      );

      // Ignore if newer request was made
      if (_isDisposed || currentRequestId != _requestId) return;

      _filteredItems = results;
      _hasMorePages = results.length == pageSize;

      // Cache results
      if (cacheResults) {
        _addToCache(cacheKey, results);
      }
    } catch (e) {
      if (_isDisposed || currentRequestId != _requestId) return;
      _setError(e);
    } finally {
      if (!_isDisposed && currentRequestId == _requestId) {
        _setLoading(false);
      }
    }
  }

  void _applyFiltersAndSort() {
    if (_isDisposed) return;

    List<T> filtered = List.from(_allItems);

    // Apply search
    if (_searchQuery.isNotEmpty) {
      final query = caseSensitive ? _searchQuery : _searchQuery.toLowerCase();
      filtered = filtered.where((item) {
        final searchableTexts = searchableFields(item);
        return searchableTexts.any((text) {
          final searchText = caseSensitive ? text : text.toLowerCase();
          return searchText.contains(query);
        });
      }).toList();
    }

    // Apply filters
    for (final filter in _activeFilters.entries) {
      filtered = filtered.where(filter.value).toList();
    }

    // Apply sort
    if (_currentComparator != null) {
      filtered.sort(_currentComparator!);
    }

    _filteredItems = filtered;
  }

  /// Add a filter
  void setFilter(String key, bool Function(T) predicate) {
    if (_isDisposed) return;

    _activeFilters[key] = predicate;
    _performSearch(_searchQuery);
  }

  /// Remove a filter
  void removeFilter(String key) {
    if (_isDisposed) return;

    _activeFilters.remove(key);
    _performSearch(_searchQuery);
  }

  /// Clear all filters
  void clearFilters() {
    if (_isDisposed) return;

    _activeFilters.clear();
    _performSearch(_searchQuery);
  }

  /// Set sort comparator
  void setSortBy(int Function(T, T)? comparator) {
    if (_isDisposed) return;

    _currentComparator = comparator;
    _performSearch(_searchQuery);
  }

  /// Load more items (pagination)
  Future<void> loadMore() async {
    if (_isDisposed ||
        !_hasMorePages ||
        _isLoadingMore ||
        _asyncLoader == null) {
      return;
    }

    _isLoadingMore = true;
    _notifyListeners();

    final currentRequestId = ++_requestId;

    try {
      final nextPage = _currentPage + 1;
      final results = await _asyncLoader!(
        _searchQuery,
        page: nextPage,
        pageSize: pageSize,
      );

      if (_isDisposed || currentRequestId != _requestId) return;

      if (results.isEmpty) {
        _hasMorePages = false;
      } else {
        _currentPage = nextPage;
        _filteredItems.addAll(results);
        _hasMorePages = results.length == pageSize;
      }
    } catch (e) {
      if (!_isDisposed && currentRequestId == _requestId) {
        _setError(e);
      }
    } finally {
      if (!_isDisposed && currentRequestId == _requestId) {
        _isLoadingMore = false;
        _notifyListeners();
      }
    }
  }

  /// Refresh data (clear cache and reload)
  Future<void> refresh() async {
    if (_isDisposed) return;

    _clearCache();
    _currentPage = 0;
    _hasMorePages = true;
    await _performSearch(_searchQuery);
  }

  /// Clear search
  void clearSearch() {
    if (_isDisposed) return;
    search('');
  }

  /// Retry after error
  Future<void> retry() async {
    if (_isDisposed) return;

    _setError(null);
    await _performSearch(_searchQuery);
  }

  String _getCacheKey() {
    return '${_searchQuery}_${_currentPage}_${_activeFilters.length}';
  }

  void _addToCache(String key, List<T> items) {
    if (_cacheKeys.length >= maxCacheSize) {
      final oldestKey = _cacheKeys.removeAt(0);
      _cache.remove(oldestKey);
    }

    _cache[key] = List.from(items);
    _cacheKeys.add(key);
  }

  void _clearCache() {
    _cache.clear();
    _cacheKeys.clear();
  }

  void _setLoading(bool loading) {
    if (_isDisposed) return;
    _isLoading = loading;
    _notifyListeners();
  }

  void _setError(Object? error) {
    if (_isDisposed) return;
    _error = error;
    _notifyListeners();
  }

  void _notifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _debounceTimer?.cancel();
    _clearCache();
    super.dispose();
  }
}
