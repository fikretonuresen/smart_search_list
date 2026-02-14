import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_search_list/smart_search_list.dart';

void main() {
  group('SliverSmartSearchList Widget', () {
    // -----------------------------------------------------------------------
    // Basic rendering
    // -----------------------------------------------------------------------

    testWidgets('renders all items in a CustomScrollView', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverSmartSearchList<String>(
                  items: const ['Apple', 'Banana', 'Cherry'],
                  searchableFields: (item) => [item],
                  itemBuilder:
                      (context, item, index, {searchTerms = const []}) {
                        return ListTile(title: Text(item));
                      },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Cherry'), findsOneWidget);
    });

    testWidgets('renders alongside other slivers', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: Text('Header Section')),
                SliverSmartSearchList<String>(
                  items: const ['Apple', 'Banana'],
                  searchableFields: (item) => [item],
                  itemBuilder:
                      (context, item, index, {searchTerms = const []}) {
                        return ListTile(title: Text(item));
                      },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Header Section'), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Search functionality
    // -----------------------------------------------------------------------

    testWidgets('filters items when controller.search() is called', (
      tester,
    ) async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: const Duration(milliseconds: 10),
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setItems(const ['Apple', 'Banana', 'Cherry']);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverSmartSearchList<String>.controller(
                  controller: controller,
                  itemBuilder:
                      (context, item, index, {searchTerms = const []}) {
                        return ListTile(title: Text(item));
                      },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // All items visible initially
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Cherry'), findsOneWidget);

      // Search for 'App'
      controller.search('App');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsNothing);
      expect(find.text('Cherry'), findsNothing);
    });

    testWidgets('filters items with searchImmediate', (tester) async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: const Duration(milliseconds: 300),
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setItems(const ['Apple', 'Banana', 'Cherry']);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverSmartSearchList<String>.controller(
                  controller: controller,
                  itemBuilder:
                      (context, item, index, {searchTerms = const []}) {
                        return ListTile(title: Text(item));
                      },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // searchImmediate bypasses debounce
      controller.searchImmediate('Ban');
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsNothing);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Cherry'), findsNothing);
    });

    testWidgets('clears search and shows all items again', (tester) async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: const Duration(milliseconds: 10),
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setItems(const ['Apple', 'Banana', 'Cherry']);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverSmartSearchList<String>.controller(
                  controller: controller,
                  itemBuilder:
                      (context, item, index, {searchTerms = const []}) {
                        return ListTile(title: Text(item));
                      },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Search to filter
      controller.searchImmediate('Apple');
      await tester.pumpAndSettle();
      expect(find.text('Banana'), findsNothing);

      // Clear search
      controller.clearSearch();
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Cherry'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // _searchTerms caching: verify search terms are passed to itemBuilder
    // -----------------------------------------------------------------------

    testWidgets('passes search terms to itemBuilder correctly', (tester) async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: const Duration(milliseconds: 10),
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      List<String> capturedTerms = [];

      controller.setItems(const ['Apple', 'Banana', 'Cherry']);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverSmartSearchList<String>.controller(
                  controller: controller,
                  itemBuilder:
                      (context, item, index, {searchTerms = const []}) {
                        capturedTerms = searchTerms;
                        return ListTile(title: Text(item));
                      },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No search active - search terms should be empty
      expect(capturedTerms, isEmpty);

      // Search with a single term
      controller.searchImmediate('Apple');
      await tester.pumpAndSettle();

      expect(capturedTerms, ['Apple']);
    });

    testWidgets('splits multi-word search query into separate terms', (
      tester,
    ) async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: const Duration(milliseconds: 10),
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      List<String> capturedTerms = [];

      controller.setItems(const ['red apple', 'green apple', 'red banana']);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverSmartSearchList<String>.controller(
                  controller: controller,
                  itemBuilder:
                      (context, item, index, {searchTerms = const []}) {
                        capturedTerms = List.from(searchTerms);
                        return ListTile(title: Text(item));
                      },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Search with multi-word query
      controller.searchImmediate('red apple');
      await tester.pumpAndSettle();

      // The _searchTerms getter splits by spaces
      expect(capturedTerms, ['red', 'apple']);
    });

    testWidgets(
      'search terms are empty list when query is empty after clearing',
      (tester) async {
        final controller = SmartSearchController<String>(
          searchableFields: (item) => [item],
          debounceDelay: const Duration(milliseconds: 10),
        );
        addTearDown(() {
          if (!controller.isDisposed) controller.dispose();
        });

        List<String> capturedTerms = ['placeholder'];

        controller.setItems(const ['Apple', 'Banana']);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                slivers: [
                  SliverSmartSearchList<String>.controller(
                    controller: controller,
                    itemBuilder:
                        (context, item, index, {searchTerms = const []}) {
                          capturedTerms = List.from(searchTerms);
                          return ListTile(title: Text(item));
                        },
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Search then clear
        controller.searchImmediate('Apple');
        await tester.pumpAndSettle();
        expect(capturedTerms, ['Apple']);

        controller.clearSearch();
        await tester.pumpAndSettle();

        // After clearing, search terms should be empty
        expect(capturedTerms, isEmpty);

        controller.dispose();
      },
    );

    testWidgets(
      'search terms are consistent across all items in the same build',
      (tester) async {
        final controller = SmartSearchController<String>(
          searchableFields: (item) => [item],
          debounceDelay: const Duration(milliseconds: 10),
        );
        addTearDown(() {
          if (!controller.isDisposed) controller.dispose();
        });

        final termsPerItem = <String, List<String>>{};

        controller.setItems(const ['Apple pie', 'Apple juice', 'Apple sauce']);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                slivers: [
                  SliverSmartSearchList<String>.controller(
                    controller: controller,
                    itemBuilder:
                        (context, item, index, {searchTerms = const []}) {
                          termsPerItem[item] = List.from(searchTerms);
                          return ListTile(title: Text(item));
                        },
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        controller.searchImmediate('Apple');
        await tester.pumpAndSettle();

        // All items should receive the same search terms
        for (final entry in termsPerItem.entries) {
          expect(entry.value, [
            'Apple',
          ], reason: '${entry.key} should receive ["Apple"]');
        }

        controller.dispose();
      },
    );

    // -----------------------------------------------------------------------
    // Empty states
    // -----------------------------------------------------------------------

    testWidgets('shows default empty widget when items list is empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverSmartSearchList<String>(
                  items: const [],
                  searchableFields: (item) => [item],
                  itemBuilder:
                      (context, item, index, {searchTerms = const []}) {
                        return ListTile(title: Text(item));
                      },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // DefaultEmptyWidget shows "No items to display"
      expect(find.text('No items to display'), findsOneWidget);
    });

    testWidgets('shows custom emptyStateBuilder when items list is empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverSmartSearchList<String>(
                  items: const [],
                  searchableFields: (item) => [item],
                  emptyStateBuilder: (context) {
                    return const Text('Nothing here');
                  },
                  itemBuilder:
                      (context, item, index, {searchTerms = const []}) {
                        return ListTile(title: Text(item));
                      },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nothing here'), findsOneWidget);
    });

    testWidgets('shows empty search state when search has no results', (
      tester,
    ) async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: const Duration(milliseconds: 10),
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setItems(const ['Apple', 'Banana', 'Cherry']);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverSmartSearchList<String>.controller(
                  controller: controller,
                  emptySearchStateBuilder: (context, query) {
                    return Text('No results for "$query"');
                  },
                  itemBuilder:
                      (context, item, index, {searchTerms = const []}) {
                        return ListTile(title: Text(item));
                      },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Search for something that doesn't exist
      controller.searchImmediate('zzzzz');
      await tester.pumpAndSettle();

      expect(find.text('No results for "zzzzz"'), findsOneWidget);
    });

    testWidgets('shows default empty search widget when no custom builder', (
      tester,
    ) async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: const Duration(milliseconds: 10),
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setItems(const ['Apple', 'Banana']);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverSmartSearchList<String>.controller(
                  controller: controller,
                  itemBuilder:
                      (context, item, index, {searchTerms = const []}) {
                        return ListTile(title: Text(item));
                      },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      controller.searchImmediate('zzzzz');
      await tester.pumpAndSettle();

      // DefaultEmptySearchWidget shows "No results found"
      expect(find.text('No results found'), findsOneWidget);
      expect(find.textContaining('zzzzz'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Grouped rendering
    // -----------------------------------------------------------------------

    testWidgets('groupBy creates sections with headers', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverSmartSearchList<String>(
                  items: const ['Apple', 'Avocado', 'Banana', 'Blueberry'],
                  searchableFields: (item) => [item],
                  groupBy: (item) => item[0], // group by first letter
                  itemBuilder:
                      (context, item, index, {searchTerms = const []}) {
                        return ListTile(title: Text(item));
                      },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Items should appear
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Avocado'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Blueberry'), findsOneWidget);

      // DefaultGroupHeader shows "A (2)" and "B (2)"
      expect(find.text('A (2)'), findsOneWidget);
      expect(find.text('B (2)'), findsOneWidget);
    });

    testWidgets('groupComparator orders groups', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverSmartSearchList<String>(
                  items: const ['Banana', 'Apple', 'Cherry'],
                  searchableFields: (item) => [item],
                  groupBy: (item) => item[0],
                  groupComparator: (a, b) =>
                      (a as String).compareTo(b as String),
                  itemBuilder:
                      (context, item, index, {searchTerms = const []}) {
                        return ListTile(title: Text(item));
                      },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // All items and headers should render
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Cherry'), findsOneWidget);
      expect(find.text('A (1)'), findsOneWidget);
      expect(find.text('B (1)'), findsOneWidget);
      expect(find.text('C (1)'), findsOneWidget);
    });

    testWidgets('custom groupHeaderBuilder is used when provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverSmartSearchList<String>(
                  items: const ['Apple', 'Avocado', 'Banana'],
                  searchableFields: (item) => [item],
                  groupBy: (item) => item[0],
                  groupHeaderBuilder: (context, groupValue, itemCount) {
                    return Container(
                      height: 48,
                      color: Colors.blue,
                      child: Text('Group: $groupValue ($itemCount items)'),
                    );
                  },
                  itemBuilder:
                      (context, item, index, {searchTerms = const []}) {
                        return ListTile(title: Text(item));
                      },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Group: A (2 items)'), findsOneWidget);
      expect(find.text('Group: B (1 items)'), findsOneWidget);
    });

    testWidgets('grouped search filters groups correctly', (tester) async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: const Duration(milliseconds: 10),
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setItems(const ['Apple', 'Avocado', 'Banana', 'Blueberry']);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverSmartSearchList<String>.controller(
                  controller: controller,
                  groupBy: (item) => item[0],
                  itemBuilder:
                      (context, item, index, {searchTerms = const []}) {
                        return ListTile(title: Text(item));
                      },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially all groups visible
      expect(find.text('A (2)'), findsOneWidget);
      expect(find.text('B (2)'), findsOneWidget);

      // Search for 'Apple' - only items matching should remain
      controller.searchImmediate('Apple');
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Avocado'), findsNothing);
      expect(find.text('Banana'), findsNothing);
      expect(find.text('Blueberry'), findsNothing);

      // Only the A group should remain with 1 item
      expect(find.text('A (1)'), findsOneWidget);
      expect(find.text('B (2)'), findsNothing);
    });

    testWidgets('search terms are passed in grouped mode', (tester) async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: const Duration(milliseconds: 10),
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      List<String> capturedTerms = [];

      controller.setItems(const ['Apple', 'Avocado', 'Banana']);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverSmartSearchList<String>.controller(
                  controller: controller,
                  groupBy: (item) => item[0],
                  itemBuilder:
                      (context, item, index, {searchTerms = const []}) {
                        capturedTerms = List.from(searchTerms);
                        return ListTile(title: Text(item));
                      },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      controller.searchImmediate('A');
      await tester.pumpAndSettle();

      // Search terms should be passed even in grouped mode
      expect(capturedTerms, ['A']);
    });

    // -----------------------------------------------------------------------
    // Error states
    // -----------------------------------------------------------------------

    testWidgets('shows error state on async error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverSmartSearchList<String>.async(
                  asyncLoader:
                      (query, {int page = 0, int pageSize = 20}) async {
                        throw Exception('Network failure');
                      },
                  searchConfig: const SearchConfiguration(
                    debounceDelay: Duration(milliseconds: 10),
                  ),
                  errorStateBuilder: (context, error, onRetry) {
                    return Text('Error: $error');
                  },
                  itemBuilder:
                      (context, item, index, {searchTerms = const []}) {
                        return ListTile(title: Text(item));
                      },
                ),
              ],
            ),
          ),
        ),
      );

      // Wait for debounce + async loader to fire and fail
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(find.textContaining('Network failure'), findsOneWidget);
    });

    testWidgets('shows default error widget when no custom builder', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverSmartSearchList<String>.async(
                  asyncLoader:
                      (query, {int page = 0, int pageSize = 20}) async {
                        throw Exception('Server error');
                      },
                  searchConfig: const SearchConfiguration(
                    debounceDelay: Duration(milliseconds: 10),
                  ),
                  itemBuilder:
                      (context, item, index, {searchTerms = const []}) {
                        return ListTile(title: Text(item));
                      },
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      // DefaultErrorWidget shows "Something went wrong" and "Try again"
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Loading state
    // -----------------------------------------------------------------------

    testWidgets('shows loading state during initial async load', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverSmartSearchList<String>.async(
                  asyncLoader:
                      (query, {int page = 0, int pageSize = 20}) async {
                        await Future.delayed(const Duration(milliseconds: 500));
                        return ['Item 1'];
                      },
                  searchConfig: const SearchConfiguration(
                    debounceDelay: Duration(milliseconds: 10),
                  ),
                  loadingStateBuilder: (context) {
                    return const Text('Loading...');
                  },
                  itemBuilder:
                      (context, item, index, {searchTerms = const []}) {
                        return ListTile(title: Text(item));
                      },
                ),
              ],
            ),
          ),
        ),
      );

      // After debounce fires but before async completes, loading state shows
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();

      expect(find.text('Loading...'), findsOneWidget);

      // Advance time to let the async loader complete and drain pending timers
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
    });

    testWidgets('shows default loading widget when no custom builder', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverSmartSearchList<String>.async(
                  asyncLoader:
                      (query, {int page = 0, int pageSize = 20}) async {
                        await Future.delayed(const Duration(milliseconds: 500));
                        return ['Item 1'];
                      },
                  searchConfig: const SearchConfiguration(
                    debounceDelay: Duration(milliseconds: 10),
                  ),
                  itemBuilder:
                      (context, item, index, {searchTerms = const []}) {
                        return ListTile(title: Text(item));
                      },
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();

      // DefaultLoadingWidget uses CircularProgressIndicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Advance time to let the async loader complete and drain pending timers
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
    });

    // -----------------------------------------------------------------------
    // onItemTap
    // -----------------------------------------------------------------------

    testWidgets('onItemTap fires with correct item and index', (tester) async {
      String? tappedItem;
      int? tappedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverSmartSearchList<String>(
                  items: const ['Apple', 'Banana', 'Cherry'],
                  searchableFields: (item) => [item],
                  onItemTap: (item, index) {
                    tappedItem = item;
                    tappedIndex = index;
                  },
                  itemBuilder:
                      (context, item, index, {searchTerms = const []}) {
                        return ListTile(title: Text(item));
                      },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Banana'));
      await tester.pumpAndSettle();

      expect(tappedItem, 'Banana');
      expect(tappedIndex, 1);
    });

    // -----------------------------------------------------------------------
    // Multi-select
    // -----------------------------------------------------------------------

    testWidgets('selection checkboxes render and toggle', (tester) async {
      final selectedItems = <String>{};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverSmartSearchList<String>(
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
                  itemBuilder:
                      (context, item, index, {searchTerms = const []}) {
                        return ListTile(title: Text(item));
                      },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find checkboxes
      final checkboxes = find.byType(Checkbox);
      expect(checkboxes, findsNWidgets(3));

      // Tap the first checkbox
      await tester.tap(checkboxes.first);
      await tester.pumpAndSettle();

      expect(selectedItems.length, 1);
      expect(selectedItems.contains('Apple'), true);
    });

    // -----------------------------------------------------------------------
    // Controller lifecycle: internal vs external
    // -----------------------------------------------------------------------

    testWidgets('disposes internal controller when widget is removed', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverSmartSearchList<String>(
                  items: const ['Apple', 'Banana'],
                  searchableFields: (item) => [item],
                  itemBuilder:
                      (context, item, index, {searchTerms = const []}) {
                        return ListTile(title: Text(item));
                      },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Remove widget - should not crash (internal controller disposed)
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      await tester.pumpAndSettle();

      // No exception means the internal controller was disposed cleanly
    });

    testWidgets('does not dispose external controller when widget is removed', (
      tester,
    ) async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setItems(const ['Apple', 'Banana']);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverSmartSearchList<String>.controller(
                  controller: controller,
                  itemBuilder:
                      (context, item, index, {searchTerms = const []}) {
                        return ListTile(title: Text(item));
                      },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Remove widget
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      await tester.pumpAndSettle();

      // External controller should NOT be disposed
      expect(controller.isDisposed, false);

      // Should still work
      controller.setItems(['Test']);
      expect(controller.items.length, 1);
    });

    // -----------------------------------------------------------------------
    // didUpdateWidget
    // -----------------------------------------------------------------------

    testWidgets('didUpdateWidget propagates items change', (tester) async {
      var items = const ['Apple', 'Banana'];
      late StateSetter rebuildParent;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rebuildParent = setState;
                return CustomScrollView(
                  slivers: [
                    SliverSmartSearchList<String>(
                      items: items,
                      searchableFields: (item) => [item],
                      itemBuilder:
                          (context, item, index, {searchTerms = const []}) {
                            return ListTile(title: Text(item));
                          },
                    ),
                  ],
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
        items = const ['Cherry', 'Date'];
      });
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsNothing);
      expect(find.text('Banana'), findsNothing);
      expect(find.text('Cherry'), findsOneWidget);
      expect(find.text('Date'), findsOneWidget);
    });

    testWidgets('didUpdateWidget propagates asyncLoader change', (
      tester,
    ) async {
      Future<List<String>> loaderA(
        String query, {
        int page = 0,
        int pageSize = 20,
      }) async {
        return ['FromA'];
      }

      Future<List<String>> loaderB(
        String query, {
        int page = 0,
        int pageSize = 20,
      }) async {
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
                return CustomScrollView(
                  slivers: [
                    SliverSmartSearchList<String>.async(
                      asyncLoader: currentLoader,
                      searchConfig: const SearchConfiguration(
                        debounceDelay: Duration(milliseconds: 10),
                      ),
                      itemBuilder:
                          (context, item, index, {searchTerms = const []}) {
                            return ListTile(title: Text(item));
                          },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Wait for initial load
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(find.text('FromA'), findsOneWidget);

      // Swap loader
      rebuildParent(() {
        currentLoader = loaderB;
      });

      // Wait for debounced re-search
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(find.text('FromA'), findsNothing);
      expect(find.text('FromB'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Async data loading
    // -----------------------------------------------------------------------

    testWidgets('offline constructor initializes data and filters correctly', (
      tester,
    ) async {
      // Use StatefulBuilder to swap items and trigger didUpdateWidget,
      // verifying the offline constructor's _initializeData() path.
      var items = const ['Apple', 'Banana', 'Cherry', 'Date'];
      late StateSetter rebuildParent;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rebuildParent = setState;
                return CustomScrollView(
                  slivers: [
                    SliverSmartSearchList<String>(
                      items: items,
                      searchableFields: (item) => [item],
                      itemBuilder:
                          (context, item, index, {searchTerms = const []}) {
                            return ListTile(title: Text(item));
                          },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // All items visible initially
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Cherry'), findsOneWidget);
      expect(find.text('Date'), findsOneWidget);

      // Change items to verify offline constructor re-initializes
      rebuildParent(() {
        items = const ['Fig', 'Grape'];
      });
      await tester.pumpAndSettle();

      expect(find.text('Fig'), findsOneWidget);
      expect(find.text('Grape'), findsOneWidget);
      expect(find.text('Apple'), findsNothing);
      expect(find.text('Cherry'), findsNothing);
    });

    testWidgets('loads and displays async data', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverSmartSearchList<String>.async(
                  asyncLoader:
                      (query, {int page = 0, int pageSize = 20}) async {
                        return ['Async Item 1', 'Async Item 2'];
                      },
                  searchConfig: const SearchConfiguration(
                    debounceDelay: Duration(milliseconds: 10),
                  ),
                  itemBuilder:
                      (context, item, index, {searchTerms = const []}) {
                        return ListTile(title: Text(item));
                      },
                ),
              ],
            ),
          ),
        ),
      );

      // Wait for debounce + async
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(find.text('Async Item 1'), findsOneWidget);
      expect(find.text('Async Item 2'), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // Filters and sorting
    // -----------------------------------------------------------------------

    testWidgets('filter applied via controller reduces items', (tester) async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: const Duration(milliseconds: 10),
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setItems(const ['Apple', 'Banana', 'Apricot', 'Cherry']);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverSmartSearchList<String>.controller(
                  controller: controller,
                  itemBuilder:
                      (context, item, index, {searchTerms = const []}) {
                        return ListTile(title: Text(item));
                      },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);

      // Apply filter
      controller.setFilter('startsWithA', (item) => item.startsWith('A'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Apricot'), findsOneWidget);
      expect(find.text('Banana'), findsNothing);
      expect(find.text('Cherry'), findsNothing);
    });

    testWidgets('sort applied via controller reorders items', (tester) async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: const Duration(milliseconds: 10),
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      final displayedOrder = <String>[];

      controller.setItems(const ['Cherry', 'Apple', 'Banana']);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverSmartSearchList<String>.controller(
                  controller: controller,
                  itemBuilder:
                      (context, item, index, {searchTerms = const []}) {
                        displayedOrder.add(item);
                        return ListTile(title: Text(item));
                      },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      displayedOrder.clear();

      // Sort alphabetically
      controller.setSortBy((a, b) => a.compareTo(b));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      // Items should be in alphabetical order
      expect(displayedOrder, ['Apple', 'Banana', 'Cherry']);
    });

    // -----------------------------------------------------------------------
    // onSearchChanged callback
    // -----------------------------------------------------------------------

    group('onSearchChanged callback', () {
      testWidgets('fires when controller query changes via searchImmediate', (
        tester,
      ) async {
        final controller = SmartSearchController<String>(
          searchableFields: (item) => [item],
          debounceDelay: const Duration(milliseconds: 10),
        );
        addTearDown(() {
          if (!controller.isDisposed) controller.dispose();
        });

        controller.setItems(const ['Apple', 'Banana', 'Cherry']);

        final queries = <String>[];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                slivers: [
                  SliverSmartSearchList<String>.controller(
                    controller: controller,
                    onSearchChanged: (query) => queries.add(query),
                    itemBuilder:
                        (context, item, index, {searchTerms = const []}) {
                          return ListTile(title: Text(item));
                        },
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        controller.searchImmediate('App');
        await tester.pumpAndSettle();

        expect(queries, ['App']);
      });

      testWidgets('fires with empty string on clearSearch', (tester) async {
        final controller = SmartSearchController<String>(
          searchableFields: (item) => [item],
          debounceDelay: const Duration(milliseconds: 10),
        );
        addTearDown(() {
          if (!controller.isDisposed) controller.dispose();
        });

        controller.setItems(const ['Apple', 'Banana', 'Cherry']);

        final queries = <String>[];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                slivers: [
                  SliverSmartSearchList<String>.controller(
                    controller: controller,
                    onSearchChanged: (query) => queries.add(query),
                    itemBuilder:
                        (context, item, index, {searchTerms = const []}) {
                          return ListTile(title: Text(item));
                        },
                  ),
                ],
              ),
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
          debounceDelay: const Duration(milliseconds: 10),
        );
        addTearDown(() {
          if (!controller.isDisposed) controller.dispose();
        });

        controller.setItems(const ['Apple', 'Banana', 'Cherry']);

        final queries = <String>[];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                slivers: [
                  SliverSmartSearchList<String>.controller(
                    controller: controller,
                    onSearchChanged: (query) => queries.add(query),
                    itemBuilder:
                        (context, item, index, {searchTerms = const []}) {
                          return ListTile(title: Text(item));
                        },
                  ),
                ],
              ),
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

      testWidgets('fires correctly after controller swap in didUpdateWidget', (
        tester,
      ) async {
        final controllerA = SmartSearchController<String>(
          searchableFields: (item) => [item],
          debounceDelay: const Duration(milliseconds: 10),
        );
        final controllerB = SmartSearchController<String>(
          searchableFields: (item) => [item],
          debounceDelay: const Duration(milliseconds: 10),
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
                      SliverSmartSearchList<String>.controller(
                        controller: activeController,
                        onSearchChanged: (query) => queries.add(query),
                        itemBuilder:
                            (context, item, index, {searchTerms = const []}) {
                              return ListTile(title: Text(item));
                            },
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

        // Swap to controller B (query resets to '')
        rebuildParent(() {
          activeController = controllerB;
        });
        await tester.pumpAndSettle();

        // Search on controller B should fire
        controllerB.searchImmediate('Cher');
        await tester.pumpAndSettle();
        expect(queries, ['App', 'Cher']);
      });

      testWidgets('fires once per distinct query (dedup check)', (
        tester,
      ) async {
        final controller = SmartSearchController<String>(
          searchableFields: (item) => [item],
          debounceDelay: const Duration(milliseconds: 10),
        );
        addTearDown(() {
          if (!controller.isDisposed) controller.dispose();
        });

        controller.setItems(const ['Apple', 'Banana', 'Cherry']);

        final queries = <String>[];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                slivers: [
                  SliverSmartSearchList<String>.controller(
                    controller: controller,
                    onSearchChanged: (query) => queries.add(query),
                    itemBuilder:
                        (context, item, index, {searchTerms = const []}) {
                          return ListTile(title: Text(item));
                        },
                  ),
                ],
              ),
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
    });
  });
}
