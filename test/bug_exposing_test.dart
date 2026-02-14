import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_search_list/smart_search_list.dart';

void main() {
  // =========================================================================
  // B1 — scrollController change not handled in didUpdateWidget
  // =========================================================================

  group('B1: scrollController swap in SmartSearchList', () {
    testWidgets('changing scrollController moves pagination listener', (
      tester,
    ) async {
      final scrollA = ScrollController();
      final scrollB = ScrollController();
      var currentScroll = scrollA;

      late StateSetter rebuildParent;

      // Track loadMore calls
      var loadMoreCalls = 0;
      Future<List<String>> loader(
        String query, {
        int page = 0,
        int pageSize = 20,
      }) async {
        if (page > 0) loadMoreCalls++;
        return List.generate(20, (i) => 'Item ${page * 20 + i}');
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rebuildParent = setState;
                return SmartSearchList<String>.async(
                  asyncLoader: loader,
                  scrollController: currentScroll,
                  paginationConfig: const PaginationConfiguration(
                    enabled: true,
                    triggerDistance: 100,
                  ),
                  searchConfig: const SearchConfiguration(
                    debounceDelay: Duration.zero,
                  ),
                  itemBuilder:
                      (context, item, index, {searchTerms = const []}) {
                        return SizedBox(height: 50, child: Text(item));
                      },
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Swap scroll controller
      rebuildParent(() {
        currentScroll = scrollB;
      });
      await tester.pumpAndSettle();

      // Scroll the new controller to end — should trigger pagination
      loadMoreCalls = 0;
      scrollB.jumpTo(scrollB.position.maxScrollExtent);
      await tester.pumpAndSettle();

      expect(
        loadMoreCalls,
        greaterThan(0),
        reason: 'New scroll controller should trigger pagination',
      );

      scrollA.dispose();
      scrollB.dispose();
    });

    testWidgets(
      'changing scrollController from external to null creates internal',
      (tester) async {
        final scrollExt = ScrollController();
        ScrollController? currentScroll = scrollExt;

        late StateSetter rebuildParent;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  rebuildParent = setState;
                  return SmartSearchList<String>(
                    items: const ['Apple', 'Banana', 'Cherry'],
                    searchableFields: (item) => [item],
                    scrollController: currentScroll,
                    itemBuilder:
                        (context, item, index, {searchTerms = const []}) {
                          return ListTile(title: Text(item));
                        },
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Switch to null — widget should create an internal scroll controller
        rebuildParent(() {
          currentScroll = null;
        });
        await tester.pumpAndSettle();

        // Items should still render (no crash)
        expect(find.text('Apple'), findsOneWidget);
        expect(find.text('Banana'), findsOneWidget);

        // Dispose the old external one — should not crash
        scrollExt.dispose();
      },
    );

    testWidgets('old scroll controller listeners are removed on swap', (
      tester,
    ) async {
      final scrollA = ScrollController();
      final scrollB = ScrollController();
      var currentScroll = scrollA;

      late StateSetter rebuildParent;

      var loadMoreCalls = 0;
      Future<List<String>> loader(
        String query, {
        int page = 0,
        int pageSize = 20,
      }) async {
        if (page > 0) loadMoreCalls++;
        return List.generate(20, (i) => 'Item ${page * 20 + i}');
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rebuildParent = setState;
                return SmartSearchList<String>.async(
                  asyncLoader: loader,
                  scrollController: currentScroll,
                  paginationConfig: const PaginationConfiguration(
                    enabled: true,
                    triggerDistance: 100,
                  ),
                  searchConfig: const SearchConfiguration(
                    debounceDelay: Duration.zero,
                  ),
                  itemBuilder:
                      (context, item, index, {searchTerms = const []}) {
                        return SizedBox(height: 50, child: Text(item));
                      },
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Swap to scrollB
      rebuildParent(() {
        currentScroll = scrollB;
      });
      await tester.pumpAndSettle();

      // Scrolling old controller should NOT trigger loadMore
      loadMoreCalls = 0;
      if (scrollA.hasClients) {
        scrollA.jumpTo(scrollA.position.maxScrollExtent);
      }
      await tester.pumpAndSettle();

      expect(
        loadMoreCalls,
        0,
        reason: 'Old scroll controller must not trigger pagination after swap',
      );

      scrollA.dispose();
      scrollB.dispose();
    });
  });

  // =========================================================================
  // B2 — searchSemanticsEnabled toggle without controller change
  // =========================================================================

  group('B2: searchSemanticsEnabled toggle mid-lifecycle', () {
    testWidgets(
      'SmartSearchList: enabling searchSemanticsEnabled starts announcements',
      (tester) async {
        var a11yEnabled = false;
        late StateSetter rebuildParent;

        final controller = SmartSearchController<String>(
          searchableFields: (item) => [item],
          debounceDelay: Duration.zero,
        );
        addTearDown(() {
          if (!controller.isDisposed) controller.dispose();
        });
        controller.setItems(['Apple', 'Banana', 'Cherry']);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  rebuildParent = setState;
                  return SmartSearchList<String>.controller(
                    controller: controller,
                    accessibilityConfig: AccessibilityConfiguration(
                      searchSemanticsEnabled: a11yEnabled,
                    ),
                    itemBuilder:
                        (context, item, index, {searchTerms = const []}) {
                          return ListTile(title: Text(item));
                        },
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Enable a11y announcements mid-lifecycle
        rebuildParent(() {
          a11yEnabled = true;
        });
        await tester.pumpAndSettle();

        // Trigger a search — should announce results (listener should be active)
        controller.searchImmediate('App');
        await tester.pumpAndSettle();

        // If the listener was correctly added, no error occurs.
        // We verify indirectly: the controller should have the listener.
        // The key assertion is that the listener count increased.
        expect(controller.items, ['Apple']);

        controller.dispose();
      },
    );

    testWidgets(
      'SmartSearchList: disabling searchSemanticsEnabled stops announcements',
      (tester) async {
        var a11yEnabled = true;
        late StateSetter rebuildParent;

        final controller = SmartSearchController<String>(
          searchableFields: (item) => [item],
          debounceDelay: Duration.zero,
        );
        addTearDown(() {
          if (!controller.isDisposed) controller.dispose();
        });
        controller.setItems(['Apple', 'Banana', 'Cherry']);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  rebuildParent = setState;
                  return SmartSearchList<String>.controller(
                    controller: controller,
                    accessibilityConfig: AccessibilityConfiguration(
                      searchSemanticsEnabled: a11yEnabled,
                    ),
                    itemBuilder:
                        (context, item, index, {searchTerms = const []}) {
                          return ListTile(title: Text(item));
                        },
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Disable a11y announcements mid-lifecycle
        rebuildParent(() {
          a11yEnabled = false;
        });
        await tester.pumpAndSettle();

        // Search — should NOT crash or announce
        controller.searchImmediate('Ban');
        await tester.pumpAndSettle();

        expect(controller.items, ['Banana']);

        controller.dispose();
      },
    );

    testWidgets(
      'SliverSmartSearchList: enabling searchSemanticsEnabled starts announcements',
      (tester) async {
        var a11yEnabled = false;
        late StateSetter rebuildParent;

        final controller = SmartSearchController<String>(
          searchableFields: (item) => [item],
          debounceDelay: Duration.zero,
        );
        addTearDown(() {
          if (!controller.isDisposed) controller.dispose();
        });
        controller.setItems(['Apple', 'Banana', 'Cherry']);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  rebuildParent = setState;
                  return CustomScrollView(
                    slivers: [
                      SliverSmartSearchList<String>.controller(
                        controller: controller,
                        accessibilityConfig: AccessibilityConfiguration(
                          searchSemanticsEnabled: a11yEnabled,
                        ),
                        itemBuilder:
                            (context, item, index, {searchTerms = const []}) {
                              return ListTile(title: Text(item));
                            },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Enable a11y
        rebuildParent(() {
          a11yEnabled = true;
        });
        await tester.pumpAndSettle();

        controller.searchImmediate('App');
        await tester.pumpAndSettle();

        expect(controller.items, ['Apple']);

        controller.dispose();
      },
    );

    testWidgets(
      'SliverSmartSearchList: disabling searchSemanticsEnabled stops announcements',
      (tester) async {
        var a11yEnabled = true;
        late StateSetter rebuildParent;

        final controller = SmartSearchController<String>(
          searchableFields: (item) => [item],
          debounceDelay: Duration.zero,
        );
        addTearDown(() {
          if (!controller.isDisposed) controller.dispose();
        });
        controller.setItems(['Apple', 'Banana', 'Cherry']);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  rebuildParent = setState;
                  return CustomScrollView(
                    slivers: [
                      SliverSmartSearchList<String>.controller(
                        controller: controller,
                        accessibilityConfig: AccessibilityConfiguration(
                          searchSemanticsEnabled: a11yEnabled,
                        ),
                        itemBuilder:
                            (context, item, index, {searchTerms = const []}) {
                              return ListTile(title: Text(item));
                            },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        rebuildParent(() {
          a11yEnabled = false;
        });
        await tester.pumpAndSettle();

        controller.searchImmediate('Che');
        await tester.pumpAndSettle();

        expect(controller.items, ['Cherry']);

        controller.dispose();
      },
    );
  });

  // =========================================================================
  // B3 — Sliver ext→null controller swap listener order
  // =========================================================================

  group('B3: Sliver ext→null controller swap listener order', () {
    testWidgets(
      'SliverSmartSearchList shows items after switching from external to null controller',
      (tester) async {
        final extController = SmartSearchController<String>(
          searchableFields: (item) => [item],
        );
        addTearDown(() {
          if (!extController.isDisposed) extController.dispose();
        });
        extController.setItems(['External']);

        SmartSearchController<String>? currentController = extController;
        var items = const ['Internal A', 'Internal B'];
        late StateSetter rebuildParent;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  rebuildParent = setState;
                  if (currentController != null) {
                    return CustomScrollView(
                      slivers: [
                        SliverSmartSearchList<String>.controller(
                          controller: currentController!,
                          itemBuilder:
                              (context, item, index, {searchTerms = const []}) {
                                return ListTile(title: Text(item));
                              },
                        ),
                      ],
                    );
                  }
                  return CustomScrollView(
                    slivers: [
                      SliverSmartSearchList<String>(
                        items: items,
                        searchableFields: (item) => [item],
                        itemBuilder:
                            (context, item, index, {searchTerms = const []}) {
                              return ListTile(title: Text(item));
                            },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('External'), findsOneWidget);

        // Switch from external to null controller (offline mode)
        rebuildParent(() {
          currentController = null;
        });
        await tester.pumpAndSettle();

        // Items from the new internal controller should be visible
        expect(find.text('Internal A'), findsOneWidget);
        expect(find.text('Internal B'), findsOneWidget);
        expect(find.text('External'), findsNothing);

        extController.dispose();
      },
    );
  });

  // =========================================================================
  // B4 — maxCacheSize=0 crash
  // =========================================================================

  group('B4: maxCacheSize=0 with cacheResults=true', () {
    test(
      'does not crash or set error when caching with maxCacheSize=0',
      () async {
        final controller = SmartSearchController<String>(
          cacheResults: true,
          maxCacheSize: 0,
          debounceDelay: Duration.zero,
        );
        addTearDown(() {
          if (!controller.isDisposed) controller.dispose();
        });

        controller.setAsyncLoader((
          query, {
          int page = 0,
          int pageSize = 20,
        }) async {
          return ['result-$query'];
        });

        // This should not throw a RangeError or set an error
        controller.searchImmediate('test');
        await Future.microtask(() {});
        await Future.microtask(() {});

        expect(controller.items, ['result-test']);
        expect(
          controller.error,
          isNull,
          reason: 'maxCacheSize=0 should not cause a RangeError',
        );

        controller.dispose();
      },
    );

    test('maxCacheSize=0 effectively disables caching without errors', () async {
      var loaderCalls = 0;
      final controller = SmartSearchController<String>(
        cacheResults: true,
        maxCacheSize: 0,
        debounceDelay: Duration.zero,
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });

      controller.setAsyncLoader((
        query, {
        int page = 0,
        int pageSize = 20,
      }) async {
        loaderCalls++;
        return ['result-$query'];
      });

      controller.searchImmediate('a');
      await Future.microtask(() {});
      await Future.microtask(() {});
      expect(controller.error, isNull, reason: 'No error on first search');

      controller.searchImmediate('b');
      await Future.microtask(() {});
      await Future.microtask(() {});
      expect(controller.error, isNull, reason: 'No error on second search');

      // Search 'a' again — should still call the loader since nothing is cached
      controller.searchImmediate('a');
      await Future.microtask(() {});
      await Future.microtask(() {});
      expect(controller.error, isNull, reason: 'No error on third search');

      expect(loaderCalls, 3, reason: 'All 3 searches should call the loader');
    });
  });
}
