import 'package:flutter_test/flutter_test.dart';
import 'package:smart_search_list/smart_search_list.dart';

void main() {
  group('SearchTriggerMode', () {
    test('onEdit mode: controller.search is called on text change', () async {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: const Duration(milliseconds: 10),
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });
      controller.setItems(['Apple', 'Banana', 'Cherry']);

      // In onEdit mode (default), calling search triggers debounced search
      controller.search('App');
      await Future.delayed(const Duration(milliseconds: 20));

      expect(controller.searchQuery, 'App');
      expect(controller.hasSearched, true);
    });

    test('searchImmediate bypasses debounce', () {
      final controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: const Duration(milliseconds: 5000), // long debounce
      );
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });
      controller.setItems(['Apple', 'Banana', 'Cherry']);

      // searchImmediate should apply immediately without waiting for debounce
      controller.searchImmediate('Ban');

      expect(controller.searchQuery, 'Ban');
      expect(controller.hasSearched, true);
      expect(controller.items.length, 1);
      expect(controller.items.first, 'Banana');
    });

    test('SearchConfiguration.triggerMode defaults to onEdit', () {
      const config = SearchConfiguration();
      expect(config.triggerMode, SearchTriggerMode.onEdit);
    });

    test('SearchConfiguration.copyWith preserves triggerMode', () {
      const config = SearchConfiguration(
        triggerMode: SearchTriggerMode.onSubmit,
      );

      final copied = config.copyWith(hintText: 'Search...');
      expect(copied.triggerMode, SearchTriggerMode.onSubmit);
    });

    test('SearchConfiguration.copyWith can override triggerMode', () {
      const config = SearchConfiguration(triggerMode: SearchTriggerMode.onEdit);

      final copied = config.copyWith(triggerMode: SearchTriggerMode.onSubmit);
      expect(copied.triggerMode, SearchTriggerMode.onSubmit);
    });
  });
}
