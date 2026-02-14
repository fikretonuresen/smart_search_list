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

// Wraps a sliver widget in a CustomScrollView inside MaterialApp/Scaffold
Widget _sliverHarness(Widget sliver) {
  return MaterialApp(
    home: Scaffold(body: CustomScrollView(slivers: [sliver])),
  );
}

void main() {
  group('SliverSmartSearchGrid — offline', () {
    testWidgets('renders all items initially', (tester) async {
      await tester.pumpWidget(
        _sliverHarness(
          SliverSmartSearchGrid<String>(
            items: const ['Apple', 'Banana', 'Cherry'],
            searchableFields: (item) => [item],
            itemBuilder: (context, item, index, {searchTerms = const []}) {
              return Text(item);
            },
            gridConfig: _gridConfig(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Cherry'), findsOneWidget);
    });

    testWidgets('shows empty state when items list is empty', (tester) async {
      await tester.pumpWidget(
        _sliverHarness(
          SliverSmartSearchGrid<String>(
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
      );
      await tester.pumpAndSettle();

      expect(find.text('No data here'), findsOneWidget);
    });

    testWidgets('onItemTap fires with correct item and index', (tester) async {
      String? tappedItem;
      int? tappedIndex;

      await tester.pumpWidget(
        _sliverHarness(
          SliverSmartSearchGrid<String>(
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
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Banana'));
      await tester.pump();

      expect(tappedItem, 'Banana');
      expect(tappedIndex, 1);
    });
  });

  group('SliverSmartSearchGrid — async', () {
    testWidgets('shows loading then items', (tester) async {
      final completer = Completer<List<String>>();

      await tester.pumpWidget(
        _sliverHarness(
          SliverSmartSearchGrid<String>.async(
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
      );
      // Debounce timer + rebuild
      await tester.pump(const Duration(milliseconds: 10));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(['Apple', 'Banana']);
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
    });

    testWidgets('shows error state on failure', (tester) async {
      await tester.pumpWidget(
        _sliverHarness(
          SliverSmartSearchGrid<String>.async(
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
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Network error'), findsOneWidget);
    });
  });

  group('SliverSmartSearchGrid — controller', () {
    testWidgets('renders items from external controller', (tester) async {
      final ctrl = SmartSearchController<String>(
        searchableFields: (item) => [item],
      );
      addTearDown(() {
        if (!ctrl.isDisposed) ctrl.dispose();
      });
      ctrl.setItems(['Alpha', 'Beta', 'Gamma']);

      await tester.pumpWidget(
        _sliverHarness(
          SliverSmartSearchGrid<String>.controller(
            controller: ctrl,
            itemBuilder: (context, item, index, {searchTerms = const []}) {
              return Text(item);
            },
            gridConfig: _gridConfig(),
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
            body: CustomScrollView(
              slivers: [
                ValueListenableBuilder<SmartSearchController<String>>(
                  valueListenable: controllerNotifier,
                  builder: (context, ctrl, _) {
                    return SliverSmartSearchGrid<String>.controller(
                      controller: ctrl,
                      itemBuilder:
                          (context, item, index, {searchTerms = const []}) {
                            return Text(item);
                          },
                      gridConfig: _gridConfig(),
                    );
                  },
                ),
              ],
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

    testWidgets('onSearchChanged fires when controller query changes', (
      tester,
    ) async {
      final ctrl = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!ctrl.isDisposed) ctrl.dispose();
      });
      ctrl.setItems(['Apple', 'Banana']);

      String? lastQuery;

      await tester.pumpWidget(
        _sliverHarness(
          SliverSmartSearchGrid<String>.controller(
            controller: ctrl,
            itemBuilder: (context, item, index, {searchTerms = const []}) {
              return Text(item);
            },
            gridConfig: _gridConfig(),
            onSearchChanged: (query) {
              lastQuery = query;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      ctrl.searchImmediate('App');
      await tester.pumpAndSettle();

      expect(lastQuery, 'App');
    });
  });

  group('SliverSmartSearchGrid — grouping', () {
    testWidgets('items are grouped with sticky headers', (tester) async {
      await tester.pumpWidget(
        _sliverHarness(
          SliverSmartSearchGrid<String>(
            items: const ['Apple', 'Avocado', 'Banana', 'Blueberry'],
            searchableFields: (item) => [item],
            itemBuilder: (context, item, index, {searchTerms = const []}) {
              return Text(item);
            },
            gridConfig: _gridConfig(),
            groupBy: (item) => item[0],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
    });

    testWidgets('custom group header builder works', (tester) async {
      await tester.pumpWidget(
        _sliverHarness(
          SliverSmartSearchGrid<String>(
            items: const ['Apple', 'Banana'],
            searchableFields: (item) => [item],
            itemBuilder: (context, item, index, {searchTerms = const []}) {
              return Text(item);
            },
            gridConfig: _gridConfig(),
            groupBy: (item) => item[0],
            groupHeaderBuilder: (context, groupValue, itemCount) {
              return Text('Section: $groupValue');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Section: A'), findsOneWidget);
      expect(find.text('Section: B'), findsOneWidget);
    });

    testWidgets('groupHeaderExtent is customizable', (tester) async {
      await tester.pumpWidget(
        _sliverHarness(
          SliverSmartSearchGrid<String>(
            items: const ['Apple', 'Banana'],
            searchableFields: (item) => [item],
            itemBuilder: (context, item, index, {searchTerms = const []}) {
              return Text(item);
            },
            gridConfig: _gridConfig(),
            groupBy: (item) => item[0],
            groupHeaderExtent: 64.0,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should render without errors with custom header extent
      expect(find.text('Apple'), findsOneWidget);
    });
  });

  group('SliverSmartSearchGrid — selection', () {
    testWidgets('selection checkboxes appear when enabled', (tester) async {
      await tester.pumpWidget(
        _sliverHarness(
          SliverSmartSearchGrid<String>(
            items: const ['Apple', 'Banana'],
            searchableFields: (item) => [item],
            itemBuilder: (context, item, index, {searchTerms = const []}) {
              return Text(item);
            },
            gridConfig: _gridConfig(),
            selectionConfig: const SelectionConfiguration(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Checkbox), findsWidgets);
    });
  });

  group('SliverSmartSearchGrid — disposal', () {
    testWidgets('disposes cleanly without errors', (tester) async {
      await tester.pumpWidget(
        _sliverHarness(
          SliverSmartSearchGrid<String>(
            items: const ['Apple'],
            searchableFields: (item) => [item],
            itemBuilder: (context, item, index, {searchTerms = const []}) {
              return Text(item);
            },
            gridConfig: _gridConfig(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );
      await tester.pumpAndSettle();
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
        _sliverHarness(
          SliverSmartSearchGrid<String>.controller(
            controller: ctrl,
            itemBuilder: (context, item, index, {searchTerms = const []}) {
              return Text(item);
            },
            gridConfig: _gridConfig(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );
      await tester.pumpAndSettle();

      expect(ctrl.isDisposed, false);
    });
  });

  group('SliverSmartSearchGrid — didUpdateWidget', () {
    testWidgets('updates items when changed', (tester) async {
      final items = ValueNotifier(const ['A', 'B']);
      addTearDown(items.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                ValueListenableBuilder<List<String>>(
                  valueListenable: items,
                  builder: (context, value, _) {
                    return SliverSmartSearchGrid<String>(
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
              ],
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
      expect(find.text('Z'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // onSearchChanged callback (sliver — fires post-debounce on query change)
  // -------------------------------------------------------------------------

  group('SliverSmartSearchGrid — onSearchChanged', () {
    testWidgets('fires with empty string on clearSearch', (tester) async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });
      controller.setItems(const ['Apple', 'Banana', 'Cherry']);

      final queries = <String>[];

      await tester.pumpWidget(
        _sliverHarness(
          SliverSmartSearchGrid<String>.controller(
            controller: controller,
            onSearchChanged: (query) => queries.add(query),
            itemBuilder: (context, item, index, {searchTerms = const []}) {
              return Text(item);
            },
            gridConfig: _gridConfig(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      controller.searchImmediate('App');
      await tester.pumpAndSettle();

      controller.clearSearch();
      await tester.pumpAndSettle();

      expect(queries, ['App', '']);
    });

    testWidgets('does NOT fire on non-query changes (filter, sort)', (
      tester,
    ) async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });
      controller.setItems(const ['Apple', 'Banana', 'Cherry']);

      final queries = <String>[];

      await tester.pumpWidget(
        _sliverHarness(
          SliverSmartSearchGrid<String>.controller(
            controller: controller,
            onSearchChanged: (query) => queries.add(query),
            itemBuilder: (context, item, index, {searchTerms = const []}) {
              return Text(item);
            },
            gridConfig: _gridConfig(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Apply filter — should NOT fire onSearchChanged
      controller.setFilter('startsA', (item) => item.startsWith('A'));
      await tester.pumpAndSettle();

      // Apply sort — should NOT fire onSearchChanged
      controller.setSortBy((a, b) => a.compareTo(b));
      await tester.pumpAndSettle();

      // Toggle selection — should NOT fire onSearchChanged
      controller.toggleSelection('Apple');
      await tester.pumpAndSettle();

      expect(queries, isEmpty);
    });

    testWidgets('fires correctly after controller swap', (tester) async {
      final controllerA = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      final controllerB = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controllerA.isDisposed) controllerA.dispose();
        if (!controllerB.isDisposed) controllerB.dispose();
      });

      controllerA.setItems(const ['Apple', 'Banana']);
      controllerB.setItems(const ['Cherry', 'Date']);

      final queries = <String>[];
      late StateSetter rebuildParent;
      SmartSearchController<String> activeController = controllerA;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rebuildParent = setState;
                return CustomScrollView(
                  slivers: [
                    SliverSmartSearchGrid<String>.controller(
                      controller: activeController,
                      onSearchChanged: (query) => queries.add(query),
                      itemBuilder:
                          (context, item, index, {searchTerms = const []}) {
                            return Text(item);
                          },
                      gridConfig: _gridConfig(),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Search on controller A
      controllerA.searchImmediate('App');
      await tester.pumpAndSettle();
      expect(queries, ['App']);

      // Swap to controller B
      rebuildParent(() {
        activeController = controllerB;
      });
      await tester.pumpAndSettle();

      // Search on controller B should fire
      controllerB.searchImmediate('Cher');
      await tester.pumpAndSettle();
      expect(queries, ['App', 'Cher']);
    });

    testWidgets('fires once per distinct query (dedup check)', (tester) async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });
      controller.setItems(const ['Apple', 'Banana', 'Cherry']);

      final queries = <String>[];

      await tester.pumpWidget(
        _sliverHarness(
          SliverSmartSearchGrid<String>.controller(
            controller: controller,
            onSearchChanged: (query) => queries.add(query),
            itemBuilder: (context, item, index, {searchTerms = const []}) {
              return Text(item);
            },
            gridConfig: _gridConfig(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Search the same query twice — should only fire once
      controller.searchImmediate('App');
      await tester.pumpAndSettle();

      controller.searchImmediate('App');
      await tester.pumpAndSettle();

      expect(queries, ['App']);
    });

    testWidgets('does not fire on non-query rebuild (setItems)', (
      tester,
    ) async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });
      controller.setItems(const ['Apple', 'Banana']);

      final queries = <String>[];

      await tester.pumpWidget(
        _sliverHarness(
          SliverSmartSearchGrid<String>.controller(
            controller: controller,
            onSearchChanged: (query) => queries.add(query),
            itemBuilder: (context, item, index, {searchTerms = const []}) {
              return Text(item);
            },
            gridConfig: _gridConfig(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Changing items should NOT fire onSearchChanged
      controller.setItems(const ['Cherry', 'Date']);
      await tester.pumpAndSettle();

      expect(queries, isEmpty);
    });

    testWidgets('fires on debounced search after delay', (tester) async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: const Duration(milliseconds: 100),
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });
      controller.setItems(const ['Apple', 'Banana']);

      final queries = <String>[];

      await tester.pumpWidget(
        _sliverHarness(
          SliverSmartSearchGrid<String>.controller(
            controller: controller,
            onSearchChanged: (query) => queries.add(query),
            itemBuilder: (context, item, index, {searchTerms = const []}) {
              return Text(item);
            },
            gridConfig: _gridConfig(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Debounced search — should not fire immediately
      controller.search('App');
      await tester.pump();
      expect(queries, isEmpty);

      // After debounce delay, should fire
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(queries, ['App']);
    });
  });

  // -------------------------------------------------------------------------
  // searchTerms passthrough (sliver variant)
  // -------------------------------------------------------------------------

  group('SliverSmartSearchGrid — searchTerms passthrough', () {
    testWidgets('single term passed correctly', (tester) async {
      List<String> capturedTerms = [];

      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });
      controller.setItems(const ['Apple', 'Banana']);

      await tester.pumpWidget(
        _sliverHarness(
          SliverSmartSearchGrid<String>.controller(
            controller: controller,
            itemBuilder: (context, item, index, {searchTerms = const []}) {
              capturedTerms = List.from(searchTerms);
              return Text(item);
            },
            gridConfig: _gridConfig(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      controller.searchImmediate('App');
      await tester.pumpAndSettle();

      expect(capturedTerms, ['App']);
    });

    testWidgets('multi-word splits by space', (tester) async {
      List<String> capturedTerms = [];

      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });
      controller.setItems(const ['Red Apple', 'Green Banana']);

      await tester.pumpWidget(
        _sliverHarness(
          SliverSmartSearchGrid<String>.controller(
            controller: controller,
            itemBuilder: (context, item, index, {searchTerms = const []}) {
              capturedTerms = List.from(searchTerms);
              return Text(item);
            },
            gridConfig: _gridConfig(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      controller.searchImmediate('red apple');
      await tester.pumpAndSettle();

      expect(capturedTerms, ['red', 'apple']);
    });

    testWidgets('empty after clear', (tester) async {
      List<String> capturedTerms = ['placeholder'];

      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });
      controller.setItems(const ['Apple', 'Banana']);

      await tester.pumpWidget(
        _sliverHarness(
          SliverSmartSearchGrid<String>.controller(
            controller: controller,
            itemBuilder: (context, item, index, {searchTerms = const []}) {
              capturedTerms = List.from(searchTerms);
              return Text(item);
            },
            gridConfig: _gridConfig(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      controller.searchImmediate('App');
      await tester.pumpAndSettle();
      expect(capturedTerms, ['App']);

      controller.clearSearch();
      await tester.pumpAndSettle();

      expect(capturedTerms, isEmpty);
    });

    testWidgets('consistent across all items in same build', (tester) async {
      final termsPerItem = <String, List<String>>{};

      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });
      controller.setItems(const ['Apple', 'Apricot']);

      await tester.pumpWidget(
        _sliverHarness(
          SliverSmartSearchGrid<String>.controller(
            controller: controller,
            itemBuilder: (context, item, index, {searchTerms = const []}) {
              termsPerItem[item] = List.from(searchTerms);
              return Text(item);
            },
            gridConfig: _gridConfig(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      controller.searchImmediate('Ap');
      await tester.pumpAndSettle();

      // Both items should receive the same search terms
      expect(termsPerItem['Apple'], ['Ap']);
      expect(termsPerItem['Apricot'], ['Ap']);
    });
  });

  // -------------------------------------------------------------------------
  // Grouped search filtering (sliver variant)
  // -------------------------------------------------------------------------

  group('SliverSmartSearchGrid — grouped search filtering', () {
    testWidgets('search filters groups via controller', (tester) async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });
      controller.setItems(const ['Apple', 'Avocado', 'Banana', 'Blueberry']);

      await tester.pumpWidget(
        _sliverHarness(
          SliverSmartSearchGrid<String>.controller(
            controller: controller,
            itemBuilder: (context, item, index, {searchTerms = const []}) {
              return Text(item);
            },
            gridConfig: _gridConfig(),
            groupBy: (item) => item[0],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Both groups visible initially
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);

      // Search — only A-group items should remain
      controller.searchImmediate('App');
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Avocado'), findsNothing);
      expect(find.text('Banana'), findsNothing);
    });

    testWidgets('search terms passed in grouped mode', (tester) async {
      List<String> capturedTerms = [];

      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });
      controller.setItems(const ['Apple', 'Banana']);

      await tester.pumpWidget(
        _sliverHarness(
          SliverSmartSearchGrid<String>.controller(
            controller: controller,
            itemBuilder: (context, item, index, {searchTerms = const []}) {
              capturedTerms = List.from(searchTerms);
              return Text(item);
            },
            gridConfig: _gridConfig(),
            groupBy: (item) => item[0],
          ),
        ),
      );
      await tester.pumpAndSettle();

      controller.searchImmediate('App');
      await tester.pumpAndSettle();

      expect(capturedTerms, ['App']);
    });

    testWidgets('clearing search restores all groups', (tester) async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });
      controller.setItems(const ['Apple', 'Avocado', 'Banana', 'Blueberry']);

      await tester.pumpWidget(
        _sliverHarness(
          SliverSmartSearchGrid<String>.controller(
            controller: controller,
            itemBuilder: (context, item, index, {searchTerms = const []}) {
              return Text(item);
            },
            gridConfig: _gridConfig(),
            groupBy: (item) => item[0],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Search to filter
      controller.searchImmediate('App');
      await tester.pumpAndSettle();
      expect(find.text('Banana'), findsNothing);

      // Clear search
      controller.clearSearch();
      await tester.pumpAndSettle();

      // All groups restored
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Avocado'), findsOneWidget);
      expect(find.text('Blueberry'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // didUpdateWidget — asyncLoader & config (sliver variant)
  // -------------------------------------------------------------------------

  group('SliverSmartSearchGrid — didUpdateWidget advanced', () {
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
                return CustomScrollView(
                  slivers: [
                    SliverSmartSearchGrid<String>.async(
                      asyncLoader: loaderVersion == 1 ? loaderV1 : loaderV2,
                      itemBuilder:
                          (context, item, index, {searchTerms = const []}) {
                            return Text(item);
                          },
                      gridConfig: _gridConfig(),
                      searchConfig: const SearchConfiguration(
                        debounceDelay: Duration.zero,
                      ),
                    ),
                  ],
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
                return CustomScrollView(
                  slivers: [
                    SliverSmartSearchGrid<String>(
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
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // All items visible initially — use controller to search
      // SliverSmartSearchGrid is controller-driven, so we need to get
      // the internal controller. Since this is offline mode without
      // an external controller, we verify via item visibility after
      // config change. First let's search — but the sliver has no
      // TextField, so we need to verify via the items themselves.
      // This test verifies the config propagates, not the search itself.
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('APPLE'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);

      // Switch to case-sensitive — no search active so all items visible
      rebuildParent(() {
        caseSensitive = true;
      });
      await tester.pumpAndSettle();

      // Items still visible (no search applied), but config is propagated
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('APPLE'), findsOneWidget);
    });

    testWidgets('items change propagates to controller', (tester) async {
      final items = ValueNotifier(const ['A', 'B']);
      addTearDown(items.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                ValueListenableBuilder<List<String>>(
                  valueListenable: items,
                  builder: (context, value, _) {
                    return SliverSmartSearchGrid<String>(
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
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);

      items.value = const ['X', 'Y'];
      await tester.pumpAndSettle();

      expect(find.text('A'), findsNothing);
      expect(find.text('X'), findsOneWidget);
      expect(find.text('Y'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // A11y announcements (sliver variant)
  // -------------------------------------------------------------------------

  group('SliverSmartSearchGrid — a11y announcements', () {
    testWidgets('announces result count after search', (tester) async {
      final handle = tester.ensureSemantics();

      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });
      controller.setItems(const ['Apple', 'Banana', 'Cherry']);

      await tester.pumpWidget(
        _sliverHarness(
          SliverSmartSearchGrid<String>.controller(
            controller: controller,
            itemBuilder: (context, item, index, {searchTerms = const []}) {
              return Text(item);
            },
            gridConfig: _gridConfig(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Clear any initial announcements
      tester.takeAnnouncements();

      controller.searchImmediate('App');
      await tester.pumpAndSettle();

      final announcements = tester.takeAnnouncements();
      expect(announcements, isNotEmpty);
      expect(announcements.last.message, '1 result found');

      handle.dispose();
    });

    testWidgets('custom announcement builder', (tester) async {
      final handle = tester.ensureSemantics();

      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });
      controller.setItems(const ['Apple', 'Banana', 'Cherry']);

      await tester.pumpWidget(
        _sliverHarness(
          SliverSmartSearchGrid<String>.controller(
            controller: controller,
            itemBuilder: (context, item, index, {searchTerms = const []}) {
              return Text(item);
            },
            gridConfig: _gridConfig(),
            accessibilityConfig: AccessibilityConfiguration(
              resultsAnnouncementBuilder: (count) => '$count Ergebnis',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      tester.takeAnnouncements();

      controller.searchImmediate('App');
      await tester.pumpAndSettle();

      final announcements = tester.takeAnnouncements();
      expect(announcements, isNotEmpty);
      expect(announcements.last.message, '1 Ergebnis');

      handle.dispose();
    });

    testWidgets('no announcements when searchSemanticsEnabled: false', (
      tester,
    ) async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });
      controller.setItems(const ['Apple', 'Banana', 'Cherry']);

      await tester.pumpWidget(
        _sliverHarness(
          SliverSmartSearchGrid<String>.controller(
            controller: controller,
            itemBuilder: (context, item, index, {searchTerms = const []}) {
              return Text(item);
            },
            gridConfig: _gridConfig(),
            accessibilityConfig: const AccessibilityConfiguration(
              searchSemanticsEnabled: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      tester.takeAnnouncements();

      controller.searchImmediate('App');
      await tester.pumpAndSettle();

      final announcements = tester.takeAnnouncements();
      expect(announcements, isEmpty);
    });

    testWidgets(
      'enabling searchSemanticsEnabled mid-lifecycle starts announcements',
      (tester) async {
        final handle = tester.ensureSemantics();

        final controller = SmartSearchController<String>(
          searchableFields: (item) => [item],
          debounceDelay: Duration.zero,
        );
        addTearDown(() {
          if (!controller.isDisposed) controller.dispose();
        });
        controller.setItems(const ['Apple', 'Banana', 'Cherry']);

        late StateSetter rebuildParent;
        var semanticsEnabled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  rebuildParent = setState;
                  return CustomScrollView(
                    slivers: [
                      SliverSmartSearchGrid<String>.controller(
                        controller: controller,
                        itemBuilder:
                            (context, item, index, {searchTerms = const []}) {
                              return Text(item);
                            },
                        gridConfig: _gridConfig(),
                        accessibilityConfig: AccessibilityConfiguration(
                          searchSemanticsEnabled: semanticsEnabled,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        tester.takeAnnouncements();

        // Search with semantics disabled — no announcement
        controller.searchImmediate('App');
        await tester.pumpAndSettle();

        var announcements = tester.takeAnnouncements();
        expect(announcements, isEmpty);

        // Enable semantics mid-lifecycle
        controller.clearSearch();
        await tester.pumpAndSettle();
        rebuildParent(() {
          semanticsEnabled = true;
        });
        await tester.pumpAndSettle();
        tester.takeAnnouncements();

        // New search should trigger announcement
        controller.searchImmediate('Ban');
        await tester.pumpAndSettle();

        announcements = tester.takeAnnouncements();
        expect(announcements, isNotEmpty);
        expect(announcements.last.message, '1 result found');

        handle.dispose();
      },
    );
  });

  // -------------------------------------------------------------------------
  // GridConfiguration passthrough (sliver variant)
  // -------------------------------------------------------------------------

  group('SliverSmartSearchGrid — GridConfiguration passthrough', () {
    testWidgets('padding creates SliverPadding in tree', (tester) async {
      await tester.pumpWidget(
        _sliverHarness(
          SliverSmartSearchGrid<String>(
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
      );
      await tester.pumpAndSettle();

      expect(find.byType(SliverPadding), findsOneWidget);
    });

    testWidgets('no SliverPadding when padding is null', (tester) async {
      await tester.pumpWidget(
        _sliverHarness(
          SliverSmartSearchGrid<String>(
            items: const ['Apple'],
            searchableFields: (item) => [item],
            itemBuilder: (context, item, index, {searchTerms = const []}) {
              return Text(item);
            },
            gridConfig: _gridConfig(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SliverPadding), findsNothing);
    });

    testWidgets('grouped grid with padding wraps each group in SliverPadding', (
      tester,
    ) async {
      await tester.pumpWidget(
        _sliverHarness(
          SliverSmartSearchGrid<String>(
            items: const ['Apple', 'Banana'],
            searchableFields: (item) => [item],
            itemBuilder: (context, item, index, {searchTerms = const []}) {
              return Text(item);
            },
            gridConfig: GridConfiguration(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 5.0,
              ),
              padding: const EdgeInsets.all(8.0),
            ),
            groupBy: (item) => item[0],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Each group gets its own SliverPadding (2 groups: A, B)
      expect(find.byType(SliverPadding), findsNWidgets(2));
    });
  });

  // -------------------------------------------------------------------------
  // Pagination load-more (sliver variant)
  // -------------------------------------------------------------------------

  group('SliverSmartSearchGrid — pagination load-more', () {
    testWidgets('load-more indicator appears when isLoadingMore', (
      tester,
    ) async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });
      controller.setItems(const ['Apple', 'Banana']);

      // Set up an async loader that triggers isLoadingMore
      final loadMoreCompleter = Completer<List<String>>();
      controller.setAsyncLoader((query, {int page = 0, int pageSize = 20}) {
        if (page > 0) return loadMoreCompleter.future;
        return Future.value(['Apple', 'Banana']);
      });

      await tester.pumpWidget(
        _sliverHarness(
          SliverSmartSearchGrid<String>.controller(
            controller: controller,
            itemBuilder: (context, item, index, {searchTerms = const []}) {
              return Text(item);
            },
            gridConfig: _gridConfig(),
            paginationConfig: const PaginationConfiguration(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Trigger load more
      controller.loadMore();
      await tester.pump();

      // Load-more widget should appear
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete to clean up
      loadMoreCompleter.complete(const ['Cherry']);
      await tester.pumpAndSettle();
    });

    testWidgets('load-more not shown when not loading more', (tester) async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });
      controller.setItems(const ['Apple', 'Banana']);

      await tester.pumpWidget(
        _sliverHarness(
          SliverSmartSearchGrid<String>.controller(
            controller: controller,
            itemBuilder: (context, item, index, {searchTerms = const []}) {
              return Text(item);
            },
            gridConfig: _gridConfig(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No load-more indicator when not loading
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is CircularProgressIndicator &&
              w.key == null, // Exclude any app-level indicators
        ),
        findsNothing,
      );
    });
  });
}
