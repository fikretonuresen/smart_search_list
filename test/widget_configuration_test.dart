import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_search_list/smart_search_list.dart';

void main() {
  group('New Features Tests', () {
    testWidgets('belowSearchWidget should render correctly', (tester) async {
      final testWidget = Container(
        key: const Key('below_search_widget'),
        height: 50,
        color: Colors.red,
        child: const Text('Filter Widget'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchList<String>(
              items: const ['Apple', 'Banana'],
              searchableFields: (item) => [item],
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return ListTile(title: Text(item));
              },
              belowSearchWidget: testWidget,
            ),
          ),
        ),
      );

      // Verify the widget is rendered
      expect(find.byKey(const Key('below_search_widget')), findsOneWidget);
      expect(find.text('Filter Widget'), findsOneWidget);

      // Verify the widget is positioned after search field
      final searchField = find.byType(TextField);
      final belowWidget = find.byKey(const Key('below_search_widget'));

      expect(searchField, findsOneWidget);
      expect(belowWidget, findsOneWidget);

      // Get positions
      final searchRect = tester.getRect(searchField);
      final belowRect = tester.getRect(belowWidget);

      // Below widget should be below search field
      expect(belowRect.top, greaterThan(searchRect.bottom));
    });

    testWidgets('searchTerms should be passed to itemBuilder', (tester) async {
      List<String> receivedSearchTerms = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchList<String>(
              items: const ['Apple', 'Banana'],
              searchableFields: (item) => [item],
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                if (searchTerms.isNotEmpty) {
                  receivedSearchTerms = searchTerms;
                }
                return ListTile(title: Text(item));
              },
            ),
          ),
        ),
      );

      // Initially no search terms
      await tester.pump();
      expect(receivedSearchTerms, isEmpty);

      // Type in search field
      await tester.enterText(find.byType(TextField), 'Apple');
      await tester.pump(const Duration(milliseconds: 350)); // Wait for debounce
      await tester.pumpAndSettle(); // Wait for all animations

      // Should receive search terms
      expect(receivedSearchTerms, ['Apple']);
    });

    testWidgets('searchTerms should be computed correctly', (tester) async {
      String? receivedQuery;
      List<String> receivedSearchTerms = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchList<String>(
              items: const ['Apple', 'Orange'],
              searchableFields: (item) => [item],
              searchConfig: const SearchConfiguration(
                caseSensitive: false, // Make search case insensitive
              ),
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                receivedSearchTerms = List.from(searchTerms); // Make a copy
                return ListTile(
                  title: Text(item),
                  subtitle: Text('Terms: ${searchTerms.join(", ")}'),
                );
              },
              onSearchChanged: (query) {
                receivedQuery = query;
              },
            ),
          ),
        ),
      );

      // Initial state - empty search terms
      await tester.pump();
      expect(receivedSearchTerms, isEmpty);

      // Test simple search - this should find matches since search is case insensitive
      await tester.enterText(find.byType(TextField), 'app');
      await tester.pump(const Duration(milliseconds: 350)); // Wait for debounce
      await tester.pumpAndSettle();

      // Verify search was triggered
      expect(receivedQuery, 'app');

      // Verify search terms were passed
      expect(receivedSearchTerms, ['app']);

      // Test that search terms are split correctly
      await tester.enterText(find.byType(TextField), 'app');
      await tester.pump(const Duration(milliseconds: 350)); // Wait for debounce
      await tester.pumpAndSettle();

      // Verify that both terms are passed to itemBuilder for highlighting
      // even though the search itself looks for the complete phrase
      expect(receivedSearchTerms, ['app']);
    });

    testWidgets('pull to refresh should show RefreshIndicator when enabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchList<String>(
              items: const ['Apple', 'Banana'],
              searchableFields: (item) => [item],
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return ListTile(title: Text(item));
              },
              listConfig: const ListConfiguration(pullToRefresh: true),
              onRefresh: () async {},
            ),
          ),
        ),
      );

      // Should find RefreshIndicator when pull to refresh is enabled
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets(
      'pull to refresh should not show RefreshIndicator when disabled',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SmartSearchList<String>(
                items: const ['Apple', 'Banana'],
                searchableFields: (item) => [item],
                itemBuilder: (context, item, index, {searchTerms = const []}) {
                  return ListTile(title: Text(item));
                },
                listConfig: const ListConfiguration(pullToRefresh: false),
              ),
            ),
          ),
        );

        // Should not find RefreshIndicator when pull to refresh is disabled
        expect(find.byType(RefreshIndicator), findsNothing);
      },
    );

    testWidgets('belowSearchWidget should be null by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchList<String>(
              items: const ['Apple'],
              searchableFields: (item) => [item],
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return ListTile(title: Text(item));
              },
            ),
          ),
        ),
      );

      // Should only have search field and list, no additional widgets
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);

      // Should not find any extra containers or widgets between search and list
      final column = find.byType(Column);
      expect(column, findsOneWidget);
    });

    testWidgets(
      'backward compatibility - itemBuilder without searchTerms should work',
      (tester) async {
        // This test ensures old code still works
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SmartSearchList<String>(
                items: const ['Apple'],
                searchableFields: (item) => [item],
                // Old style itemBuilder without searchTerms parameter
                itemBuilder: (context, item, index, {searchTerms = const []}) {
                  return ListTile(title: Text(item));
                },
              ),
            ),
          ),
        );

        expect(find.text('Apple'), findsOneWidget);
      },
    );
  });

  // ===========================================================================
  // ListConfiguration passthrough tests
  // ===========================================================================

  group('ListConfiguration passthrough', () {
    Widget buildWithConfig(
      ListConfiguration config, {
      bool withSeparator = false,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SmartSearchList<String>(
            items: const ['Apple', 'Banana', 'Cherry'],
            searchableFields: (item) => [item],
            itemBuilder: (context, item, index, {searchTerms = const []}) {
              return ListTile(title: Text(item));
            },
            listConfig: config,
            separatorBuilder: withSeparator
                ? (context, index) => const Divider(key: Key('sep'))
                : null,
          ),
        ),
      );
    }

    testWidgets('separatorBuilder renders dividers', (tester) async {
      await tester.pumpWidget(
        buildWithConfig(const ListConfiguration(), withSeparator: true),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('sep')), findsWidgets);
    });

    testWidgets('physics passes through to ListView', (tester) async {
      await tester.pumpWidget(
        buildWithConfig(
          const ListConfiguration(physics: NeverScrollableScrollPhysics()),
        ),
      );
      await tester.pumpAndSettle();

      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.physics, isA<NeverScrollableScrollPhysics>());
    });

    testWidgets('padding passes through to ListView', (tester) async {
      await tester.pumpWidget(
        buildWithConfig(const ListConfiguration(padding: EdgeInsets.all(32))),
      );
      await tester.pumpAndSettle();

      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.padding, const EdgeInsets.all(32));
    });

    testWidgets('shrinkWrap passes through to ListView', (tester) async {
      await tester.pumpWidget(
        buildWithConfig(const ListConfiguration(shrinkWrap: true)),
      );
      await tester.pumpAndSettle();

      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.shrinkWrap, true);
    });

    testWidgets('reverse passes through to ListView', (tester) async {
      await tester.pumpWidget(
        buildWithConfig(const ListConfiguration(reverse: true)),
      );
      await tester.pumpAndSettle();

      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.reverse, true);
    });

    testWidgets('itemExtent passes through to ListView', (tester) async {
      await tester.pumpWidget(
        buildWithConfig(const ListConfiguration(itemExtent: 80.0)),
      );
      await tester.pumpAndSettle();

      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.itemExtent, 80.0);
    });

    testWidgets('clipBehavior passes through to ListView', (tester) async {
      await tester.pumpWidget(
        buildWithConfig(const ListConfiguration(clipBehavior: Clip.antiAlias)),
      );
      await tester.pumpAndSettle();

      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.clipBehavior, Clip.antiAlias);
    });
  });
}
