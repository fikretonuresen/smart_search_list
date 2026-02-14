import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_search_list/smart_search_list.dart';

void main() {
  // =========================================================================
  // clearSearch
  // =========================================================================

  group('clearSearch', () {
    test('resets query and shows all items', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setItems(['Apple', 'Banana', 'Cherry']);
      controller.searchImmediate('App');
      expect(controller.items, ['Apple']);
      expect(controller.searchQuery, 'App');

      controller.clearSearch();
      expect(controller.searchQuery, '');
      expect(controller.items.length, 3);
    });

    test('is no-op after dispose', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setItems(['Apple']);
      controller.searchImmediate('App');
      controller.dispose();

      // Should not throw
      controller.clearSearch();
      expect(controller.isDisposed, true);
    });

    test('clears search when nothing was searched', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setItems(['Apple', 'Banana']);
      controller.clearSearch();

      expect(controller.searchQuery, '');
      expect(controller.items.length, 2);
    });
  });

  // =========================================================================
  // searchImmediate
  // =========================================================================

  group('searchImmediate', () {
    test('bypasses debounce', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: const Duration(seconds: 10),
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setItems(['Apple', 'Banana']);
      controller.searchImmediate('App');

      // Should have results immediately, not after 10 seconds
      expect(controller.items, ['Apple']);
    });

    test('respects minSearchLength', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
        minSearchLength: 3,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setItems(['Apple', 'Banana']);
      controller.searchImmediate('Ap');

      // Should not filter — too short
      expect(controller.items.length, 2);

      controller.searchImmediate('App');
      expect(controller.items, ['Apple']);
    });

    test('empty string shows all items', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setItems(['Apple', 'Banana']);
      controller.searchImmediate('App');
      expect(controller.items, ['Apple']);

      controller.searchImmediate('');
      expect(controller.items.length, 2);
    });

    test('cancels pending debounced search', () async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: const Duration(milliseconds: 200),
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setItems(['Apple', 'Banana', 'Cherry']);

      // Start a debounced search
      controller.search('Ban');

      // Immediately override with searchImmediate
      controller.searchImmediate('Che');
      expect(controller.items, ['Cherry']);

      // Wait for debounce — should NOT revert to 'Ban'
      await Future.delayed(const Duration(milliseconds: 300));
      expect(controller.items, ['Cherry']);
    });

    test('is no-op after dispose', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.dispose();
      controller.searchImmediate('test');
      expect(controller.isDisposed, true);
    });
  });

  // =========================================================================
  // retry
  // =========================================================================

  group('retry', () {
    test('clears error and re-searches', () async {
      var shouldFail = true;
      final controller = SmartSearchController<String>(
        debounceDelay: Duration.zero,
        cacheResults: false,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setAsyncLoader((
        query, {
        int page = 0,
        int pageSize = 20,
      }) async {
        if (shouldFail) throw Exception('fail');
        return ['success'];
      });

      controller.searchImmediate('test');
      await Future.microtask(() {});
      await Future.microtask(() {});

      expect(controller.error, isNotNull);

      shouldFail = false;
      await controller.retry();
      await Future.microtask(() {});

      expect(controller.error, isNull);
      expect(controller.items, ['success']);
    });

    test('works after successful search too', () async {
      var callCount = 0;
      final controller = SmartSearchController<String>(
        debounceDelay: Duration.zero,
        cacheResults: false,
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
        return ['result-$callCount'];
      });

      controller.searchImmediate('test');
      await Future.microtask(() {});
      await Future.microtask(() {});

      expect(controller.items, ['result-1']);

      await controller.retry();
      await Future.microtask(() {});

      expect(controller.items, ['result-2']);
    });

    test('is no-op after dispose', () async {
      final controller = SmartSearchController<String>(
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.dispose();
      await controller.retry();
      expect(controller.isDisposed, true);
    });
  });

  // =========================================================================
  // refresh
  // =========================================================================

  group('refresh', () {
    test('clears cache and reloads page 0', () async {
      var callCount = 0;
      final controller = SmartSearchController<String>(
        debounceDelay: Duration.zero,
        cacheResults: true,
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
        return ['result-$callCount'];
      });

      controller.searchImmediate('test');
      await Future.microtask(() {});
      await Future.microtask(() {});
      expect(controller.items, ['result-1']);

      await controller.refresh();
      await Future.microtask(() {});

      // Should have called loader again (cache cleared)
      expect(callCount, 2);
      expect(controller.items, ['result-2']);
    });

    test('resets hasMorePages', () async {
      final controller = SmartSearchController<String>(
        debounceDelay: Duration.zero,
        pageSize: 5,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setAsyncLoader((
        query, {
        int page = 0,
        int pageSize = 20,
      }) async {
        // Return fewer items than page size → signals no more pages
        return ['only-one'];
      });

      controller.searchImmediate('test');
      await Future.microtask(() {});
      await Future.microtask(() {});

      expect(controller.hasMorePages, false);

      await controller.refresh();
      await Future.microtask(() {});

      // After refresh, hasMorePages should be re-evaluated based on new results
      // Since only-one < pageSize(5), it should be false
      expect(controller.hasMorePages, false);
    });

    test('is no-op after dispose', () async {
      final controller = SmartSearchController<String>(
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.dispose();
      await controller.refresh();
      expect(controller.isDisposed, true);
    });
  });

  // =========================================================================
  // selectAll / deselectAll
  // =========================================================================

  group('selectAll / deselectAll', () {
    test('selectAll selects only filtered (visible) items', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setItems(['Apple', 'Banana', 'Cherry']);
      controller.searchImmediate('a');

      // Only 'Apple' and 'Banana' match
      controller.selectAll();

      expect(controller.selectedItems, {'Apple', 'Banana'});
      expect(controller.isSelected('Cherry'), false);
    });

    test('deselectAll when empty is no-op (does not notify)', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setItems(['Apple']);

      var notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.deselectAll();
      expect(notifyCount, 0, reason: 'Empty deselectAll should not notify');
    });

    test('selectAll after dispose is no-op', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setItems(['Apple']);
      controller.dispose();

      controller.selectAll();
      expect(controller.selectedItems, isEmpty);
    });

    test('deselectAll clears all selections', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setItems(['Apple', 'Banana', 'Cherry']);
      controller.selectAll();
      expect(controller.selectedItems.length, 3);

      controller.deselectAll();
      expect(controller.selectedItems, isEmpty);
    });
  });

  // =========================================================================
  // selectWhere / deselectWhere
  // =========================================================================

  group('selectWhere / deselectWhere', () {
    test('selectWhere is additive to existing selection', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setItems(['Apple', 'Banana', 'Cherry', 'Avocado']);
      controller.select('Cherry');
      controller.selectWhere((item) => item.startsWith('A'));

      expect(controller.selectedItems, {'Cherry', 'Apple', 'Avocado'});
    });

    test('deselectWhere removes only matching items', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setItems(['Apple', 'Banana', 'Cherry']);
      controller.selectAll();
      controller.deselectWhere((item) => item.startsWith('B'));

      expect(controller.selectedItems, {'Apple', 'Cherry'});
    });
  });

  // =========================================================================
  // setItems
  // =========================================================================

  group('setItems', () {
    test('replaces items and re-applies filters and sort', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setItems(['Apple', 'Banana']);
      controller.setFilter('long', (item) => item.length > 5);
      controller.searchImmediate(''); // re-trigger filter

      expect(controller.items, ['Banana']);

      // Replace items — filter should still apply
      controller.setItems(['Cherry', 'Date', 'Elderberry']);
      expect(controller.items, ['Cherry', 'Elderberry']);
    });

    test('empty list clears everything', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setItems(['Apple', 'Banana']);
      expect(controller.items.length, 2);

      controller.setItems([]);
      expect(controller.items, isEmpty);
      expect(controller.allItems, isEmpty);
    });

    test('is no-op after dispose', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.dispose();
      controller.setItems(['Apple']);
      expect(controller.items, isEmpty);
    });

    test('re-applies active sort when items change', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setItems(['Banana', 'Apple', 'Cherry']);
      controller.setSortBy((a, b) => a.compareTo(b));

      expect(controller.items, ['Apple', 'Banana', 'Cherry']);

      // New items should also be sorted
      controller.setItems(['Zebra', 'Mango', 'Date']);
      expect(controller.items, ['Date', 'Mango', 'Zebra']);
    });
  });

  // =========================================================================
  // error → retry → success flow
  // =========================================================================

  group('error → retry → success', () {
    test('three-step async recovery', () async {
      var callCount = 0;
      final controller = SmartSearchController<String>(
        debounceDelay: Duration.zero,
        cacheResults: false,
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
        if (callCount == 1) throw Exception('network error');
        return ['recovered-data'];
      });

      // Step 1: Error
      controller.searchImmediate('test');
      await Future.microtask(() {});
      await Future.microtask(() {});

      expect(controller.error, isA<Exception>());
      expect(controller.items, isEmpty);
      expect(controller.isLoading, false);

      // Step 2: Retry
      await controller.retry();
      await Future.microtask(() {});

      // Step 3: Success
      expect(controller.error, isNull);
      expect(controller.items, ['recovered-data']);
      expect(controller.isLoading, false);
    });
  });

  // =========================================================================
  // select / deselect / toggleSelection
  // =========================================================================

  group('select / deselect / toggleSelection', () {
    test('select adds, deselect removes', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setItems(['Apple', 'Banana']);

      controller.select('Apple');
      expect(controller.isSelected('Apple'), true);
      expect(controller.isSelected('Banana'), false);

      controller.deselect('Apple');
      expect(controller.isSelected('Apple'), false);
    });

    test('select same item twice does not notify twice', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setItems(['Apple']);

      var notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.select('Apple');
      expect(notifyCount, 1);

      controller.select('Apple');
      expect(
        notifyCount,
        1,
        reason: 'Re-selecting same item should not notify',
      );
    });

    test('deselect unselected item does not notify', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setItems(['Apple']);

      var notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.deselect('Apple');
      expect(notifyCount, 0);
    });

    test('toggleSelection flips state', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setItems(['Apple']);

      controller.toggleSelection('Apple');
      expect(controller.isSelected('Apple'), true);

      controller.toggleSelection('Apple');
      expect(controller.isSelected('Apple'), false);
    });
  });

  // =========================================================================
  // filter interactions
  // =========================================================================

  group('filter operations', () {
    test('setFilter replaces filter with same key', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setItems(['Apple', 'Banana', 'Cherry']);

      controller.setFilter('starts', (item) => item.startsWith('A'));
      expect(controller.items, ['Apple']);

      // Replace with different predicate
      controller.setFilter('starts', (item) => item.startsWith('B'));
      expect(controller.items, ['Banana']);
    });

    test('removeFilter restores items', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setItems(['Apple', 'Banana', 'Cherry']);
      controller.setFilter('short', (item) => item.length <= 5);
      expect(controller.items, ['Apple']);

      controller.removeFilter('short');
      expect(controller.items.length, 3);
    });

    test('clearFilters removes all filters', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setItems(['Apple', 'Banana', 'Cherry']);
      controller.setFilter('a', (item) => item.startsWith('A'));
      controller.setFilter('long', (item) => item.length > 4);
      expect(controller.items, ['Apple']);

      controller.clearFilters();
      expect(controller.items.length, 3);
    });

    test('removeFilter for non-existent key is safe', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setItems(['Apple']);
      controller.removeFilter('nonexistent');
      expect(controller.items, ['Apple']);
    });
  });

  // =========================================================================
  // setSortBy
  // =========================================================================

  group('setSortBy', () {
    test('sorts items and clears cache', () async {
      var loaderCalls = 0;
      final controller = SmartSearchController<String>(
        debounceDelay: Duration.zero,
        cacheResults: true,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setAsyncLoader((
        query, {
        int page = 0,
        int pageSize = 20,
      }) async {
        loaderCalls++;
        return ['B', 'A', 'C'];
      });

      controller.searchImmediate('');
      await Future.microtask(() {});
      await Future.microtask(() {});
      expect(loaderCalls, 1);

      // Set sort — should clear cache and re-search
      controller.setSortBy((a, b) => a.compareTo(b));
      await Future.microtask(() {});
      await Future.microtask(() {});

      expect(loaderCalls, 2, reason: 'Cache should be cleared on sort change');
    });

    test('passing null removes sort', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setItems(['Banana', 'Apple', 'Cherry']);
      controller.setSortBy((a, b) => a.compareTo(b));
      expect(controller.items, ['Apple', 'Banana', 'Cherry']);

      controller.setSortBy(null);
      // Should revert to original insertion order
      expect(controller.items, ['Banana', 'Apple', 'Cherry']);
    });
  });

  // =========================================================================
  // loadMore
  // =========================================================================

  group('loadMore', () {
    test('appends next page of results', () async {
      final controller = SmartSearchController<String>(
        debounceDelay: Duration.zero,
        pageSize: 2,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setAsyncLoader((
        query, {
        int page = 0,
        int pageSize = 20,
      }) async {
        return ['p${page}a', 'p${page}b'];
      });

      controller.searchImmediate('');
      await Future.microtask(() {});
      await Future.microtask(() {});

      expect(controller.items, ['p0a', 'p0b']);

      await controller.loadMore();
      await Future.microtask(() {});

      expect(controller.items, ['p0a', 'p0b', 'p1a', 'p1b']);
    });

    test('no-op when no async loader', () async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setItems(['Apple']);
      await controller.loadMore();
      expect(controller.items, ['Apple']);
    });

    test('no-op when already loading more', () async {
      final completer = Completer<List<String>>();
      final controller = SmartSearchController<String>(
        debounceDelay: Duration.zero,
        pageSize: 2,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      var callCount = 0;
      controller.setAsyncLoader((
        query, {
        int page = 0,
        int pageSize = 20,
      }) async {
        callCount++;
        if (page == 0) return ['a', 'b'];
        return completer.future;
      });

      controller.searchImmediate('');
      await Future.microtask(() {});
      await Future.microtask(() {});

      // Start loadMore
      controller.loadMore();
      await Future.microtask(() {});

      // Try loadMore again while first is in-flight
      final secondCall = callCount;
      controller.loadMore();
      await Future.microtask(() {});

      expect(callCount, secondCall, reason: 'Should not call loader again');

      completer.complete(['c', 'd']);
      await Future.microtask(() {});
    });

    test('sets hasMorePages=false when results < pageSize', () async {
      final controller = SmartSearchController<String>(
        debounceDelay: Duration.zero,
        pageSize: 5,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setAsyncLoader((
        query, {
        int page = 0,
        int pageSize = 20,
      }) async {
        if (page == 0) return ['a', 'b', 'c', 'd', 'e'];
        return ['f']; // Only 1 item — less than pageSize
      });

      controller.searchImmediate('');
      await Future.microtask(() {});
      await Future.microtask(() {});

      expect(controller.hasMorePages, true);

      await controller.loadMore();
      await Future.microtask(() {});

      expect(controller.hasMorePages, false);
      expect(controller.items.length, 6);
    });

    test('sets hasMorePages=false when page returns empty', () async {
      final controller = SmartSearchController<String>(
        debounceDelay: Duration.zero,
        pageSize: 2,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setAsyncLoader((
        query, {
        int page = 0,
        int pageSize = 20,
      }) async {
        if (page == 0) return ['a', 'b'];
        return []; // Empty page
      });

      controller.searchImmediate('');
      await Future.microtask(() {});
      await Future.microtask(() {});

      await controller.loadMore();
      await Future.microtask(() {});

      expect(controller.hasMorePages, false);
      expect(controller.items, ['a', 'b']);
    });
  });

  // =========================================================================
  // concurrent operations
  // =========================================================================

  group('concurrent operations', () {
    test('search + setFilter: filter applies to new search results', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setItems(['Apple', 'Apricot', 'Banana', 'Blueberry']);

      controller.searchImmediate('a');
      expect(controller.items, ['Apple', 'Apricot', 'Banana']);

      controller.setFilter('short', (item) => item.length <= 6);
      expect(controller.items, ['Apple', 'Banana']);
    });

    test('search + setSortBy: results are sorted', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setItems(['Cherry', 'Apple', 'Coconut', 'Banana']);

      controller.setSortBy((a, b) => a.compareTo(b));
      controller.searchImmediate('');

      expect(controller.items, ['Apple', 'Banana', 'Cherry', 'Coconut']);
    });

    test('search during loadMore: loadMore is superseded', () async {
      final loadMoreCompleter = Completer<List<String>>();
      final controller = SmartSearchController<String>(
        debounceDelay: Duration.zero,
        pageSize: 2,
        cacheResults: false,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setAsyncLoader((
        query, {
        int page = 0,
        int pageSize = 20,
      }) async {
        if (page > 0) return loadMoreCompleter.future;
        return ['a', 'b'];
      });

      controller.searchImmediate('test');
      await Future.microtask(() {});
      await Future.microtask(() {});

      // Start loadMore
      controller.loadMore();
      await Future.microtask(() {});

      // New search supersedes loadMore
      controller.searchImmediate('new');
      await Future.microtask(() {});
      await Future.microtask(() {});

      // Complete the loadMore — should be ignored
      loadMoreCompleter.complete(['c', 'd']);
      await Future.microtask(() {});

      // Items should be from the new search, not loadMore
      expect(controller.items, ['a', 'b']);
    });
  });

  // =========================================================================
  // unmodifiable getters
  // =========================================================================

  group('unmodifiable getters', () {
    test('items getter returns unmodifiable list', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setItems(['Apple', 'Banana']);

      expect(() => controller.items.add('Hack'), throwsUnsupportedError);
    });

    test('allItems getter returns unmodifiable list', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setItems(['Apple']);

      expect(() => controller.allItems.add('Hack'), throwsUnsupportedError);
    });

    test('selectedItems getter returns unmodifiable set', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setItems(['Apple']);
      controller.select('Apple');

      expect(
        () => controller.selectedItems.add('Hack'),
        throwsUnsupportedError,
      );
    });

    test('activeFilters getter returns unmodifiable map', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setItems(['Apple']);
      controller.setFilter('test', (_) => true);

      expect(
        () => controller.activeFilters['hack'] = (_) => false,
        throwsUnsupportedError,
      );
    });
  });

  // =========================================================================
  // setAsyncLoader
  // =========================================================================

  group('setAsyncLoader', () {
    test('does not trigger search — requires explicit call', () async {
      var called = false;
      final controller = SmartSearchController<String>(
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setAsyncLoader((
        query, {
        int page = 0,
        int pageSize = 20,
      }) async {
        called = true;
        return [];
      });

      await Future.microtask(() {});
      expect(called, false, reason: 'setAsyncLoader should not auto-search');
    });

    test('is no-op after dispose', () {
      final controller = SmartSearchController<String>(
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.dispose();
      controller.setAsyncLoader(
        (query, {int page = 0, int pageSize = 20}) async => [],
      );
      expect(controller.isDisposed, true);
    });
  });
}
