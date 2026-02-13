import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_search_list/smart_search_list.dart';

void main() {
  group('DefaultEmptySearchWidget', () {
    testWidgets('renders query text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DefaultEmptySearchWidget(searchQuery: 'xyz')),
        ),
      );

      expect(find.textContaining('xyz'), findsOneWidget);
      expect(find.text('No results found'), findsOneWidget);
    });

    testWidgets('renders empty query fallback', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DefaultEmptySearchWidget(searchQuery: '')),
        ),
      );

      expect(find.text('No results found'), findsOneWidget);
      expect(find.text('Try a different search term.'), findsOneWidget);
    });
  });

  group('DefaultLoadMoreWidget', () {
    testWidgets('renders progress indicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: DefaultLoadMoreWidget())),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('DefaultLoadingWidget', () {
    testWidgets('renders centered progress indicator', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: DefaultLoadingWidget())),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Center), findsOneWidget);
    });
  });

  group('DefaultEmptyWidget', () {
    testWidgets('renders icon and text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: DefaultEmptyWidget())),
      );

      expect(find.text('No items to display'), findsOneWidget);
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    });
  });

  group('DefaultErrorWidget', () {
    testWidgets('renders error and retry button', (tester) async {
      var retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DefaultErrorWidget(
              error: Exception('test error'),
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.textContaining('test error'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      expect(retried, isTrue);
    });
  });

  group('DefaultGroupHeader', () {
    testWidgets('renders with semantic header', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DefaultGroupHeader(groupValue: 'Fruits', itemCount: 3),
          ),
        ),
      );

      expect(find.text('Fruits (3)'), findsOneWidget);

      // Verify Semantics(header: true) is a direct descendant of DefaultGroupHeader
      final headerSemantics = find.descendant(
        of: find.byType(DefaultGroupHeader),
        matching: find.byType(Semantics),
      );
      final semantics = tester.widget<Semantics>(headerSemantics.first);
      expect(semantics.properties.header, isTrue);
    });
  });
}
