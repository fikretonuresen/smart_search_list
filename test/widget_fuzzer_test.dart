import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_search_list/smart_search_list.dart';

import 'helpers/widget_test_helpers.dart';

void main() {
  group('widget fuzzer', () {
    testWidgets('20 trials x 15 ops maintain widget invariants', (
      tester,
    ) async {
      final masterRandom = Random(77);

      for (var trial = 0; trial < 20; trial++) {
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

        for (var op = 0; op < 15; op++) {
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

            // 1. No uncaught exceptions
            final exception = tester.takeException();
            expect(
              exception,
              isNull,
              reason: '$tag: uncaught exception: $exception',
            );

            // 2. SmartSearchList exists in tree
            expect(
              find.byType(SmartSearchList<String>),
              findsOneWidget,
              reason: '$tag: SmartSearchList must exist',
            );

            // 3. If searchEnabled, TextField exists; else it doesn't
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
                reason: '$tag: TextField must not exist when search disabled',
              );
            }

            // 4. At most one state widget visible
            //    (loading, error, list/empty — mutually exclusive)
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
                  '$tag: at most one state widget visible '
                  '(list=$hasListView, loading=$hasCircularProgress)',
            );

            // 5. If ListView is present, rendered item count <= items list length
            if (hasListView) {
              final listTileCount = find.byType(ListTile).evaluate().length;
              expect(
                listTileCount,
                lessThanOrEqualTo(state.items.length),
                reason:
                    '$tag: rendered ListTile count ($listTileCount) must not '
                    'exceed items length (${state.items.length})',
              );
            }
          } catch (e) {
            fail(
              'Widget trial $trial (seed=$seed), op $op, operation=$operation '
              'threw: $e',
            );
          }
        }

        // Clean up: pump an empty widget to dispose the previous trial's state.
        await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
        await pumpSettle(tester);
        if (state.externalController != null) {
          state.externalController!.dispose();
          state.externalController = null;
        }
      }
    });
  });
}
