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
        addTearDown(() {
          if (!controller.isDisposed) controller.dispose();
        });

        // Start with a base set of items.
        final baseItems = List.generate(20, (i) => 'Item$i');
        controller.setItems(baseItems);

        for (var op = 0; op < 50; op++) {
          final operation = rng.nextInt(offlineOpCount);
          try {
            dispatchOfflineOp(controller, rng, operation, seed, trial, op);
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
        addTearDown(() {
          if (!controller.isDisposed) controller.dispose();
        });

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
          final operation = rng.nextInt(asyncOpCount);
          state.shouldFail = rng.nextInt(5) == 0;
          state.failureType = rng.nextInt(4);
          state.returnMode = rng.nextInt(4);

          try {
            await dispatchAsyncOp(
              controller,
              state,
              loader,
              rng,
              operation,
              seed,
              trial,
              op,
            );
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
