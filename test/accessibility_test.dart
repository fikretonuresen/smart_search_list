import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_search_list/smart_search_list.dart';

void main() {
  group('AccessibilityConfiguration', () {
    test('default values', () {
      const config = AccessibilityConfiguration();

      expect(config.searchSemanticsEnabled, true);
      expect(config.searchFieldLabel, isNull);
      expect(config.resultsAnnouncementBuilder, isNull);
      expect(config.clearButtonLabel, isNull);
      expect(config.searchButtonLabel, isNull);
    });

    test('buildResultsAnnouncement with defaults', () {
      const config = AccessibilityConfiguration();

      expect(config.buildResultsAnnouncement(0), 'No results found');
      expect(config.buildResultsAnnouncement(1), '1 result found');
      expect(config.buildResultsAnnouncement(5), '5 results found');
      expect(config.buildResultsAnnouncement(100), '100 results found');
    });

    test('buildResultsAnnouncement with custom builder', () {
      final config = AccessibilityConfiguration(
        resultsAnnouncementBuilder: (count) => '$count sonuc bulundu',
      );

      expect(config.buildResultsAnnouncement(0), '0 sonuc bulundu');
      expect(config.buildResultsAnnouncement(3), '3 sonuc bulundu');
    });

    test('copyWith preserves values', () {
      final original = AccessibilityConfiguration(
        searchSemanticsEnabled: false,
        searchFieldLabel: 'Search items',
        resultsAnnouncementBuilder: (c) => '$c items',
        clearButtonLabel: 'Temizle',
        searchButtonLabel: 'Ara',
      );

      final copy = original.copyWith(searchFieldLabel: 'Search products');

      expect(copy.searchSemanticsEnabled, false);
      expect(copy.searchFieldLabel, 'Search products');
      expect(copy.clearButtonLabel, 'Temizle');
      expect(copy.searchButtonLabel, 'Ara');
      expect(copy.buildResultsAnnouncement(2), '2 items');
    });

    test('copyWith with no arguments returns equivalent config', () {
      const original = AccessibilityConfiguration(
        searchFieldLabel: 'Search',
      );

      final copy = original.copyWith();

      expect(copy.searchFieldLabel, 'Search');
      expect(copy.searchSemanticsEnabled, true);
    });
  });

  group('DefaultSearchField accessibility', () {
    testWidgets('clear button has tooltip', (tester) async {
      final textController = TextEditingController(text: 'hello');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DefaultSearchField(
              controller: textController,
              focusNode: FocusNode(),
              configuration: const SearchConfiguration(),
              onClear: () {},
            ),
          ),
        ),
      );

      // Clear button should have tooltip
      final clearButton = find.widgetWithIcon(IconButton, Icons.clear);
      expect(clearButton, findsOneWidget);

      final iconButton = tester.widget<IconButton>(clearButton);
      expect(iconButton.tooltip, 'Clear search');

      textController.dispose();
    });

    testWidgets('clear button uses custom label from accessibility config',
        (tester) async {
      final textController = TextEditingController(text: 'hello');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DefaultSearchField(
              controller: textController,
              focusNode: FocusNode(),
              configuration: const SearchConfiguration(),
              onClear: () {},
              accessibilityConfig: const AccessibilityConfiguration(
                clearButtonLabel: 'Aramayı temizle',
              ),
            ),
          ),
        ),
      );

      final clearButton = find.widgetWithIcon(IconButton, Icons.clear);
      final iconButton = tester.widget<IconButton>(clearButton);
      expect(iconButton.tooltip, 'Aramayı temizle');

      textController.dispose();
    });

    testWidgets('search button has tooltip in onSubmit mode', (tester) async {
      final textController = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DefaultSearchField(
              controller: textController,
              focusNode: FocusNode(),
              configuration: const SearchConfiguration(
                triggerMode: SearchTriggerMode.onSubmit,
              ),
              onClear: () {},
              onSubmitted: (_) {},
            ),
          ),
        ),
      );

      final searchButton = find.widgetWithIcon(IconButton, Icons.search);
      expect(searchButton, findsOneWidget);

      final iconButton = tester.widget<IconButton>(searchButton);
      expect(iconButton.tooltip, 'Search');

      textController.dispose();
    });

    testWidgets('search button uses custom label', (tester) async {
      final textController = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DefaultSearchField(
              controller: textController,
              focusNode: FocusNode(),
              configuration: const SearchConfiguration(
                triggerMode: SearchTriggerMode.onSubmit,
              ),
              onClear: () {},
              onSubmitted: (_) {},
              accessibilityConfig: const AccessibilityConfiguration(
                searchButtonLabel: 'Ara',
              ),
            ),
          ),
        ),
      );

      final searchButton = find.widgetWithIcon(IconButton, Icons.search);
      final iconButton = tester.widget<IconButton>(searchButton);
      expect(iconButton.tooltip, 'Ara');

      textController.dispose();
    });

    testWidgets('searchFieldLabel is applied to InputDecoration',
        (tester) async {
      final textController = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DefaultSearchField(
              controller: textController,
              focusNode: FocusNode(),
              configuration: const SearchConfiguration(),
              onClear: () {},
              accessibilityConfig: const AccessibilityConfiguration(
                searchFieldLabel: 'Search products',
              ),
            ),
          ),
        ),
      );

      // The label text should be rendered
      expect(find.text('Search products'), findsOneWidget);

      textController.dispose();
    });
  });

  group('DefaultGroupHeader accessibility', () {
    testWidgets('has header semantics', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DefaultGroupHeader(
              groupValue: 'Electronics',
              itemCount: 5,
            ),
          ),
        ),
      );

      // Find the Semantics node with header: true
      final semantics = tester.getSemantics(find.byType(DefaultGroupHeader));
      // Verify the header flag is set via the semantics tree
      expect(
        semantics,
        matchesSemantics(isHeader: true),
      );

      handle.dispose();
    });
  });

  group('SmartSearchList live region', () {
    testWidgets('live region is present when semantics enabled',
        (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchList<String>(
              items: const ['Apple', 'Banana', 'Cherry'],
              searchableFields: (item) => [item],
              itemBuilder: (context, item, index, {searchTerms = const []}) =>
                  ListTile(title: Text(item)),
            ),
          ),
        ),
      );

      // Find the live region Semantics widget
      final liveRegion = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.liveRegion == true,
      );
      expect(liveRegion, findsOneWidget);

      handle.dispose();
    });

    testWidgets('live region is absent when semantics disabled',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchList<String>(
              items: const ['Apple', 'Banana', 'Cherry'],
              searchableFields: (item) => [item],
              itemBuilder: (context, item, index, {searchTerms = const []}) =>
                  ListTile(title: Text(item)),
              accessibilityConfig: const AccessibilityConfiguration(
                searchSemanticsEnabled: false,
              ),
            ),
          ),
        ),
      );

      final liveRegion = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.liveRegion == true,
      );
      expect(liveRegion, findsNothing);
    });

    testWidgets('live region announces result count after search',
        (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchList<String>(
              items: const ['Apple', 'Banana', 'Cherry'],
              searchableFields: (item) => [item],
              searchConfig: const SearchConfiguration(
                debounceDelay: Duration(milliseconds: 10),
              ),
              itemBuilder: (context, item, index, {searchTerms = const []}) =>
                  ListTile(title: Text(item)),
            ),
          ),
        ),
      );

      // Type a search query
      await tester.enterText(find.byType(TextField), 'App');
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pump();

      // Find the live region and check its label
      final liveRegion = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.liveRegion == true,
      );
      expect(liveRegion, findsOneWidget);

      final semanticsWidget = tester.widget<Semantics>(liveRegion);
      expect(semanticsWidget.properties.label, '1 result found');

      handle.dispose();
    });

    testWidgets('live region uses custom announcement builder', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchList<String>(
              items: const ['Apple', 'Banana', 'Cherry'],
              searchableFields: (item) => [item],
              searchConfig: const SearchConfiguration(
                debounceDelay: Duration(milliseconds: 10),
              ),
              accessibilityConfig: AccessibilityConfiguration(
                resultsAnnouncementBuilder: (count) => '$count Ergebnis',
              ),
              itemBuilder: (context, item, index, {searchTerms = const []}) =>
                  ListTile(title: Text(item)),
            ),
          ),
        ),
      );

      // Type a search query
      await tester.enterText(find.byType(TextField), 'App');
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pump();

      final liveRegion = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.liveRegion == true,
      );
      final semanticsWidget = tester.widget<Semantics>(liveRegion);
      expect(semanticsWidget.properties.label, '1 Ergebnis');

      handle.dispose();
    });

    testWidgets('live region shows empty message for zero results',
        (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchList<String>(
              items: const ['Apple', 'Banana', 'Cherry'],
              searchableFields: (item) => [item],
              searchConfig: const SearchConfiguration(
                debounceDelay: Duration(milliseconds: 10),
              ),
              itemBuilder: (context, item, index, {searchTerms = const []}) =>
                  ListTile(title: Text(item)),
            ),
          ),
        ),
      );

      // Search for something that doesn't exist
      await tester.enterText(find.byType(TextField), 'xyz');
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pump();

      final liveRegion = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.liveRegion == true,
      );
      final semanticsWidget = tester.widget<Semantics>(liveRegion);
      expect(semanticsWidget.properties.label, 'No results found');

      handle.dispose();
    });
  });

  group('SmartSearchList tap target guidelines', () {
    testWidgets('meets labeled tap target guideline', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchList<String>(
              items: const ['Apple', 'Banana', 'Cherry'],
              searchableFields: (item) => [item],
              itemBuilder: (context, item, index, {searchTerms = const []}) =>
                  ListTile(title: Text(item)),
            ),
          ),
        ),
      );

      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      handle.dispose();
    });
  });

  group('SliverSmartSearchList accessibility', () {
    testWidgets('accepts accessibilityConfig parameter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverSmartSearchList<String>(
                  items: const ['Apple', 'Banana'],
                  searchableFields: (item) => [item],
                  itemBuilder: (context, item, index,
                          {searchTerms = const []}) =>
                      ListTile(title: Text(item)),
                  accessibilityConfig: const AccessibilityConfiguration(
                    searchFieldLabel: 'Search fruits',
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Should render without errors
      expect(find.text('Apple'), findsOneWidget);
    });

    testWidgets('sliver variant renders with accessibility enabled',
        (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverSmartSearchList<String>(
                  items: const ['Apple', 'Banana'],
                  searchableFields: (item) => [item],
                  itemBuilder: (context, item, index,
                          {searchTerms = const []}) =>
                      ListTile(title: Text(item)),
                  accessibilityConfig: const AccessibilityConfiguration(
                    searchSemanticsEnabled: true,
                    searchFieldLabel: 'Search fruits',
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump();

      // The sliver renders items correctly with accessibility enabled
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);

      // The outer SliverMainAxisGroup wraps the live region + list
      expect(find.byType(SliverMainAxisGroup), findsOneWidget);

      handle.dispose();
    });
  });
}
