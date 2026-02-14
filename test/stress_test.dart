/// Stress tests — scaled-up versions of property-based and fuzzer tests.
///
/// Tagged 'stress' and skipped by default via dart_test.yaml.
/// Run with: flutter test -t stress --run-skipped
/// Expected runtime: ~3-5 minutes on a modern machine.
@Tags(['stress'])
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_search_list/smart_search_list.dart';

import 'helpers/controller_test_helpers.dart';
import 'helpers/fuzzy_test_helpers.dart';
import 'helpers/widget_test_helpers.dart';

void main() {
  // ===========================================================================
  // Stress 1: Offline controller — 500 trials × 100 ops = 50,000 operations
  // ===========================================================================

  group('stress: offline controller', () {
    test('500 trials x 100 ops', () {
      final masterRandom = Random(1337);

      for (var trial = 0; trial < 500; trial++) {
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

        final baseItems = List.generate(20, (i) => 'Item$i');
        controller.setItems(baseItems);

        for (var op = 0; op < 100; op++) {
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
    }, timeout: const Timeout(Duration(minutes: 5)));
  });

  // ===========================================================================
  // Stress 2: Async controller — 200 trials × 50 ops = 10,000 operations
  // ===========================================================================

  group('stress: async controller', () {
    test('200 trials x 50 ops', () async {
      final masterRandom = Random(2718);

      for (var trial = 0; trial < 200; trial++) {
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
            1 => max(1, pageSize ~/ 2),
            2 => 0,
            3 => pageSize + 5,
            _ => pageSize,
          };
          return List.generate(count, (i) => 'Async${page}_$i');
        }

        controller.setAsyncLoader(loader);

        for (var op = 0; op < 50; op++) {
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

        // Post-disposal safety.
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
    }, timeout: const Timeout(Duration(minutes: 5)));
  });

  // ===========================================================================
  // Stress 3: FuzzyMatcher — 500 trials × 50 pairs = 25,000 pairs
  // ===========================================================================

  group('stress: FuzzyMatcher', () {
    test('500 trials x 50 pairs', () {
      final masterRng = Random(3141);

      for (var trial = 0; trial < 500; trial++) {
        final seed = masterRng.nextInt(1 << 30);
        final rng = Random(seed);

        for (var pair = 0; pair < 50; pair++) {
          final tag = _tag(seed, trial, pair, 'fuzzy stress');

          // Cycle through query generators.
          final generatorType = pair % 4;
          // Alternate between ASCII and mixed-Unicode text
          final text = pair.isEven
              ? randomText(rng, 5, 40)
              : randomMixedText(rng, 5, 40);
          late String query;

          switch (generatorType) {
            case 0: // exact substring
              query = randomSubstring(rng, text);
            case 1: // subsequence
              query = randomSubsequence(rng, text);
            case 2: // edit distance
              final base = randomSubstring(rng, text);
              query = applyEdits(rng, base, 1 + rng.nextInt(2));
            case 3: // fully random
              query = randomText(rng, 1, 10);
          }

          final result = FuzzyMatcher.match(query, text);
          if (result == null) continue;

          // Universal invariants.
          expect(
            result.score,
            greaterThanOrEqualTo(0.01),
            reason: '$tag: score >= 0.01',
          );
          expect(
            result.score,
            lessThanOrEqualTo(1.0),
            reason: '$tag: score <= 1.0',
          );
          expect(
            result.matchIndices,
            isNotEmpty,
            reason: '$tag: indices must not be empty',
          );

          for (final idx in result.matchIndices) {
            expect(idx, greaterThanOrEqualTo(0), reason: '$tag: idx >= 0');
            expect(
              idx,
              lessThan(text.length),
              reason: '$tag: idx < text.length',
            );
          }

          // Indices non-decreasing.
          for (var i = 1; i < result.matchIndices.length; i++) {
            expect(
              result.matchIndices[i],
              greaterThanOrEqualTo(result.matchIndices[i - 1]),
              reason: '$tag: indices must be non-decreasing at $i',
            );
          }

          // Score 1.0 biconditional.
          final isContiguous = text.toLowerCase().contains(query.toLowerCase());
          if (isContiguous) {
            expect(
              result.score,
              1.0,
              reason: '$tag: contiguous must yield score 1.0',
            );
          } else {
            expect(
              result.score,
              lessThan(1.0),
              reason: '$tag: non-contiguous must yield score < 1.0',
            );
          }
        }
      }
    }, timeout: const Timeout(Duration(minutes: 2)));
  });

  // ===========================================================================
  // Stress 4: Widget — 100 trials × 30 ops = 3,000 operations
  // ===========================================================================

  group('stress: widget', () {
    testWidgets('100 trials x 30 ops', (tester) async {
      final masterRandom = Random(1618);

      for (var trial = 0; trial < 100; trial++) {
        final seed = masterRandom.nextInt(1 << 30);
        final rng = Random(seed);

        final state = WidgetFuzzerState();

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                state.rebuild = setState;
                Widget listWidget;
                if (state.externalController != null) {
                  listWidget = SmartSearchList<String>.controller(
                    controller: state.externalController!,
                    searchConfig: SearchConfiguration(
                      enabled: state.searchEnabled,
                      debounceDelay: const Duration(milliseconds: 10),
                    ),
                    selectionConfig: state.selectionEnabled
                        ? const SelectionConfiguration()
                        : null,
                    accessibilityConfig: AccessibilityConfiguration(
                      searchSemanticsEnabled: state.a11yEnabled,
                    ),
                    itemBuilder:
                        (context, item, index, {searchTerms = const []}) {
                          return ListTile(
                            key: ValueKey(item),
                            title: Text(item),
                          );
                        },
                  );
                } else {
                  listWidget = SmartSearchList<String>(
                    items: state.items,
                    searchableFields: (item) => [item],
                    searchConfig: SearchConfiguration(
                      enabled: state.searchEnabled,
                      debounceDelay: const Duration(milliseconds: 10),
                    ),
                    selectionConfig: state.selectionEnabled
                        ? const SelectionConfiguration()
                        : null,
                    accessibilityConfig: AccessibilityConfiguration(
                      searchSemanticsEnabled: state.a11yEnabled,
                    ),
                    itemBuilder:
                        (context, item, index, {searchTerms = const []}) {
                          return ListTile(
                            key: ValueKey(item),
                            title: Text(item),
                          );
                        },
                  );
                }
                return Scaffold(body: listWidget);
              },
            ),
          ),
        );
        await pumpSettle(tester);

        for (var op = 0; op < 30; op++) {
          final operation = rng.nextInt(9);
          final tag = 'trial=$trial seed=$seed op=$op opType=$operation';

          try {
            switch (operation) {
              case 0: // Enter text in search field
                if (state.searchEnabled) {
                  final finder = find.byType(TextField);
                  if (finder.evaluate().isNotEmpty) {
                    final queries = [
                      '',
                      'Item',
                      'X',
                      'a',
                      'Item1',
                      ' ',
                      'Ítém',
                    ];
                    await tester.enterText(
                      finder,
                      queries[rng.nextInt(queries.length)],
                    );
                  }
                }
              case 1: // Clear text
                if (state.searchEnabled) {
                  final finder = find.byType(TextField);
                  if (finder.evaluate().isNotEmpty) {
                    await tester.enterText(finder, '');
                  }
                }
              case 2: // Scroll down
                final listFinder = find.byType(Scrollable);
                if (listFinder.evaluate().isNotEmpty) {
                  await tester.drag(listFinder.first, const Offset(0, -100));
                }
              case 3: // Swap items list
                final newItems = List.generate(
                  rng.nextInt(20),
                  (i) => 'Item$i',
                );
                state.items = newItems;
                state.externalController?.setItems(newItems);
                state.rebuild(() {});
              case 4: // Toggle searchEnabled
                state.searchEnabled = !state.searchEnabled;
                state.rebuild(() {});
              case 5: // Toggle a11yEnabled
                state.a11yEnabled = !state.a11yEnabled;
                state.rebuild(() {});
              case 6: // Toggle selectionEnabled
                state.selectionEnabled = !state.selectionEnabled;
                state.rebuild(() {});
              case 7: // Wait (settle only)
                break;
              case 8: // Swap controller mode (null→ext or ext→null)
                if (state.externalController == null) {
                  final ctrl = SmartSearchController<String>(
                    searchableFields: (item) => [item],
                    debounceDelay: const Duration(milliseconds: 10),
                  );
                  addTearDown(() {
                    if (!ctrl.isDisposed) ctrl.dispose();
                  });
                  ctrl.setItems(state.items);
                  state.externalController = ctrl;
                } else {
                  state.externalController!.dispose();
                  state.externalController = null;
                }
                state.rebuild(() {});
            }

            await pumpSettle(tester);

            // ---- Invariant checks ----

            // 1. No uncaught exceptions.
            final exception = tester.takeException();
            expect(
              exception,
              isNull,
              reason: '$tag: uncaught exception: $exception',
            );

            // 2. SmartSearchList exists in tree.
            expect(
              find.byType(SmartSearchList<String>),
              findsOneWidget,
              reason: '$tag: SmartSearchList must exist',
            );

            // 3. TextField presence matches searchEnabled state.
            if (state.searchEnabled) {
              expect(
                find.byType(TextField),
                findsOneWidget,
                reason: '$tag: TextField must exist when search enabled',
              );
            } else {
              expect(
                find.byType(TextField),
                findsNothing,
                reason: '$tag: no TextField when search disabled',
              );
            }

            // 4. At most one state widget visible.
            final hasListView = find.byType(ListView).evaluate().isNotEmpty;
            final hasCircularProgress = find
                .byType(CircularProgressIndicator)
                .evaluate()
                .isNotEmpty;
            final stateWidgetCount =
                (hasListView ? 1 : 0) + (hasCircularProgress ? 1 : 0);
            expect(
              stateWidgetCount,
              lessThanOrEqualTo(1),
              reason:
                  '$tag: at most one state widget '
                  '(list=$hasListView, loading=$hasCircularProgress)',
            );

            // 5. Rendered items <= items list length.
            if (hasListView) {
              final listTileCount = find.byType(ListTile).evaluate().length;
              expect(
                listTileCount,
                lessThanOrEqualTo(state.items.length),
                reason:
                    '$tag: ListTile count ($listTileCount) must not '
                    'exceed items length (${state.items.length})',
              );
            }
          } catch (e) {
            fail(
              'Widget trial $trial (seed=$seed), op $op, '
              'operation=$operation threw: $e',
            );
          }
        }

        // Clean up before next trial.
        await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
        await pumpSettle(tester);
        if (state.externalController != null) {
          state.externalController!.dispose();
          state.externalController = null;
        }
      }
    }, timeout: const Timeout(Duration(minutes: 3)));
  });
}

// =============================================================================
// Helpers
// =============================================================================

String _tag(int seed, int trial, int op, String detail) =>
    'trial=$trial seed=$seed op=$op: $detail';
