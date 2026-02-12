import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_search_list/smart_search_list.dart';

/// Helper: extracts the highlight [TextSpan] children from [SearchHighlightText].
///
/// `Text.rich(TextSpan(children: spans))` renders as:
///   RichText(text: TextSpan(style: effectiveStyle, children: [TextSpan(children: spans)]))
/// So we navigate: root → children[0] → children (the actual highlight spans).
List<TextSpan> _extractSpans(WidgetTester tester) {
  final richTextFinder = find.descendant(
    of: find.byType(SearchHighlightText),
    matching: find.byType(RichText),
  );
  final richText = tester.widget<RichText>(richTextFinder.first);
  final root = richText.text as TextSpan;
  final wrapper = root.children!.first as TextSpan;
  return List<TextSpan>.from(wrapper.children ?? []);
}

/// Helper: returns the concatenated text of highlighted (styled) spans.
String _highlightedText(List<TextSpan> spans) {
  return spans.where((s) => s.style != null).map((s) => s.text ?? '').join();
}

/// Helper: returns the concatenated text of non-highlighted spans.
String _plainText(List<TextSpan> spans) {
  return spans.where((s) => s.style == null).map((s) => s.text ?? '').join();
}

void main() {
  group('SearchHighlightText', () {
    // -----------------------------------------------------------------------
    // Basic exact highlighting
    // -----------------------------------------------------------------------

    testWidgets('highlights a single exact term', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchHighlightText(
              text: 'Apple Juice',
              searchTerms: ['Apple'],
            ),
          ),
        ),
      );

      final spans = _extractSpans(tester);
      expect(_highlightedText(spans), 'Apple');
      expect(_plainText(spans), ' Juice');
    });

    testWidgets('highlights multiple distinct terms', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchHighlightText(
              text: 'Apple Banana Cherry',
              searchTerms: ['Apple', 'Cherry'],
            ),
          ),
        ),
      );

      final spans = _extractSpans(tester);
      expect(_highlightedText(spans), 'AppleCherry');
      expect(_plainText(spans), ' Banana ');
    });

    testWidgets('highlights overlapping terms correctly', (tester) async {
      // "an" and "ban" both match in "Banana" — merged range
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchHighlightText(
              text: 'Banana',
              searchTerms: ['an', 'ban'],
            ),
          ),
        ),
      );

      final spans = _extractSpans(tester);
      // "ban" matches index 0-2, "an" matches indices 1-2 and 3-4
      // Merged: indices 0-4 highlighted => "Banan", plain: "a"
      expect(_highlightedText(spans), 'Banan');
      expect(_plainText(spans), 'a');
    });

    testWidgets('highlights all occurrences of a term', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchHighlightText(
              text: 'an ant on an anthill',
              searchTerms: ['an'],
            ),
          ),
        ),
      );

      final spans = _extractSpans(tester);
      expect(_highlightedText(spans), 'anananan');
    });

    // -----------------------------------------------------------------------
    // Case sensitivity
    // -----------------------------------------------------------------------

    testWidgets('matches case-insensitively by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchHighlightText(
              text: 'Apple APPLE apple',
              searchTerms: ['apple'],
            ),
          ),
        ),
      );

      final spans = _extractSpans(tester);
      // All three "apple" variants highlighted
      expect(_highlightedText(spans), 'AppleAPPLEapple');
    });

    testWidgets('respects caseSensitive: true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchHighlightText(
              text: 'Apple APPLE apple',
              searchTerms: ['Apple'],
              caseSensitive: true,
            ),
          ),
        ),
      );

      final spans = _extractSpans(tester);
      expect(_highlightedText(spans), 'Apple');
    });

    // -----------------------------------------------------------------------
    // Edge cases: empty text, empty terms, no match
    // -----------------------------------------------------------------------

    testWidgets('renders plain text when searchTerms is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchHighlightText(text: 'Hello World', searchTerms: []),
          ),
        ),
      );

      // Falls through to plain Text widget (no RichText with children)
      expect(find.text('Hello World'), findsOneWidget);
      // No RichText expected (plain Text renders via RichText internally,
      // but the widget tree has a Text, not Text.rich)
      final textWidget = tester.widget<Text>(find.text('Hello World'));
      expect(textWidget.textSpan, isNull);
    });

    testWidgets('renders plain text when text is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchHighlightText(text: '', searchTerms: ['test']),
          ),
        ),
      );

      // Empty text + non-empty terms => falls through to plain Text('')
      expect(find.text(''), findsOneWidget);
    });

    testWidgets('renders unstyled when no terms match', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchHighlightText(
              text: 'Hello World',
              searchTerms: ['xyz'],
            ),
          ),
        ),
      );

      final spans = _extractSpans(tester);
      expect(_highlightedText(spans), isEmpty);
      expect(_plainText(spans), 'Hello World');
    });

    // -----------------------------------------------------------------------
    // Custom styling
    // -----------------------------------------------------------------------

    testWidgets('applies custom matchStyle to highlighted spans', (
      tester,
    ) async {
      const customStyle = TextStyle(
        color: Colors.red,
        fontWeight: FontWeight.w900,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchHighlightText(
              text: 'Apple',
              searchTerms: ['Apple'],
              matchStyle: customStyle,
            ),
          ),
        ),
      );

      final spans = _extractSpans(tester);
      final styledSpan = spans.firstWhere((s) => s.style != null);
      expect(styledSpan.style!.color, Colors.red);
      expect(styledSpan.style!.fontWeight, FontWeight.w900);
    });

    testWidgets('applies highlightColor as background when no matchStyle', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchHighlightText(
              text: 'Apple',
              searchTerms: const ['Apple'],
              highlightColor: Colors.green.withValues(alpha: 0.5),
            ),
          ),
        ),
      );

      final spans = _extractSpans(tester);
      final styledSpan = spans.firstWhere((s) => s.style != null);
      expect(styledSpan.style!.backgroundColor!.a, closeTo(0.5, 0.01));
      expect(styledSpan.style!.fontWeight, FontWeight.bold);
    });

    // -----------------------------------------------------------------------
    // Fuzzy highlighting
    // -----------------------------------------------------------------------

    testWidgets('highlights fuzzy matches when fuzzySearchEnabled is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchHighlightText(
              text: 'Banana',
              searchTerms: ['bna'],
              fuzzySearchEnabled: true,
            ),
          ),
        ),
      );

      final spans = _extractSpans(tester);
      // Fuzzy "bna" against "Banana" should highlight B, n, a characters
      expect(_highlightedText(spans).isNotEmpty, isTrue);
    });

    testWidgets('fuzzy mode falls back gracefully when no fuzzy match', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchHighlightText(
              text: 'Apple',
              searchTerms: ['zzzzzz'],
              fuzzySearchEnabled: true,
            ),
          ),
        ),
      );

      final spans = _extractSpans(tester);
      expect(_highlightedText(spans), isEmpty);
      expect(_plainText(spans), 'Apple');
    });

    // -----------------------------------------------------------------------
    // Unicode
    // -----------------------------------------------------------------------

    testWidgets('handles Unicode accented characters', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchHighlightText(
              text: 'Café résumé',
              searchTerms: ['résumé'],
            ),
          ),
        ),
      );

      final spans = _extractSpans(tester);
      expect(_highlightedText(spans), 'résumé');
      expect(_plainText(spans), 'Café ');
    });

    testWidgets('handles CJK characters', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchHighlightText(text: '東京タワー', searchTerms: ['タワー']),
          ),
        ),
      );

      final spans = _extractSpans(tester);
      expect(_highlightedText(spans), 'タワー');
      expect(_plainText(spans), '東京');
    });
  });
}
