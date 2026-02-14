import 'package:flutter_test/flutter_test.dart';
import 'package:smart_search_list/smart_search_list.dart';

void main() {
  group('SmartSearchController', () {
    test('should initialize correctly', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      expect(controller.items, isEmpty);
      expect(controller.searchQuery, isEmpty);
      expect(controller.hasSearched, false);
      expect(controller.isLoading, false);
      expect(controller.error, isNull);
    });

    test('should handle offline items correctly', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setItems(['Apple', 'Banana', 'Cherry']);

      expect(controller.items.length, 3);
      expect(controller.allItems.length, 3);
    });

    test('should search items correctly', () async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: const Duration(milliseconds: 10), // Fast for testing
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setItems(['Apple', 'Banana', 'Cherry']);
      controller.search('App');

      // Wait for debounce
      await Future.delayed(const Duration(milliseconds: 20));

      expect(controller.hasSearched, true);
      expect(controller.searchQuery, 'App');
    });

    test('should dispose safely', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.dispose();

      expect(controller.isDisposed, true);

      // Should not crash when calling methods after dispose
      controller.search('test');
      controller.setItems(['test']);
    });

    test('should respect caseSensitive setting', () async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        caseSensitive: true,
        debounceDelay: const Duration(milliseconds: 10),
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setItems(['Apple', 'apple', 'APPLE']);
      controller.search('apple');

      await Future.delayed(const Duration(milliseconds: 20));

      // Should only match exact case
      expect(controller.items.length, 1);
      expect(controller.items.first, 'apple');
    });

    test('should respect minSearchLength', () async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        minSearchLength: 3,
        debounceDelay: const Duration(milliseconds: 10),
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setItems(['Apple', 'Banana', 'Cherry']);

      // Search with less than minSearchLength should be ignored
      controller.search('Ap');
      await Future.delayed(const Duration(milliseconds: 20));

      expect(controller.hasSearched, false);
      expect(controller.items.length, 3); // Should show all items

      // Search with minSearchLength should work
      controller.search('App');
      await Future.delayed(const Duration(milliseconds: 20));

      expect(controller.hasSearched, true);
      expect(controller.searchQuery, 'App');
    });

    test('should handle filters correctly', () async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: const Duration(milliseconds: 10),
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setItems(['Apple', 'Banana', 'Cherry', 'Apricot']);

      // Add filter for items starting with 'A'
      controller.setFilter('startsWithA', (item) => item.startsWith('A'));
      await Future.delayed(const Duration(milliseconds: 20));

      expect(controller.items.length, 2);
      expect(controller.items, containsAll(['Apple', 'Apricot']));
      expect(controller.activeFilters.containsKey('startsWithA'), true);

      // Remove filter
      controller.removeFilter('startsWithA');
      await Future.delayed(const Duration(milliseconds: 20));

      expect(controller.items.length, 4);
      expect(controller.activeFilters.isEmpty, true);
    });

    test('should handle sorting correctly', () async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: const Duration(milliseconds: 10),
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setItems(['Banana', 'Apple', 'Cherry']);

      // Sort alphabetically
      controller.setSortBy((a, b) => a.compareTo(b));
      await Future.delayed(const Duration(milliseconds: 20));

      expect(controller.items, ['Apple', 'Banana', 'Cherry']);
      expect(controller.currentComparator, isNotNull);

      // Clear sorting
      controller.setSortBy(null);
      await Future.delayed(const Duration(milliseconds: 20));

      expect(controller.currentComparator, isNull);
    });

    test('should handle async data loading', () async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: const Duration(milliseconds: 10),
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      // Mock async loader
      controller.setAsyncLoader((
        query, {
        int page = 0,
        int pageSize = 20,
      }) async {
        await Future.delayed(const Duration(milliseconds: 50));
        if (query.isEmpty) {
          return ['Item 1', 'Item 2', 'Item 3'];
        }
        return ['Searched Item'];
      });

      // Initial load
      controller.search('');

      // Wait for debounce and then check loading state
      await Future.delayed(const Duration(milliseconds: 20));
      expect(controller.isLoading, true);

      // Wait for async operation to complete
      await Future.delayed(const Duration(milliseconds: 60));

      expect(controller.isLoading, false);
      expect(controller.items.length, 3);
      expect(controller.error, isNull);
    });

    test('should handle async errors', () async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: const Duration(milliseconds: 10),
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      // Mock async loader that throws error
      controller.setAsyncLoader((
        query, {
        int page = 0,
        int pageSize = 20,
      }) async {
        await Future.delayed(const Duration(milliseconds: 50));
        throw Exception('Network error');
      });

      controller.search('');

      // Wait for debounce and initial loading state
      await Future.delayed(const Duration(milliseconds: 20));
      expect(controller.isLoading, true);

      // Wait for error to occur
      await Future.delayed(const Duration(milliseconds: 60));

      expect(controller.isLoading, false);
      expect(controller.error, isNotNull);
      expect(controller.error.toString(), contains('Network error'));
    });

    test('should handle race conditions in async operations', () async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: const Duration(milliseconds: 10),
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      int callCount = 0;
      controller.setAsyncLoader((
        query, {
        int page = 0,
        int pageSize = 20,
      }) async {
        final currentCall = ++callCount;
        // First call takes longer than second
        await Future.delayed(
          Duration(milliseconds: currentCall == 1 ? 100 : 20),
        );
        return ['Result $currentCall for: $query'];
      });

      // Trigger two searches quickly
      controller.search('first');
      await Future.delayed(const Duration(milliseconds: 15));
      controller.search('second');

      // Wait for both to complete
      await Future.delayed(const Duration(milliseconds: 120));

      // Should only show results from the second (latest) search
      expect(controller.items.length, 1);
      expect(controller.items.first, 'Result 2 for: second');
    });

    test('should handle pagination correctly', () async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        pageSize: 2,
        debounceDelay: const Duration(milliseconds: 10),
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setAsyncLoader((
        query, {
        int page = 0,
        int pageSize = 20,
      }) async {
        await Future.delayed(const Duration(milliseconds: 20));
        // Return 2 items for first page, 1 item for second page (< pageSize = no more pages)
        if (page == 0) return ['Item 1', 'Item 2'];
        if (page == 1) {
          return ['Item 3']; // Less than pageSize, so hasMorePages = false
        }
        return []; // No more items
      });

      // Initial load
      controller.search('');

      // Wait for debounce and async operation
      await Future.delayed(const Duration(milliseconds: 50));

      expect(controller.items.length, 2);
      expect(controller.hasMorePages, true);

      // Load more
      await controller.loadMore();

      // Wait a bit more to ensure async completes
      await Future.delayed(const Duration(milliseconds: 30));

      expect(controller.items.length, 3);
      expect(controller.hasMorePages, false);
    });

    test(
      'should pass through all items when searchableFields is null',
      () async {
        final controller = SmartSearchController<String>(
          searchableFields: null,
          debounceDelay: const Duration(milliseconds: 10),
        );
        addTearDown(() {
          if (!controller.isDisposed) controller.dispose();
        });

        controller.setItems(['Apple', 'Banana', 'Cherry']);

        // Search should not throw and all items should pass through unfiltered
        controller.search('Apple');
        await Future.delayed(const Duration(milliseconds: 20));

        expect(controller.items.length, 3);
        expect(controller.items, containsAll(['Apple', 'Banana', 'Cherry']));

        controller.dispose();
      },
    );

    // -----------------------------------------------------------------------
    // Bug investigation tests — cache corruption and sort cache invalidation
    // -----------------------------------------------------------------------

    test('loadMore should not corrupt cached first-page results', () async {
      final controller = SmartSearchController<String>(
        pageSize: 2,
        cacheResults: true,
        debounceDelay: const Duration(milliseconds: 10),
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setAsyncLoader((
        query, {
        int page = 0,
        int pageSize = 20,
      }) async {
        await Future.delayed(const Duration(milliseconds: 20));
        if (page == 0) return ['Item A', 'Item B'];
        if (page == 1) return ['Item C'];
        return [];
      });

      // Cycle 1: search → cache miss → loadMore
      controller.search('');
      await Future.delayed(const Duration(milliseconds: 50));
      expect(controller.items.length, 2);

      await controller.loadMore();
      await Future.delayed(const Duration(milliseconds: 30));
      expect(controller.items.length, 3);

      // Cycle 2: re-search → cache HIT (now _filteredItems IS the cache entry)
      controller.search('');
      await Future.delayed(const Duration(milliseconds: 50));
      expect(
        controller.items.length,
        2,
        reason: 'First cache read should return original 2 items',
      );

      // loadMore again — this mutates _filteredItems which IS the cache list
      await controller.loadMore();
      await Future.delayed(const Duration(milliseconds: 30));
      expect(controller.items.length, 3);

      // Cycle 3: re-search → cache HIT again — now the cache is corrupted
      // because loadMore in cycle 2 mutated the cache list directly
      controller.search('');
      await Future.delayed(const Duration(milliseconds: 50));
      expect(
        controller.items.length,
        2,
        reason:
            'Cache should still contain original page 0 results (2 items), '
            'not the corrupted list with loadMore results appended',
      );
    });

    test('setSortBy should invalidate cache in async mode', () async {
      int callCount = 0;
      final controller = SmartSearchController<String>(
        cacheResults: true,
        debounceDelay: const Duration(milliseconds: 10),
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setAsyncLoader((
        query, {
        int page = 0,
        int pageSize = 20,
      }) async {
        callCount++;
        await Future.delayed(const Duration(milliseconds: 20));
        return ['C', 'A', 'B'];
      });

      // First search — fetches from server, caches result
      controller.search('');
      await Future.delayed(const Duration(milliseconds: 50));
      expect(controller.items, ['C', 'A', 'B']);
      final callsAfterFirstSearch = callCount;

      // Change sort — should clear cache and re-fetch from server
      controller.setSortBy((a, b) => a.compareTo(b));
      await Future.delayed(const Duration(milliseconds: 50));

      // The async loader should have been called again (cache invalidated)
      expect(
        callCount,
        greaterThan(callsAfterFirstSearch),
        reason: 'setSortBy should invalidate cache and re-invoke async loader',
      );
    });

    test('setSortBy should apply comparator in offline mode', () async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: const Duration(milliseconds: 10),
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setItems(['Cherry', 'Apple', 'Banana']);

      // Sort ascending
      controller.setSortBy((a, b) => a.compareTo(b));
      await Future.delayed(const Duration(milliseconds: 20));
      expect(controller.items, ['Apple', 'Banana', 'Cherry']);

      // Sort descending
      controller.setSortBy((a, b) => b.compareTo(a));
      await Future.delayed(const Duration(milliseconds: 20));
      expect(controller.items, ['Cherry', 'Banana', 'Apple']);

      // Clear sort — items return to original order
      controller.setSortBy(null);
      await Future.delayed(const Duration(milliseconds: 20));
      expect(controller.items, ['Cherry', 'Apple', 'Banana']);
    });

    // -----------------------------------------------------------------------
    // Edge-case tests — disposal, concurrency, cache eviction, async contract
    // -----------------------------------------------------------------------

    test('loadMore after dispose should be a no-op', () async {
      final controller = SmartSearchController<String>(
        pageSize: 2,
        debounceDelay: const Duration(milliseconds: 10),
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      int callCount = 0;
      controller.setAsyncLoader((
        query, {
        int page = 0,
        int pageSize = 20,
      }) async {
        callCount++;
        return ['Item ${page}A', 'Item ${page}B'];
      });

      controller.search('');
      await Future.delayed(const Duration(milliseconds: 50));
      expect(callCount, 1);

      controller.dispose();

      // Should be a safe no-op — no crash, no additional call
      await controller.loadMore();
      expect(callCount, 1);
    });

    test('concurrent loadMore calls should not duplicate results', () async {
      final controller = SmartSearchController<String>(
        pageSize: 2,
        debounceDelay: const Duration(milliseconds: 10),
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setAsyncLoader((
        query, {
        int page = 0,
        int pageSize = 20,
      }) async {
        await Future.delayed(const Duration(milliseconds: 30));
        if (page == 0) return ['A', 'B'];
        if (page == 1) return ['C', 'D'];
        return [];
      });

      controller.search('');
      await Future.delayed(const Duration(milliseconds: 50));
      expect(controller.items.length, 2);

      // Fire two loadMore calls concurrently — second should be guarded
      final f1 = controller.loadMore();
      final f2 = controller.loadMore();
      await Future.wait([f1, f2]);
      await Future.delayed(const Duration(milliseconds: 40));

      expect(controller.items.length, 4);
      expect(controller.items, ['A', 'B', 'C', 'D']);
    });

    test('cache should respect maxCacheSize eviction', () async {
      final controller = SmartSearchController<String>(
        cacheResults: true,
        maxCacheSize: 2,
        debounceDelay: const Duration(milliseconds: 10),
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      int callCount = 0;
      controller.setAsyncLoader((
        query, {
        int page = 0,
        int pageSize = 20,
      }) async {
        callCount++;
        return ['Result for: $query'];
      });

      // Fill cache with 2 entries: [a, b]
      controller.search('a');
      await Future.delayed(const Duration(milliseconds: 50));
      controller.search('b');
      await Future.delayed(const Duration(milliseconds: 50));
      expect(callCount, 2);

      // 'a' should be cached — no new call
      controller.search('a');
      await Future.delayed(const Duration(milliseconds: 50));
      expect(callCount, 2);

      // Add 'c' — FIFO evicts 'a' (oldest). Cache: [b, c]
      controller.search('c');
      await Future.delayed(const Duration(milliseconds: 50));
      expect(callCount, 3);

      // 'a' was evicted — needs new call. FIFO evicts 'b'. Cache: [c, a]
      controller.search('a');
      await Future.delayed(const Duration(milliseconds: 50));
      expect(callCount, 4, reason: 'Evicted entry should trigger a new call');

      // 'c' should still be cached — no new call
      controller.search('c');
      await Future.delayed(const Duration(milliseconds: 50));
      expect(callCount, 4, reason: 'Non-evicted entry should still be cached');
    });

    test('setSortBy in async mode should not client-sort results', () async {
      final controller = SmartSearchController<String>(
        cacheResults: true,
        debounceDelay: const Duration(milliseconds: 10),
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setAsyncLoader((
        query, {
        int page = 0,
        int pageSize = 20,
      }) async {
        return ['Z', 'A', 'M'];
      });

      // Set ascending sort before searching
      controller.setSortBy((a, b) => a.compareTo(b));
      controller.search('');
      await Future.delayed(const Duration(milliseconds: 50));

      // In async mode the comparator is NOT applied client-side —
      // the async loader is responsible for its own sort order.
      expect(controller.items, ['Z', 'A', 'M']);
    });

    test('search after loadMore should reset to page 0 results', () async {
      final controller = SmartSearchController<String>(
        pageSize: 2,
        cacheResults: false,
        debounceDelay: const Duration(milliseconds: 10),
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setAsyncLoader((
        query, {
        int page = 0,
        int pageSize = 20,
      }) async {
        await Future.delayed(const Duration(milliseconds: 20));
        if (query == 'a') {
          if (page == 0) return ['A1', 'A2'];
          if (page == 1) return ['A3'];
          return [];
        }
        if (page == 0) return ['B1', 'B2'];
        return [];
      });

      controller.search('a');
      await Future.delayed(const Duration(milliseconds: 50));
      expect(controller.items, ['A1', 'A2']);

      await controller.loadMore();
      await Future.delayed(const Duration(milliseconds: 30));
      expect(controller.items, ['A1', 'A2', 'A3']);

      // New search should reset page and results
      controller.search('b');
      await Future.delayed(const Duration(milliseconds: 50));
      expect(controller.items, ['B1', 'B2']);
      expect(controller.hasMorePages, true);
    });

    // -----------------------------------------------------------------------
    // Existing tests
    // -----------------------------------------------------------------------

    test('should refresh data correctly', () async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        cacheResults: true,
        debounceDelay: const Duration(milliseconds: 10),
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      bool firstCall = true;
      controller.setAsyncLoader((
        query, {
        int page = 0,
        int pageSize = 20,
      }) async {
        await Future.delayed(const Duration(milliseconds: 20));
        if (firstCall) {
          firstCall = false;
          return ['Old Data'];
        }
        return ['New Data'];
      });

      // Initial load
      controller.search('');
      await Future.delayed(const Duration(milliseconds: 50));

      expect(controller.items.isNotEmpty, true);
      expect(controller.items.first, 'Old Data');

      // Refresh should clear cache and reload
      await controller.refresh();

      expect(controller.items.isNotEmpty, true);
      expect(controller.items.first, 'New Data');
    });
  });
}
