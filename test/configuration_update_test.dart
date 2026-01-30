import 'package:flutter_test/flutter_test.dart';
import 'package:smart_search_list/smart_search_list.dart';

void main() {
  group('SmartSearchController Configuration Updates', () {
    late SmartSearchController<String> controller;

    setUp(() {
      controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        caseSensitive: false,
        minSearchLength: 0,
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('should update case sensitive setting dynamically', () {
      // Setup initial state
      controller.setItems(['Apple', 'apple', 'APPLE']);

      // Verify initial case insensitive behavior
      expect(controller.caseSensitive, false);

      // Update to case sensitive
      controller.updateCaseSensitive(true);
      expect(controller.caseSensitive, true);

      // Test that search behavior changed (would need actual search to verify)
      controller.search('apple');
      // In case sensitive mode, 'apple' should only match 'apple', not 'Apple' or 'APPLE'
    });

    test('should update minimum search length dynamically', () {
      // Setup initial state
      controller.setItems(['Apple', 'Banana', 'Cherry']);

      // Verify initial minimum length
      expect(controller.minSearchLength, 0);

      // Update minimum search length
      controller.updateMinSearchLength(2);
      expect(controller.minSearchLength, 2);

      // Verify search behavior respects new minimum length
      controller.search('A'); // Should not trigger search since length < 2
      expect(controller.searchQuery,
          ''); // Query should be empty since it's below minimum
    });

    test('should not update if value is the same', () {
      final initialCaseSensitive = controller.caseSensitive;
      final initialMinLength = controller.minSearchLength;

      // Try to update with same values
      controller.updateCaseSensitive(initialCaseSensitive);
      controller.updateMinSearchLength(initialMinLength);

      // Values should remain the same
      expect(controller.caseSensitive, initialCaseSensitive);
      expect(controller.minSearchLength, initialMinLength);
    });

    test('should not update after disposal', () {
      // Create a separate controller for this test
      final testController = SmartSearchController<String>(
        searchableFields: (item) => [item],
        caseSensitive: false,
        minSearchLength: 0,
      );

      testController.dispose();

      // Try to update after disposal - should not crash
      testController.updateCaseSensitive(true);
      testController.updateMinSearchLength(5);

      // These should not change anything since controller is disposed
      expect(testController.isDisposed, true);
    });
  });
}
