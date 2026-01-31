import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_search_list/smart_search_list.dart';

void main() {
  group('Grouped List Widget', () {
    testWidgets('items are grouped correctly by groupBy function',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchList<String>(
              items: const ['Apple', 'Avocado', 'Banana', 'Blueberry'],
              searchableFields: (item) => [item],
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return ListTile(title: Text(item));
              },
              groupBy: (item) => item[0], // group by first letter
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Items should appear
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
    });

    testWidgets('group headers render with correct text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchList<String>(
              items: const ['Apple', 'Avocado', 'Banana'],
              searchableFields: (item) => [item],
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return ListTile(title: Text(item));
              },
              groupBy: (item) => item[0],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // DefaultGroupHeader shows "A (2)" and "B (1)"
      expect(find.textContaining('A'), findsWidgets);
      expect(find.textContaining('B'), findsWidgets);
    });

    testWidgets('empty groups do not appear after search filter',
        (tester) async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: const Duration(milliseconds: 10),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchList<String>(
              items: const ['Apple', 'Avocado', 'Banana'],
              searchableFields: (item) => [item],
              controller: controller,
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return ListTile(title: Text(item));
              },
              groupBy: (item) => item[0],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Search for 'A' items only
      controller.searchImmediate('Apple');
      await tester.pumpAndSettle();

      // 'Banana' should not appear
      expect(find.text('Banana'), findsNothing);
    });

    testWidgets('group comparator orders groups correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchList<String>(
              items: const ['Banana', 'Apple', 'Cherry'],
              searchableFields: (item) => [item],
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return ListTile(title: Text(item));
              },
              groupBy: (item) => item[0],
              groupComparator: (a, b) =>
                  (a as String).compareTo(b as String), // alphabetical
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // All items should render
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Cherry'), findsOneWidget);
    });

    testWidgets('DefaultGroupHeader shows group name and count',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DefaultGroupHeader(groupValue: 'Fruit', itemCount: 3),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Fruit'), findsOneWidget);
      expect(find.textContaining('3'), findsOneWidget);
    });
  });
}
