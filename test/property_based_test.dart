import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_search_list/smart_search_list.dart';

import 'helpers/controller_test_helpers.dart';

/// Seed-based random for reproducible test failures.
///
/// When a test fails, the printed seed can be used to reproduce the exact
/// operation sequence.
void main() {
  // ===========================================================================
  // Offline randomized test
  // ===========================================================================

  group('property-based: offline randomized', () {
    test('100 trials x 50 ops maintain invariants', () {
      final masterRandom = Random(42);

      for (var trial = 0; trial < 100; trial++) {
        final seed = masterRandom.nextInt(1 << 30);
        final rng = Random(seed);

        final swarm = randomSwarmConfig(rng);
        final controller = SmartSearchController<String>(
          searchableFields: (item) => [item],
          debounceDelay: Duration.zero,
          caseSensitive: swarm.caseSensitive,
          fuzzySearchEnabled: swarm.fuzzySearchEnabled,
          fuzzyThreshold: swarm.fuzzyThreshold,
          cacheResults: swarm.cacheResults,
          maxCacheSize: swarm.maxCacheSize,
          minSearchLength: swarm.minSearchLength,
          pageSize: swarm.pageSize,
        );

        // Start with a base set of items.
        final baseItems = List.generate(20, (i) => 'Item$i');
        controller.setItems(baseItems);

        for (var op = 0; op < 50; op++) {
          final operation = rng.nextInt(18);
          try {
            switch (operation) {
              case 0: // setItems
                final newItems = List.generate(rng.nextInt(30), (i) => 'New$i');
                controller.setItems(newItems);
              case 1: // searchImmediate
                final queries = ['', 'Item', 'New', 'X', 'a', 'Item1', 'ew0'];
                controller.searchImmediate(
                  queries[rng.nextInt(queries.length)],
                );
              case 2: // clearSearch
                controller.clearSearch();
                expect(
                  controller.searchQuery,
                  '',
                  reason: _tag(seed, trial, op, 'clearSearch → query empty'),
                );
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
                expect(
                  controller.activeFilters.isEmpty,
                  true,
                  reason: _tag(seed, trial, op, 'clearFilters → filters empty'),
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
                    reason: _tag(seed, trial, op, 'selectAll → $item selected'),
                  );
                }
              case 8: // deselectAll
                controller.deselectAll();
                expect(
                  controller.selectedItems.isEmpty,
                  true,
                  reason: _tag(seed, trial, op, 'deselectAll → empty'),
                );
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
              case 12: // selectWhere
                controller.selectWhere((s) => s.length > 4);
              case 13: // deselectWhere
                controller.deselectWhere((s) => s.contains('0'));
              case 14: // updateCaseSensitive
                final v = rng.nextBool();
                controller.updateCaseSensitive(v);
                expect(
                  controller.caseSensitive,
                  v,
                  reason: _tag(seed, trial, op, 'caseSensitive == $v'),
                );
              case 15: // updateFuzzySearchEnabled
                final v = rng.nextBool();
                controller.updateFuzzySearchEnabled(v);
                expect(
                  controller.fuzzySearchEnabled,
                  v,
                  reason: _tag(seed, trial, op, 'fuzzySearchEnabled == $v'),
                );
              case 16: // updateFuzzyThreshold
                final v = rng.nextDouble();
                controller.updateFuzzyThreshold(v);
                expect(
                  controller.fuzzyThreshold,
                  v,
                  reason: _tag(seed, trial, op, 'fuzzyThreshold == $v'),
                );
              case 17: // updateMinSearchLength
                final v = rng.nextInt(4);
                controller.updateMinSearchLength(v);
                expect(
                  controller.minSearchLength,
                  v,
                  reason: _tag(seed, trial, op, 'minSearchLength == $v'),
                );
            }

            // ---- Universal invariant checks after every operation ----
            checkOfflineInvariants(controller, seed, trial, op);
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

  // ===========================================================================
  // Async randomized test
  // ===========================================================================

  group('property-based: async randomized', () {
    test('50 trials x 30 ops maintain invariants', () async {
      final masterRandom = Random(99);

      for (var trial = 0; trial < 50; trial++) {
        final seed = masterRandom.nextInt(1 << 30);
        final rng = Random(seed);

        final swarm = randomSwarmConfig(rng);
        final state = AsyncTestState();

        final controller = SmartSearchController<String>(
          debounceDelay: Duration.zero,
          cacheResults: swarm.cacheResults,
          maxCacheSize: swarm.maxCacheSize,
          pageSize: swarm.pageSize,
        );

        Future<List<String>> loader(
          String query, {
          int page = 0,
          int pageSize = 20,
        }) async {
          if (state.shouldFail) {
            throw switch (state.failureType) {
              1 => StateError('random-state-error'),
              2 => TimeoutException('random-timeout'),
              3 => FormatException('random-format-error'),
              _ => Exception('random-failure'),
            };
          }
          final count = switch (state.returnMode) {
            1 => max(1, pageSize ~/ 2), // partial
            2 => 0, // empty
            3 => pageSize + 5, // oversized
            _ => pageSize, // full
          };
          return List.generate(count, (i) => 'Async${page}_$i');
        }

        controller.setAsyncLoader(loader);

        for (var op = 0; op < 30; op++) {
          final operation = rng.nextInt(10);
          // Randomize failure, failure type, and return mode before each op.
          state.shouldFail = rng.nextInt(5) == 0;
          state.failureType = rng.nextInt(4);
          state.returnMode = rng.nextInt(4);

          try {
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
                expect(
                  controller.searchQuery,
                  '',
                  reason: _tag(
                    seed,
                    trial,
                    op,
                    'async clearSearch → query empty',
                  ),
                );
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
                  reason: _tag(seed, trial, op, 'retry preserves searchQuery'),
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
                final keys = ['even', 'short'];
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
                  reason: _tag(seed, trial, op, 'async clearFilters → empty'),
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
                  reason: _tag(
                    seed,
                    trial,
                    op,
                    'setAsyncLoader preserves query',
                  ),
                );
            }

            // ---- Universal invariant checks ----
            checkAsyncInvariants(controller, seed, trial, op);
          } catch (e) {
            fail(
              'Async trial $trial (seed=$seed), op $op, operation=$operation '
              'threw: $e',
            );
          }
        }

        controller.dispose();

        // Post-disposal safety: operations on disposed controller must not throw.
        expect(controller.isDisposed, true);
        controller.searchImmediate('after-dispose');
        controller.clearSearch();
        controller.clearFilters();
        controller.selectAll();
        controller.deselectAll();
        await controller.loadMore();
        await controller.refresh();
        await controller.retry();
      }
    });
  });
}

// =============================================================================
// Helpers
// =============================================================================

String _tag(int seed, int trial, int op, String detail) =>
    'trial=$trial seed=$seed op=$op: $detail';
