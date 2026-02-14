import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_search_list/smart_search_list.dart';

// Helper to create a standard grid config for tests.
GridConfiguration _gridConfig({int crossAxisCount = 2}) {
  return GridConfiguration(
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      childAspectRatio: 5.0,
    ),
  );
}

// Helper widget that allows swapping between widget configurations via setState.
// No ValueKey is used so that Flutter calls didUpdateWidget instead of destroying
// and recreating. For transitions that change between .controller() and offline
// (ext→null, null→ext), the wrapper conditionally picks a different constructor,
// which still triggers didUpdateWidget because both constructors produce the same
// SmartSearchGrid<String> widget type.
class _SwappableSmartSearchGrid extends StatefulWidget {
  final SmartSearchController<String>? initialController;
  final List<String>? initialItems;
  final List<String>? Function(List<String>? current)? itemsSwapper;
  final SmartSearchController<String>? Function(
    SmartSearchController<String>? current,
  )?
  controllerSwapper;

  const _SwappableSmartSearchGrid({
    this.initialController,
    this.initialItems,
    this.itemsSwapper,
    this.controllerSwapper,
  });

  @override
  State<_SwappableSmartSearchGrid> createState() =>
      _SwappableSmartSearchGridState();
}

class _SwappableSmartSearchGridState extends State<_SwappableSmartSearchGrid> {
  late SmartSearchController<String>? _controller;
  late List<String>? _items;

  @override
  void initState() {
    super.initState();
    _controller = widget.initialController;
    _items = widget.initialItems;
  }

  void swap() {
    setState(() {
      if (widget.controllerSwapper != null) {
        _controller = widget.controllerSwapper!(_controller);
      }
      if (widget.itemsSwapper != null) {
        _items = widget.itemsSwapper!(_items);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_controller != null) {
      return SmartSearchGrid<String>.controller(
        controller: _controller!,
        itemBuilder: (context, item, index, {searchTerms = const []}) {
          return Text(item);
        },
        gridConfig: _gridConfig(),
      );
    }
    return SmartSearchGrid<String>(
      items: _items ?? const [],
      searchableFields: (item) => [item],
      itemBuilder: (context, item, index, {searchTerms = const []}) {
        return Text(item);
      },
      gridConfig: _gridConfig(),
    );
  }
}

// Helper for sliver variant.
class _SwappableSliverSmartSearchGrid extends StatefulWidget {
  final SmartSearchController<String>? initialController;
  final List<String>? initialItems;
  final List<String>? Function(List<String>? current)? itemsSwapper;
  final SmartSearchController<String>? Function(
    SmartSearchController<String>? current,
  )?
  controllerSwapper;

  const _SwappableSliverSmartSearchGrid({
    this.initialController,
    this.initialItems,
    this.itemsSwapper,
    this.controllerSwapper,
  });

  @override
  State<_SwappableSliverSmartSearchGrid> createState() =>
      _SwappableSliverSmartSearchGridState();
}

class _SwappableSliverSmartSearchGridState
    extends State<_SwappableSliverSmartSearchGrid> {
  late SmartSearchController<String>? _controller;
  late List<String>? _items;

  @override
  void initState() {
    super.initState();
    _controller = widget.initialController;
    _items = widget.initialItems;
  }

  void swap() {
    setState(() {
      if (widget.controllerSwapper != null) {
        _controller = widget.controllerSwapper!(_controller);
      }
      if (widget.itemsSwapper != null) {
        _items = widget.itemsSwapper!(_items);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_controller != null) {
      return CustomScrollView(
        slivers: [
          SliverSmartSearchGrid<String>.controller(
            controller: _controller!,
            itemBuilder: (context, item, index, {searchTerms = const []}) {
              return Text(item);
            },
            gridConfig: _gridConfig(),
          ),
        ],
      );
    }
    return CustomScrollView(
      slivers: [
        SliverSmartSearchGrid<String>(
          items: _items ?? const [],
          searchableFields: (item) => [item],
          itemBuilder: (context, item, index, {searchTerms = const []}) {
            return Text(item);
          },
          gridConfig: _gridConfig(),
        ),
      ],
    );
  }
}

void main() {
  group('SmartSearchGrid controller swap lifecycle', () {
    testWidgets('ext→ext: swapping external controllers transfers state', (
      tester,
    ) async {
      final controllerA = SmartSearchController<String>();
      addTearDown(() {
        if (!controllerA.isDisposed) controllerA.dispose();
      });
      controllerA.setItems(['Alpha', 'Bravo']);

      final controllerB = SmartSearchController<String>();
      addTearDown(() {
        if (!controllerB.isDisposed) controllerB.dispose();
      });
      controllerB.setItems(['Charlie', 'Delta']);

      final wrapper = _SwappableSmartSearchGrid(
        initialController: controllerA,
        controllerSwapper: (current) =>
            identical(current, controllerA) ? controllerB : controllerA,
      );

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: wrapper)));
      await tester.pumpAndSettle();

      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Bravo'), findsOneWidget);

      // Swap to controllerB via didUpdateWidget
      final state = tester.state<_SwappableSmartSearchGridState>(
        find.byType(_SwappableSmartSearchGrid),
      );
      state.swap();
      await tester.pumpAndSettle();

      expect(find.text('Charlie'), findsOneWidget);
      expect(find.text('Delta'), findsOneWidget);
      expect(find.text('Alpha'), findsNothing);
    });

    testWidgets('ext→null: removing external controller creates internal', (
      tester,
    ) async {
      final controller = SmartSearchController<String>();
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });
      controller.setItems(['Ext1', 'Ext2']);

      final wrapper = _SwappableSmartSearchGrid(
        initialController: controller,
        controllerSwapper: (_) => null,
        itemsSwapper: (_) => ['Int1', 'Int2'],
      );

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: wrapper)));
      await tester.pumpAndSettle();

      expect(find.text('Ext1'), findsOneWidget);

      // Swap to offline mode (no controller)
      final state = tester.state<_SwappableSmartSearchGridState>(
        find.byType(_SwappableSmartSearchGrid),
      );
      state.swap();
      await tester.pumpAndSettle();

      expect(find.text('Int1'), findsOneWidget);
      expect(find.text('Int2'), findsOneWidget);
      expect(find.text('Ext1'), findsNothing);
    });

    testWidgets('null→ext: adding external controller replaces internal', (
      tester,
    ) async {
      final controller = SmartSearchController<String>();
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });
      controller.setItems(['FromCtrl']);

      final wrapper = _SwappableSmartSearchGrid(
        initialItems: ['FromItems'],
        controllerSwapper: (_) => controller,
      );

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: wrapper)));
      await tester.pumpAndSettle();

      expect(find.text('FromItems'), findsOneWidget);

      // Swap to controller mode
      final state = tester.state<_SwappableSmartSearchGridState>(
        find.byType(_SwappableSmartSearchGrid),
      );
      state.swap();
      await tester.pumpAndSettle();

      expect(find.text('FromCtrl'), findsOneWidget);
      expect(find.text('FromItems'), findsNothing);
    });

    testWidgets('null→null: swapping items without controller works', (
      tester,
    ) async {
      final wrapper = _SwappableSmartSearchGrid(
        initialItems: ['First1', 'First2'],
        itemsSwapper: (current) =>
            current?.first == 'First1' ? ['Second1'] : ['First1', 'First2'],
      );

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: wrapper)));
      await tester.pumpAndSettle();

      expect(find.text('First1'), findsOneWidget);
      expect(find.text('First2'), findsOneWidget);

      // Swap items via didUpdateWidget
      final state = tester.state<_SwappableSmartSearchGridState>(
        find.byType(_SwappableSmartSearchGrid),
      );
      state.swap();
      await tester.pumpAndSettle();

      expect(find.text('Second1'), findsOneWidget);
      expect(find.text('First2'), findsNothing);
    });
  });

  group('SliverSmartSearchGrid controller swap lifecycle', () {
    testWidgets('ext→ext: swapping external controllers transfers state', (
      tester,
    ) async {
      final controllerA = SmartSearchController<String>();
      addTearDown(() {
        if (!controllerA.isDisposed) controllerA.dispose();
      });
      controllerA.setItems(['Alpha', 'Bravo']);

      final controllerB = SmartSearchController<String>();
      addTearDown(() {
        if (!controllerB.isDisposed) controllerB.dispose();
      });
      controllerB.setItems(['Charlie', 'Delta']);

      final wrapper = _SwappableSliverSmartSearchGrid(
        initialController: controllerA,
        controllerSwapper: (current) =>
            identical(current, controllerA) ? controllerB : controllerA,
      );

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: wrapper)));
      await tester.pumpAndSettle();

      expect(find.text('Alpha'), findsOneWidget);

      // Swap to controllerB
      final state = tester.state<_SwappableSliverSmartSearchGridState>(
        find.byType(_SwappableSliverSmartSearchGrid),
      );
      state.swap();
      await tester.pumpAndSettle();

      expect(find.text('Charlie'), findsOneWidget);
      expect(find.text('Alpha'), findsNothing);
    });

    testWidgets('ext→null: removing external controller creates internal', (
      tester,
    ) async {
      final controller = SmartSearchController<String>();
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });
      controller.setItems(['SliverExt1']);

      final wrapper = _SwappableSliverSmartSearchGrid(
        initialController: controller,
        controllerSwapper: (_) => null,
        itemsSwapper: (_) => ['SliverInt1'],
      );

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: wrapper)));
      await tester.pumpAndSettle();

      expect(find.text('SliverExt1'), findsOneWidget);

      // Swap to offline mode
      final state = tester.state<_SwappableSliverSmartSearchGridState>(
        find.byType(_SwappableSliverSmartSearchGrid),
      );
      state.swap();
      await tester.pumpAndSettle();

      expect(find.text('SliverInt1'), findsOneWidget);
      expect(find.text('SliverExt1'), findsNothing);
    });

    testWidgets('null→ext: adding external controller replaces internal', (
      tester,
    ) async {
      final controller = SmartSearchController<String>();
      addTearDown(() {
        if (!controller.isDisposed) controller.dispose();
      });
      controller.setItems(['SliverCtrl']);

      final wrapper = _SwappableSliverSmartSearchGrid(
        initialItems: ['SliverItems'],
        controllerSwapper: (_) => controller,
      );

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: wrapper)));
      await tester.pumpAndSettle();

      expect(find.text('SliverItems'), findsOneWidget);

      // Swap to controller mode
      final state = tester.state<_SwappableSliverSmartSearchGridState>(
        find.byType(_SwappableSliverSmartSearchGrid),
      );
      state.swap();
      await tester.pumpAndSettle();

      expect(find.text('SliverCtrl'), findsOneWidget);
      expect(find.text('SliverItems'), findsNothing);
    });

    testWidgets('null→null: swapping items without controller works', (
      tester,
    ) async {
      final wrapper = _SwappableSliverSmartSearchGrid(
        initialItems: ['SFirst1'],
        itemsSwapper: (current) =>
            current?.first == 'SFirst1' ? ['SSecond1'] : ['SFirst1'],
      );

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: wrapper)));
      await tester.pumpAndSettle();

      expect(find.text('SFirst1'), findsOneWidget);

      // Swap items
      final state = tester.state<_SwappableSliverSmartSearchGridState>(
        find.byType(_SwappableSliverSmartSearchGrid),
      );
      state.swap();
      await tester.pumpAndSettle();

      expect(find.text('SSecond1'), findsOneWidget);
    });
  });
}
