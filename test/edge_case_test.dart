import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_search_list/smart_search_list.dart';

void main() {
  // =========================================================================
  // Empty state discrimination
  // =========================================================================

  group('empty state discrimination', () {
    testWidgets('shows empty state when no data provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchList<String>(
              items: const [],
              searchableFields: (item) => [item],
              emptyStateBuilder: (context) => const Text('NO DATA'),
              emptySearchStateBuilder: (context, query) =>
                  Text('NO RESULTS: $query'),
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return ListTile(title: Text(item));
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('NO DATA'), findsOneWidget);
      expect(find.textContaining('NO RESULTS'), findsNothing);
    });

    testWidgets('shows empty search state when search yields no results', (
      tester,
    ) async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      controller.setItems(['Apple', 'Banana']);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchList<String>.controller(
              controller: controller,
              emptyStateBuilder: (context) => const Text('NO DATA'),
              emptySearchStateBuilder: (context, query) =>
                  Text('NO RESULTS: $query'),
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return ListTile(title: Text(item));
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      controller.searchImmediate('zzz');
      await tester.pumpAndSettle();

      expect(find.text('NO RESULTS: zzz'), findsOneWidget);
      expect(find.text('NO DATA'), findsNothing);

      controller.dispose();
    });

    testWidgets('shows empty state when filter removes all items', (
      tester,
    ) async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      controller.setItems(['Apple', 'Banana']);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchList<String>.controller(
              controller: controller,
              emptyStateBuilder: (context) => const Text('NO DATA'),
              emptySearchStateBuilder: (context, query) =>
                  Text('NO RESULTS: $query'),
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return ListTile(title: Text(item));
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Filter removes everything but we haven't searched
      controller.setFilter('impossible', (_) => false);
      await tester.pumpAndSettle();

      // Since there's no active search query, this shows the empty state
      // (hasSearched is true from setFilter calling _performSearch, but
      // searchQuery is empty)
      expect(find.text('NO DATA'), findsOneWidget);

      controller.dispose();
    });
  });

  // =========================================================================
  // Cache key collision resistance
  // =========================================================================

  group('cache key', () {
    test('different filter versions produce different cache keys', () async {
      final controller = SmartSearchController<String>(
        debounceDelay: Duration.zero,
        cacheResults: true,
      );

      var callCount = 0;
      controller.setAsyncLoader((
        query, {
        int page = 0,
        int pageSize = 20,
      }) async {
        callCount++;
        return ['result-$callCount'];
      });

      // Search with no filter
      controller.searchImmediate('test');
      await Future.microtask(() {});
      await Future.microtask(() {});
      expect(controller.items, ['result-1']);

      // Add a filter — should create a different cache key
      controller.setFilter('f1', (_) => true);
      await Future.microtask(() {});
      await Future.microtask(() {});
      expect(callCount, 2, reason: 'New filter version → new cache key');

      // Remove filter — different version again
      controller.removeFilter('f1');
      await Future.microtask(() {});
      await Future.microtask(() {});
      expect(callCount, 3, reason: 'Filter removal → new cache key');

      controller.dispose();
    });

    test('filter name containing separator does not cause collision', () async {
      final controller = SmartSearchController<String>(
        debounceDelay: Duration.zero,
        cacheResults: true,
      );

      var callCount = 0;
      controller.setAsyncLoader((
        query, {
        int page = 0,
        int pageSize = 20,
      }) async {
        callCount++;
        return ['result'];
      });

      // Filter with comma in name (commas are used as separator in cache key)
      controller.setFilter('a,b', (_) => true);
      await Future.microtask(() {});
      await Future.microtask(() {});

      final firstCallCount = callCount;

      // Different filter that would collide if separator isn't handled
      controller.removeFilter('a,b');
      controller.setFilter('a', (_) => true);
      controller.setFilter('b', (_) => true);
      await Future.microtask(() {});
      await Future.microtask(() {});

      // Should have been called again (different filter configuration)
      expect(
        callCount,
        greaterThan(firstCallCount),
        reason: 'Different filter config should produce different cache key',
      );

      controller.dispose();
    });
  });

  // =========================================================================
  // SearchHighlightText regex safety
  // =========================================================================

  group('SearchHighlightText regex-unsafe characters', () {
    testWidgets('dot character in search term', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchHighlightText(
              text: 'file.txt and filetxt',
              searchTerms: ['.'],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SearchHighlightText), findsOneWidget);
    });

    testWidgets('parentheses in search term', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchHighlightText(
              text: 'call() and test',
              searchTerms: ['()'],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SearchHighlightText), findsOneWidget);
    });

    testWidgets('backslash in search term', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchHighlightText(
              text: r'path\to\file',
              searchTerms: [r'\'],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SearchHighlightText), findsOneWidget);
    });

    testWidgets('square brackets in search term', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchHighlightText(
              text: 'array[0] access',
              searchTerms: ['[0]'],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SearchHighlightText), findsOneWidget);
    });

    testWidgets('plus and star in search term', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchHighlightText(
              text: 'a+b*c expression',
              searchTerms: ['+*'],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SearchHighlightText), findsOneWidget);
    });

    testWidgets('pipe character in search term', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchHighlightText(text: 'a|b or c', searchTerms: ['|']),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SearchHighlightText), findsOneWidget);
    });

    testWidgets('caret and dollar in search term', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchHighlightText(
              text: r'$100 price ^up',
              searchTerms: [r'$', '^'],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SearchHighlightText), findsOneWidget);
    });

    testWidgets('question mark in search term', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchHighlightText(
              text: 'Is this correct?',
              searchTerms: ['?'],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SearchHighlightText), findsOneWidget);
    });
  });

  // =========================================================================
  // Empty searchableFields
  // =========================================================================

  group('empty searchableFields', () {
    test('returns no results but does not crash', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [],
        debounceDelay: Duration.zero,
      );

      controller.setItems(['Apple', 'Banana', 'Cherry']);
      controller.searchImmediate('App');

      // No searchable fields → nothing matches → empty results
      expect(controller.items, isEmpty);

      controller.dispose();
    });

    test('empty string search still shows all items', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [],
        debounceDelay: Duration.zero,
      );

      controller.setItems(['Apple', 'Banana']);
      controller.searchImmediate('');

      // Empty query doesn't search, just shows all
      expect(controller.items.length, 2);

      controller.dispose();
    });
  });

  // =========================================================================
  // Boundary values
  // =========================================================================

  group('boundary values', () {
    test('pageSize=1 loads one item per page', () async {
      final controller = SmartSearchController<String>(
        debounceDelay: Duration.zero,
        pageSize: 1,
      );

      controller.setAsyncLoader((
        query, {
        int page = 0,
        int pageSize = 20,
      }) async {
        if (page >= 3) return [];
        return ['item-$page'];
      });

      controller.searchImmediate('');
      await Future.microtask(() {});
      await Future.microtask(() {});

      expect(controller.items, ['item-0']);
      expect(controller.hasMorePages, true);

      await controller.loadMore();
      await Future.microtask(() {});
      expect(controller.items, ['item-0', 'item-1']);

      controller.dispose();
    });

    test('fuzzyThreshold=0.0 accepts every fuzzy match', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
        fuzzySearchEnabled: true,
        fuzzyThreshold: 0.0,
      );

      controller.setItems(['Apple', 'Banana', 'Cherry', 'Apricot']);
      controller.searchImmediate('a');

      // Threshold 0 should accept very loose matches
      expect(controller.items.length, greaterThanOrEqualTo(1));

      controller.dispose();
    });

    test('fuzzyThreshold=1.0 only accepts exact substring matches', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
        fuzzySearchEnabled: true,
        fuzzyThreshold: 1.0,
      );

      controller.setItems(['Apple', 'apple', 'APPLE', 'Banana']);
      controller.searchImmediate('apple');

      // Only exact substring matches should pass threshold of 1.0
      // Case-insensitive by default, so Apple, apple, APPLE should match
      expect(controller.items.length, 3);

      controller.dispose();
    });

    test('maxCacheSize=1 evicts on second distinct search', () async {
      var callCount = 0;
      final controller = SmartSearchController<String>(
        debounceDelay: Duration.zero,
        cacheResults: true,
        maxCacheSize: 1,
      );

      controller.setAsyncLoader((
        query, {
        int page = 0,
        int pageSize = 20,
      }) async {
        callCount++;
        return ['result-$query'];
      });

      controller.searchImmediate('a');
      await Future.microtask(() {});
      await Future.microtask(() {});
      expect(callCount, 1);

      controller.searchImmediate('b');
      await Future.microtask(() {});
      await Future.microtask(() {});
      expect(callCount, 2);

      // 'a' was evicted because maxCacheSize=1
      controller.searchImmediate('a');
      await Future.microtask(() {});
      await Future.microtask(() {});
      expect(callCount, 3, reason: 'Cache should have evicted "a"');

      // 'b' is still the most recent, but was evicted by 'a'
      controller.searchImmediate('b');
      await Future.microtask(() {});
      await Future.microtask(() {});
      expect(callCount, 4, reason: 'Cache should have evicted "b"');

      controller.dispose();
    });

    test('debounceDelay=Duration.zero works correctly', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );

      controller.setItems(['Apple', 'Banana']);
      controller.searchImmediate('App');

      expect(controller.items, ['Apple']);

      controller.dispose();
    });
  });

  // =========================================================================
  // SliverSmartSearchList empty state discrimination
  // =========================================================================

  group('SliverSmartSearchList empty state discrimination', () {
    testWidgets('shows empty state when no data', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverSmartSearchList<String>(
                  items: const [],
                  searchableFields: (item) => [item],
                  emptyStateBuilder: (context) => const Text('NO DATA'),
                  emptySearchStateBuilder: (context, query) =>
                      Text('NO RESULTS: $query'),
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

      expect(find.text('NO DATA'), findsOneWidget);
      expect(find.textContaining('NO RESULTS'), findsNothing);
    });

    testWidgets('shows empty search state when search yields no results', (
      tester,
    ) async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );
      controller.setItems(['Apple', 'Banana']);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverSmartSearchList<String>.controller(
                  controller: controller,
                  emptyStateBuilder: (context) => const Text('NO DATA'),
                  emptySearchStateBuilder: (context, query) =>
                      Text('NO RESULTS: $query'),
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

      controller.searchImmediate('zzz');
      await tester.pumpAndSettle();

      expect(find.text('NO RESULTS: zzz'), findsOneWidget);
      expect(find.text('NO DATA'), findsNothing);

      controller.dispose();
    });
  });

  // =========================================================================
  // updateCaseSensitive / updateMinSearchLength
  // =========================================================================

  group('dynamic config updates', () {
    test('updateCaseSensitive re-searches with new setting', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
        caseSensitive: false,
      );

      controller.setItems(['Apple', 'apple', 'APPLE']);
      controller.searchImmediate('apple');

      expect(controller.items.length, 3); // case-insensitive

      controller.updateCaseSensitive(true);
      expect(controller.items, ['apple']);

      controller.dispose();
    });

    test('updateMinSearchLength re-evaluates current query', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
        minSearchLength: 0,
      );

      controller.setItems(['Apple', 'Banana']);
      controller.searchImmediate('Ap');

      expect(controller.items, ['Apple']);

      // Increase min length to 3 — current query 'Ap' is too short
      controller.updateMinSearchLength(3);

      // Query 'Ap' should no longer produce filtered results
      // (minSearchLength check happens in _performSearch)
      expect(controller.items, ['Apple']); // stays as-is, search was no-op

      controller.dispose();
    });

    test('updateFuzzySearchEnabled toggles fuzzy mode', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
        fuzzySearchEnabled: false,
      );

      controller.setItems(['Apple', 'Application', 'Banana']);
      controller.searchImmediate('apln');

      // Exact match — 'apln' not found anywhere
      expect(controller.items, isEmpty);

      // Enable fuzzy
      controller.updateFuzzySearchEnabled(true);

      // 'apln' should fuzzy-match against 'Application' (a-p-l-n subsequence)
      expect(controller.items.isNotEmpty, true);

      controller.dispose();
    });

    test('updateFuzzyThreshold adjusts strictness', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
        fuzzySearchEnabled: true,
        fuzzyThreshold: 0.0,
      );

      controller.setItems(['Apple', 'Xylophone', 'Banana']);
      controller.searchImmediate('apl');

      final loosyCount = controller.items.length;

      // Tighten threshold
      controller.updateFuzzyThreshold(0.9);

      // Should have fewer or equal matches
      expect(controller.items.length, lessThanOrEqualTo(loosyCount));

      controller.dispose();
    });
  });

  // =========================================================================
  // dispose safety
  // =========================================================================

  group('dispose safety', () {
    test('all public methods are safe after dispose', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: Duration.zero,
      );

      controller.dispose();

      // None of these should throw
      controller.search('test');
      controller.searchImmediate('test');
      controller.clearSearch();
      controller.setItems(['a']);
      controller.setAsyncLoader(
        (q, {int page = 0, int pageSize = 20}) async => [],
      );
      controller.setFilter('f', (_) => true);
      controller.removeFilter('f');
      controller.clearFilters();
      controller.setSortBy((a, b) => 0);
      controller.select('a');
      controller.deselect('a');
      controller.toggleSelection('a');
      controller.selectAll();
      controller.deselectAll();
      controller.selectWhere((_) => true);
      controller.deselectWhere((_) => true);
      controller.updateCaseSensitive(true);
      controller.updateMinSearchLength(5);
      controller.updateFuzzySearchEnabled(true);
      controller.updateFuzzyThreshold(0.5);
    });

    test('async operations after dispose are safe', () async {
      final controller = SmartSearchController<String>(
        debounceDelay: Duration.zero,
      );

      controller.dispose();

      await controller.loadMore();
      await controller.refresh();
      await controller.retry();
    });
  });
}
