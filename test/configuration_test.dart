import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_search_list/smart_search_list.dart';

void main() {
  group('SearchConfiguration.copyWith', () {
    test('preserves all fields when no args', () {
      const config = SearchConfiguration(
        enabled: false,
        autofocus: true,
        showClearButton: false,
        debounceDelay: Duration(milliseconds: 500),
        hintText: 'Find...',
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        caseSensitive: true,
        closeKeyboardOnScroll: false,
        minSearchLength: 3,
        padding: EdgeInsets.all(8.0),
        triggerMode: SearchTriggerMode.onSubmit,
        fuzzySearchEnabled: true,
        fuzzyThreshold: 0.5,
      );

      final copy = config.copyWith();

      expect(copy.enabled, config.enabled);
      expect(copy.autofocus, config.autofocus);
      expect(copy.showClearButton, config.showClearButton);
      expect(copy.debounceDelay, config.debounceDelay);
      expect(copy.hintText, config.hintText);
      expect(copy.keyboardType, config.keyboardType);
      expect(copy.textInputAction, config.textInputAction);
      expect(copy.caseSensitive, config.caseSensitive);
      expect(copy.closeKeyboardOnScroll, config.closeKeyboardOnScroll);
      expect(copy.minSearchLength, config.minSearchLength);
      expect(copy.padding, config.padding);
      expect(copy.triggerMode, config.triggerMode);
      expect(copy.fuzzySearchEnabled, config.fuzzySearchEnabled);
      expect(copy.fuzzyThreshold, config.fuzzyThreshold);
    });

    test('overrides each field independently', () {
      const config = SearchConfiguration();

      // Override one field at a time and verify only that field changed
      expect(config.copyWith(enabled: false).enabled, false);
      expect(config.copyWith(autofocus: true).autofocus, true);
      expect(config.copyWith(showClearButton: false).showClearButton, false);
      expect(
        config.copyWith(debounceDelay: Duration.zero).debounceDelay,
        Duration.zero,
      );
      expect(config.copyWith(hintText: 'Go').hintText, 'Go');
      expect(
        config.copyWith(keyboardType: TextInputType.url).keyboardType,
        TextInputType.url,
      );
      expect(
        config.copyWith(textInputAction: TextInputAction.go).textInputAction,
        TextInputAction.go,
      );
      expect(config.copyWith(caseSensitive: true).caseSensitive, true);
      expect(
        config.copyWith(closeKeyboardOnScroll: false).closeKeyboardOnScroll,
        false,
      );
      expect(config.copyWith(minSearchLength: 5).minSearchLength, 5);
      expect(
        config.copyWith(padding: EdgeInsets.zero).padding,
        EdgeInsets.zero,
      );
      expect(
        config.copyWith(triggerMode: SearchTriggerMode.onSubmit).triggerMode,
        SearchTriggerMode.onSubmit,
      );
      expect(
        config.copyWith(fuzzySearchEnabled: true).fuzzySearchEnabled,
        true,
      );
      expect(config.copyWith(fuzzyThreshold: 0.9).fuzzyThreshold, 0.9);

      // Verify unchanged fields remain default
      final partial = config.copyWith(hintText: 'Changed');
      expect(partial.hintText, 'Changed');
      expect(partial.enabled, config.enabled);
      expect(partial.fuzzySearchEnabled, config.fuzzySearchEnabled);
    });
  });

  group('ListConfiguration.copyWith', () {
    test('preserves all fields when no args', () {
      const config = ListConfiguration(
        pullToRefresh: false,
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.all(12.0),
        shrinkWrap: true,
        reverse: true,
        scrollDirection: Axis.horizontal,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: false,
        addSemanticIndexes: false,
        itemExtent: 50.0,
        cacheExtent: 300.0,
        clipBehavior: Clip.none,
      );

      final copy = config.copyWith();

      expect(copy.pullToRefresh, config.pullToRefresh);
      expect(copy.physics, config.physics);
      expect(copy.padding, config.padding);
      expect(copy.shrinkWrap, config.shrinkWrap);
      expect(copy.reverse, config.reverse);
      expect(copy.scrollDirection, config.scrollDirection);
      expect(copy.addAutomaticKeepAlives, config.addAutomaticKeepAlives);
      expect(copy.addRepaintBoundaries, config.addRepaintBoundaries);
      expect(copy.addSemanticIndexes, config.addSemanticIndexes);
      expect(copy.itemExtent, config.itemExtent);
      expect(copy.cacheExtent, config.cacheExtent);
      expect(copy.clipBehavior, config.clipBehavior);
    });

    test('overrides each field independently', () {
      const config = ListConfiguration();

      expect(config.copyWith(pullToRefresh: false).pullToRefresh, false);
      expect(config.copyWith(shrinkWrap: true).shrinkWrap, true);
      expect(config.copyWith(reverse: true).reverse, true);
      expect(
        config.copyWith(scrollDirection: Axis.horizontal).scrollDirection,
        Axis.horizontal,
      );
      expect(
        config.copyWith(addAutomaticKeepAlives: false).addAutomaticKeepAlives,
        false,
      );
      expect(
        config.copyWith(addRepaintBoundaries: false).addRepaintBoundaries,
        false,
      );
      expect(
        config.copyWith(addSemanticIndexes: false).addSemanticIndexes,
        false,
      );
      expect(config.copyWith(itemExtent: 100.0).itemExtent, 100.0);
      expect(config.copyWith(cacheExtent: 500.0).cacheExtent, 500.0);
      expect(
        config.copyWith(clipBehavior: Clip.antiAlias).clipBehavior,
        Clip.antiAlias,
      );

      // Verify unchanged fields remain default
      final partial = config.copyWith(reverse: true);
      expect(partial.reverse, true);
      expect(partial.pullToRefresh, config.pullToRefresh);
      expect(partial.shrinkWrap, config.shrinkWrap);
    });
  });

  group('SelectionConfiguration.copyWith', () {
    test('preserves all fields when no args', () {
      const config = SelectionConfiguration(
        enabled: false,
        showCheckbox: false,
        position: CheckboxPosition.trailing,
      );

      final copy = config.copyWith();

      expect(copy.enabled, config.enabled);
      expect(copy.showCheckbox, config.showCheckbox);
      expect(copy.position, config.position);
    });

    test('overrides each field independently', () {
      const config = SelectionConfiguration();

      expect(config.copyWith(enabled: false).enabled, false);
      expect(config.copyWith(showCheckbox: false).showCheckbox, false);
      expect(
        config.copyWith(position: CheckboxPosition.trailing).position,
        CheckboxPosition.trailing,
      );

      // Verify unchanged fields remain default
      final partial = config.copyWith(enabled: false);
      expect(partial.enabled, false);
      expect(partial.showCheckbox, config.showCheckbox);
      expect(partial.position, config.position);
    });
  });

  group('PaginationConfiguration', () {
    test('copyWith preserves all fields when no args', () {
      const config = PaginationConfiguration(
        pageSize: 50,
        triggerDistance: 100.0,
        enabled: false,
      );

      final copy = config.copyWith();

      expect(copy.pageSize, config.pageSize);
      expect(copy.triggerDistance, config.triggerDistance);
      expect(copy.enabled, config.enabled);
    });

    test('copyWith overrides each field independently', () {
      const config = PaginationConfiguration();

      expect(config.copyWith(pageSize: 10).pageSize, 10);
      expect(config.copyWith(triggerDistance: 50.0).triggerDistance, 50.0);
      expect(config.copyWith(enabled: false).enabled, false);

      // Verify unchanged fields remain default
      final partial = config.copyWith(pageSize: 10);
      expect(partial.pageSize, 10);
      expect(partial.triggerDistance, config.triggerDistance);
      expect(partial.enabled, config.enabled);
    });

    test('isValid returns correct values', () {
      // Valid defaults
      expect(const PaginationConfiguration().isValid, isTrue);
      expect(const PaginationConfiguration(pageSize: 1).isValid, isTrue);
      expect(
        const PaginationConfiguration(triggerDistance: 0.0).isValid,
        isTrue,
      );
    });
  });

  group('AccessibilityConfiguration.copyWith', () {
    test('preserves all fields when no args', () {
      String builder(int count) => '$count items';
      final config = AccessibilityConfiguration(
        searchSemanticsEnabled: false,
        searchFieldLabel: 'Find items',
        resultsAnnouncementBuilder: builder,
        clearButtonLabel: 'Reset',
        searchButtonLabel: 'Go',
      );

      final copy = config.copyWith();

      expect(copy.searchSemanticsEnabled, config.searchSemanticsEnabled);
      expect(copy.searchFieldLabel, config.searchFieldLabel);
      expect(
        copy.resultsAnnouncementBuilder,
        config.resultsAnnouncementBuilder,
      );
      expect(copy.clearButtonLabel, config.clearButtonLabel);
      expect(copy.searchButtonLabel, config.searchButtonLabel);
    });

    test('overrides each field independently', () {
      const config = AccessibilityConfiguration();

      expect(
        config.copyWith(searchSemanticsEnabled: false).searchSemanticsEnabled,
        false,
      );
      expect(
        config.copyWith(searchFieldLabel: 'Find').searchFieldLabel,
        'Find',
      );
      expect(config.copyWith(clearButtonLabel: 'X').clearButtonLabel, 'X');
      expect(config.copyWith(searchButtonLabel: 'Go').searchButtonLabel, 'Go');

      // Verify unchanged fields remain default
      final partial = config.copyWith(searchFieldLabel: 'Find');
      expect(partial.searchFieldLabel, 'Find');
      expect(partial.searchSemanticsEnabled, config.searchSemanticsEnabled);
    });
  });
}
