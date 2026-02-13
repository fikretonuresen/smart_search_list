import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_search_list/smart_search_list.dart';

/// Seed-based random for reproducible test failures.
///
/// When a test fails, the printed seed can be used to reproduce the exact
/// operation sequence.
void main() {
  // =========================================================================
  // Offline randomized test
  // =========================================================================

  group('property-based: offline randomized', () {
    test('50 trials x 30 ops maintain invariants', () {
      final masterRandom = Random(42);

      for (var trial = 0; trial < 50; trial++) {
        final seed = masterRandom.nextInt(1 << 30);
        final rng = Random(seed);

        final controller = SmartSearchController<String>(
          searchableFields: (item) => [item],
          debounceDelay: Duration.zero,
        );

        // Start with a base set of items
        final baseItems = List.generate(20, (i) => 'Item$i');
        controller.setItems(baseItems);

        for (var op = 0; op < 30; op++) {
          final operation = rng.nextInt(12);
          try {
            switch (operation) {
              case 0: // setItems
                final newItems = List.generate(rng.nextInt(30), (i) => 'New$i');
                controller.setItems(newItems);
              case 1: // searchImmediate
                final queries = ['', 'Item', 'New', 'X', 'a', 'Item1'];
                controller.searchImmediate(
                  queries[rng.nextInt(queries.length)],
                );
              case 2: // clearSearch
                controller.clearSearch();
              case 3: // setFilter
                final filters = [
                  ('even', (String s) => s.hashCode.isEven),
                  ('short', (String s) => s.length <= 5),
                  ('has1', (String s) => s.contains('1')),
                ];
                final f = filters[rng.nextInt(filters.length)];
                controller.setFilter(f.$1, f.$2);
              case 4: // removeFilter
                final keys = ['even', 'short', 'has1'];
                controller.removeFilter(keys[rng.nextInt(keys.length)]);
              case 5: // clearFilters
                controller.clearFilters();
              case 6: // setSortBy
                if (rng.nextBool()) {
                  controller.setSortBy((a, b) => a.compareTo(b));
                } else {
                  controller.setSortBy(null);
                }
              case 7: // selectAll
                controller.selectAll();
              case 8: // deselectAll
                controller.deselectAll();
              case 9: // select
                if (controller.items.isNotEmpty) {
                  final idx = rng.nextInt(controller.items.length);
                  controller.select(controller.items[idx]);
                }
              case 10: // deselect
                if (controller.items.isNotEmpty) {
                  final idx = rng.nextInt(controller.items.length);
                  controller.deselect(controller.items[idx]);
                }
              case 11: // toggleSelection
                if (controller.items.isNotEmpty) {
                  final idx = rng.nextInt(controller.items.length);
                  controller.toggleSelection(controller.items[idx]);
                }
            }

            // ---- Invariant checks after every operation ----
            _checkOfflineInvariants(controller, seed, trial, op);
          } catch (e) {
            fail(
              'Trial $trial (seed=$seed), op $op, operation=$operation '
              'threw: $e',
            );
          }
        }

        controller.dispose();
      }
    });
  });

  // =========================================================================
  // Async randomized test
  // =========================================================================

  group('property-based: async randomized', () {
    test('20 trials x 15 ops maintain invariants', () async {
      final masterRandom = Random(99);

      for (var trial = 0; trial < 20; trial++) {
        final seed = masterRandom.nextInt(1 << 30);
        final rng = Random(seed);

        var shouldFail = false;
        final controller = SmartSearchController<String>(
          debounceDelay: Duration.zero,
          cacheResults: false,
          pageSize: 5,
        );

        controller.setAsyncLoader((
          query, {
          int page = 0,
          int pageSize = 20,
        }) async {
          if (shouldFail) throw Exception('random-failure');
          return List.generate(
            min(5, 5 - page), // Fewer items on later pages
            (i) => 'Async${page}_$i',
          );
        });

        for (var op = 0; op < 15; op++) {
          final operation = rng.nextInt(5);
          try {
            switch (operation) {
              case 0: // searchImmediate
                shouldFail = rng.nextInt(5) == 0; // 20% failure rate
                controller.searchImmediate('q${rng.nextInt(3)}');
                await Future.microtask(() {});
                await Future.microtask(() {});
              case 1: // clearSearch
                shouldFail = false;
                controller.clearSearch();
                await Future.microtask(() {});
                await Future.microtask(() {});
              case 2: // loadMore
                shouldFail = rng.nextInt(5) == 0;
                await controller.loadMore();
                await Future.microtask(() {});
              case 3: // refresh
                shouldFail = rng.nextInt(5) == 0;
                await controller.refresh();
                await Future.microtask(() {});
              case 4: // retry
                shouldFail = false;
                await controller.retry();
                await Future.microtask(() {});
            }

            // ---- Invariant checks ----
            _checkAsyncInvariants(controller, seed, trial, op);
          } catch (e) {
            fail(
              'Async trial $trial (seed=$seed), op $op, operation=$operation '
              'threw: $e',
            );
          }
        }

        controller.dispose();
      }
    });
  });
}

/// Checks invariants that must always hold for offline controllers.
void _checkOfflineInvariants(
  SmartSearchController<String> controller,
  int seed,
  int trial,
  int op,
) {
  final tag = 'trial=$trial seed=$seed op=$op';

  // Items are never null (Dart non-null, but check list is valid)
  expect(controller.items, isNotNull, reason: '$tag: items should not be null');

  // isLoading is always false for offline mode
  expect(
    controller.isLoading,
    false,
    reason: '$tag: isLoading should be false in offline mode',
  );

  // isLoadingMore is always false for offline mode
  expect(
    controller.isLoadingMore,
    false,
    reason: '$tag: isLoadingMore should be false in offline mode',
  );

  // Filtered items ≤ all items when searching
  if (controller.searchQuery.isNotEmpty) {
    expect(
      controller.items.length,
      lessThanOrEqualTo(controller.allItems.length),
      reason: '$tag: filtered items should not exceed allItems',
    );
  }

  // Selected items should be valid objects
  for (final selected in controller.selectedItems) {
    expect(
      selected,
      isNotNull,
      reason: '$tag: selected item should not be null',
    );
  }

  // Unmodifiable getters should throw on mutation
  expect(
    () => controller.items.add('X'),
    throwsUnsupportedError,
    reason: '$tag: items getter must be unmodifiable',
  );
}

/// Checks invariants that must always hold for async controllers.
void _checkAsyncInvariants(
  SmartSearchController<String> controller,
  int seed,
  int trial,
  int op,
) {
  final tag = 'async trial=$trial seed=$seed op=$op';

  // Items are never null
  expect(controller.items, isNotNull, reason: '$tag: items should not be null');

  // isLoading and isLoadingMore should not both be true
  expect(
    controller.isLoading && controller.isLoadingMore,
    false,
    reason: '$tag: isLoading and isLoadingMore must not both be true',
  );

  // Error is cleared after successful retry (checked contextually)
  if (controller.error == null && !controller.isLoading) {
    // If no error and not loading, items should be accessible
    expect(controller.items, isNotNull, reason: '$tag: items accessible');
  }
}
