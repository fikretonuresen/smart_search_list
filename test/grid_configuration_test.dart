import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_search_list/smart_search_list.dart';

void main() {
  group('GridConfiguration', () {
    test('constructor sets defaults correctly', () {
      final config = GridConfiguration(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
        ),
      );

      expect(config.pullToRefresh, true);
      expect(config.physics, isNull);
      expect(config.padding, isNull);
      expect(config.shrinkWrap, false);
      expect(config.reverse, false);
      expect(config.scrollDirection, Axis.vertical);
      expect(config.addAutomaticKeepAlives, true);
      expect(config.addRepaintBoundaries, true);
      expect(config.addSemanticIndexes, true);
      expect(config.cacheExtent, isNull);
      expect(config.clipBehavior, Clip.hardEdge);
    });

    test('constructor accepts custom values', () {
      const physics = BouncingScrollPhysics();
      const padding = EdgeInsets.all(8.0);

      final config = GridConfiguration(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
        ),
        pullToRefresh: false,
        physics: physics,
        padding: padding,
        shrinkWrap: true,
        reverse: true,
        scrollDirection: Axis.horizontal,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: false,
        addSemanticIndexes: false,
        cacheExtent: 500.0,
        clipBehavior: Clip.antiAlias,
      );

      expect(config.pullToRefresh, false);
      expect(config.physics, physics);
      expect(config.padding, padding);
      expect(config.shrinkWrap, true);
      expect(config.reverse, true);
      expect(config.scrollDirection, Axis.horizontal);
      expect(config.addAutomaticKeepAlives, false);
      expect(config.addRepaintBoundaries, false);
      expect(config.addSemanticIndexes, false);
      expect(config.cacheExtent, 500.0);
      expect(config.clipBehavior, Clip.antiAlias);
    });

    test('copyWith replaces specified fields', () {
      final original = GridConfiguration(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
        ),
      );

      final copied = original.copyWith(
        pullToRefresh: false,
        shrinkWrap: true,
        cacheExtent: 300.0,
      );

      expect(copied.pullToRefresh, false);
      expect(copied.shrinkWrap, true);
      expect(copied.cacheExtent, 300.0);
      // Unchanged fields
      expect(copied.reverse, false);
      expect(copied.scrollDirection, Axis.vertical);
      expect(copied.addAutomaticKeepAlives, true);
    });

    test('copyWith with no arguments returns equivalent config', () {
      final original = GridConfiguration(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
        ),
        pullToRefresh: false,
        shrinkWrap: true,
      );

      final copied = original.copyWith();

      expect(copied.pullToRefresh, original.pullToRefresh);
      expect(copied.shrinkWrap, original.shrinkWrap);
      expect(copied.reverse, original.reverse);
      expect(copied.scrollDirection, original.scrollDirection);
    });

    test('copyWith can replace gridDelegate', () {
      final original = GridConfiguration(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
        ),
      );

      const newDelegate = SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
      );
      final copied = original.copyWith(gridDelegate: newDelegate);

      expect(copied.gridDelegate, newDelegate);
    });

    test('const construction works with const delegate', () {
      // Verifies the constructor can be used with const
      const config = GridConfiguration(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
        ),
      );

      expect(config.pullToRefresh, true);
    });
  });
}
