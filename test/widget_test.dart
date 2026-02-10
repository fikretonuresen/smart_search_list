import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_search_list/smart_search_list.dart';

void main() {
  group('SmartSearchList Widget', () {
    testWidgets('renders all items initially', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchList<String>(
              items: const ['Apple', 'Banana', 'Cherry'],
              searchableFields: (item) => [item],
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return ListTile(title: Text(item));
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Cherry'), findsOneWidget);
    });

    testWidgets('filters items on text input', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchList<String>(
              items: const ['Apple', 'Banana', 'Cherry'],
              searchableFields: (item) => [item],
              searchConfig: const SearchConfiguration(
                debounceDelay: Duration(milliseconds: 10),
              ),
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return ListTile(title: Text(item));
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Type into search field
      await tester.enterText(find.byType(TextField), 'App');
      // Wait for debounce + rebuild
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsNothing);
      expect(find.text('Cherry'), findsNothing);
    });

    testWidgets('shows emptySearchStateBuilder when no matches',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchList<String>(
              items: const ['Apple', 'Banana', 'Cherry'],
              searchableFields: (item) => [item],
              searchConfig: const SearchConfiguration(
                debounceDelay: Duration(milliseconds: 10),
              ),
              emptySearchStateBuilder: (context, query) {
                return Text('Nothing found for "$query"');
              },
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return ListTile(title: Text(item));
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'zzzzz');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(find.text('Nothing found for "zzzzz"'), findsOneWidget);
    });

    testWidgets('shows emptyStateBuilder when items list is empty',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchList<String>(
              items: const [],
              searchableFields: (item) => [item],
              emptyStateBuilder: (context) {
                return const Text('No data here');
              },
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return ListTile(title: Text(item));
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No data here'), findsOneWidget);
    });

    testWidgets('shows errorStateBuilder on async error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchList<String>(
              asyncLoader: (query, {int page = 0, int pageSize = 20}) async {
                throw Exception('Network failure');
              },
              searchableFields: (item) => [item],
              searchConfig: const SearchConfiguration(
                debounceDelay: Duration(milliseconds: 10),
              ),
              errorStateBuilder: (context, error, onRetry) {
                return Text('Error: $error');
              },
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return ListTile(title: Text(item));
              },
            ),
          ),
        ),
      );

      // Wait for debounce timer + async loader to fire and fail
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(find.textContaining('Network failure'), findsOneWidget);
    });

    testWidgets('didUpdateWidget propagates items change', (tester) async {
      var items = const ['Apple', 'Banana'];

      late StateSetter rebuildParent;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rebuildParent = setState;
                return SmartSearchList<String>(
                  items: items,
                  searchableFields: (item) => [item],
                  itemBuilder:
                      (context, item, index, {searchTerms = const []}) {
                    return ListTile(title: Text(item));
                  },
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Cherry'), findsNothing);

      // Change items via parent rebuild
      rebuildParent(() {
        items = const ['Cherry', 'Date', 'Elderberry'];
      });
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsNothing);
      expect(find.text('Banana'), findsNothing);
      expect(find.text('Cherry'), findsOneWidget);
      expect(find.text('Date'), findsOneWidget);
      expect(find.text('Elderberry'), findsOneWidget);
    });

    testWidgets('didUpdateWidget propagates asyncLoader change',
        (tester) async {
      int loaderCallCount = 0;

      Future<List<String>> loaderA(
        String query, {
        int page = 0,
        int pageSize = 20,
      }) async {
        loaderCallCount++;
        return ['FromA'];
      }

      Future<List<String>> loaderB(
        String query, {
        int page = 0,
        int pageSize = 20,
      }) async {
        loaderCallCount++;
        return ['FromB'];
      }

      var currentLoader = loaderA;
      late StateSetter rebuildParent;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rebuildParent = setState;
                return SmartSearchList<String>(
                  asyncLoader: currentLoader,
                  searchableFields: (item) => [item],
                  searchConfig: const SearchConfiguration(
                    debounceDelay: Duration(milliseconds: 10),
                  ),
                  itemBuilder:
                      (context, item, index, {searchTerms = const []}) {
                    return ListTile(title: Text(item));
                  },
                );
              },
            ),
          ),
        ),
      );

      // Wait for initial load via loaderA
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(find.text('FromA'), findsOneWidget);

      // Swap to loaderB via parent rebuild
      loaderCallCount = 0;
      rebuildParent(() {
        currentLoader = loaderB;
      });

      // Wait for debounced re-search triggered by didUpdateWidget
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(find.text('FromA'), findsNothing);
      expect(find.text('FromB'), findsOneWidget);
      expect(loaderCallCount, greaterThanOrEqualTo(1));
    });

    testWidgets('selection toggles and onSelectionChanged fires',
        (tester) async {
      final selectedItems = <String>{};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchList<String>(
              items: const ['Apple', 'Banana', 'Cherry'],
              searchableFields: (item) => [item],
              selectionConfig: const SelectionConfiguration(
                enabled: true,
                showCheckbox: true,
                position: CheckboxPosition.leading,
              ),
              onSelectionChanged: (items) {
                selectedItems
                  ..clear()
                  ..addAll(items);
              },
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return ListTile(title: Text(item));
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find checkboxes and tap the first one
      final checkboxes = find.byType(Checkbox);
      expect(checkboxes, findsNWidgets(3));

      await tester.tap(checkboxes.first);
      await tester.pumpAndSettle();

      expect(selectedItems.length, 1);
      expect(selectedItems.contains('Apple'), true);
    });

    testWidgets('group headers render when groupBy is provided',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchList<String>(
              items: const [
                'Apple',
                'Avocado',
                'Banana',
                'Blueberry',
              ],
              searchableFields: (item) => [item],
              groupBy: (item) => item[0], // Group by first letter
              groupComparator: (a, b) => (a as String).compareTo(b as String),
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return ListTile(title: Text(item));
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Group headers should show "A (2)" and "B (2)"
      expect(find.text('A (2)'), findsOneWidget);
      expect(find.text('B (2)'), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
    });

    testWidgets('disposed controller does not crash', (tester) async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: const Duration(milliseconds: 10),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchList<String>(
              controller: controller,
              items: const ['Apple', 'Banana'],
              searchableFields: (item) => [item],
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return ListTile(title: Text(item));
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Remove the widget from the tree
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      await tester.pumpAndSettle();

      // Operations on the controller after widget disposal should not crash
      controller.dispose();
      expect(controller.isDisposed, true);

      // These should be no-ops, not crashes
      controller.search('test');
      controller.setItems(['test']);
    });

    testWidgets('pagination triggers loadMore at scroll threshold',
        (tester) async {
      int lastRequestedPage = 0;
      final completer = Completer<List<String>>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchList<String>(
              asyncLoader: (query, {int page = 0, int pageSize = 20}) async {
                lastRequestedPage = page;
                if (page == 0) {
                  // Return exactly pageSize items to indicate more pages
                  return List.generate(
                    pageSize,
                    (i) => 'Item ${i + 1}',
                  );
                }
                // Second page — wait on completer so we can check the request
                return completer.future;
              },
              searchableFields: (item) => [item],
              searchConfig: const SearchConfiguration(
                debounceDelay: Duration(milliseconds: 10),
              ),
              paginationConfig: const PaginationConfiguration(
                pageSize: 20,
                enabled: true,
                triggerDistance: 200.0,
              ),
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return SizedBox(
                  height: 56,
                  child: ListTile(title: Text(item)),
                );
              },
            ),
          ),
        ),
      );

      // Wait for debounce + initial async load
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(find.text('Item 1'), findsOneWidget);

      // Scroll to the bottom to trigger pagination
      await tester.drag(find.byType(ListView), const Offset(0, -5000));
      await tester.pump();

      // The async loader should have been called with page 1
      expect(lastRequestedPage, 1);

      // Complete the second page
      completer.complete(['Item 21', 'Item 22']);
      await tester.pumpAndSettle();
    });
  });
}
