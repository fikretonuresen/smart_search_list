import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_search_list/smart_search_list.dart';

/// Randomized configuration for swarm testing — each trial gets a different
/// combination of controller settings.
class SwarmConfig {
  final bool caseSensitive;
  final bool fuzzySearchEnabled;
  final double fuzzyThreshold;
  final bool cacheResults;
  final int maxCacheSize;
  final int minSearchLength;
  final int pageSize;
  const SwarmConfig({
    required this.caseSensitive,
    required this.fuzzySearchEnabled,
    required this.fuzzyThreshold,
    required this.cacheResults,
    required this.maxCacheSize,
    required this.minSearchLength,
    required this.pageSize,
  });
}

/// Generates a random [SwarmConfig] for property-based testing.
SwarmConfig randomSwarmConfig(Random rng) => SwarmConfig(
  caseSensitive: rng.nextBool(),
  fuzzySearchEnabled: rng.nextBool(),
  fuzzyThreshold: rng.nextDouble(),
  cacheResults: rng.nextBool(),
  maxCacheSize: rng.nextInt(10),
  minSearchLength: rng.nextInt(4),
  pageSize: rng.nextInt(20) + 1,
);

/// Mutable state for async fuzzer trials.
class AsyncTestState {
  bool shouldFail = false;

  /// 0=Exception, 1=StateError, 2=TimeoutException, 3=FormatException
  int failureType = 0;

  /// 0=full, 1=partial, 2=empty, 3=oversized
  int returnMode = 0;
}

// =============================================================================
// Shared dispatch functions for property-based and stress tests
// =============================================================================

/// Number of distinct offline operations.
const offlineOpCount = 18;

/// Number of distinct async operations.
const asyncOpCount = 14;

/// Dispatches one random offline operation on [controller].
///
/// [operation] must be in [0, offlineOpCount).
void dispatchOfflineOp(
  SmartSearchController<String> controller,
  Random rng,
  int operation,
  int seed,
  int trial,
  int op,
) {
  String tag(String detail) => 'trial=$trial seed=$seed op=$op: $detail';

  switch (operation) {
    case 0: // setItems
      final useUnicode = rng.nextInt(3) == 0;
      final newItems = useUnicode
          ? List.generate(rng.nextInt(30), (i) => 'Ítém$i')
          : List.generate(rng.nextInt(30), (i) => 'New$i');
      controller.setItems(newItems);
    case 1: // searchImmediate
      final queries = [
        '',
        'Item',
        'New',
        'X',
        'a',
        'Item1',
        'ew0',
        ' ',
        'Ítém',
        'Ünïcödé',
        'a' * 200,
      ];
      controller.searchImmediate(queries[rng.nextInt(queries.length)]);
    case 2: // clearSearch
      controller.clearSearch();
      expect(controller.searchQuery, '', reason: tag('clearSearch → empty'));
    case 3: // setFilter
      final filters = [
        ('even', (String s) => s.hashCode.isEven),
        ('short', (String s) => s.length <= 5),
        ('has1', (String s) => s.contains('1')),
      ];
      final f = filters[rng.nextInt(filters.length)];
      controller.setFilter(f.$1, f.$2);
    case 4: // removeFilter
      const keys = ['even', 'short', 'has1'];
      controller.removeFilter(keys[rng.nextInt(keys.length)]);
    case 5: // clearFilters
      controller.clearFilters();
      expect(
        controller.activeFilters.isEmpty,
        true,
        reason: tag('clearFilters → empty'),
      );
    case 6: // setSortBy
      if (rng.nextBool()) {
        controller.setSortBy((a, b) => a.compareTo(b));
      } else {
        controller.setSortBy(null);
      }
    case 7: // selectAll
      controller.selectAll();
      for (final item in controller.items) {
        expect(
          controller.selectedItems.contains(item),
          true,
          reason: tag('selectAll → $item selected'),
        );
      }
    case 8: // deselectAll
      controller.deselectAll();
      expect(
        controller.selectedItems.isEmpty,
        true,
        reason: tag('deselectAll → empty'),
      );
    case 9: // select
      if (controller.items.isNotEmpty) {
        controller.select(
          controller.items[rng.nextInt(controller.items.length)],
        );
      }
    case 10: // deselect
      if (controller.items.isNotEmpty) {
        controller.deselect(
          controller.items[rng.nextInt(controller.items.length)],
        );
      }
    case 11: // toggleSelection
      if (controller.items.isNotEmpty) {
        controller.toggleSelection(
          controller.items[rng.nextInt(controller.items.length)],
        );
      }
    case 12: // selectWhere
      controller.selectWhere((s) => s.length > 4);
    case 13: // deselectWhere
      controller.deselectWhere((s) => s.contains('0'));
    case 14: // updateCaseSensitive
      final v = rng.nextBool();
      controller.updateCaseSensitive(v);
      expect(controller.caseSensitive, v, reason: tag('caseSensitive == $v'));
    case 15: // updateFuzzySearchEnabled
      final v = rng.nextBool();
      controller.updateFuzzySearchEnabled(v);
      expect(
        controller.fuzzySearchEnabled,
        v,
        reason: tag('fuzzySearchEnabled == $v'),
      );
    case 16: // updateFuzzyThreshold
      final v = rng.nextDouble();
      controller.updateFuzzyThreshold(v);
      expect(controller.fuzzyThreshold, v, reason: tag('fuzzyThreshold == $v'));
    case 17: // updateMinSearchLength
      final v = rng.nextInt(4);
      controller.updateMinSearchLength(v);
      expect(
        controller.minSearchLength,
        v,
        reason: tag('minSearchLength == $v'),
      );
  }
}

/// Dispatches one random async operation on [controller].
///
/// [operation] must be in [0, asyncOpCount). Includes selection ops (10-13)
/// that the original property-based tests were missing.
Future<void> dispatchAsyncOp(
  SmartSearchController<String> controller,
  AsyncTestState state,
  Future<List<String>> Function(String query, {int page, int pageSize}) loader,
  Random rng,
  int operation,
  int seed,
  int trial,
  int op,
) async {
  String tag(String detail) => 'trial=$trial seed=$seed op=$op: $detail';

  switch (operation) {
    case 0: // searchImmediate
      controller.searchImmediate('q${rng.nextInt(5)}');
      await Future.microtask(() {});
      await Future.microtask(() {});
    case 1: // clearSearch
      state.shouldFail = false;
      controller.clearSearch();
      await Future.microtask(() {});
      await Future.microtask(() {});
      expect(controller.searchQuery, '', reason: tag('clearSearch → empty'));
    case 2: // loadMore
      await controller.loadMore();
      await Future.microtask(() {});
    case 3: // refresh
      await controller.refresh();
      await Future.microtask(() {});
    case 4: // retry
      state.shouldFail = false;
      final queryBefore = controller.searchQuery;
      await controller.retry();
      await Future.microtask(() {});
      expect(
        controller.searchQuery,
        queryBefore,
        reason: tag('retry preserves searchQuery'),
      );
    case 5: // setFilter
      final filters = [
        ('even', (String s) => s.hashCode.isEven),
        ('short', (String s) => s.length <= 8),
      ];
      final f = filters[rng.nextInt(filters.length)];
      controller.setFilter(f.$1, f.$2);
      await Future.microtask(() {});
      await Future.microtask(() {});
    case 6: // removeFilter
      const keys = ['even', 'short'];
      controller.removeFilter(keys[rng.nextInt(keys.length)]);
      await Future.microtask(() {});
      await Future.microtask(() {});
    case 7: // clearFilters
      controller.clearFilters();
      await Future.microtask(() {});
      await Future.microtask(() {});
      expect(
        controller.activeFilters.isEmpty,
        true,
        reason: tag('clearFilters → empty'),
      );
    case 8: // setSortBy
      if (rng.nextBool()) {
        controller.setSortBy((a, b) => a.compareTo(b));
      } else {
        controller.setSortBy(null);
      }
      await Future.microtask(() {});
      await Future.microtask(() {});
    case 9: // setAsyncLoader swap
      final queryBefore = controller.searchQuery;
      controller.setAsyncLoader(loader);
      expect(
        controller.searchQuery,
        queryBefore,
        reason: tag('setAsyncLoader preserves query'),
      );
    case 10: // selectAll
      controller.selectAll();
    case 11: // deselectAll
      controller.deselectAll();
    case 12: // select random item
      if (controller.items.isNotEmpty) {
        controller.select(
          controller.items[rng.nextInt(controller.items.length)],
        );
      }
    case 13: // deselect random item
      if (controller.items.isNotEmpty) {
        controller.deselect(
          controller.items[rng.nextInt(controller.items.length)],
        );
      }
  }
}

/// Checks invariants that must always hold for offline controllers.
void checkOfflineInvariants(
  SmartSearchController<String> controller,
  int seed,
  int trial,
  int op,
) {
  final tag = 'trial=$trial seed=$seed op=$op';

  // 1. Items not null
  expect(controller.items, isNotNull, reason: '$tag: items not null');

  // 2. Items unmodifiable
  expect(
    () => controller.items.add('X'),
    throwsUnsupportedError,
    reason: '$tag: items must be unmodifiable',
  );

  // 3. allItems unmodifiable
  expect(
    () => controller.allItems.add('X'),
    throwsUnsupportedError,
    reason: '$tag: allItems must be unmodifiable',
  );

  // 4. selectedItems unmodifiable
  expect(
    () => controller.selectedItems.add('X'),
    throwsUnsupportedError,
    reason: '$tag: selectedItems must be unmodifiable',
  );

  // 5. activeFilters unmodifiable
  expect(
    () => controller.activeFilters['x'] = (_) => true,
    throwsUnsupportedError,
    reason: '$tag: activeFilters must be unmodifiable',
  );

  // 6. isLoading always false in offline mode
  expect(
    controller.isLoading,
    false,
    reason: '$tag: isLoading must be false in offline mode',
  );

  // 7. isLoadingMore always false in offline mode
  expect(
    controller.isLoadingMore,
    false,
    reason: '$tag: isLoadingMore must be false in offline mode',
  );

  // 8. error always null in offline mode
  expect(
    controller.error,
    isNull,
    reason: '$tag: error must be null in offline mode',
  );

  // 9. items.length <= allItems.length
  expect(
    controller.items.length,
    lessThanOrEqualTo(controller.allItems.length),
    reason: '$tag: items.length <= allItems.length',
  );

  // 10. items stable (two getter calls return equal lists)
  expect(
    controller.items,
    equals(controller.items),
    reason: '$tag: items must be stable across calls',
  );

  // 11. No duplicates in items (assumes test data generator produces unique
  // String values — the controller does NOT deduplicate input)
  final itemSet = controller.items.toSet();
  expect(
    itemSet.length,
    controller.items.length,
    reason: '$tag: items must not contain duplicates',
  );

  // 12. If comparator is set, items are in sorted order
  if (controller.currentComparator != null) {
    final sorted = List<String>.from(controller.items)
      ..sort(controller.currentComparator);
    expect(
      controller.items,
      orderedEquals(sorted),
      reason: '$tag: items must be in sorted order when comparator is set',
    );
  }

  // 13. Identity invariant: no search + no filters → items.length == allItems.length
  if (controller.searchQuery.isEmpty && controller.activeFilters.isEmpty) {
    expect(
      controller.items.length,
      controller.allItems.length,
      reason: '$tag: no search + no filters → items.length == allItems.length',
    );
  }

  // NOTE: These plan invariants are intentionally NOT checked here:
  // #10 (selectedItems ⊆ allItems): selectAll + setItems(newData) deliberately
  //     retains old selections — verified in boundary_transition_test.dart.
  // #20 (fuzzy score ordering): requires access to per-item scores, which the
  //     public API does not expose.
  // #22 (hasSearched): only meaningful after a search op, but this function
  //     runs after every op including setItems/select/filter. The first few ops
  //     may not have searched yet.
}

/// Checks invariants that must always hold for async controllers.
void checkAsyncInvariants(
  SmartSearchController<String> controller,
  int seed,
  int trial,
  int op,
) {
  final tag = 'async trial=$trial seed=$seed op=$op';

  // 1. Items not null
  expect(controller.items, isNotNull, reason: '$tag: items not null');

  // 2. Items unmodifiable
  expect(
    () => controller.items.add('X'),
    throwsUnsupportedError,
    reason: '$tag: items must be unmodifiable',
  );

  // 3. If error != null then isLoading == false
  if (controller.error != null) {
    expect(
      controller.isLoading,
      false,
      reason: '$tag: error present → isLoading must be false',
    );
  }

  // 4. Items stable
  expect(
    controller.items,
    equals(controller.items),
    reason: '$tag: items must be stable across calls',
  );

  // 5. activeFilters unmodifiable
  expect(
    () => controller.activeFilters['x'] = (_) => true,
    throwsUnsupportedError,
    reason: '$tag: activeFilters must be unmodifiable',
  );

  // 6. selectedItems unmodifiable
  expect(
    () => controller.selectedItems.add('X'),
    throwsUnsupportedError,
    reason: '$tag: selectedItems must be unmodifiable',
  );

  // 7. allItems unmodifiable
  expect(
    () => controller.allItems.add('X'),
    throwsUnsupportedError,
    reason: '$tag: allItems must be unmodifiable',
  );

  // 8-9: Smoke checks — type-guaranteed by Dart, kept as getter-exercising
  // canaries that would catch a throwing getter or corrupted state object.
  expect(controller.hasMorePages, isA<bool>(), reason: '$tag: hasMorePages');
  if (!controller.isLoading && controller.error == null) {
    expect(controller.items, isA<List<String>>(), reason: '$tag: items');
  }

  // NOTE: These invariants are intentionally NOT checked in async mode:
  // - Sorted order: async loader returns server-sorted data; the client-side
  //   comparator is not applied to async results (see setSortBy dartdoc).
  // - Identity invariant (no search + no filters → items == allItems): In async
  //   mode, allItems is always empty — the server owns the data.
  // - "no duplicates": Race conditions between searchImmediate (fire-and-forget)
  //   and loadMore (appends to _filteredItems) can cause legitimate overlaps
  //   when the search's _loadAsyncData gets preempted by a requestId mismatch.
  // - #11 (hasMorePages after partial page): Would require tracking the last
  //   return count via a shadow variable — the async loader's return is not
  //   directly observable from the invariant checker.
  // - #12 (loadMore idempotency): Tested deterministically in
  //   boundary_transition_test.dart. The fuzzer's fire-and-forget timing makes
  //   this hard to verify reliably.
  // - #13 (refresh resets page to 0): currentPage is not exposed publicly.
}
