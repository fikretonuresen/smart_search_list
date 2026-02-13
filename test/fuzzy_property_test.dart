import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_search_list/smart_search_list.dart';

import 'helpers/fuzzy_test_helpers.dart';

void main() {
  group('FuzzyMatcher property tests', () {
    // =========================================================================
    // Test 1: Exact substring invariants
    // =========================================================================
    test('exact substring invariants', () {
      final masterRng = Random(101);
      for (var trial = 0; trial < 200; trial++) {
        final seed = masterRng.nextInt(1 << 30);
        final rng = Random(seed);
        final text = randomText(rng, 5, 40);

        for (var pair = 0; pair < 5; pair++) {
          final query = randomSubstring(rng, text);
          final result = FuzzyMatcher.match(query, text);
          final tag = _tag(seed, trial, pair, 'exact substring');

          expect(result, isNotNull, reason: '$tag: result must not be null');
          expect(result!.score, 1.0, reason: '$tag: score must be 1.0');
          expect(
            result.matchIndices.length,
            query.length,
            reason: '$tag: indices.length must equal query.length',
          );

          // Indices must be consecutive.
          for (var i = 1; i < result.matchIndices.length; i++) {
            expect(
              result.matchIndices[i],
              result.matchIndices[i - 1] + 1,
              reason: '$tag: indices must be consecutive at $i',
            );
          }

          // Indices in bounds.
          for (final idx in result.matchIndices) {
            expect(idx, greaterThanOrEqualTo(0), reason: '$tag: idx >= 0');
            expect(idx, lessThan(text.length), reason: '$tag: idx < text.len');
          }
        }
      }
    });

    // =========================================================================
    // Test 2: Subsequence invariants
    // =========================================================================
    test('subsequence invariants', () {
      final masterRng = Random(102);
      for (var trial = 0; trial < 200; trial++) {
        final seed = masterRng.nextInt(1 << 30);
        final rng = Random(seed);
        final text = randomText(rng, 8, 40);

        for (var pair = 0; pair < 5; pair++) {
          final query = randomSubsequence(rng, text);
          final result = FuzzyMatcher.match(query, text);
          final tag = _tag(seed, trial, pair, 'subsequence');

          expect(result, isNotNull, reason: '$tag: result must not be null');
          expect(
            result!.matchIndices.length,
            query.length,
            reason: '$tag: indices.length must equal query.length',
          );

          // Indices strictly increasing.
          for (var i = 1; i < result.matchIndices.length; i++) {
            expect(
              result.matchIndices[i],
              greaterThan(result.matchIndices[i - 1]),
              reason: '$tag: indices must be strictly increasing at $i',
            );
          }

          // If the query is NOT a contiguous substring, score must be < 1.0.
          final isContiguous = text.toLowerCase().contains(query.toLowerCase());
          if (!isContiguous) {
            expect(
              result.score,
              lessThan(1.0),
              reason: '$tag: non-contiguous subsequence score must be < 1.0',
            );
          }

          // Score in valid range.
          expect(
            result.score,
            greaterThanOrEqualTo(0.01),
            reason: '$tag: score >= 0.01',
          );
          expect(
            result.score,
            lessThanOrEqualTo(1.0),
            reason: '$tag: score <= 1.0',
          );

          // Indices in bounds.
          for (final idx in result.matchIndices) {
            expect(idx, greaterThanOrEqualTo(0), reason: '$tag: idx >= 0');
            expect(idx, lessThan(text.length), reason: '$tag: idx < text.len');
          }
        }
      }
    });

    // =========================================================================
    // Test 3: Edit distance invariants
    // =========================================================================
    test('edit distance invariants', () {
      final masterRng = Random(103);
      for (var trial = 0; trial < 200; trial++) {
        final seed = masterRng.nextInt(1 << 30);
        final rng = Random(seed);
        final text = randomText(rng, 10, 40);

        for (var pair = 0; pair < 5; pair++) {
          // Take a substring and apply edits.
          final base = randomSubstring(rng, text);
          final query = applyEdits(rng, base, 1 + rng.nextInt(2));
          final result = FuzzyMatcher.match(query, text);
          final tag = _tag(seed, trial, pair, 'edit distance');

          // The edit distance path may reject if ratio filter fails.
          if (result == null) continue;

          // Universal invariants for any non-null result.
          expect(
            result.score,
            greaterThanOrEqualTo(0.01),
            reason: '$tag: score >= 0.01',
          );
          expect(
            result.score,
            lessThanOrEqualTo(1.0),
            reason: '$tag: score <= 1.0',
          );
          expect(
            result.matchIndices,
            isNotEmpty,
            reason: '$tag: indices must not be empty',
          );

          // Indices in bounds.
          for (final idx in result.matchIndices) {
            expect(idx, greaterThanOrEqualTo(0), reason: '$tag: idx >= 0');
            expect(idx, lessThan(text.length), reason: '$tag: idx < text.len');
          }

          // Indices non-decreasing (holds for both subsequence and edit
          // distance paths — we can't distinguish which path matched).
          for (var i = 1; i < result.matchIndices.length; i++) {
            expect(
              result.matchIndices[i],
              greaterThanOrEqualTo(result.matchIndices[i - 1]),
              reason: '$tag: indices must be non-decreasing at $i',
            );
          }
        }
      }
    });

    // =========================================================================
    // Test 4: Random pairs — universal invariants
    // =========================================================================
    test('random pairs: universal invariants', () {
      final masterRng = Random(104);
      for (var trial = 0; trial < 200; trial++) {
        final seed = masterRng.nextInt(1 << 30);
        final rng = Random(seed);

        for (var pair = 0; pair < 5; pair++) {
          final query = randomText(rng, 1, 10);
          final text = randomText(rng, 1, 40);
          final result = FuzzyMatcher.match(query, text);
          final tag = _tag(seed, trial, pair, 'random pair');

          if (result == null) continue;

          expect(
            result.score,
            greaterThanOrEqualTo(0.01),
            reason: '$tag: score >= 0.01',
          );
          expect(
            result.score,
            lessThanOrEqualTo(1.0),
            reason: '$tag: score <= 1.0',
          );
          expect(
            result.matchIndices,
            isNotEmpty,
            reason: '$tag: indices must not be empty',
          );

          // Indices in bounds.
          for (final idx in result.matchIndices) {
            expect(idx, greaterThanOrEqualTo(0), reason: '$tag: idx >= 0');
            expect(idx, lessThan(text.length), reason: '$tag: idx < text.len');
          }

          // Indices strictly increasing (for exact + subsequence paths)
          // or consecutive (for edit distance path).
          // Both satisfy: indices[i] >= indices[i-1].
          for (var i = 1; i < result.matchIndices.length; i++) {
            expect(
              result.matchIndices[i],
              greaterThanOrEqualTo(result.matchIndices[i - 1]),
              reason: '$tag: indices must be non-decreasing at $i',
            );
          }
        }
      }
    });

    // =========================================================================
    // Test 5: Idempotence
    // =========================================================================
    test('idempotence', () {
      final masterRng = Random(105);
      for (var trial = 0; trial < 200; trial++) {
        final seed = masterRng.nextInt(1 << 30);
        final rng = Random(seed);

        for (var pair = 0; pair < 5; pair++) {
          final query = randomText(rng, 1, 10);
          final text = randomText(rng, 1, 40);
          final tag = _tag(seed, trial, pair, 'idempotence');

          final r1 = FuzzyMatcher.match(query, text);
          final r2 = FuzzyMatcher.match(query, text);

          if (r1 == null) {
            expect(r2, isNull, reason: '$tag: both must be null');
            continue;
          }

          expect(r2, isNotNull, reason: '$tag: both must be non-null');
          expect(r1.score, r2!.score, reason: '$tag: scores must match');
          expect(
            r1.matchIndices,
            r2.matchIndices,
            reason: '$tag: indices must match',
          );
        }
      }
    });

    // =========================================================================
    // Test 6: Case-insensitive symmetry
    // =========================================================================
    test('case-insensitive symmetry', () {
      final masterRng = Random(106);
      for (var trial = 0; trial < 200; trial++) {
        final seed = masterRng.nextInt(1 << 30);
        final rng = Random(seed);

        for (var pair = 0; pair < 5; pair++) {
          final query = randomText(rng, 1, 10);
          final text = randomText(rng, 1, 40);
          final tag = _tag(seed, trial, pair, 'case symmetry');

          final upper = FuzzyMatcher.match(query.toUpperCase(), text);
          final lower = FuzzyMatcher.match(query.toLowerCase(), text);

          if (upper == null) {
            expect(lower, isNull, reason: '$tag: both must be null');
            continue;
          }

          expect(lower, isNotNull, reason: '$tag: both must be non-null');
          expect(upper.score, lower!.score, reason: '$tag: scores must match');
          expect(
            upper.matchIndices,
            lower.matchIndices,
            reason: '$tag: indices must match',
          );
        }
      }
    });

    // =========================================================================
    // Test 7: matchFields returns best score
    // =========================================================================
    test('matchFields returns best score', () {
      final masterRng = Random(107);
      for (var trial = 0; trial < 200; trial++) {
        final seed = masterRng.nextInt(1 << 30);
        final rng = Random(seed);

        for (var pair = 0; pair < 3; pair++) {
          final query = randomText(rng, 1, 8);
          final fields = List.generate(3, (_) => randomText(rng, 3, 30));
          final tag = _tag(seed, trial, pair, 'matchFields');

          final multi = FuzzyMatcher.matchFields(query, fields);

          // Compute expected best by calling match() on each field.
          FuzzyMatchResult? expectedBest;
          for (final field in fields) {
            final r = FuzzyMatcher.match(query, field);
            if (r != null &&
                (expectedBest == null || r.score > expectedBest.score)) {
              expectedBest = r;
            }
          }

          if (expectedBest == null) {
            expect(multi, isNull, reason: '$tag: null iff all matches null');
            continue;
          }

          expect(multi, isNotNull, reason: '$tag: non-null when match exists');
          expect(
            multi!.score,
            expectedBest.score,
            reason: '$tag: score must equal best individual score',
          );
        }
      }
    });

    // =========================================================================
    // Test 8: Score 1.0 biconditional
    // =========================================================================
    test('score 1.0 biconditional', () {
      final masterRng = Random(108);
      for (var trial = 0; trial < 200; trial++) {
        final seed = masterRng.nextInt(1 << 30);
        final rng = Random(seed);

        for (var pair = 0; pair < 5; pair++) {
          final query = randomText(rng, 1, 10);
          final text = randomText(rng, 1, 40);
          final result = FuzzyMatcher.match(query, text);
          final tag = _tag(seed, trial, pair, 'score 1.0 biconditional');

          final isContiguous = text.toLowerCase().contains(query.toLowerCase());

          if (result == null) {
            // No match at all — contiguous check is irrelevant.
            continue;
          }

          if (isContiguous) {
            expect(
              result.score,
              1.0,
              reason: '$tag: contiguous substring must yield score 1.0',
            );
          } else {
            expect(
              result.score,
              lessThan(1.0),
              reason: '$tag: non-contiguous must yield score < 1.0',
            );
          }
        }
      }
    });
  });
}

// =============================================================================
// Helpers
// =============================================================================

String _tag(int seed, int trial, int pair, String detail) =>
    'trial=$trial seed=$seed pair=$pair: $detail';
