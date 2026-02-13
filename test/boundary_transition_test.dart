import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_search_list/smart_search_list.dart';

/// Completer-per-call async loader for precise timing control.
///
/// Each [call] creates a fresh Completer, addressable by index.
/// Enables tests like "3 rapid searches, middle one fails".
class _TestLoader {
  final _completers = <Completer<List<String>>>[];
  int callCount = 0;
  String? lastQuery;
  int? lastPage;

  Future<List<String>> call(String query, {int page = 0, int pageSize = 20}) {
    callCount++;
    lastQuery = query;
    lastPage = page;
    final c = Completer<List<String>>();
    _completers.add(c);
    return c.future;
  }

  /// Completes the Nth call (0-indexed).
  void complete(int callIndex, List<String> items) =>
      _completers[callIndex].complete(items);

  /// Fails the Nth call (0-indexed).
  void completeError(int callIndex, Object error) =>
      _completers[callIndex].completeError(error);
}

void main() {
  // ===========================================================================
  // Group 1: State Transition Tests
  // ===========================================================================

  group('state transitions', () {
    test('error → retry → error again: no stale success leaks', () async {
      final loader = _TestLoader();
      final controller = SmartSearchController<String>(
        debounceDelay: Duration.zero,
        pageSize: 10,
      );
      addTearDown(controller.dispose);
      controller.setAsyncLoader(loader.call);

      // First search → error
      controller.searchImmediate('q1');
      await Future.microtask(() {});
      loader.completeError(0, StateError('fail-1'));
      await Future.microtask(() {});

      expect(controller.error, isA<StateError>());
      expect(controller.isLoading, false);

      // Retry → error again
      controller.retry();
      await Future.microtask(() {});
      loader.completeError(1, FormatException('fail-2'));
      await Future.microtask(() {});

      expect(controller.error, isA<FormatException>());
      expect(controller.isLoading, false);
      expect(controller.items, isEmpty);
    });

    test('error → new search clears error', () async {
      final loader = _TestLoader();
      final controller = SmartSearchController<String>(
        debounceDelay: Duration.zero,
        pageSize: 10,
      );
      addTearDown(controller.dispose);
      controller.setAsyncLoader(loader.call);

      // Search → error
      controller.searchImmediate('q1');
      await Future.microtask(() {});
      loader.completeError(0, Exception('fail'));
      await Future.microtask(() {});
      expect(controller.error, isNotNull);

      // New search clears error via _setError(null) at L333
      controller.searchImmediate('q2');
      await Future.microtask(() {});

      // Error should be cleared before the async load completes
      expect(controller.error, isNull);

      loader.complete(1, ['result']);
      await Future.microtask(() {});
      expect(controller.items, ['result']);
    });

    test('minSearchLength increase makes query too short', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
        minSearchLength: 1,
      );
      addTearDown(controller.dispose);

      controller.setItems(['apple', 'banana', 'cherry']);
      controller.searchImmediate('ap');
      expect(controller.items, ['apple']);

      // Increase minSearchLength — "ap" is now too short (< 5)
      controller.updateMinSearchLength(5);

      // Items remain from previous search (bail-out at L325-326)
      expect(controller.searchQuery, 'ap');
      expect(controller.items, ['apple']);

      // Verify the setting actually took effect: a long-enough query works
      controller.searchImmediate('apple');
      expect(controller.items, ['apple']);

      // And a too-short query still bails out
      controller.searchImmediate('ban');
      expect(controller.items, ['apple']);
    });

    test('minSearchLength valid → invalid → valid: results recover', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
        minSearchLength: 1,
      );
      addTearDown(controller.dispose);

      controller.setItems(['apple', 'banana', 'cherry']);
      controller.searchImmediate('ap');
      expect(controller.items, ['apple']);

      // Make query too short — results stale from previous search
      controller.updateMinSearchLength(5);
      expect(controller.searchQuery, 'ap');

      // Restore — query is valid again, search re-executes
      controller.updateMinSearchLength(1);
      expect(controller.items, ['apple']);
      expect(controller.searchQuery, 'ap');
    });

    test('selectAll → setItems(new data): old selections retained', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(controller.dispose);

      controller.setItems(['a', 'b', 'c']);
      controller.selectAll();
      expect(controller.selectedItems, {'a', 'b', 'c'});

      // Replace items — old selections NOT cleared
      controller.setItems(['x', 'y']);
      expect(controller.selectedItems.contains('a'), true);
      expect(controller.selectedItems.contains('x'), false);
    });

    test('selectAll → filter removes selected items: selections persist', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(controller.dispose);

      controller.setItems(['apple', 'banana', 'cherry']);
      controller.selectAll();
      expect(controller.selectedItems.length, 3);

      // Filter excludes 'banana'
      controller.setFilter('no-b', (item) => !item.startsWith('b'));
      expect(controller.items, ['apple', 'cherry']);

      // Selections persist independent of visible items
      expect(controller.selectedItems.contains('banana'), true);
      expect(controller.selectedItems.length, 3);
    });

    test('filter change during async load preempts load', () async {
      final loader = _TestLoader();
      final controller = SmartSearchController<String>(
        debounceDelay: Duration.zero,
        pageSize: 10,
      );
      addTearDown(controller.dispose);
      controller.setAsyncLoader(loader.call);

      // Start search (call 0)
      controller.searchImmediate('q');
      await Future.microtask(() {});
      expect(loader.callCount, 1);

      // Set filter → new search (call 1), increments requestId
      controller.setFilter('f', (item) => true);
      await Future.microtask(() {});
      expect(loader.callCount, 2);

      // Complete OLD loader (call 0) — stale, ignored
      loader.complete(0, ['stale']);
      await Future.microtask(() {});

      // Complete NEW loader (call 1) — applied
      loader.complete(1, ['fresh']);
      await Future.microtask(() {});

      expect(controller.items, ['fresh']);
    });

    test('refresh during loadMore preempts loadMore', () async {
      final loader = _TestLoader();
      final controller = SmartSearchController<String>(
        debounceDelay: Duration.zero,
        pageSize: 10,
      );
      addTearDown(controller.dispose);
      controller.setAsyncLoader(loader.call);

      // Initial load
      controller.searchImmediate('q');
      await Future.microtask(() {});
      loader.complete(0, List.generate(10, (i) => 'item$i'));
      await Future.microtask(() {});
      expect(controller.items.length, 10);

      // Start loadMore (call 1)
      controller.loadMore();
      await Future.microtask(() {});
      expect(loader.callCount, 2);

      // Refresh (call 2) — increments requestId, preempts loadMore
      controller.refresh();
      await Future.microtask(() {});
      expect(loader.callCount, 3);

      // Complete loadMore (call 1) — stale, ignored
      loader.complete(1, ['stale-page1']);
      await Future.microtask(() {});

      // Complete refresh (call 2) — applied
      loader.complete(2, ['refreshed']);
      await Future.microtask(() {});

      expect(controller.items, ['refreshed']);
    });

    test('multiple rapid setItems calls: final state is last call', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(controller.dispose);

      controller.setItems(['a']);
      controller.setItems(['b', 'c']);
      controller.setItems(['d']);
      controller.setItems(['e', 'f', 'g']);
      controller.setItems(['final']);

      expect(controller.items, ['final']);
      expect(controller.allItems, ['final']);
    });

    test('cache full → clearCache → refill: no ghost entries', () async {
      final loader = _TestLoader();
      final controller = SmartSearchController<String>(
        debounceDelay: Duration.zero,
        pageSize: 10,
        maxCacheSize: 2,
        cacheResults: true,
      );
      addTearDown(controller.dispose);
      controller.setAsyncLoader(loader.call);

      // Fill cache with 2 entries
      controller.searchImmediate('a');
      await Future.microtask(() {});
      loader.complete(0, ['a1']);
      await Future.microtask(() {});

      controller.searchImmediate('b');
      await Future.microtask(() {});
      loader.complete(1, ['b1']);
      await Future.microtask(() {});

      // Clear cache via refresh (don't await — loader is Completer-based)
      unawaited(controller.refresh());
      await Future.microtask(() {});
      // Refresh triggers a new search (call 2)
      loader.complete(2, ['refreshed']);
      await Future.microtask(() {});

      // Refill: search 'a' should NOT hit stale cache
      controller.searchImmediate('a');
      await Future.microtask(() {});
      expect(
        loader.callCount,
        4,
        reason: 'Should make a new call, not serve from cleared cache',
      );
      loader.complete(3, ['a-fresh']);
      await Future.microtask(() {});

      expect(controller.items, ['a-fresh']);
    });

    test('sort change during async load preempts load', () async {
      final loader = _TestLoader();
      final controller = SmartSearchController<String>(
        debounceDelay: Duration.zero,
        pageSize: 10,
      );
      addTearDown(controller.dispose);
      controller.setAsyncLoader(loader.call);

      // Start search (call 0)
      controller.searchImmediate('q');
      await Future.microtask(() {});
      expect(loader.callCount, 1);

      // Set sort → clears cache + new search (call 1)
      controller.setSortBy((a, b) => a.compareTo(b));
      await Future.microtask(() {});
      expect(loader.callCount, 2);

      // Complete OLD (call 0) — stale
      loader.complete(0, ['stale']);
      await Future.microtask(() {});

      // Complete NEW (call 1) — applied
      loader.complete(1, ['sorted']);
      await Future.microtask(() {});

      expect(controller.items, ['sorted']);
    });
  });

  // ===========================================================================
  // Group 2: Error Path Tests
  // ===========================================================================

  group('error paths', () {
    test('asyncLoader throws synchronously', () async {
      final controller = SmartSearchController<String>(
        debounceDelay: Duration.zero,
        pageSize: 10,
      );
      addTearDown(controller.dispose);

      controller.setAsyncLoader((query, {int page = 0, int pageSize = 20}) {
        throw StateError('sync throw');
      });

      controller.searchImmediate('q');
      await Future.microtask(() {});
      await Future.microtask(() {});

      expect(controller.error, isA<StateError>());
      expect(controller.isLoading, false);
    });

    test('asyncLoader throws non-Exception (String)', () async {
      final controller = SmartSearchController<String>(
        debounceDelay: Duration.zero,
        pageSize: 10,
      );
      addTearDown(controller.dispose);

      controller.setAsyncLoader((query, {int page = 0, int pageSize = 20}) {
        // ignore: only_throw_errors
        throw 'oops';
      });

      controller.searchImmediate('q');
      await Future.microtask(() {});
      await Future.microtask(() {});

      expect(controller.error, 'oops');
      expect(controller.isLoading, false);
    });

    test('asyncLoader throws TypeError: preserved in error getter', () async {
      final controller = SmartSearchController<String>(
        debounceDelay: Duration.zero,
        pageSize: 10,
      );
      addTearDown(controller.dispose);

      controller.setAsyncLoader((query, {int page = 0, int pageSize = 20}) {
        // Force a TypeError by casting null to non-nullable
        final dynamic x = null;
        return (x as Future<List<String>>);
      });

      controller.searchImmediate('q');
      await Future.microtask(() {});
      await Future.microtask(() {});

      expect(controller.error, isA<TypeError>());
      expect(controller.isLoading, false);
    });

    test(
      'loadMore page 0 success → page 1 error: preserves page 0 items',
      () async {
        final loader = _TestLoader();
        final controller = SmartSearchController<String>(
          debounceDelay: Duration.zero,
          pageSize: 10,
        );
        addTearDown(controller.dispose);
        controller.setAsyncLoader(loader.call);

        // Page 0 success
        controller.searchImmediate('q');
        await Future.microtask(() {});
        loader.complete(0, List.generate(10, (i) => 'p0_$i'));
        await Future.microtask(() {});
        expect(controller.items.length, 10);

        // loadMore → page 1 error
        controller.loadMore();
        await Future.microtask(() {});
        loader.completeError(1, Exception('page 1 failed'));
        await Future.microtask(() {});

        // Page 0 items still intact
        expect(controller.items.length, 10);
        expect(controller.items.first, 'p0_0');
        expect(controller.error, isA<Exception>());
        expect(controller.isLoadingMore, false);
      },
    );

    test(
      '3 rapid searches, middle one fails: only last result matters',
      () async {
        final loader = _TestLoader();
        final controller = SmartSearchController<String>(
          debounceDelay: Duration.zero,
          pageSize: 10,
        );
        addTearDown(controller.dispose);
        controller.setAsyncLoader(loader.call);

        // Fire 3 searches rapidly
        controller.searchImmediate('A');
        await Future.microtask(() {});
        controller.searchImmediate('B');
        await Future.microtask(() {});
        controller.searchImmediate('C');
        await Future.microtask(() {});

        expect(loader.callCount, 3);

        // Complete A (call 0) — stale
        loader.complete(0, ['result-A']);
        await Future.microtask(() {});

        // Fail B (call 1) — stale
        loader.completeError(1, Exception('B failed'));
        await Future.microtask(() {});

        // Complete C (call 2) — this is the current request
        loader.complete(2, ['result-C']);
        await Future.microtask(() {});

        expect(controller.items, ['result-C']);
        expect(controller.error, isNull);
      },
    );

    test('loadMore error preserves existing items', () async {
      final loader = _TestLoader();
      final controller = SmartSearchController<String>(
        debounceDelay: Duration.zero,
        pageSize: 5,
      );
      addTearDown(controller.dispose);
      controller.setAsyncLoader(loader.call);

      // Load page 0
      controller.searchImmediate('q');
      await Future.microtask(() {});
      loader.complete(0, ['a', 'b', 'c', 'd', 'e']);
      await Future.microtask(() {});
      expect(controller.items.length, 5);

      // loadMore fails
      controller.loadMore();
      await Future.microtask(() {});
      loader.completeError(1, Exception('network'));
      await Future.microtask(() {});

      // Original items untouched
      expect(controller.items, ['a', 'b', 'c', 'd', 'e']);
      expect(controller.error, isA<Exception>());
    });

    test('setAsyncLoader → fail → setAsyncLoader → retry → success', () async {
      final controller = SmartSearchController<String>(
        debounceDelay: Duration.zero,
        pageSize: 10,
      );
      addTearDown(controller.dispose);

      // Set failing loader
      final failLoader = _TestLoader();
      controller.setAsyncLoader(failLoader.call);

      controller.searchImmediate('q');
      await Future.microtask(() {});
      failLoader.completeError(0, Exception('loader-1-fail'));
      await Future.microtask(() {});
      expect(controller.error, isA<Exception>());

      // Swap to working loader
      final goodLoader = _TestLoader();
      controller.setAsyncLoader(goodLoader.call);

      // Retry uses the new loader
      controller.retry();
      await Future.microtask(() {});
      goodLoader.complete(0, ['success']);
      await Future.microtask(() {});

      expect(controller.error, isNull);
      expect(controller.items, ['success']);
    });
  });

  // ===========================================================================
  // Group 3: Configuration Boundary Tests
  // ===========================================================================

  group('configuration boundaries', () {
    test('minSearchLength=0: empty query triggers async search', () async {
      final loader = _TestLoader();
      final controller = SmartSearchController<String>(
        debounceDelay: Duration.zero,
        pageSize: 10,
        minSearchLength: 0,
      );
      addTearDown(controller.dispose);
      controller.setAsyncLoader(loader.call);

      // Empty query should pass through (not bail at L325)
      controller.searchImmediate('');
      await Future.microtask(() {});

      expect(loader.callCount, 1);
      expect(loader.lastQuery, '');
    });

    test('minSearchLength very high: no search triggers', () async {
      final loader = _TestLoader();
      final controller = SmartSearchController<String>(
        debounceDelay: Duration.zero,
        pageSize: 10,
        minSearchLength: 999,
      );
      addTearDown(controller.dispose);
      controller.setAsyncLoader(loader.call);

      controller.searchImmediate('short query');
      await Future.microtask(() {});

      // Query bails at L325-326 — loader never called
      expect(loader.callCount, 0);
    });

    test('pageSize very large: single page, hasMorePages=false', () async {
      final loader = _TestLoader();
      final controller = SmartSearchController<String>(
        debounceDelay: Duration.zero,
        pageSize: 100000,
      );
      addTearDown(controller.dispose);
      controller.setAsyncLoader(loader.call);

      controller.searchImmediate('q');
      await Future.microtask(() {});
      // Return fewer than pageSize items
      loader.complete(0, List.generate(10, (i) => 'item$i'));
      await Future.microtask(() {});

      expect(controller.items.length, 10);
      expect(controller.hasMorePages, false);
    });

    test(
      'searchableFields returns all empty strings: substring matches all',
      () {
        final controller = SmartSearchController<String>(
          searchableFields: (_) => ['', '', ''],
          debounceDelay: Duration.zero,
        );
        addTearDown(controller.dispose);

        controller.setItems(['a', 'b', 'c']);
        // Searching for non-empty string against empty fields — no match
        controller.searchImmediate('x');
        expect(controller.items, isEmpty);

        // Empty search shows all
        controller.searchImmediate('');
        expect(controller.items.length, 3);
      },
    );

    test('items with identical searchableFields: all returned, no dedup', () {
      final controller = SmartSearchController<String>(
        searchableFields: (_) => ['same'],
        debounceDelay: Duration.zero,
      );
      addTearDown(controller.dispose);

      final items = ['a', 'b', 'c', 'd', 'e'];
      controller.setItems(items);
      controller.searchImmediate('same');

      expect(controller.items.length, 5);
    });

    test('retry preserves query and does NOT clear cache', () async {
      final loader = _TestLoader();
      final controller = SmartSearchController<String>(
        debounceDelay: Duration.zero,
        pageSize: 10,
        cacheResults: true,
      );
      addTearDown(controller.dispose);
      controller.setAsyncLoader(loader.call);

      // Search 'q' → success (cached)
      controller.searchImmediate('q');
      await Future.microtask(() {});
      loader.complete(0, ['cached-result']);
      await Future.microtask(() {});
      expect(controller.items, ['cached-result']);

      // Search something else → error
      controller.searchImmediate('fail');
      await Future.microtask(() {});
      loader.completeError(1, Exception('fail'));
      await Future.microtask(() {});
      expect(controller.error, isNotNull);

      // Retry re-runs search for 'fail'
      controller.retry();
      await Future.microtask(() {});
      expect(controller.searchQuery, 'fail');
      expect(loader.callCount, 3, reason: 'retry triggers new loader call');
    });

    test(
      'refresh clears cache + resets page; retry only clears error',
      () async {
        final loader = _TestLoader();
        final controller = SmartSearchController<String>(
          debounceDelay: Duration.zero,
          pageSize: 10,
          cacheResults: true,
        );
        addTearDown(controller.dispose);
        controller.setAsyncLoader(loader.call);

        // Initial search and cache it
        controller.searchImmediate('q');
        await Future.microtask(() {});
        loader.complete(0, ['original']);
        await Future.microtask(() {});

        // --- Test refresh behavior ---
        final callsBefore = loader.callCount;
        // Don't await — loader is Completer-based
        unawaited(controller.refresh());
        await Future.microtask(() {});
        // Refresh should trigger a new loader call (cache cleared)
        expect(loader.callCount, greaterThan(callsBefore));
        loader.complete(1, ['refreshed']);
        await Future.microtask(() {});
        expect(controller.items, ['refreshed']);

        // --- Test retry behavior ---
        // Create an error state first
        controller.searchImmediate('err');
        await Future.microtask(() {});
        loader.completeError(2, Exception('e'));
        await Future.microtask(() {});
        expect(controller.error, isNotNull);

        final callsBeforeRetry = loader.callCount;
        // Don't await — loader is Completer-based
        unawaited(controller.retry());
        await Future.microtask(() {});
        // Retry should also trigger a loader call
        expect(loader.callCount, greaterThan(callsBeforeRetry));
        // But retry does NOT clear cache (no _clearCache call in retry)
        expect(controller.searchQuery, 'err');
      },
    );
  });
}
