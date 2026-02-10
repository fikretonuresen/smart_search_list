/// Fuzzy search utilities for subsequence matching with scoring.
///
/// Provides a zero-dependency fuzzy matching algorithm optimized for
/// real-time search over short strings (product names, usernames, cities).
///
/// The algorithm uses **ordered subsequence matching**: every character in
/// the query must appear in the text *in order*, but not necessarily
/// consecutively. Scores favor consecutive runs and word-boundary alignment.
library;

/// Result of a fuzzy match attempt.
///
/// Contains the [score] (`[0.01, 1.0]`) and the character [matchIndices] in
/// the source text that were matched so consumers can highlight them.
class FuzzyMatchResult {
  /// Match score in the range `[0.01, 1.0]`.
  ///
  /// A score of **1.0** indicates an exact contiguous substring match.
  /// Non-exact matches are clamped to a minimum of **0.01**.
  final double score;

  /// Indices in the source text that matched the query characters, in order.
  ///
  /// For exact and subsequence matches the length equals the query length.
  /// For edit-distance fallback matches the length may differ (it spans the
  /// matched window in the source text).
  final List<int> matchIndices;

  /// Creates a match result with the given [score] and [matchIndices].
  const FuzzyMatchResult({required this.score, required this.matchIndices});

  /// Returns a human-readable representation including score and indices.
  @override
  String toString() =>
      'FuzzyMatchResult(score: ${score.toStringAsFixed(3)}, indices: $matchIndices)';
}

/// Provides fuzzy-matching via static, pure methods for subsequence and edit-distance searches.
abstract final class FuzzyMatcher {
  // -----------------------------------------------------------------------
  // Public API
  // -----------------------------------------------------------------------

  /// Maximum edit distance for the Levenshtein fallback.
  ///
  /// Queries with 1-2 extra/wrong characters are caught. Keeping this low
  /// ensures the fallback stays fast.
  static const int maxEditDistance = 2;

  /// Attempts to fuzzy-match [query] against [text].
  ///
  /// Returns `null` when the text does not contain every query character in
  /// order (i.e. no subsequence match exists) and the edit-distance fallback
  /// also fails.
  ///
  /// When [caseSensitive] is false (the default) both strings are compared
  /// in lower-case.
  ///
  /// The returned [FuzzyMatchResult.score] is in the range `[0.01, 1.0]`.
  /// A score of **1.0** means the query is an exact contiguous substring.
  /// Non-exact matches are clamped to a minimum of **0.01**.
  static FuzzyMatchResult? match(
    String query,
    String text, {
    bool caseSensitive = false,
  }) {
    if (query.isEmpty) return null;
    if (text.isEmpty) return null;

    final q = caseSensitive ? query : query.toLowerCase();
    final t = caseSensitive ? text : text.toLowerCase();

    // Fast path: exact substring match.
    if (q.length <= t.length) {
      final exactIndex = t.indexOf(q);
      if (exactIndex != -1) {
        return FuzzyMatchResult(
          score: 1.0,
          matchIndices: List<int>.generate(q.length, (i) => exactIndex + i),
        );
      }
    }

    // Phase 1: subsequence matching (handles missing characters in query).
    if (q.length <= t.length) {
      final subResult = _bestSubsequenceMatch(q, t);
      if (subResult != null) return subResult;
    }

    // Phase 2: bounded Levenshtein fallback (handles extra/wrong characters).
    // Only attempt when lengths are close – large length differences can't
    // produce a useful match within the edit distance bound.
    return _editDistanceFallback(q, t);
  }

  /// Scores a single item against [query] using multiple [fields].
  ///
  /// Returns the **best** (highest) score across all fields, or `null` when
  /// no field matches.
  static FuzzyMatchResult? matchFields(
    String query,
    List<String> fields, {
    bool caseSensitive = false,
  }) {
    FuzzyMatchResult? best;
    for (final field in fields) {
      final result = match(query, field, caseSensitive: caseSensitive);
      if (result != null && (best == null || result.score > best.score)) {
        best = result;
        if (best.score == 1.0) break; // Can't beat an exact match.
      }
    }
    return best;
  }

  // -----------------------------------------------------------------------
  // Internal: greedy subsequence with consecutive-run bonus
  // -----------------------------------------------------------------------

  /// Finds the best scoring subsequence match of [query] in [text].
  ///
  /// Strategy: run a greedy scan that, for each query character, picks the
  /// first occurrence in the remaining text. Then attempt to *improve* the
  /// result by sliding earlier matches forward when doing so would create
  /// longer consecutive runs.
  static FuzzyMatchResult? _bestSubsequenceMatch(String q, String t) {
    final qLen = q.length;

    // Phase 1 – greedy first-occurrence scan.
    final indices = List<int>.filled(qLen, 0);
    var tPos = 0;
    for (var i = 0; i < qLen; i++) {
      final idx = t.indexOf(q[i], tPos);
      if (idx == -1) return null; // No subsequence match.
      indices[i] = idx;
      tPos = idx + 1;
    }

    // Phase 2 – backward pass: try to pull matches closer together by
    // scanning backwards from the *next* match position.
    for (var i = qLen - 2; i >= 0; i--) {
      final maxPos = indices[i + 1] - 1;
      // Search backwards from maxPos for q[i] to get a tighter cluster.
      for (var j = maxPos; j > indices[i]; j--) {
        if (t[j] == q[i]) {
          indices[i] = j;
          break;
        }
      }
    }

    return FuzzyMatchResult(
      score: _score(q, t, indices),
      matchIndices: indices,
    );
  }

  // -----------------------------------------------------------------------
  // Scoring
  // -----------------------------------------------------------------------

  /// Compute a score in `[0.01, 0.99]` for the given match [indices].
  ///
  /// Factors (each normalized to 0–1, then weighted):
  ///   1. **Consecutive ratio** (weight 0.50) – proportion of matched chars
  ///      that are part of a consecutive run of ≥ 2.
  ///   2. **Density** (weight 0.25) – how tightly packed the matches are
  ///      relative to query length.
  ///   3. **Position** (weight 0.15) – earlier matches score higher.
  ///   4. **Word-boundary bonus** (weight 0.10) – first match at index 0 or
  ///      preceded by a space / punctuation.
  static double _score(String q, String t, List<int> indices) {
    final qLen = q.length;
    final tLen = t.length;

    if (qLen == 0 || tLen == 0) return 0.0;

    // 1. Consecutive ratio – count characters in consecutive runs.
    var consecutiveCount = 0;
    for (var i = 1; i < qLen; i++) {
      if (indices[i] == indices[i - 1] + 1) {
        consecutiveCount++;
        // Also count the start of the run.
        if (i == 1 || indices[i - 1] != indices[i - 2] + 1) {
          consecutiveCount++;
        }
      }
    }
    final consecutiveRatio = qLen <= 1 ? 1.0 : consecutiveCount / qLen;

    // 2. Density – span of match vs query length.
    final span = indices.last - indices.first + 1;
    final density = qLen / span; // 1.0 when fully consecutive.

    // 3. Position – normalized start position (0 = start of text).
    final position = 1.0 - (indices.first / tLen);

    // 4. Word-boundary bonus.
    final firstIndex = indices.first;
    final atBoundary = firstIndex == 0 || _isWordBoundary(t, firstIndex);
    final boundaryBonus = atBoundary ? 1.0 : 0.0;

    // Weighted sum.
    final raw =
        (consecutiveRatio * 0.50) +
        (density * 0.25) +
        (position * 0.15) +
        (boundaryBonus * 0.10);

    // Clamp to (0, 1) – never return 1.0 for non-exact matches.
    return raw.clamp(0.01, 0.99);
  }

  // -----------------------------------------------------------------------
  // Internal: bounded Levenshtein fallback for extra/wrong characters
  // -----------------------------------------------------------------------

  /// Attempt edit-distance matching of [query] against sliding windows of
  /// [text]. Returns a low-scored result when a window is within
  /// [maxEditDistance] edits, or `null` if nothing is close enough.
  static FuzzyMatchResult? _editDistanceFallback(String q, String t) {
    final qLen = q.length;
    final tLen = t.length;

    // Try windows of varying sizes around the query length.
    int bestDistance = maxEditDistance + 1;
    int bestWindowStart = 0;
    int bestWindowLen = qLen;

    // Window sizes: from (qLen - maxEditDistance) to (qLen + maxEditDistance),
    // clamped to valid range.
    // Window must be at least half the query length to avoid nonsensical
    // matches (e.g. single-char window matching a 3-char query).
    final minWinRaw = (qLen - maxEditDistance).clamp(1, qLen);
    final minWin = (minWinRaw < qLen ~/ 2 + 1) ? qLen ~/ 2 + 1 : minWinRaw;
    if (minWin > tLen) return null; // Text too short for any reasonable match.
    final maxWin = (qLen + maxEditDistance).clamp(minWin, tLen);

    for (var winLen = minWin; winLen <= maxWin; winLen++) {
      for (var start = 0; start <= tLen - winLen; start++) {
        final window = t.substring(start, start + winLen);
        final dist = _boundedLevenshtein(q, window, maxEditDistance);
        if (dist < bestDistance) {
          bestDistance = dist;
          bestWindowStart = start;
          bestWindowLen = winLen;
          if (dist == 0) break; // Perfect match in window.
        }
      }
      if (bestDistance == 0) break;
    }

    if (bestDistance > maxEditDistance) return null;

    // Reject matches where the edit distance is too large relative to query
    // length. E.g. "bbb" matching "ban" (distance 2, qLen 3) is nonsensical.
    // Reject when edit distance is too high relative to query length.
    // For short queries especially, 2 edits out of 3 chars is nonsensical.
    if (bestDistance * 3 >= qLen * 2) return null;

    // Build match indices: highlight the matched window characters.
    final indices = List<int>.generate(
      bestWindowLen,
      (i) => bestWindowStart + i,
    );

    // Score: penalize based on edit distance. Max score for fallback is 0.6.
    final distancePenalty = bestDistance / (qLen.clamp(1, 100));
    final positionBonus = 1.0 - (bestWindowStart / tLen);
    final boundaryBonus =
        (bestWindowStart == 0 || _isWordBoundary(t, bestWindowStart))
        ? 0.1
        : 0.0;

    final score =
        ((0.6 - distancePenalty * 0.3) + boundaryBonus + positionBonus * 0.05)
            .clamp(0.01, 0.59);

    return FuzzyMatchResult(score: score, matchIndices: indices);
  }

  /// Levenshtein distance with early termination when distance exceeds [max].
  ///
  /// Returns `max + 1` when the strings are further apart than [max].
  static int _boundedLevenshtein(String a, String b, int max) {
    final aLen = a.length;
    final bLen = b.length;

    // Quick length-difference check.
    if ((aLen - bLen).abs() > max) return max + 1;

    // Single-row DP with early termination.
    var row = List<int>.generate(bLen + 1, (i) => i);

    for (var i = 1; i <= aLen; i++) {
      var prev = row[0];
      row[0] = i;
      var rowMin = row[0];

      for (var j = 1; j <= bLen; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        final temp = row[j];
        row[j] = _min3(
          row[j] + 1, // deletion
          row[j - 1] + 1, // insertion
          prev + cost, // substitution
        );
        prev = temp;
        if (row[j] < rowMin) rowMin = row[j];
      }

      // Early termination: if minimum value in this row exceeds max,
      // the final result will too.
      if (rowMin > max) return max + 1;
    }

    return row[bLen];
  }

  static int _min3(int a, int b, int c) {
    if (a <= b && a <= c) return a;
    return b <= c ? b : c;
  }

  /// Whether [index] in [text] sits at a word boundary (preceded by
  /// whitespace or common punctuation).
  static bool _isWordBoundary(String text, int index) {
    if (index <= 0) return true;
    final prev = text[index - 1];
    return prev == ' ' ||
        prev == '-' ||
        prev == '_' ||
        prev == '.' ||
        prev == ',' ||
        prev == '/' ||
        prev == '(' ||
        prev == ')';
  }
}
