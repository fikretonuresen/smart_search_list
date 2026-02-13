import 'dart:async';
import 'package:flutter/foundation.dart';
import 'fuzzy_utils.dart';

/// Controller for managing search, filter, sort, and pagination state.
///
/// Handles both offline and async data sources with proper disposal safety
/// and race condition prevention. `T extends Object` ensures non-nullable types.
///
/// Example (offline mode):
/// ```dart
/// final controller = SmartSearchController<String>(
///   searchableFields: (item) => [item],
/// );
/// controller.setItems(['Apple', 'Banana', 'Cherry']);
/// controller.search('App');
/// ```
///
/// Example (async mode — [searchableFields] not needed):
/// ```dart
/// final controller = SmartSearchController<Product>();
/// controller.setAsyncLoader(api.searchProducts);
/// controller.search('shoes');
/// ```
class SmartSearchController<T extends Object> extends ChangeNotifier {
  /// Creates a search controller.
  SmartSearchController({
    this.debounceDelay = const Duration(milliseconds: 300),
    this.searchableFields,
    this.cacheResults = true,
    this.maxCacheSize = 100,
    bool caseSensitive = false,
    int minSearchLength = 0,
    this.pageSize = 20,
    bool fuzzySearchEnabled = false,
    double fuzzyThreshold = 0.3,
  }) : _caseSensitive = caseSensitive,
       _minSearchLength = minSearchLength,
       _fuzzySearchEnabled = fuzzySearchEnabled,
       _fuzzyThreshold = fuzzyThreshold;

  /// Delay for search debouncing.
  final Duration debounceDelay;

  /// Function to extract searchable text from items.
  ///
  /// Required for offline search mode. In async mode the server handles search
  /// matching, so this can be omitted.
  final List<String> Function(T item)? searchableFields;

  /// Whether to cache search results.
  final bool cacheResults;

  /// Maximum number of cached results.
  final int maxCacheSize;

  bool _caseSensitive;
  int _minSearchLength;

  /// Page size for pagination.
  final int pageSize;

  bool _fuzzySearchEnabled;
  double _fuzzyThreshold;

  /// Whether search is case-sensitive.
  bool get caseSensitive => _caseSensitive;

  /// Minimum characters to trigger search.
  int get minSearchLength => _minSearchLength;

  /// Whether fuzzy (subsequence) matching is enabled for offline search.
  bool get fuzzySearchEnabled => _fuzzySearchEnabled;

  /// Minimum score (0.0 – 1.0) for fuzzy matches to be included.
  ///
  /// Actual match scores range from 0.01 (weakest fuzzy match) to 1.0 (exact
  /// substring). A threshold of 0.0 accepts every fuzzy match; a threshold
  /// above 1.0 effectively disables fuzzy results.
  double get fuzzyThreshold => _fuzzyThreshold;

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
  int _filterVersion = 0;
  int Function(T, T)? _currentComparator;

  // Multi-select
  final Set<T> _selectedItems = {};

  /// Current filtered and sorted items.
  List<T> get items => List.unmodifiable(_filteredItems);

  /// All items (unfiltered).
  List<T> get allItems => List.unmodifiable(_allItems);

  /// Current search query.
  String get searchQuery => _searchQuery;

  /// Whether the user has performed a search.
  bool get hasSearched => _hasSearched;

  /// Whether the controller is currently loading data.
  bool get isLoading => _isLoading;

  /// Whether the controller is loading more pages.
  bool get isLoadingMore => _isLoadingMore;

  /// Current error, or `null` if none.
  Object? get error => _error;

  /// Whether there are more pages to load.
  bool get hasMorePages => _hasMorePages;

  /// Whether the controller is disposed.
  bool get isDisposed => _isDisposed;

  /// Currently active filters.
  Map<String, bool Function(T)> get activeFilters =>
      Map.unmodifiable(_activeFilters);

  /// Current sort comparator.
  int Function(T, T)? get currentComparator => _currentComparator;

  /// Updates the case-sensitive setting and re-searches if needed.
  void updateCaseSensitive(bool value) {
    if (_isDisposed || _caseSensitive == value) return;

    _caseSensitive = value;

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

  /// Updates the minimum search length and re-searches if needed.
  void updateMinSearchLength(int value) {
    if (_isDisposed || _minSearchLength == value) return;

    _minSearchLength = value;

    // Clear cache since minimum length affects search behavior
    _clearCache();

    // Re-apply search if we have a current query
    if (_searchQuery.isNotEmpty) {
      _performSearch(_searchQuery);
    }
  }

  /// Replaces all items and immediately re-applies filters and sort.
  void setItems(List<T> items) {
    if (_isDisposed) return;

    _allItems = List.from(items);
    _applyFiltersAndSort();
    _notifyListeners();
  }

  /// Sets the async data loader. Does not trigger a search — call
  /// [search] or [refresh] after.
  void setAsyncLoader(
    Future<List<T>> Function(String query, {int page, int pageSize}) loader,
  ) {
    if (_isDisposed) return;
    _asyncLoader = loader;
  }

  // ---------------------------------------------------------------------------
  // Multi-select API
  // ---------------------------------------------------------------------------

  /// Currently selected items.
  Set<T> get selectedItems => Set.unmodifiable(_selectedItems);

  /// Whether an item is currently selected.
  bool isSelected(T item) => _selectedItems.contains(item);

  /// Toggles selection state of an item.
  void toggleSelection(T item) {
    if (_isDisposed) return;
    if (_selectedItems.contains(item)) {
      _selectedItems.remove(item);
    } else {
      _selectedItems.add(item);
    }
    _notifyListeners();
  }

  /// Selects a single item.
  void select(T item) {
    if (_isDisposed) return;
    if (_selectedItems.add(item)) {
      _notifyListeners();
    }
  }

  /// Deselects a single item.
  void deselect(T item) {
    if (_isDisposed) return;
    if (_selectedItems.remove(item)) {
      _notifyListeners();
    }
  }

  /// Selects all currently visible (filtered) items.
  void selectAll() {
    if (_isDisposed) return;
    _selectedItems.addAll(_filteredItems);
    _notifyListeners();
  }

  /// Deselects all items.
  void deselectAll() {
    if (_isDisposed) return;
    if (_selectedItems.isEmpty) return;
    _selectedItems.clear();
    _notifyListeners();
  }

  /// Selects items matching a predicate (from visible items).
  void selectWhere(bool Function(T item) predicate) {
    if (_isDisposed) return;
    _selectedItems.addAll(_filteredItems.where(predicate));
    _notifyListeners();
  }

  /// Deselects items matching a predicate.
  void deselectWhere(bool Function(T item) predicate) {
    if (_isDisposed) return;
    _selectedItems.removeWhere(predicate);
    _notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Search API
  // ---------------------------------------------------------------------------

  /// Performs a debounced search for [query].
  ///
  /// Triggers after [debounceDelay]. Subsequent calls within the debounce
  /// window cancel previous pending searches.
  ///
  /// **Note:** The debounce delay applies to every call, including the initial
  /// load when the widget calls `search('')`. This means there is a
  /// [debounceDelay] pause (default 300 ms) before the first results appear.
  /// Use [searchImmediate] if you need results without the debounce delay.
  void search(String query) {
    if (_isDisposed) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDelay, () => _performSearch(query));
  }

  /// Performs search immediately, bypassing debounce.
  ///
  /// Use this for `SearchTriggerMode.onSubmit` or programmatic searches
  /// where you want instant results.
  void searchImmediate(String query) {
    if (_isDisposed) return;
    _debounceTimer?.cancel();
    _performSearch(query);
  }

  Future<void> _performSearch(String query) async {
    if (_isDisposed) return;

    // Check minimum search length
    if (query.isNotEmpty && query.length < _minSearchLength) {
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
      _notifyListeners();
    }
  }

  Future<void> _loadAsyncData() async {
    if (_isDisposed || _asyncLoader == null) return;

    final cacheKey = _getCacheKey();

    // Check cache first
    if (cacheResults && _cache.containsKey(cacheKey)) {
      // Defensive copy — loadMore mutates _filteredItems via addAll.
      _filteredItems = List.from(_cache[cacheKey]!);
      _notifyListeners();
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

    // Apply filters first (reduces the set before expensive search).
    for (final filter in _activeFilters.entries) {
      filtered = filtered.where(filter.value).toList();
    }

    // Apply search (only when searchableFields is provided — async mode
    // delegates search matching to the server).
    assert(() {
      if (_searchQuery.isNotEmpty &&
          searchableFields == null &&
          _asyncLoader == null) {
        debugPrint(
          'SmartSearchController: searchableFields is null and no asyncLoader '
          'is set. Search queries will not filter results. Pass '
          'searchableFields to the controller constructor for offline search.',
        );
      }
      return true;
    }());
    if (_searchQuery.isNotEmpty && searchableFields != null) {
      if (_fuzzySearchEnabled) {
        filtered = _fuzzySearch(filtered);
      } else {
        final query = _caseSensitive
            ? _searchQuery
            : _searchQuery.toLowerCase();
        filtered = filtered.where((item) {
          final searchableTexts = searchableFields!(item);
          return searchableTexts.any((text) {
            final searchText = _caseSensitive ? text : text.toLowerCase();
            return searchText.contains(query);
          });
        }).toList();
      }
    }

    // Apply user sort (overrides fuzzy relevance sort when set).
    if (_currentComparator != null) {
      filtered.sort(_currentComparator!);
    }

    _filteredItems = filtered;
  }

  /// Scores, filters, and ranks items using fuzzy subsequence matching.
  ///
  /// Items are sorted descending by best match score. Exact substring
  /// matches always score 1.0 and appear first.
  List<T> _fuzzySearch(List<T> items) {
    final threshold = _fuzzyThreshold;
    final scored = <_ScoredItem<T>>[];

    for (final item in items) {
      final fields = searchableFields!(item);
      final result = FuzzyMatcher.matchFields(
        _searchQuery,
        fields,
        caseSensitive: _caseSensitive,
      );
      if (result != null && result.score >= threshold) {
        scored.add(_ScoredItem(item, result.score));
      }
    }

    // Sort descending by score (highest first).
    scored.sort((a, b) => b.score.compareTo(a.score));

    return scored.map((s) => s.item).toList();
  }

  /// Adds or replaces a named filter and re-triggers search immediately.
  ///
  /// The same [key] with a different predicate replaces the previous filter.
  ///
  /// **Offline mode:** The predicate is applied client-side to [allItems]
  /// before search matching runs, so items that fail the filter are excluded
  /// from results.
  ///
  /// **Async mode:** The filter change invalidates the cache and re-invokes
  /// the async loader, but the predicate itself is **not** applied to the
  /// returned results. The async loader is responsible for its own filtering
  /// logic. If you need client-side filtering of async results, post-process
  /// them in your loader or switch to offline mode with pre-fetched data.
  void setFilter(String key, bool Function(T) predicate) {
    if (_isDisposed) return;

    _activeFilters[key] = predicate;
    _filterVersion++;
    _performSearch(_searchQuery);
  }

  /// Removes a named filter and re-triggers search immediately.
  ///
  /// In async mode this invalidates the cache and re-invokes the async
  /// loader; see [setFilter] for details on how filters interact with
  /// async results.
  void removeFilter(String key) {
    if (_isDisposed) return;

    _activeFilters.remove(key);
    _filterVersion++;
    _performSearch(_searchQuery);
  }

  /// Removes all filters and re-triggers search immediately.
  ///
  /// In async mode this invalidates the cache and re-invokes the async
  /// loader; see [setFilter] for details on how filters interact with
  /// async results.
  void clearFilters() {
    if (_isDisposed) return;

    _activeFilters.clear();
    _filterVersion++;
    _performSearch(_searchQuery);
  }

  /// Sets the sort comparator and re-triggers search immediately.
  ///
  /// Pass `null` to remove sorting.
  ///
  /// **Offline mode:** The comparator is applied client-side after filtering
  /// and search matching.
  ///
  /// **Async mode:** This invalidates the cache and re-invokes the async
  /// loader, but the comparator is **not** applied to the returned results.
  /// The async loader is responsible for its own sort order.
  void setSortBy(int Function(T, T)? comparator) {
    if (_isDisposed) return;

    _currentComparator = comparator;
    _clearCache();
    _performSearch(_searchQuery);
  }

  /// Loads the next page of results (pagination).
  ///
  /// No-op if already loading, no more pages, or no async loader is set.
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

  /// Clears the result cache, resets pagination, and reloads from page 0.
  Future<void> refresh() async {
    if (_isDisposed) return;

    _clearCache();
    _currentPage = 0;
    _hasMorePages = true;
    await _performSearch(_searchQuery);
  }

  /// Clears the search query immediately (bypasses debounce).
  void clearSearch() {
    if (_isDisposed) return;
    searchImmediate('');
  }

  /// Retries the last search after an error.
  Future<void> retry() async {
    if (_isDisposed) return;

    _setError(null);
    await _performSearch(_searchQuery);
  }

  String _getCacheKey() {
    final filterKeys = _activeFilters.keys.toList()..sort();
    return '${_searchQuery}_${_currentPage}_${filterKeys.join(',')}_fv$_filterVersion';
  }

  void _addToCache(String key, List<T> items) {
    // When maxCacheSize is 0, caching is effectively disabled.
    if (maxCacheSize <= 0) return;

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

  /// Updates fuzzy search enabled state and re-searches if needed.
  void updateFuzzySearchEnabled(bool value) {
    if (_isDisposed || _fuzzySearchEnabled == value) return;

    _fuzzySearchEnabled = value;
    _clearCache();

    if (_searchQuery.isNotEmpty) {
      _performSearch(_searchQuery);
    } else if (_allItems.isNotEmpty) {
      _applyFiltersAndSort();
      _notifyListeners();
    }
  }

  /// Updates fuzzy threshold and re-searches if needed.
  void updateFuzzyThreshold(double value) {
    if (_isDisposed || _fuzzyThreshold == value) return;

    _fuzzyThreshold = value;
    _clearCache();

    if (_searchQuery.isNotEmpty) {
      _performSearch(_searchQuery);
    }
  }

  /// Releases resources: cancels debounce timer, clears selection and cache.
  @override
  void dispose() {
    _isDisposed = true;
    _debounceTimer?.cancel();
    _selectedItems.clear();
    _clearCache();
    super.dispose();
  }
}

/// Internal helper for sorting items by fuzzy match score.
class _ScoredItem<T> {
  final T item;
  final double score;
  const _ScoredItem(this.item, this.score);
}
