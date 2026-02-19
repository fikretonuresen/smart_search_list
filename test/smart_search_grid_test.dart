import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_search_list/smart_search_list.dart';

// Helper to create a standard grid config for tests.
// childAspectRatio 5.0 keeps cells short so grouped grids fit the viewport.
GridConfiguration _gridConfig({int crossAxisCount = 2}) {
  return GridConfiguration(
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      childAspectRatio: 5.0,
    ),
  );
}

void main() {
  group('SmartSearchGrid — offline', () {
    testWidgets('renders all items initially', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchGrid<String>(
              items: const ['Apple', 'Banana', 'Cherry'],
              searchableFields: (item) => [item],
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return Text(item);
              },
              gridConfig: _gridConfig(),
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
            body: SmartSearchGrid<String>(
              items: const ['Apple', 'Banana', 'Cherry'],
              searchableFields: (item) => [item],
              searchConfig: const SearchConfiguration(
                debounceDelay: Duration(milliseconds: 10),
              ),
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return Text(item);
              },
              gridConfig: _gridConfig(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'App');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsNothing);
      expect(find.text('Cherry'), findsNothing);
    });

    testWidgets('shows empty search state when no matches', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchGrid<String>(
              items: const ['Apple', 'Banana', 'Cherry'],
              searchableFields: (item) => [item],
              searchConfig: const SearchConfiguration(
                debounceDelay: Duration(milliseconds: 10),
              ),
              emptySearchStateBuilder: (context, query) {
                return Text('Nothing found for "$query"');
              },
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return Text(item);
              },
              gridConfig: _gridConfig(),
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

    testWidgets('shows empty state when items list is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchGrid<String>(
              items: const [],
              searchableFields: (item) => [item],
              emptyStateBuilder: (context) {
                return const Text('No data here');
              },
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return Text(item);
              },
              gridConfig: _gridConfig(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No data here'), findsOneWidget);
    });

    testWidgets('onItemTap fires with correct item and index', (tester) async {
      String? tappedItem;
      int? tappedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchGrid<String>(
              items: const ['Apple', 'Banana'],
              searchableFields: (item) => [item],
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return Text(item);
              },
              gridConfig: _gridConfig(),
              onItemTap: (item, index) {
                tappedItem = item;
                tappedIndex = index;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Banana'));
      await tester.pump();

      expect(tappedItem, 'Banana');
      expect(tappedIndex, 1);
    });

    testWidgets('search field can be hidden', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchGrid<String>(
              items: const ['Apple'],
              searchableFields: (item) => [item],
              searchConfig: const SearchConfiguration(enabled: false),
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return Text(item);
              },
              gridConfig: _gridConfig(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
      expect(find.text('Apple'), findsOneWidget);
    });
  });

  group('SmartSearchGrid — async', () {
    testWidgets('shows loading then items', (tester) async {
      final completer = Completer<List<String>>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchGrid<String>.async(
              asyncLoader: (query, {int page = 0, int pageSize = 20}) {
                return completer.future;
              },
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return Text(item);
              },
              gridConfig: _gridConfig(),
              searchConfig: const SearchConfiguration(
                debounceDelay: Duration.zero,
              ),
            ),
          ),
        ),
      );
      // Debounce timer + rebuild
      await tester.pump(const Duration(milliseconds: 10));
      await tester.pump();

      // Should show loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(['Apple', 'Banana']);
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
    });

    testWidgets('shows error state on failure', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchGrid<String>.async(
              asyncLoader: (query, {int page = 0, int pageSize = 20}) async {
                throw Exception('Network error');
              },
              errorStateBuilder: (context, error, onRetry) {
                return Text('Error: $error');
              },
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return Text(item);
              },
              gridConfig: _gridConfig(),
              searchConfig: const SearchConfiguration(
                debounceDelay: Duration.zero,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Network error'), findsOneWidget);
    });
  });

  group('SmartSearchGrid — controller', () {
    testWidgets('renders items from external controller', (tester) async {
      final ctrl = SmartSearchController<String>(
        searchableFields: (item) => [item],
      );
      addTearDown(() {
        if (!ctrl.isDisposed) ctrl.dispose();
      });
      ctrl.setItems(['Alpha', 'Beta', 'Gamma']);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchGrid<String>.controller(
              controller: ctrl,
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return Text(item);
              },
              gridConfig: _gridConfig(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
      expect(find.text('Gamma'), findsOneWidget);
    });

    testWidgets('controller swap updates display', (tester) async {
      final ctrl1 = SmartSearchController<String>(
        searchableFields: (item) => [item],
      );
      addTearDown(() {
        if (!ctrl1.isDisposed) ctrl1.dispose();
      });
      ctrl1.setItems(['One']);

      final ctrl2 = SmartSearchController<String>(
        searchableFields: (item) => [item],
      );
      addTearDown(() {
        if (!ctrl2.isDisposed) ctrl2.dispose();
      });
      ctrl2.setItems(['Two']);

      final controllerNotifier = ValueNotifier(ctrl1);
      addTearDown(controllerNotifier.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<SmartSearchController<String>>(
              valueListenable: controllerNotifier,
              builder: (context, ctrl, _) {
                return SmartSearchGrid<String>.controller(
                  controller: ctrl,
                  itemBuilder:
                      (context, item, index, {searchTerms = const []}) {
                        return Text(item);
                      },
                  gridConfig: _gridConfig(),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('One'), findsOneWidget);
      expect(find.text('Two'), findsNothing);

      controllerNotifier.value = ctrl2;
      await tester.pumpAndSettle();

      expect(find.text('One'), findsNothing);
      expect(find.text('Two'), findsOneWidget);
    });
  });

  group('SmartSearchGrid — grouping', () {
    testWidgets('items are grouped with headers', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchGrid<String>(
              items: const ['Apple', 'Avocado', 'Banana', 'Blueberry'],
              searchableFields: (item) => [item],
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return Text(item);
              },
              gridConfig: _gridConfig(),
              groupBy: (item) => item[0],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      // Group headers show "A (2)" and "B (2)"
      expect(find.textContaining('A (2)'), findsOneWidget);
      expect(find.textContaining('B (2)'), findsOneWidget);
    });

    testWidgets('custom group header builder works', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchGrid<String>(
              items: const ['Apple', 'Banana'],
              searchableFields: (item) => [item],
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return Text(item);
              },
              gridConfig: _gridConfig(),
              groupBy: (item) => item[0],
              groupHeaderBuilder: (context, groupValue, itemCount) {
                return Text('Group: $groupValue');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Group: A'), findsOneWidget);
      expect(find.text('Group: B'), findsOneWidget);
    });

    testWidgets('group comparator orders groups', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchGrid<String>(
              items: const ['Banana', 'Apple', 'Cherry'],
              searchableFields: (item) => [item],
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return Text(item);
              },
              gridConfig: _gridConfig(),
              groupBy: (item) => item[0],
              groupComparator: (a, b) => (a as String).compareTo(b as String),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Cherry'), findsOneWidget);
    });
  });

  group('SmartSearchGrid — selection', () {
    testWidgets('selection checkboxes appear when enabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchGrid<String>(
              items: const ['Apple', 'Banana'],
              searchableFields: (item) => [item],
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return Text(item);
              },
              gridConfig: _gridConfig(),
              selectionConfig: const SelectionConfiguration(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Checkbox), findsWidgets);
    });

    testWidgets('onSelectionChanged fires on checkbox tap', (tester) async {
      Set<String>? lastSelection;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchGrid<String>(
              items: const ['Apple', 'Banana'],
              searchableFields: (item) => [item],
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return Text(item);
              },
              gridConfig: _gridConfig(),
              selectionConfig: const SelectionConfiguration(),
              onSelectionChanged: (selected) {
                lastSelection = selected;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();

      expect(lastSelection, isNotNull);
      expect(lastSelection!.length, 1);
    });
  });

  group('SmartSearchGrid — didUpdateWidget', () {
    testWidgets('updates items when changed', (tester) async {
      final items = ValueNotifier(const ['A', 'B']);
      addTearDown(items.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<List<String>>(
              valueListenable: items,
              builder: (context, value, _) {
                return SmartSearchGrid<String>(
                  items: value,
                  searchableFields: (item) => [item],
                  itemBuilder:
                      (context, item, index, {searchTerms = const []}) {
                        return Text(item);
                      },
                  gridConfig: _gridConfig(),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);

      items.value = const ['X', 'Y', 'Z'];
      await tester.pumpAndSettle();

      expect(find.text('A'), findsNothing);
      expect(find.text('X'), findsOneWidget);
      expect(find.text('Y'), findsOneWidget);
      expect(find.text('Z'), findsOneWidget);
    });
  });

  group('SmartSearchGrid — disposal', () {
    testWidgets('disposes cleanly without errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchGrid<String>(
              items: const ['Apple'],
              searchableFields: (item) => [item],
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return Text(item);
              },
              gridConfig: _gridConfig(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Replace with empty container — forces disposal
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );
      await tester.pumpAndSettle();

      // No exceptions thrown
    });

    testWidgets('does not dispose external controller', (tester) async {
      final ctrl = SmartSearchController<String>(
        searchableFields: (item) => [item],
      );
      addTearDown(() {
        if (!ctrl.isDisposed) ctrl.dispose();
      });
      ctrl.setItems(['Apple']);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchGrid<String>.controller(
              controller: ctrl,
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return Text(item);
              },
              gridConfig: _gridConfig(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );
      await tester.pumpAndSettle();

      // External controller should NOT be disposed
      expect(ctrl.isDisposed, false);
    });
  });

  group('SmartSearchGrid — pull-to-refresh', () {
    testWidgets('RefreshIndicator wraps grid when pullToRefresh is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchGrid<String>(
              items: const ['Apple'],
              searchableFields: (item) => [item],
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return Text(item);
              },
              gridConfig: GridConfiguration(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                ),
                pullToRefresh: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('no RefreshIndicator when pullToRefresh is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchGrid<String>(
              items: const ['Apple'],
              searchableFields: (item) => [item],
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return Text(item);
              },
              gridConfig: GridConfiguration(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                ),
                pullToRefresh: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RefreshIndicator), findsNothing);
    });
  });

  group('SmartSearchGrid — sort and filter builders', () {
    testWidgets('sortBuilder and filterBuilder render', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchGrid<String>(
              items: const ['Banana', 'Apple', 'Cherry'],
              searchableFields: (item) => [item],
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return Text(item);
              },
              gridConfig: _gridConfig(),
              sortBuilder: (context, comparator, onChanged) {
                return const Text('SORT');
              },
              filterBuilder: (context, filters, onChanged, onRemoved) {
                return const Text('FILTER');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SORT'), findsOneWidget);
      expect(find.text('FILTER'), findsOneWidget);
    });
  });

  group('SmartSearchGrid — belowSearchWidget', () {
    testWidgets('belowSearchWidget renders between search and grid', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchGrid<String>(
              items: const ['Apple'],
              searchableFields: (item) => [item],
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return Text(item);
              },
              gridConfig: _gridConfig(),
              belowSearchWidget: const Text('CHIPS'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('CHIPS'), findsOneWidget);
    });
  });

  group('SmartSearchGrid — progressIndicatorBuilder', () {
    testWidgets('progress indicator renders during loading', (tester) async {
      final completer = Completer<List<String>>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchGrid<String>.async(
              asyncLoader: (query, {int page = 0, int pageSize = 20}) {
                return completer.future;
              },
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return Text(item);
              },
              gridConfig: _gridConfig(),
              searchConfig: const SearchConfiguration(
                debounceDelay: Duration.zero,
              ),
              progressIndicatorBuilder: (context, isLoading) {
                return isLoading
                    ? const Text('LOADING BAR')
                    : const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      // Debounce timer + rebuild
      await tester.pump(const Duration(milliseconds: 10));
      await tester.pump();

      expect(find.text('LOADING BAR'), findsOneWidget);

      completer.complete(['Apple']);
      await tester.pumpAndSettle();

      expect(find.text('LOADING BAR'), findsNothing);
    });
  });

  group('SmartSearchGrid — onSearchChanged', () {
    testWidgets('fires on text input', (tester) async {
      final queries = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchGrid<String>(
              items: const ['Apple', 'Banana', 'Cherry'],
              searchableFields: (item) => [item],
              searchConfig: const SearchConfiguration(
                debounceDelay: Duration(milliseconds: 10),
              ),
              onSearchChanged: (query) => queries.add(query),
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return Text(item);
              },
              gridConfig: _gridConfig(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'App');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(queries, isNotEmpty);
      expect(queries.last, 'App');
    });

    testWidgets('fires empty string when clear button tapped', (tester) async {
      final queries = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchGrid<String>(
              items: const ['Apple', 'Banana', 'Cherry'],
              searchableFields: (item) => [item],
              searchConfig: const SearchConfiguration(
                debounceDelay: Duration(milliseconds: 10),
              ),
              onSearchChanged: (query) => queries.add(query),
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return Text(item);
              },
              gridConfig: _gridConfig(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Type a query first
      await tester.enterText(find.byType(TextField), 'App');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      queries.clear();

      // Tap the clear button (X icon)
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(queries, isNotEmpty);
      expect(queries.last, '');
    });

    testWidgets('fires each keystroke individually', (tester) async {
      final queries = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchGrid<String>(
              items: const ['Apple', 'Banana', 'Cherry'],
              searchableFields: (item) => [item],
              searchConfig: const SearchConfiguration(
                debounceDelay: Duration(milliseconds: 10),
              ),
              onSearchChanged: (query) => queries.add(query),
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return Text(item);
              },
              gridConfig: _gridConfig(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap to focus and establish input connection
      await tester.tap(find.byType(TextField));
      await tester.pump();
      queries.clear();

      // Type one character at a time
      await tester.enterText(find.byType(TextField), 'A');
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Ap');
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'App');
      await tester.pump();

      // Each keystroke fires onSearchChanged (pre-debounce)
      expect(queries, ['A', 'Ap', 'App']);
    });

    testWidgets('still fires in onSubmit mode', (tester) async {
      final queries = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchGrid<String>(
              items: const ['Apple', 'Banana', 'Cherry'],
              searchableFields: (item) => [item],
              searchConfig: const SearchConfiguration(
                debounceDelay: Duration(milliseconds: 10),
                triggerMode: SearchTriggerMode.onSubmit,
              ),
              onSearchChanged: (query) => queries.add(query),
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return Text(item);
              },
              gridConfig: _gridConfig(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap to focus and establish input connection
      await tester.tap(find.byType(TextField));
      await tester.pump();
      queries.clear();

      // Type text — onSearchChanged fires even in onSubmit mode
      await tester.enterText(find.byType(TextField), 'App');
      await tester.pump();

      expect(queries, ['App']);

      // Items should NOT be filtered yet (onSubmit hasn't been triggered)
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
    });
  });

  group('SmartSearchGrid — searchTerms passthrough', () {
    testWidgets('empty terms when no search', (tester) async {
      List<String> capturedTerms = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchGrid<String>(
              items: const ['Apple'],
              searchableFields: (item) => [item],
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                capturedTerms = List.from(searchTerms);
                return Text(item);
              },
              gridConfig: _gridConfig(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(capturedTerms, isEmpty);
    });

    testWidgets('single term passed correctly', (tester) async {
      List<String> capturedTerms = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchGrid<String>(
              items: const ['Apple', 'Banana'],
              searchableFields: (item) => [item],
              searchConfig: const SearchConfiguration(
                debounceDelay: Duration(milliseconds: 10),
              ),
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                capturedTerms = List.from(searchTerms);
                return Text(item);
              },
              gridConfig: _gridConfig(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'App');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(capturedTerms, ['App']);
    });

    testWidgets('multi-word splits by space', (tester) async {
      List<String> capturedTerms = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchGrid<String>(
              items: const ['Red Apple', 'Green Banana'],
              searchableFields: (item) => [item],
              searchConfig: const SearchConfiguration(
                debounceDelay: Duration(milliseconds: 10),
              ),
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                capturedTerms = List.from(searchTerms);
                return Text(item);
              },
              gridConfig: _gridConfig(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'red apple');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(capturedTerms, ['red', 'apple']);
    });

    testWidgets('empty after clear', (tester) async {
      List<String> capturedTerms = ['placeholder'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchGrid<String>(
              items: const ['Apple', 'Banana'],
              searchableFields: (item) => [item],
              searchConfig: const SearchConfiguration(
                debounceDelay: Duration(milliseconds: 10),
              ),
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                capturedTerms = List.from(searchTerms);
                return Text(item);
              },
              gridConfig: _gridConfig(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Search, then clear
      await tester.enterText(find.byType(TextField), 'App');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();
      expect(capturedTerms, ['App']);

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(capturedTerms, isEmpty);
    });
  });

  group('SmartSearchGrid — grouped search filtering', () {
    testWidgets('search filters groups and empty groups vanish', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchGrid<String>(
              items: const ['Apple', 'Avocado', 'Banana', 'Blueberry'],
              searchableFields: (item) => [item],
              searchConfig: const SearchConfiguration(
                debounceDelay: Duration(milliseconds: 10),
              ),
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return Text(item);
              },
              gridConfig: _gridConfig(),
              groupBy: (item) => item[0],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Both groups visible initially
      expect(find.textContaining('A (2)'), findsOneWidget);
      expect(find.textContaining('B (2)'), findsOneWidget);

      // Search for 'App' — only A group items match
      await tester.enterText(find.byType(TextField), 'App');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Avocado'), findsNothing);
      expect(find.text('Banana'), findsNothing);
      // A group now has 1 item, B group vanishes
      expect(find.textContaining('A (1)'), findsOneWidget);
      expect(find.textContaining('B'), findsNothing);
    });

    testWidgets('search terms passed in grouped mode', (tester) async {
      List<String> capturedTerms = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchGrid<String>(
              items: const ['Apple', 'Banana'],
              searchableFields: (item) => [item],
              searchConfig: const SearchConfiguration(
                debounceDelay: Duration(milliseconds: 10),
              ),
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                capturedTerms = List.from(searchTerms);
                return Text(item);
              },
              gridConfig: _gridConfig(),
              groupBy: (item) => item[0],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'App');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(capturedTerms, ['App']);
    });

    testWidgets('clearing search restores all groups', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchGrid<String>(
              items: const ['Apple', 'Avocado', 'Banana', 'Blueberry'],
              searchableFields: (item) => [item],
              searchConfig: const SearchConfiguration(
                debounceDelay: Duration(milliseconds: 10),
              ),
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return Text(item);
              },
              gridConfig: _gridConfig(),
              groupBy: (item) => item[0],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Search to filter
      await tester.enterText(find.byType(TextField), 'App');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();
      expect(find.text('Banana'), findsNothing);

      // Clear search
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      // All groups restored
      expect(find.textContaining('A (2)'), findsOneWidget);
      expect(find.textContaining('B (2)'), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
    });
  });

  group('SmartSearchGrid — didUpdateWidget advanced', () {
    testWidgets('asyncLoader swap triggers reload', (tester) async {
      late StateSetter rebuildParent;
      var loaderVersion = 1;

      Future<List<String>> loaderV1(
        String query, {
        int page = 0,
        int pageSize = 20,
      }) async {
        return ['FromLoaderV1'];
      }

      Future<List<String>> loaderV2(
        String query, {
        int page = 0,
        int pageSize = 20,
      }) async {
        return ['FromLoaderV2'];
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rebuildParent = setState;
                return SmartSearchGrid<String>.async(
                  asyncLoader: loaderVersion == 1 ? loaderV1 : loaderV2,
                  itemBuilder:
                      (context, item, index, {searchTerms = const []}) {
                        return Text(item);
                      },
                  gridConfig: _gridConfig(),
                  searchConfig: const SearchConfiguration(
                    debounceDelay: Duration.zero,
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('FromLoaderV1'), findsOneWidget);

      // Swap the async loader
      rebuildParent(() {
        loaderVersion = 2;
      });
      await tester.pumpAndSettle();

      expect(find.text('FromLoaderV2'), findsOneWidget);
      expect(find.text('FromLoaderV1'), findsNothing);
    });

    testWidgets('SearchConfiguration caseSensitive change propagates', (
      tester,
    ) async {
      late StateSetter rebuildParent;
      var caseSensitive = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rebuildParent = setState;
                return SmartSearchGrid<String>(
                  items: const ['Apple', 'APPLE', 'Banana'],
                  searchableFields: (item) => [item],
                  searchConfig: SearchConfiguration(
                    debounceDelay: const Duration(milliseconds: 10),
                    caseSensitive: caseSensitive,
                  ),
                  itemBuilder:
                      (context, item, index, {searchTerms = const []}) {
                        return Text(item);
                      },
                  gridConfig: _gridConfig(),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Case-insensitive search: both Apple and APPLE should match
      await tester.enterText(find.byType(TextField), 'apple');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('APPLE'), findsOneWidget);

      // Switch to case-sensitive
      rebuildParent(() {
        caseSensitive = true;
      });
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      // Now only lowercase 'apple' matches — neither 'Apple' nor 'APPLE'
      expect(find.text('Apple'), findsNothing);
      expect(find.text('APPLE'), findsNothing);
    });

    testWidgets('items change while search is active re-filters', (
      tester,
    ) async {
      late StateSetter rebuildParent;
      var items = const ['Apple', 'Banana', 'Cherry'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rebuildParent = setState;
                return SmartSearchGrid<String>(
                  items: items,
                  searchableFields: (item) => [item],
                  searchConfig: const SearchConfiguration(
                    debounceDelay: Duration(milliseconds: 10),
                  ),
                  itemBuilder:
                      (context, item, index, {searchTerms = const []}) {
                        return Text(item);
                      },
                  gridConfig: _gridConfig(),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Search for 'App' — matches Apple only
      await tester.enterText(find.byType(TextField), 'App');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsNothing);
      expect(find.text('Cherry'), findsNothing);

      // Change items while search is active
      rebuildParent(() {
        items = const ['Appetizer', 'Dragonfruit'];
      });
      await tester.pumpAndSettle();

      // 'Appetizer' matches 'App', 'Dragonfruit' does not
      expect(find.text('Appetizer'), findsOneWidget);
      expect(find.text('Dragonfruit'), findsNothing);
      expect(find.text('Apple'), findsNothing);
    });
  });

  group('SmartSearchGrid — scroll controller swap', () {
    testWidgets('swap moves pagination listener to new controller', (
      tester,
    ) async {
      late StateSetter rebuildParent;
      final scrollA = ScrollController();
      final scrollB = ScrollController();
      addTearDown(() {
        scrollA.dispose();
        scrollB.dispose();
      });

      var activeScroll = scrollA;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rebuildParent = setState;
                return SmartSearchGrid<String>(
                  items: const ['Apple', 'Banana'],
                  searchableFields: (item) => [item],
                  scrollController: activeScroll,
                  itemBuilder:
                      (context, item, index, {searchTerms = const []}) {
                        return Text(item);
                      },
                  gridConfig: _gridConfig(),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Swap scroll controller
      rebuildParent(() {
        activeScroll = scrollB;
      });
      await tester.pumpAndSettle();

      // No exceptions thrown — widget handled the swap
      expect(find.text('Apple'), findsOneWidget);
    });

    testWidgets('external to null creates internal', (tester) async {
      late StateSetter rebuildParent;
      final externalScroll = ScrollController();
      addTearDown(externalScroll.dispose);

      ScrollController? activeScroll = externalScroll;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rebuildParent = setState;
                return SmartSearchGrid<String>(
                  items: const ['Apple'],
                  searchableFields: (item) => [item],
                  scrollController: activeScroll,
                  itemBuilder:
                      (context, item, index, {searchTerms = const []}) {
                        return Text(item);
                      },
                  gridConfig: _gridConfig(),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Remove external scroll controller — widget should create internal
      rebuildParent(() {
        activeScroll = null;
      });
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsOneWidget);
    });

    testWidgets('old controller listeners removed on swap', (tester) async {
      late StateSetter rebuildParent;
      final scrollA = ScrollController();
      final scrollB = ScrollController();
      addTearDown(() {
        scrollA.dispose();
        scrollB.dispose();
      });

      var activeScroll = scrollA;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rebuildParent = setState;
                return SmartSearchGrid<String>(
                  items: const ['Apple'],
                  searchableFields: (item) => [item],
                  scrollController: activeScroll,
                  searchConfig: const SearchConfiguration(
                    closeKeyboardOnScroll: true,
                  ),
                  itemBuilder:
                      (context, item, index, {searchTerms = const []}) {
                        return Text(item);
                      },
                  gridConfig: _gridConfig(),
                  paginationConfig: const PaginationConfiguration(),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Swap to scrollB
      rebuildParent(() {
        activeScroll = scrollB;
      });
      await tester.pumpAndSettle();

      // scrollA should have no listeners from the widget anymore
      // notifyListeners on old controller should not cause issues
      scrollA.notifyListeners();
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsOneWidget);
    });
  });

  group('SmartSearchGrid — SearchTriggerMode.onSubmit', () {
    testWidgets('typing does not filter items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchGrid<String>(
              items: const ['Apple', 'Banana', 'Cherry'],
              searchableFields: (item) => [item],
              searchConfig: const SearchConfiguration(
                debounceDelay: Duration(milliseconds: 10),
                triggerMode: SearchTriggerMode.onSubmit,
              ),
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return Text(item);
              },
              gridConfig: _gridConfig(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'App');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      // All items still visible — search hasn't been submitted
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Cherry'), findsOneWidget);
    });

    testWidgets('submitting does filter items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchGrid<String>(
              items: const ['Apple', 'Banana', 'Cherry'],
              searchableFields: (item) => [item],
              searchConfig: const SearchConfiguration(
                debounceDelay: Duration(milliseconds: 10),
                triggerMode: SearchTriggerMode.onSubmit,
              ),
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return Text(item);
              },
              gridConfig: _gridConfig(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'App');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      // Submit the search
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsNothing);
    });

    testWidgets('search icon button appears in onSubmit mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchGrid<String>(
              items: const ['Apple'],
              searchableFields: (item) => [item],
              searchConfig: const SearchConfiguration(
                triggerMode: SearchTriggerMode.onSubmit,
              ),
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return Text(item);
              },
              gridConfig: _gridConfig(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.search), findsAtLeastNWidgets(1));
    });
  });

  group('SmartSearchGrid — GridConfiguration passthrough', () {
    testWidgets('padding creates SliverPadding in tree', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchGrid<String>(
              items: const ['Apple'],
              searchableFields: (item) => [item],
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return Text(item);
              },
              gridConfig: GridConfiguration(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 5.0,
                ),
                padding: const EdgeInsets.all(16.0),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SliverPadding), findsOneWidget);
    });

    testWidgets('physics forwarded to CustomScrollView', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchGrid<String>(
              items: const ['Apple'],
              searchableFields: (item) => [item],
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return Text(item);
              },
              gridConfig: GridConfiguration(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 5.0,
                ),
                physics: const NeverScrollableScrollPhysics(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scrollView = tester.widget<CustomScrollView>(
        find.byType(CustomScrollView),
      );
      expect(scrollView.physics, isA<NeverScrollableScrollPhysics>());
    });

    testWidgets('shrinkWrap forwarded to CustomScrollView', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchGrid<String>(
              items: const ['Apple'],
              searchableFields: (item) => [item],
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return Text(item);
              },
              gridConfig: GridConfiguration(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 5.0,
                ),
                shrinkWrap: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scrollView = tester.widget<CustomScrollView>(
        find.byType(CustomScrollView),
      );
      expect(scrollView.shrinkWrap, true);
    });

    testWidgets('reverse forwarded to CustomScrollView', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchGrid<String>(
              items: const ['Apple'],
              searchableFields: (item) => [item],
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return Text(item);
              },
              gridConfig: GridConfiguration(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 5.0,
                ),
                reverse: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scrollView = tester.widget<CustomScrollView>(
        find.byType(CustomScrollView),
      );
      expect(scrollView.reverse, true);
    });

    testWidgets('cacheExtent forwarded to CustomScrollView', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchGrid<String>(
              items: const ['Apple'],
              searchableFields: (item) => [item],
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return Text(item);
              },
              gridConfig: GridConfiguration(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 5.0,
                ),
                cacheExtent: 500.0,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scrollView = tester.widget<CustomScrollView>(
        find.byType(CustomScrollView),
      );
      expect(scrollView.cacheExtent, 500.0);
    });
  });

  group('SmartSearchGrid — a11y announcements', () {
    testWidgets('announces result count after search', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchGrid<String>(
              items: const ['Apple', 'Banana', 'Cherry'],
              searchableFields: (item) => [item],
              searchConfig: const SearchConfiguration(
                debounceDelay: Duration(milliseconds: 10),
              ),
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return Text(item);
              },
              gridConfig: _gridConfig(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Clear any initial announcements
      tester.takeAnnouncements();

      await tester.enterText(find.byType(TextField), 'App');
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pump();

      final announcements = tester.takeAnnouncements();
      expect(announcements, isNotEmpty);
      expect(announcements.last.message, '1 result found');

      handle.dispose();
    });

    testWidgets('custom announcement builder', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchGrid<String>(
              items: const ['Apple', 'Banana', 'Cherry'],
              searchableFields: (item) => [item],
              searchConfig: const SearchConfiguration(
                debounceDelay: Duration(milliseconds: 10),
              ),
              accessibilityConfig: AccessibilityConfiguration(
                resultsAnnouncementBuilder: (count) => '$count Ergebnis',
              ),
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return Text(item);
              },
              gridConfig: _gridConfig(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      tester.takeAnnouncements();

      await tester.enterText(find.byType(TextField), 'App');
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pump();

      final announcements = tester.takeAnnouncements();
      expect(announcements, isNotEmpty);
      expect(announcements.last.message, '1 Ergebnis');

      handle.dispose();
    });

    testWidgets('no announcements when searchSemanticsEnabled: false', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchGrid<String>(
              items: const ['Apple', 'Banana', 'Cherry'],
              searchableFields: (item) => [item],
              searchConfig: const SearchConfiguration(
                debounceDelay: Duration(milliseconds: 10),
              ),
              accessibilityConfig: const AccessibilityConfiguration(
                searchSemanticsEnabled: false,
              ),
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return Text(item);
              },
              gridConfig: _gridConfig(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      tester.takeAnnouncements();

      await tester.enterText(find.byType(TextField), 'App');
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pump();

      final announcements = tester.takeAnnouncements();
      expect(announcements, isEmpty);
    });

    testWidgets(
      'enabling searchSemanticsEnabled mid-lifecycle starts announcements',
      (tester) async {
        final handle = tester.ensureSemantics();
        late StateSetter rebuildParent;
        var semanticsEnabled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  rebuildParent = setState;
                  return SmartSearchGrid<String>(
                    items: const ['Apple', 'Banana', 'Cherry'],
                    searchableFields: (item) => [item],
                    searchConfig: const SearchConfiguration(
                      debounceDelay: Duration(milliseconds: 10),
                    ),
                    accessibilityConfig: AccessibilityConfiguration(
                      searchSemanticsEnabled: semanticsEnabled,
                    ),
                    itemBuilder:
                        (context, item, index, {searchTerms = const []}) {
                          return Text(item);
                        },
                    gridConfig: _gridConfig(),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        tester.takeAnnouncements();

        // Search with semantics disabled — no announcement
        await tester.enterText(find.byType(TextField), 'App');
        await tester.pump(const Duration(milliseconds: 20));
        await tester.pump();

        var announcements = tester.takeAnnouncements();
        expect(announcements, isEmpty);

        // Enable semantics mid-lifecycle
        rebuildParent(() {
          semanticsEnabled = true;
        });
        await tester.pumpAndSettle();
        tester.takeAnnouncements();

        // New search should trigger announcement
        await tester.enterText(find.byType(TextField), 'Ban');
        await tester.pump(const Duration(milliseconds: 20));
        await tester.pump();

        announcements = tester.takeAnnouncements();
        expect(announcements, isNotEmpty);
        expect(announcements.last.message, '1 result found');

        handle.dispose();
      },
    );
  });

  group('SmartSearchGrid — pagination load-more', () {
    testWidgets('load-more indicator appears when isLoadingMore', (
      tester,
    ) async {
      final ctrl = SmartSearchController<String>(
        searchableFields: (item) => [item],
      );
      addTearDown(() {
        if (!ctrl.isDisposed) ctrl.dispose();
      });

      final loadMoreCompleter = Completer<List<String>>();
      ctrl.setAsyncLoader((query, {int page = 0, int pageSize = 20}) {
        if (page > 0) return loadMoreCompleter.future;
        return Future.value(['Apple', 'Banana']);
      });
      ctrl.setItems(['Apple', 'Banana']);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchGrid<String>.controller(
              controller: ctrl,
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return Text(item);
              },
              gridConfig: _gridConfig(),
              paginationConfig: const PaginationConfiguration(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Trigger load more
      ctrl.loadMore();
      await tester.pump();

      // Load-more widget should appear (SliverToBoxAdapter with DefaultLoadMoreWidget)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      loadMoreCompleter.complete(const ['Cherry']);
      await tester.pumpAndSettle();
    });

    testWidgets('load-more is full-width SliverToBoxAdapter', (tester) async {
      final ctrl = SmartSearchController<String>(
        searchableFields: (item) => [item],
      );
      addTearDown(() {
        if (!ctrl.isDisposed) ctrl.dispose();
      });

      final loadMoreCompleter = Completer<List<String>>();
      ctrl.setAsyncLoader((query, {int page = 0, int pageSize = 20}) {
        if (page > 0) return loadMoreCompleter.future;
        return Future.value(['Apple']);
      });
      ctrl.setItems(['Apple']);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchGrid<String>.controller(
              controller: ctrl,
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return Text(item);
              },
              gridConfig: _gridConfig(),
              paginationConfig: const PaginationConfiguration(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      ctrl.loadMore();
      await tester.pump();

      // The load-more is in a SliverToBoxAdapter (not a grid cell)
      expect(find.byType(SliverToBoxAdapter), findsOneWidget);

      loadMoreCompleter.complete(const ['Banana']);
      await tester.pumpAndSettle();
    });
  });
  group('SmartSearchGrid - shrinkWrap', () {
    // -----------------------------------------------------------------------
    // Widget tests
    // -----------------------------------------------------------------------
    testWidgets(
      'shrinkWrap: true renders without overflow in unbounded height',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    const Text('Above'),
                    SmartSearchGrid<String>(
                      searchableFields: (item) => [item],
                      items: const ['Apple', 'Banana', 'Cherry'],
                      itemBuilder:
                          (context, item, index, {searchTerms = const []}) =>
                              ListTile(title: Text(item)),
                      gridConfig: const GridConfiguration(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 1,
                        ),
                        shrinkWrap: true,
                      ),
                    ),
                    const Text('Below'),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Apple'), findsOneWidget);
        expect(find.text('Below'), findsOneWidget);
      },
    );
  });
}
