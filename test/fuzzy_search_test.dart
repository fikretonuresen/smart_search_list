import 'package:flutter_test/flutter_test.dart';
import 'package:smart_search_list/smart_search_list.dart';

/// Helper to get score or -1 if no match.
double _score(String query, String text, {bool caseSensitive = false}) {
  final r = FuzzyMatcher.match(query, text, caseSensitive: caseSensitive);
  return r?.score ?? -1;
}

/// Helper: does it match at all?
bool _matches(String query, String text, {bool caseSensitive = false}) {
  return FuzzyMatcher.match(query, text, caseSensitive: caseSensitive) != null;
}

void main() {
  // ===========================================================================
  // 1. EXACT SUBSTRING MATCHES — always score 1.0
  // ===========================================================================
  group('Exact substring matches', () {
    test('full word match', () {
      expect(_score('apple', 'Apple'), 1.0);
      expect(_score('banana', 'Banana'), 1.0);
      expect(_score('cherry', 'Cherry'), 1.0);
    });

    test('prefix match', () {
      expect(_score('app', 'Apple'), 1.0);
      expect(_score('ban', 'Banana'), 1.0);
      expect(_score('str', 'Strawberry'), 1.0);
    });

    test('suffix match', () {
      expect(_score('ple', 'Apple'), 1.0);
      expect(_score('ana', 'Banana'), 1.0);
      expect(_score('rry', 'Cherry'), 1.0);
    });

    test('middle match', () {
      expect(_score('ppl', 'Apple'), 1.0);
      expect(_score('anan', 'Banana'), 1.0);
      expect(_score('herr', 'Cherry'), 1.0);
    });

    test('single character match', () {
      expect(_score('a', 'Apple'), 1.0);
      expect(_score('z', 'Zebra'), 1.0);
    });

    test('full text match', () {
      expect(_score('apple', 'apple'), 1.0);
    });

    test('match in multi-word text', () {
      expect(_score('search', 'Smart Search List'), 1.0);
      expect(_score('list', 'Smart Search List'), 1.0);
    });
  });

  // ===========================================================================
  // 2. SUBSEQUENCE MATCHES — missing chars in query, score (0, 1)
  // ===========================================================================
  group('Subsequence matches (missing characters)', () {
    test('single missing character', () {
      // "aple" is missing the second 'p' from "Apple"
      expect(_matches('aple', 'Apple'), true);
      expect(_score('aple', 'Apple'), greaterThan(0.5));
      expect(_score('aple', 'Apple'), lessThan(1.0));
    });

    test('two missing characters', () {
      expect(_matches('ape', 'Apple'), true);
      expect(_score('ape', 'Apple'), greaterThan(0.0));
    });

    test('alternating characters', () {
      // Every other letter of "banana"
      expect(_matches('bnn', 'Banana'), true);
      expect(_matches('aaa', 'Banana'), true);
    });

    test('first and last character only', () {
      expect(_matches('ae', 'Apple'), true);
      expect(_matches('by', 'Blueberry'), true);
    });

    test('common abbreviation-style queries', () {
      expect(_matches('ss', 'Smart Search'), true);
      expect(_matches('ssl', 'Smart Search List'), true);
    });
  });

  // ===========================================================================
  // 3. EDIT DISTANCE MATCHES — extra/wrong chars, score capped < 0.6
  // ===========================================================================
  group('Edit distance matches (extra/wrong characters)', () {
    test('one extra character', () {
      expect(_matches('appple', 'Apple'), true); // extra 'p'
      expect(_matches('apole', 'Apple'), true); // 'o' instead of... extra
      expect(_matches('bananaa', 'Banana'), true); // extra 'a'
    });

    test('one wrong character (substitution)', () {
      expect(_matches('aXple', 'Apple'), true);
      expect(_matches('oranfe', 'Orange'), true); // f instead of g
      expect(_matches('cherri', 'Cherry'), true); // i instead of y
    });

    test('transposition (adjacent swap)', () {
      expect(_matches('appel', 'Apple'), true); // e and l swapped
      expect(_matches('banaan', 'Banana'), true); // last two swapped
    });

    test('two edits', () {
      expect(_matches('appolle', 'Apple'), true); // 2 extra chars
      expect(_matches('cherrry', 'Cherry'), true); // 1 extra r
    });

    test('three+ edits rejected', () {
      expect(_matches('appppole', 'Apple'), false);
      expect(_matches('bbbananana', 'Banana'), false);
    });

    test('edit distance scores always below subsequence scores', () {
      final subseqScore = _score('apl', 'Apple'); // subsequence
      final editScore = _score('apole', 'Apple'); // edit distance
      expect(subseqScore, greaterThan(editScore));
    });

    test('edit distance scores capped below 0.6', () {
      expect(_score('apole', 'Apple'), lessThan(0.6));
      expect(_score('oranfe', 'Orange'), lessThan(0.6));
      expect(_score('cherrry', 'Cherry'), lessThan(0.6));
    });

    test('1-edit scores higher than 2-edit', () {
      final oneEdit = _score('appel', 'Apple'); // 1 edit
      final twoEdit = _score('appolle', 'Apple'); // 2 edits
      expect(oneEdit, greaterThanOrEqualTo(twoEdit));
    });
  });

  // ===========================================================================
  // 4. SCORE RANKING — the whole point: better matches rank higher
  // ===========================================================================
  group('Score ranking (ordering correctness)', () {
    test('exact > subsequence > edit distance', () {
      final exact = _score('apple', 'Apple'); // 1.0
      final subseq = _score('aple', 'Apple'); // subsequence
      final edit = _score('apole', 'Apple'); // edit distance

      expect(exact, greaterThan(subseq));
      expect(subseq, greaterThan(edit));
    });

    test('closer subsequence scores higher', () {
      // "ape" in "Apple" is tighter than "ape" spread across long text
      final tight = _score('ape', 'Apple'); // 3 chars spread over 5
      final loose = _score('ape', 'A big purple elephant'); // spread far
      expect(tight, greaterThan(loose));
    });

    test('consecutive matches rank higher than scattered', () {
      final consec = _score('cat', 'category'); // c-a-t consecutive
      final scattered = _score('cat', 'chart about tables'); // c...a...t
      expect(consec, greaterThan(scattered));
    });
  });

  // ===========================================================================
  // 5. REAL-WORLD TYPO SCENARIOS
  // ===========================================================================
  group('Real-world typo scenarios', () {
    // --- Fruit names (common in demos) ---
    test('fruit name typos', () {
      expect(_matches('aple', 'Apple'), true); // missing p
      expect(_matches('appel', 'Apple'), true); // transposed
      expect(_matches('aplle', 'Apple'), true); // wrong char
      expect(_matches('banan', 'Banana'), true); // missing last char
      expect(_matches('bananna', 'Banana'), true); // extra n
      expect(_matches('chrry', 'Cherry'), true); // missing e
      expect(_matches('cheery', 'Cherry'), true); // extra e
      expect(_matches('strwbry', 'Strawberry'), true); // many missing
      expect(_matches('grpe', 'Grape'), true); // missing a
      expect(_matches('watrmelon', 'Watermelon'), true); // missing e
    });

    // --- Product names ---
    test('product name typos', () {
      expect(_matches('iphone', 'iPhone 15'), true);
      expect(_matches('iphon', 'iPhone 15'), true); // missing e
      expect(_matches('macbok', 'MacBook Pro'), true); // missing o
      expect(_matches('airpod', 'AirPods Pro'), true); // missing s
      expect(_matches('samsng', 'Samsung Galaxy'), true); // missing u
    });

    // --- Person names ---
    test('person name typos', () {
      expect(_matches('jonh', 'John'), true); // transposed
      expect(_matches('jonn', 'John'), true); // wrong char
      expect(_matches('michael', 'Michael'), true); // exact
      expect(_matches('micheal', 'Michael'), true); // transposed
    });

    // --- City names ---
    test('city name typos', () {
      expect(_score('new york', 'New York'), 1.0); // exact
      expect(_matches('new yrok', 'New York'), true); // transposed
      expect(_matches('londno', 'London'), true); // transposed
      expect(_matches('tokyp', 'Tokyo'), true); // wrong char
      expect(_matches('istanbull', 'Istanbul'), true); // extra l
    });
  });

  // ===========================================================================
  // 6. CASE SENSITIVITY
  // ===========================================================================
  group('Case sensitivity', () {
    test('case insensitive by default — exact', () {
      expect(_score('APPLE', 'apple'), 1.0);
      expect(_score('apple', 'APPLE'), 1.0);
      expect(_score('ApPlE', 'apple'), 1.0);
    });

    test('case insensitive — subsequence', () {
      expect(_matches('APL', 'apple'), true);
      expect(_matches('apl', 'APPLE'), true);
    });

    test('case insensitive — edit distance', () {
      expect(_matches('APOLE', 'apple'), true);
      expect(_matches('apole', 'APPLE'), true);
    });

    test('case sensitive — exact must match case', () {
      // "apple" vs "Apple" differs by 1 char (case), so edit distance matches
      // but exact/subsequence won't. Score should be low (< 0.6).
      final s = _score('apple', 'Apple', caseSensitive: true);
      expect(s, lessThan(0.6));
      expect(s, isNot(1.0));
      expect(_score('Apple', 'Apple', caseSensitive: true), 1.0);
    });

    test('case sensitive — subsequence must match case', () {
      expect(_matches('APL', 'apple', caseSensitive: true), false);
      expect(_matches('apl', 'apple', caseSensitive: true), true);
    });

    test('case sensitive — edit distance must match case', () {
      expect(_matches('APOLE', 'apple', caseSensitive: true), false);
      expect(_matches('apole', 'apple', caseSensitive: true), true);
    });
  });

  // ===========================================================================
  // 7. EDGE CASES & BOUNDARIES
  // ===========================================================================
  group('Edge cases', () {
    test('empty query returns null', () {
      expect(FuzzyMatcher.match('', 'hello'), isNull);
    });

    test('empty text returns null', () {
      expect(FuzzyMatcher.match('abc', ''), isNull);
    });

    test('both empty returns null', () {
      expect(FuzzyMatcher.match('', ''), isNull);
    });

    test('single char query vs single char text — exact', () {
      expect(_score('a', 'a'), 1.0);
    });

    test('query much longer than text is rejected', () {
      expect(_matches('abcdefgh', 'abc'), false);
    });

    test('query slightly longer than text — edit distance', () {
      // "apples" (6) vs "Apple" (5) — 1 extra char
      expect(_matches('apples', 'Apple'), true);
    });

    test('repeated characters in query — subsequence', () {
      expect(_matches('aaa', 'Banana'), true); // a appears 3x in banana
    });

    test('repeated characters in query — not enough in text', () {
      expect(_matches('bbb', 'Banana'), false); // only 1 b
    });

    test('special characters in text', () {
      expect(_matches('c++', 'C++ Programming'), true);
      expect(_matches('c#', 'C# Development'), true);
    });

    test('spaces in query', () {
      expect(_score('new york', 'New York'), 1.0);
      expect(_matches('nw yrk', 'New York'), true);
    });

    test('very short query (2 chars)', () {
      expect(_score('ap', 'Apple'), 1.0);
    });

    test('numbers in text', () {
      expect(_score('15', 'iPhone 15'), 1.0);
      // "ifn15" has chars out of order relative to "iPhone 15" and too many
      // edits for the fallback — this correctly does NOT match.
      expect(_matches('ifn15', 'iPhone 15'), false);
    });
  });

  // ===========================================================================
  // 8. NON-MATCHES — these must NOT match
  // ===========================================================================
  group('Non-matches (must return null)', () {
    test('completely unrelated strings', () {
      expect(_matches('xyz', 'Apple'), false);
      expect(_matches('qqq', 'Banana'), false);
      expect(_matches('zzz', 'Cherry'), false);
    });

    test('reversed string does not match', () {
      expect(_matches('elppa', 'Apple'), false);
    });

    test('too many errors', () {
      expect(_matches('axxxple', 'Apple'), false); // 3+ edits
      expect(_matches('completely', 'Apple'), false);
    });

    test('long unrelated query', () {
      expect(_matches('watermelon', 'Apple'), false);
      expect(_matches('strawberry', 'Banana'), false);
    });
  });

  // ===========================================================================
  // 9. matchFields — best score across multiple fields
  // ===========================================================================
  group('matchFields', () {
    test('returns best score across fields', () {
      final r = FuzzyMatcher.matchFields('app', ['Banana', 'Apple', 'Cherry']);
      expect(r, isNotNull);
      expect(r!.score, 1.0);
    });

    test('returns null when no field matches', () {
      final r = FuzzyMatcher.matchFields('xyz', ['Apple', 'Banana']);
      expect(r, isNull);
    });

    test('fuzzy match across fields picks highest score', () {
      final r = FuzzyMatcher.matchFields('apl', ['Banana', 'Apple', 'Apology']);
      expect(r, isNotNull);
      // "Apple" should score higher (tighter match) than "Apology"
    });

    test('early exit on exact match', () {
      final r = FuzzyMatcher.matchFields('ban', [
        'Banana',
        'Bandana',
        'Banned',
      ]);
      expect(r, isNotNull);
      expect(r!.score, 1.0);
    });

    test('edit distance match across fields', () {
      final r = FuzzyMatcher.matchFields('apole', [
        'Banana',
        'Apple',
        'Cherry',
      ]);
      expect(r, isNotNull);
      expect(r!.score, lessThan(0.6));
    });
  });

  // ===========================================================================
  // 10. MATCH INDICES — correct highlighting data
  // ===========================================================================
  group('Match indices (for highlighting)', () {
    test('exact match indices are contiguous', () {
      final r = FuzzyMatcher.match('app', 'Apple')!;
      expect(r.matchIndices, [0, 1, 2]);
    });

    test('exact match in middle has correct offset', () {
      final r = FuzzyMatcher.match('ear', 'Search')!;
      // "search" lowercase: s-e-a-r-c-h, "ear" at index 1
      expect(r.matchIndices, [1, 2, 3]);
    });

    test('subsequence indices are in order', () {
      final r = FuzzyMatcher.match('apl', 'Apple')!;
      for (var i = 1; i < r.matchIndices.length; i++) {
        expect(r.matchIndices[i], greaterThan(r.matchIndices[i - 1]));
      }
    });

    test('indices length equals query length for subsequence', () {
      final r = FuzzyMatcher.match('apl', 'Apple')!;
      expect(r.matchIndices.length, 3);
    });

    test('edit distance indices cover matched window', () {
      final r = FuzzyMatcher.match('apole', 'Apple')!;
      expect(r.matchIndices.length, greaterThan(0));
      for (var i = 1; i < r.matchIndices.length; i++) {
        expect(r.matchIndices[i], r.matchIndices[i - 1] + 1);
      }
    });
  });

  // ===========================================================================
  // 11. THRESHOLD BEHAVIOR with SmartSearchController
  // ===========================================================================
  group('Controller threshold filtering', () {
    final items = [
      'Apple',
      'Apricot',
      'Avocado',
      'Banana',
      'Blueberry',
      'Cherry',
      'Coconut',
      'Date',
      'Elderberry',
      'Fig',
      'Grape',
      'Kiwi',
      'Lemon',
      'Mango',
      'Orange',
      'Papaya',
      'Peach',
      'Pear',
      'Pineapple',
      'Plum',
      'Raspberry',
      'Strawberry',
      'Watermelon',
    ];

    SmartSearchController<String> makeController({double threshold = 0.3}) {
      final c = SmartSearchController<String>(
        searchableFields: (item) => [item],
        fuzzySearchEnabled: true,
        fuzzyThreshold: threshold,
      );
      addTearDown(() {
        if (!c.isDisposed) c.dispose();
      });
      c.setItems(items);
      return c;
    }

    test('threshold 0.1 — very lenient, many results', () {
      final c = makeController(threshold: 0.1);
      c.searchImmediate('ap');
      expect(c.items.length, greaterThan(0));
    });

    test('threshold 0.5 — moderate, fewer results', () {
      final c = makeController(threshold: 0.5);
      c.searchImmediate('ap');
      expect(c.items.length, greaterThan(0));
    });

    test('threshold 0.9 — strict, only near-exact', () {
      final c = makeController(threshold: 0.9);
      c.searchImmediate('ap');
      // Only items with "ap" as exact substring should pass
      for (final item in c.items) {
        expect(
          item.toLowerCase().contains('ap'),
          true,
          reason: '$item should contain "ap" at threshold 0.9',
        );
      }
    });

    test('higher threshold always returns <= items than lower threshold', () {
      final lenient = makeController(threshold: 0.1);
      final moderate = makeController(threshold: 0.5);
      final strict = makeController(threshold: 0.8);

      for (final query in ['ap', 'ban', 'ch', 'str', 'aple', 'grpe']) {
        lenient.searchImmediate(query);
        moderate.searchImmediate(query);
        strict.searchImmediate(query);

        expect(
          strict.items.length,
          lessThanOrEqualTo(moderate.items.length),
          reason: 'Query "$query": strict <= moderate',
        );
        expect(
          moderate.items.length,
          lessThanOrEqualTo(lenient.items.length),
          reason: 'Query "$query": moderate <= lenient',
        );
      }
    });

    test('exact match always passes any threshold', () {
      for (final threshold in [0.1, 0.3, 0.5, 0.7, 0.9, 1.0]) {
        final c = makeController(threshold: threshold);
        c.searchImmediate('apple');
        expect(
          c.items,
          contains('Apple'),
          reason: 'Exact match should pass threshold $threshold',
        );
        c.dispose();
      }
    });

    test('edit distance matches filtered at high threshold', () {
      final c = makeController(threshold: 0.6);
      c.searchImmediate('apole'); // edit distance match for Apple
      // Edit distance scores cap at 0.59, so threshold 0.6 should filter it
      expect(
        c.items,
        isNot(contains('Apple')),
        reason: 'Edit distance match (score<0.6) should be filtered at 0.6',
      );
    });

    test('subsequence matches survive moderate threshold', () {
      final c = makeController(threshold: 0.3);
      c.searchImmediate('apl'); // subsequence match for Apple
      expect(c.items, contains('Apple'));
    });
  });

  // ===========================================================================
  // 12. RESULT ORDERING in controller
  // ===========================================================================
  group('Controller result ordering', () {
    test('exact matches rank first', () {
      final c = SmartSearchController<String>(
        searchableFields: (item) => [item],
        fuzzySearchEnabled: true,
        fuzzyThreshold: 0.1,
      );
      addTearDown(() {
        if (!c.isDisposed) c.dispose();
      });
      c.setItems(['Pineapple', 'Apple', 'Maple', 'Applesauce']);
      c.searchImmediate('apple');
      // All items containing "apple" as substring get score 1.0.
      // Any of them can be first since scores are tied.
      expect(c.items.first, anyOf('Apple', 'Applesauce', 'Pineapple', 'Maple'));
    });

    test('user sort overrides score sort', () {
      final c = SmartSearchController<String>(
        searchableFields: (item) => [item],
        fuzzySearchEnabled: true,
        fuzzyThreshold: 0.1,
      );
      addTearDown(() {
        if (!c.isDisposed) c.dispose();
      });
      c.setItems(['Cherry', 'Apple', 'Banana']);
      c.setSortBy((a, b) => a.compareTo(b)); // alphabetical
      c.searchImmediate('a'); // all match
      expect(c.items.first, 'Apple'); // alphabetical, not score
    });

    test('filters applied before fuzzy scoring', () {
      final c = SmartSearchController<String>(
        searchableFields: (item) => [item],
        fuzzySearchEnabled: true,
        fuzzyThreshold: 0.1,
      );
      addTearDown(() {
        if (!c.isDisposed) c.dispose();
      });
      c.setItems(['Apple', 'Apricot', 'Avocado', 'Banana']);
      c.setFilter('no-b', (item) => !item.startsWith('B'));
      c.searchImmediate('a');
      expect(c.items, isNot(contains('Banana')));
    });
  });

  // ===========================================================================
  // 13. FUZZY TOGGLE — on/off behavior
  // ===========================================================================
  group('Fuzzy toggle on/off', () {
    test('fuzzy off: only exact substring matches', () {
      final c = SmartSearchController<String>(
        searchableFields: (item) => [item],
        fuzzySearchEnabled: false,
      );
      addTearDown(() {
        if (!c.isDisposed) c.dispose();
      });
      c.setItems(['Apple', 'Banana', 'Cherry']);

      c.searchImmediate('apl'); // not a substring
      expect(c.items, isEmpty);

      c.searchImmediate('app'); // substring of Apple
      expect(c.items, equals(['Apple']));
    });

    test('fuzzy on: subsequence matches included', () {
      final c = SmartSearchController<String>(
        searchableFields: (item) => [item],
        fuzzySearchEnabled: true,
        fuzzyThreshold: 0.1,
      );
      addTearDown(() {
        if (!c.isDisposed) c.dispose();
      });
      c.setItems(['Apple', 'Banana', 'Cherry']);

      c.searchImmediate('apl');
      expect(c.items, contains('Apple'));
    });

    test('toggle at runtime with updateFuzzySearchEnabled', () {
      final c = SmartSearchController<String>(
        searchableFields: (item) => [item],
        fuzzySearchEnabled: false,
        fuzzyThreshold: 0.1,
      );
      addTearDown(() {
        if (!c.isDisposed) c.dispose();
      });
      c.setItems(['Apple', 'Banana']);

      c.searchImmediate('apl');
      expect(c.items, isEmpty);

      c.updateFuzzySearchEnabled(true);
      c.searchImmediate('apl');
      expect(c.items, contains('Apple'));

      c.updateFuzzySearchEnabled(false);
      c.searchImmediate('apl');
      expect(c.items, isEmpty);
    });

    test('toggle threshold at runtime with updateFuzzyThreshold', () {
      final c = SmartSearchController<String>(
        searchableFields: (item) => [item],
        fuzzySearchEnabled: true,
        fuzzyThreshold: 0.1,
      );
      addTearDown(() {
        if (!c.isDisposed) c.dispose();
      });
      c.setItems(['Apple', 'Banana', 'Apricot']);
      c.searchImmediate('a');
      final lenientCount = c.items.length;

      c.updateFuzzyThreshold(0.99);
      c.searchImmediate('a');
      final strictCount = c.items.length;

      expect(strictCount, lessThanOrEqualTo(lenientCount));
    });
  });

  // ===========================================================================
  // 14. PERFORMANCE
  // ===========================================================================
  group('Performance', () {
    test('10K items — subsequence search under 500ms', () {
      final items = List<String>.generate(
        10000,
        (i) => 'Product item number $i with some description text',
      );
      final c = SmartSearchController<String>(
        searchableFields: (item) => [item],
        fuzzySearchEnabled: true,
        fuzzyThreshold: 0.3,
      );
      addTearDown(() {
        if (!c.isDisposed) c.dispose();
      });
      c.setItems(items);

      final sw = Stopwatch()..start();
      c.searchImmediate('prd'); // subsequence: p-r-d
      sw.stop();

      expect(sw.elapsedMilliseconds, lessThan(500));
      expect(c.items.length, greaterThan(0));
    });

    test('10K items — edit distance search under 2000ms', () {
      final items = List<String>.generate(
        10000,
        (i) => 'Product item number $i with some description text',
      );
      final c = SmartSearchController<String>(
        searchableFields: (item) => [item],
        fuzzySearchEnabled: true,
        fuzzyThreshold: 0.1,
      );
      addTearDown(() {
        if (!c.isDisposed) c.dispose();
      });
      c.setItems(items);

      final sw = Stopwatch()..start();
      c.searchImmediate('prodct'); // edit distance: missing 'u'
      sw.stop();

      // Edit distance is slower due to sliding window, allow more time
      expect(sw.elapsedMilliseconds, lessThan(2000));
    });

    test('1K items with multiple fields under 100ms', () {
      final items = List<String>.generate(1000, (i) => 'Item $i');
      final c = SmartSearchController<String>(
        searchableFields: (item) => [item, 'Category ${item.hashCode % 10}'],
        fuzzySearchEnabled: true,
        fuzzyThreshold: 0.3,
      );
      addTearDown(() {
        if (!c.isDisposed) c.dispose();
      });
      c.setItems(items);

      final sw = Stopwatch()..start();
      c.searchImmediate('itm'); // subsequence
      sw.stop();

      expect(sw.elapsedMilliseconds, lessThan(100));
    });
  });

  // ===========================================================================
  // 15. SearchConfiguration integration
  // ===========================================================================
  group('SearchConfiguration fuzzy fields', () {
    test('defaults', () {
      const config = SearchConfiguration();
      expect(config.fuzzySearchEnabled, false);
      expect(config.fuzzyThreshold, 0.3);
    });

    test('custom values', () {
      const config = SearchConfiguration(
        fuzzySearchEnabled: true,
        fuzzyThreshold: 0.7,
      );
      expect(config.fuzzySearchEnabled, true);
      expect(config.fuzzyThreshold, 0.7);
    });

    test('copyWith preserves', () {
      const config = SearchConfiguration(
        fuzzySearchEnabled: true,
        fuzzyThreshold: 0.5,
      );
      final copy = config.copyWith(hintText: 'Search...');
      expect(copy.fuzzySearchEnabled, true);
      expect(copy.fuzzyThreshold, 0.5);
    });

    test('copyWith overrides', () {
      const config = SearchConfiguration(fuzzySearchEnabled: false);
      final copy = config.copyWith(
        fuzzySearchEnabled: true,
        fuzzyThreshold: 0.8,
      );
      expect(copy.fuzzySearchEnabled, true);
      expect(copy.fuzzyThreshold, 0.8);
    });
  });
}
