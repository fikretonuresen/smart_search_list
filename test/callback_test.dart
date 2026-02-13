import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_search_list/smart_search_list.dart';

void main() {
  group('Widget callbacks', () {
    testWidgets('onSearchChanged fires with query on text input', (
      tester,
    ) async {
      final queries = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchList<String>(
              items: const ['Apple', 'Banana'],
              searchableFields: (item) => [item],
              searchConfig: const SearchConfiguration(
                debounceDelay: Duration(milliseconds: 10),
              ),
              onSearchChanged: (query) => queries.add(query),
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return ListTile(title: Text(item));
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'App');
      await tester.pump();

      // onSearchChanged fires on every text change, not debounced
      expect(queries, contains('App'));
    });

    testWidgets('onItemTap fires with correct item on tap', (tester) async {
      final tapped = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchList<String>(
              items: const ['Apple', 'Banana', 'Cherry'],
              searchableFields: (item) => [item],
              onItemTap: (item, index) => tapped.add(item),
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return ListTile(title: Text(item));
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Banana'));
      await tester.pump();

      expect(tapped, ['Banana']);
    });

    testWidgets('onSelectionChanged fires on selection toggle', (tester) async {
      final selections = <Set<String>>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchList<String>(
              items: const ['Apple', 'Banana'],
              searchableFields: (item) => [item],
              selectionConfig: const SelectionConfiguration(),
              onSelectionChanged: (items) => selections.add(Set.from(items)),
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return Text(item);
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the first checkbox
      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();

      expect(selections.length, 1);
      expect(selections.last, {'Apple'});
    });
  });

  group('Widget builders', () {
    testWidgets('progressIndicatorBuilder renders when loading', (
      tester,
    ) async {
      final loadCompleter = Completer<List<String>>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchList<String>.async(
              asyncLoader: (query, {page = 0, pageSize = 20}) {
                return loadCompleter.future;
              },
              searchConfig: const SearchConfiguration(
                debounceDelay: Duration.zero,
              ),
              progressIndicatorBuilder: (context, isLoading) {
                return isLoading
                    ? const LinearProgressIndicator(key: Key('progress'))
                    : const SizedBox.shrink(key: Key('no-progress'));
              },
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return ListTile(title: Text(item));
              },
            ),
          ),
        ),
      );

      // Advance past the Duration.zero debounce timer
      await tester.pump(const Duration(milliseconds: 10));
      // Pump again to let the AnimatedBuilder rebuild with isLoading = true
      await tester.pump();
      expect(find.byKey(const Key('progress')), findsOneWidget);

      // Complete the load
      loadCompleter.complete(['Apple']);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('no-progress')), findsOneWidget);
    });

    testWidgets('searchFieldBuilder replaces default search field', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchList<String>(
              items: const ['Apple', 'Banana'],
              searchableFields: (item) => [item],
              searchFieldBuilder: (context, controller, focusNode, onClear) {
                return Container(
                  key: const Key('custom-search'),
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(hintText: 'Custom'),
                  ),
                );
              },
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return ListTile(title: Text(item));
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('custom-search')), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);
      // Default search field should not be present
      expect(find.byType(DefaultSearchField), findsNothing);
    });

    testWidgets('emptyStateBuilder renders when items empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchList<String>(
              items: const [],
              searchableFields: (item) => [item],
              emptyStateBuilder: (context) {
                return const Text('Nothing here', key: Key('custom-empty'));
              },
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return ListTile(title: Text(item));
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('custom-empty')), findsOneWidget);
      expect(find.text('Nothing here'), findsOneWidget);
      // Default empty widget should not be present
      expect(find.byType(DefaultEmptyWidget), findsNothing);
    });

    testWidgets('errorStateBuilder renders on async error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SmartSearchList<String>.async(
              asyncLoader: (query, {page = 0, pageSize = 20}) async {
                throw Exception('network error');
              },
              searchConfig: const SearchConfiguration(
                debounceDelay: Duration.zero,
              ),
              errorStateBuilder: (context, error, onRetry) {
                return Column(
                  key: const Key('custom-error'),
                  children: [
                    Text('Error: $error'),
                    TextButton(onPressed: onRetry, child: const Text('Retry')),
                  ],
                );
              },
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return ListTile(title: Text(item));
              },
            ),
          ),
        ),
      );
      // Let the debounce fire (zero) and the async error propagate
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('custom-error')), findsOneWidget);
      expect(find.textContaining('network error'), findsOneWidget);
    });
  });
}
