import 'package:flutter_test/flutter_test.dart';
import 'package:smart_search_list/smart_search_list.dart';

void main() {
  group('SmartSearchController', () {
    test('should initialize correctly', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
      );

      expect(controller.items, isEmpty);
      expect(controller.searchQuery, isEmpty);
      expect(controller.hasSearched, false);
      expect(controller.isLoading, false);
      expect(controller.error, isNull);

      controller.dispose();
    });

    test('should handle offline items correctly', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
      );

      controller.setItems(['Apple', 'Banana', 'Cherry']);

      expect(controller.items.length, 3);
      expect(controller.allItems.length, 3);

      controller.dispose();
    });

    test('should search items correctly', () async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: const Duration(milliseconds: 10), // Fast for testing
      );

      controller.setItems(['Apple', 'Banana', 'Cherry']);
      controller.search('App');

      // Wait for debounce
      await Future.delayed(const Duration(milliseconds: 20));

      expect(controller.hasSearched, true);
      expect(controller.searchQuery, 'App');

      controller.dispose();
    });

    test('should dispose safely', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
      );

      controller.dispose();

      expect(controller.isDisposed, true);

      // Should not crash when calling methods after dispose
      controller.search('test');
      controller.setItems(['test']);
    });

    test('should respect caseSensitive setting', () async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        caseSensitive: true,
        debounceDelay: const Duration(milliseconds: 10),
      );

      controller.setItems(['Apple', 'apple', 'APPLE']);
      controller.search('apple');

      await Future.delayed(const Duration(milliseconds: 20));

      // Should only match exact case
      expect(controller.items.length, 1);
      expect(controller.items.first, 'apple');

      controller.dispose();
    });

    test('should respect minSearchLength', () async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        minSearchLength: 3,
        debounceDelay: const Duration(milliseconds: 10),
      );

      controller.setItems(['Apple', 'Banana', 'Cherry']);

      // Search with less than minSearchLength should be ignored
      controller.search('Ap');
      await Future.delayed(const Duration(milliseconds: 20));

      expect(controller.hasSearched, false);
      expect(controller.items.length, 3); // Should show all items

      // Search with minSearchLength should work
      controller.search('App');
      await Future.delayed(const Duration(milliseconds: 20));

      expect(controller.hasSearched, true);
      expect(controller.searchQuery, 'App');

      controller.dispose();
    });

    test('should handle filters correctly', () async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: const Duration(milliseconds: 10),
      );

      controller.setItems(['Apple', 'Banana', 'Cherry', 'Apricot']);

      // Add filter for items starting with 'A'
      controller.setFilter('startsWithA', (item) => item.startsWith('A'));
      await Future.delayed(const Duration(milliseconds: 20));

      expect(controller.items.length, 2);
      expect(controller.items, containsAll(['Apple', 'Apricot']));
      expect(controller.activeFilters.containsKey('startsWithA'), true);

      // Remove filter
      controller.removeFilter('startsWithA');
      await Future.delayed(const Duration(milliseconds: 20));

      expect(controller.items.length, 4);
      expect(controller.activeFilters.isEmpty, true);

      controller.dispose();
    });

    test('should handle sorting correctly', () async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: const Duration(milliseconds: 10),
      );

      controller.setItems(['Banana', 'Apple', 'Cherry']);

      // Sort alphabetically
      controller.setSortBy((a, b) => a.compareTo(b));
      await Future.delayed(const Duration(milliseconds: 20));

      expect(controller.items, ['Apple', 'Banana', 'Cherry']);
      expect(controller.currentComparator, isNotNull);

      // Clear sorting
      controller.setSortBy(null);
      await Future.delayed(const Duration(milliseconds: 20));

      expect(controller.currentComparator, isNull);

      controller.dispose();
    });

    test('should handle async data loading', () async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: const Duration(milliseconds: 10),
      );

      // Mock async loader
      controller
          .setAsyncLoader((query, {int page = 0, int pageSize = 20}) async {
        await Future.delayed(const Duration(milliseconds: 50));
        if (query.isEmpty) {
          return ['Item 1', 'Item 2', 'Item 3'];
        }
        return ['Searched Item'];
      });

      // Initial load
      controller.search('');

      // Wait for debounce and then check loading state
      await Future.delayed(const Duration(milliseconds: 20));
      expect(controller.isLoading, true);

      // Wait for async operation to complete
      await Future.delayed(const Duration(milliseconds: 60));

      expect(controller.isLoading, false);
      expect(controller.items.length, 3);
      expect(controller.error, isNull);

      controller.dispose();
    });

    test('should handle async errors', () async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: const Duration(milliseconds: 10),
      );

      // Mock async loader that throws error
      controller
          .setAsyncLoader((query, {int page = 0, int pageSize = 20}) async {
        await Future.delayed(const Duration(milliseconds: 50));
        throw Exception('Network error');
      });

      controller.search('');

      // Wait for debounce and initial loading state
      await Future.delayed(const Duration(milliseconds: 20));
      expect(controller.isLoading, true);

      // Wait for error to occur
      await Future.delayed(const Duration(milliseconds: 60));

      expect(controller.isLoading, false);
      expect(controller.error, isNotNull);
      expect(controller.error.toString(), contains('Network error'));

      controller.dispose();
    });

    test('should handle race conditions in async operations', () async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: const Duration(milliseconds: 10),
      );

      int callCount = 0;
      controller
          .setAsyncLoader((query, {int page = 0, int pageSize = 20}) async {
        final currentCall = ++callCount;
        // First call takes longer than second
        await Future.delayed(
            Duration(milliseconds: currentCall == 1 ? 100 : 20));
        return ['Result $currentCall for: $query'];
      });

      // Trigger two searches quickly
      controller.search('first');
      await Future.delayed(const Duration(milliseconds: 15));
      controller.search('second');

      // Wait for both to complete
      await Future.delayed(const Duration(milliseconds: 120));

      // Should only show results from the second (latest) search
      expect(controller.items.length, 1);
      expect(controller.items.first, 'Result 2 for: second');

      controller.dispose();
    });

    test('should handle pagination correctly', () async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        pageSize: 2,
        debounceDelay: const Duration(milliseconds: 10),
      );

      controller
          .setAsyncLoader((query, {int page = 0, int pageSize = 20}) async {
        await Future.delayed(const Duration(milliseconds: 20));
        // Return 2 items for first page, 1 item for second page (< pageSize = no more pages)
        if (page == 0) return ['Item 1', 'Item 2'];
        if (page == 1) {
          return ['Item 3']; // Less than pageSize, so hasMorePages = false
        }
        return []; // No more items
      });

      // Initial load
      controller.search('');

      // Wait for debounce and async operation
      await Future.delayed(const Duration(milliseconds: 50));

      expect(controller.items.length, 2);
      expect(controller.hasMorePages, true);

      // Load more
      await controller.loadMore();

      // Wait a bit more to ensure async completes
      await Future.delayed(const Duration(milliseconds: 30));

      expect(controller.items.length, 3);
      expect(controller.hasMorePages, false);

      controller.dispose();
    });

    test('should refresh data correctly', () async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        cacheResults: true,
        debounceDelay: const Duration(milliseconds: 10),
      );

      bool firstCall = true;
      controller
          .setAsyncLoader((query, {int page = 0, int pageSize = 20}) async {
        await Future.delayed(const Duration(milliseconds: 20));
        if (firstCall) {
          firstCall = false;
          return ['Old Data'];
        }
        return ['New Data'];
      });

      // Initial load
      controller.search('');
      await Future.delayed(const Duration(milliseconds: 50));

      expect(controller.items.isNotEmpty, true);
      expect(controller.items.first, 'Old Data');

      // Refresh should clear cache and reload
      await controller.refresh();

      expect(controller.items.isNotEmpty, true);
      expect(controller.items.first, 'New Data');

      controller.dispose();
    });
  });
}
