import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_search_list/smart_search_list.dart';

void main() {
  group('Notification correctness', () {
    group('superseded async requests', () {
      test(
        'superseded async request does not fire stale notification',
        () async {
          final controller = SmartSearchController<String>(
            debounceDelay: Duration.zero,
          );

          final completer1 = Completer<List<String>>();
          final completer2 = Completer<List<String>>();
          var callCount = 0;

          controller.setAsyncLoader((query, {int page = 0, int pageSize = 20}) {
            callCount++;
            if (callCount == 1) return completer1.future;
            return completer2.future;
          });

          var notifyCount = 0;
          controller.addListener(() => notifyCount++);

          // First search — triggers async call 1
          controller.searchImmediate('a');
          await Future.microtask(() {});

          // Second search — supersedes call 1, triggers async call 2
          controller.searchImmediate('ab');
          await Future.microtask(() {});

          final countAfterSecondStart = notifyCount;

          // Complete call 1 (superseded) — should NOT add any notifications
          completer1.complete(['stale result']);
          await Future.microtask(() {});

          expect(
            notifyCount,
            countAfterSecondStart,
            reason: 'Superseded request must not fire any notification',
          );

          // Complete call 2 (current) — should notify via _setLoading(false)
          completer2.complete(['fresh result']);
          await Future.microtask(() {});

          expect(controller.items, ['fresh result']);
          expect(
            notifyCount,
            greaterThan(countAfterSecondStart),
            reason: 'Current request must notify on completion',
          );

          // Verify no stale data leaked
          expect(controller.items.contains('stale result'), false);

          controller.dispose();
        },
      );

      test(
        'rapid-fire superseded requests only notify for the final one',
        () async {
          final controller = SmartSearchController<String>(
            debounceDelay: Duration.zero,
          );

          final completers = <int, Completer<List<String>>>{};
          var callIndex = 0;

          controller.setAsyncLoader((query, {int page = 0, int pageSize = 20}) {
            final c = Completer<List<String>>();
            completers[callIndex++] = c;
            return c.future;
          });

          var notifyCount = 0;
          controller.addListener(() => notifyCount++);

          // Fire 5 searches rapidly — only the last should apply results
          for (var i = 0; i < 5; i++) {
            controller.searchImmediate('query$i');
            await Future.microtask(() {});
          }

          final countBeforeCompletions = notifyCount;

          // Complete all in order — only the last (index 4) matters
          for (var i = 0; i < 5; i++) {
            completers[i]!.complete(['result$i']);
            await Future.microtask(() {});
          }

          expect(controller.items, ['result4']);

          // Superseded completions (0-3) should not have added notifications
          // Only completion 4 should have added its notifications
          // (1 from _setLoading(false) in finally block)
          expect(notifyCount, countBeforeCompletions + 1);

          controller.dispose();
        },
      );
    });

    group('cache hit path', () {
      test('cache hit notifies listeners with cached results', () async {
        final controller = SmartSearchController<String>(
          debounceDelay: Duration.zero,
          cacheResults: true,
        );

        var loaderCallCount = 0;
        controller.setAsyncLoader((
          query, {
          int page = 0,
          int pageSize = 20,
        }) async {
          loaderCallCount++;
          return ['cached-item-$query'];
        });

        // First search — populates cache
        controller.searchImmediate('test');
        await Future.microtask(() {});
        await Future.microtask(() {});

        expect(controller.items, ['cached-item-test']);
        expect(loaderCallCount, 1);

        // Change query to clear state
        controller.searchImmediate('other');
        await Future.microtask(() {});
        await Future.microtask(() {});

        // Now count notifications for the cache hit
        var notifyCount = 0;
        controller.addListener(() => notifyCount++);

        // Search again with 'test' — should hit cache
        controller.searchImmediate('test');
        await Future.microtask(() {});

        // Cache hit should have notified: _setError(null) + cache notify
        expect(
          notifyCount,
          greaterThan(0),
          reason: 'Cache hit must notify listeners',
        );
        expect(controller.items, ['cached-item-test']);
        expect(
          loaderCallCount,
          2,
          reason: 'Cache was hit — loader should not be called a 3rd time',
        );

        controller.dispose();
      });

      test(
        'cache hit returns correct items without calling async loader',
        () async {
          final controller = SmartSearchController<String>(
            debounceDelay: Duration.zero,
            cacheResults: true,
          );

          var loaderCallCount = 0;
          controller.setAsyncLoader((
            query, {
            int page = 0,
            int pageSize = 20,
          }) async {
            loaderCallCount++;
            return ['result-for-$query'];
          });

          // Populate cache
          controller.searchImmediate('hello');
          await Future.microtask(() {});
          await Future.microtask(() {});

          expect(loaderCallCount, 1);
          expect(controller.items, ['result-for-hello']);

          // Switch to different query
          controller.searchImmediate('world');
          await Future.microtask(() {});
          await Future.microtask(() {});

          expect(loaderCallCount, 2);

          // Return to cached query — loader must NOT be called again
          controller.searchImmediate('hello');
          await Future.microtask(() {});

          expect(
            loaderCallCount,
            2,
            reason: 'Cached query must not invoke async loader',
          );
          expect(controller.items, ['result-for-hello']);

          controller.dispose();
        },
      );
    });

    group('async success path', () {
      test(
        'successful async search notifies exactly once for results',
        () async {
          final controller = SmartSearchController<String>(
            debounceDelay: Duration.zero,
            cacheResults: false,
          );

          final completer = Completer<List<String>>();
          controller.setAsyncLoader(
            (query, {int page = 0, int pageSize = 20}) => completer.future,
          );

          // Start search and wait for loading state
          controller.searchImmediate('test');
          await Future.microtask(() {});

          // Now count from after loading started
          var notifyCount = 0;
          controller.addListener(() => notifyCount++);

          // Complete the request
          completer.complete(['result']);
          await Future.microtask(() {});

          // Exactly 1 notification: _setLoading(false) in finally block
          expect(notifyCount, 1);
          expect(controller.items, ['result']);
          expect(controller.isLoading, false);

          controller.dispose();
        },
      );
    });

    group('async error path', () {
      test('async error notifies for both error and loading state', () async {
        final controller = SmartSearchController<String>(
          debounceDelay: Duration.zero,
          cacheResults: false,
        );

        final completer = Completer<List<String>>();
        controller.setAsyncLoader(
          (query, {int page = 0, int pageSize = 20}) => completer.future,
        );

        // Start search
        controller.searchImmediate('test');
        await Future.microtask(() {});

        var notifyCount = 0;
        controller.addListener(() => notifyCount++);

        // Error the request
        completer.completeError(Exception('fail'));
        await Future.microtask(() {});

        // 2 notifications: _setError(e) + _setLoading(false) in finally
        expect(notifyCount, 2);
        expect(controller.error, isA<Exception>());
        expect(controller.isLoading, false);

        controller.dispose();
      });

      test('superseded async error does not notify', () async {
        final controller = SmartSearchController<String>(
          debounceDelay: Duration.zero,
          cacheResults: false,
        );

        final completer1 = Completer<List<String>>();
        final completer2 = Completer<List<String>>();
        var callCount = 0;

        controller.setAsyncLoader((query, {int page = 0, int pageSize = 20}) {
          callCount++;
          if (callCount == 1) return completer1.future;
          return completer2.future;
        });

        controller.addListener(() {});

        // First search
        controller.searchImmediate('a');
        await Future.microtask(() {});

        // Supersede with second search
        controller.searchImmediate('ab');
        await Future.microtask(() {});

        var notifyCount = 0;
        controller.addListener(() => notifyCount++);

        // First request errors — superseded, should NOT notify
        completer1.completeError(Exception('stale error'));
        await Future.microtask(() {});

        expect(
          notifyCount,
          0,
          reason: 'Superseded error must not trigger notification',
        );
        expect(
          controller.error,
          isNull,
          reason: 'Superseded error must not set error state',
        );

        // Second request succeeds — should notify normally
        completer2.complete(['result']);
        await Future.microtask(() {});

        expect(notifyCount, 1);
        expect(controller.items, ['result']);

        controller.dispose();
      });
    });

    group('offline path', () {
      test('offline search notifies exactly once per search', () async {
        final controller = SmartSearchController<String>(
          searchableFields: (item) => [item],
          debounceDelay: Duration.zero,
        );

        controller.setItems(['Apple', 'Banana', 'Cherry']);

        // Reset count after setItems
        var notifyCount = 0;
        controller.addListener(() => notifyCount++);

        controller.searchImmediate('App');
        await Future.microtask(() {});

        // _setError(null) + _applyFiltersAndSort/_notifyListeners = 2
        expect(notifyCount, 2);
        expect(controller.items, ['Apple']);

        controller.dispose();
      });

      test('offline empty search notifies correctly', () async {
        final controller = SmartSearchController<String>(
          searchableFields: (item) => [item],
          debounceDelay: Duration.zero,
        );

        controller.setItems(['Apple', 'Banana']);

        var notifyCount = 0;
        controller.addListener(() => notifyCount++);

        controller.searchImmediate('');
        await Future.microtask(() {});

        expect(notifyCount, 2);
        expect(controller.items, ['Apple', 'Banana']);

        controller.dispose();
      });

      test('offline search is synchronous — no stale state possible', () {
        final controller = SmartSearchController<String>(
          searchableFields: (item) => [item],
          debounceDelay: Duration.zero,
        );

        controller.setItems(['Apple', 'Banana', 'Cherry']);

        // Rapid-fire offline searches — each completes synchronously
        controller.searchImmediate('App');
        expect(controller.items, ['Apple']);

        controller.searchImmediate('Ban');
        expect(controller.items, ['Banana']);

        controller.searchImmediate('Che');
        expect(controller.items, ['Cherry']);

        controller.searchImmediate('');
        expect(controller.items.length, 3);

        controller.dispose();
      });
    });

    group('disposal during async', () {
      test('disposal during pending async does not notify', () async {
        final controller = SmartSearchController<String>(
          debounceDelay: Duration.zero,
        );

        final completer = Completer<List<String>>();
        controller.setAsyncLoader(
          (query, {int page = 0, int pageSize = 20}) => completer.future,
        );

        controller.searchImmediate('test');
        await Future.microtask(() {});

        var notifyCount = 0;
        controller.addListener(() => notifyCount++);

        // Dispose while async is pending
        controller.dispose();

        // Complete the request after disposal
        completer.complete(['too late']);
        await Future.microtask(() {});

        expect(notifyCount, 0, reason: 'Disposed controller must not notify');

        // Items should not have been updated
        expect(controller.items, isEmpty);
      });
    });
  });
}
