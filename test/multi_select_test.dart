import 'package:flutter_test/flutter_test.dart';
import 'package:smart_search_list/smart_search_list.dart';

void main() {
  group('SmartSearchController Multi-Select', () {
    late SmartSearchController<String> controller;

    setUp(() {
      controller = SmartSearchController<String>(
        searchableFields: (item) => [item],
        debounceDelay: const Duration(milliseconds: 10),
      );
      controller.setItems(['Apple', 'Banana', 'Cherry', 'Date', 'Elderberry']);
    });

    tearDown(() {
      controller.dispose();
    });

    test('toggleSelection adds and removes items', () {
      controller.toggleSelection('Apple');
      expect(controller.isSelected('Apple'), true);

      controller.toggleSelection('Apple');
      expect(controller.isSelected('Apple'), false);
    });

    test('select adds item to selection', () {
      controller.select('Banana');
      expect(controller.isSelected('Banana'), true);
      expect(controller.selectedItems.length, 1);
    });

    test('deselect removes item from selection', () {
      controller.select('Cherry');
      expect(controller.isSelected('Cherry'), true);

      controller.deselect('Cherry');
      expect(controller.isSelected('Cherry'), false);
    });

    test('selectAll selects all filtered items', () {
      controller.selectAll();
      expect(controller.selectedItems.length, 5);
      expect(controller.isSelected('Apple'), true);
      expect(controller.isSelected('Elderberry'), true);
    });

    test('deselectAll clears selection', () {
      controller.selectAll();
      expect(controller.selectedItems.length, 5);

      controller.deselectAll();
      expect(controller.selectedItems.length, 0);
    });

    test('selectWhere selects items matching predicate', () {
      controller
          .selectWhere((item) => item.startsWith('B') || item.startsWith('C'));
      expect(controller.selectedItems.length, 2);
      expect(controller.isSelected('Banana'), true);
      expect(controller.isSelected('Cherry'), true);
      expect(controller.isSelected('Apple'), false);
    });

    test('deselectWhere removes items matching predicate', () {
      controller.selectAll();
      controller.deselectWhere((item) => item.startsWith('A'));
      expect(controller.isSelected('Apple'), false);
      expect(controller.isSelected('Banana'), true);
    });

    test('isSelected returns correct values', () {
      expect(controller.isSelected('Apple'), false);
      controller.select('Apple');
      expect(controller.isSelected('Apple'), true);
      expect(controller.isSelected('Banana'), false);
    });

    test('selectedItems returns unmodifiable set', () {
      controller.select('Apple');
      final items = controller.selectedItems;
      expect(items, isA<Set<String>>());
      expect(() => items.add('Banana'), throwsUnsupportedError);
    });

    test('selection survives after search changes', () async {
      controller.select('Apple');
      controller.select('Banana');

      controller.search('Cherry');
      await Future.delayed(const Duration(milliseconds: 20));

      // Selection should persist even though filtered view changed
      expect(controller.isSelected('Apple'), true);
      expect(controller.isSelected('Banana'), true);
    });

    test('selection survives after filter changes', () async {
      controller.select('Apple');
      controller.select('Banana');

      controller.setFilter('startsWithC', (item) => item.startsWith('C'));
      await Future.delayed(const Duration(milliseconds: 20));

      expect(controller.isSelected('Apple'), true);
      expect(controller.isSelected('Banana'), true);
    });

    test('selection cleared on dispose', () {
      final ctrl = SmartSearchController<String>(
        searchableFields: (item) => [item],
      );
      ctrl.setItems(['Apple', 'Banana']);
      ctrl.select('Apple');
      expect(ctrl.isSelected('Apple'), true);

      ctrl.dispose();
      expect(ctrl.selectedItems.isEmpty, true);
    });

    test('toggleSelection does not crash after dispose', () {
      final ctrl = SmartSearchController<String>(
        searchableFields: (item) => [item],
      );
      ctrl.setItems(['Apple']);
      ctrl.dispose();

      // Should not throw
      ctrl.toggleSelection('Apple');
      ctrl.select('Apple');
      ctrl.deselect('Apple');
    });
  });
}
