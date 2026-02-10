import 'package:flutter/material.dart';
import '../core/fuzzy_utils.dart';

/// A widget that highlights matched portions of [text] based on [searchTerms].
///
/// Supports both exact substring and fuzzy (subsequence) highlighting.
/// When [fuzzySearchEnabled] is true, the widget uses [FuzzyMatcher] to find
/// the best match and highlights the individual matched characters.
///
/// Example – exact highlighting:
/// ```dart
/// SearchHighlightText(
///   text: 'Apple Juice',
///   searchTerms: ['app'],
/// )
/// ```
///
/// Example – fuzzy highlighting:
/// ```dart
/// SearchHighlightText(
///   text: 'Apple Juice',
///   searchTerms: ['aplj'],
///   fuzzySearchEnabled: true,
/// )
/// ```
class SearchHighlightText extends StatelessWidget {
  /// The full text to display.
  final String text;

  /// Search terms to highlight. Each term is matched independently.
  final List<String> searchTerms;

  /// Style for non-matching text. Defaults to the ambient [DefaultTextStyle].
  final TextStyle? style;

  /// Style for matching text. Defaults to bold with [highlightColor].
  final TextStyle? matchStyle;

  /// Background color applied to matched characters.
  ///
  /// Ignored when [matchStyle] is provided, because the entire
  /// [matchStyle] is used as-is for matched text.
  /// Defaults to `Colors.yellow.withValues(alpha: 0.3)`.
  final Color? highlightColor;

  /// Whether to use fuzzy (subsequence) matching instead of exact substring.
  final bool fuzzySearchEnabled;

  /// Whether matching is case-sensitive.
  final bool caseSensitive;

  /// Maximum number of lines. Defaults to unlimited.
  final int? maxLines;

  /// How overflowing text is handled when [maxLines] is exceeded.
  final TextOverflow? overflow;

  /// How the text is aligned horizontally.
  final TextAlign? textAlign;

  /// Creates a text widget that highlights characters matching [searchTerms].
  const SearchHighlightText({
    super.key,
    required this.text,
    this.searchTerms = const [],
    this.style,
    this.matchStyle,
    this.highlightColor,
    this.fuzzySearchEnabled = false,
    this.caseSensitive = false,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty || searchTerms.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      );
    }

    final effectiveMatchStyle =
        matchStyle ??
        (style ?? DefaultTextStyle.of(context).style).copyWith(
          fontWeight: FontWeight.bold,
          backgroundColor:
              highlightColor ?? Colors.yellow.withValues(alpha: 0.3),
        );

    final spans = fuzzySearchEnabled
        ? _buildFuzzySpans(effectiveMatchStyle)
        : _buildExactSpans(effectiveMatchStyle);

    return Text.rich(
      TextSpan(children: spans),
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }

  // ---------------------------------------------------------------------------
  // Exact substring highlighting
  // ---------------------------------------------------------------------------

  List<TextSpan> _buildExactSpans(TextStyle matchStyle) {
    // Collect all match ranges across all search terms.
    final matched = List<bool>.filled(text.length, false);

    final lowerText = caseSensitive ? text : text.toLowerCase();

    for (final term in searchTerms) {
      if (term.isEmpty) continue;
      final lowerTerm = caseSensitive ? term : term.toLowerCase();
      var start = 0;
      while (true) {
        final idx = lowerText.indexOf(lowerTerm, start);
        if (idx == -1) break;
        for (var i = idx; i < idx + lowerTerm.length && i < text.length; i++) {
          matched[i] = true;
        }
        start = idx + 1;
      }
    }

    return _spansFromMatchArray(matched, matchStyle);
  }

  // ---------------------------------------------------------------------------
  // Fuzzy (subsequence) highlighting
  // ---------------------------------------------------------------------------

  List<TextSpan> _buildFuzzySpans(TextStyle matchStyle) {
    final matched = List<bool>.filled(text.length, false);

    for (final term in searchTerms) {
      if (term.isEmpty) continue;
      final result = FuzzyMatcher.match(
        term,
        text,
        caseSensitive: caseSensitive,
      );
      if (result != null) {
        for (final idx in result.matchIndices) {
          if (idx < text.length) matched[idx] = true;
        }
      }
    }

    return _spansFromMatchArray(matched, matchStyle);
  }

  // ---------------------------------------------------------------------------
  // Shared: build TextSpan list from boolean match array
  // ---------------------------------------------------------------------------

  List<TextSpan> _spansFromMatchArray(
    List<bool> matched,
    TextStyle matchStyle,
  ) {
    final spans = <TextSpan>[];
    var i = 0;

    while (i < text.length) {
      final isMatch = matched[i];
      final start = i;
      while (i < text.length && matched[i] == isMatch) {
        i++;
      }
      spans.add(
        TextSpan(
          text: text.substring(start, i),
          style: isMatch ? matchStyle : null,
        ),
      );
    }

    return spans;
  }
}
