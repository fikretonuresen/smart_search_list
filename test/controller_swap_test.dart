import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_search_list/smart_search_list.dart';

// Helper widget that allows swapping between widget configurations via setState.
// No ValueKey is used so that Flutter calls didUpdateWidget instead of destroying
// and recreating. For transitions that change between .controller() and offline
// (ext→null, null→ext), the wrapper conditionally picks a different constructor,
// which still triggers didUpdateWidget because both constructors produce the same
// SmartSearchList<String> widget type.
class _SwappableSmartSearchList extends StatefulWidget {
  final SmartSearchController<String>? initialController;
  final List<String>? initialItems;
  final List<String>? Function(List<String>? current)? itemsSwapper;
  final SmartSearchController<String>? Function(
    SmartSearchController<String>? current,
  )?
  controllerSwapper;

  const _SwappableSmartSearchList({
    this.initialController,
    this.initialItems,
    this.itemsSwapper,
    this.controllerSwapper,
  });

  @override
  State<_SwappableSmartSearchList> createState() =>
      _SwappableSmartSearchListState();
}

class _SwappableSmartSearchListState extends State<_SwappableSmartSearchList> {
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
      return SmartSearchList<String>.controller(
        controller: _controller!,
        itemBuilder: (context, item, index, {searchTerms = const []}) {
          return ListTile(title: Text(item));
        },
      );
    }
    return SmartSearchList<String>(
      items: _items ?? const [],
      searchableFields: (item) => [item],
      itemBuilder: (context, item, index, {searchTerms = const []}) {
        return ListTile(title: Text(item));
      },
    );
  }
}

/// Helper for sliver variant.
class _SwappableSliverSmartSearchList extends StatefulWidget {
  final SmartSearchController<String>? initialController;
  final List<String>? initialItems;
  final List<String>? Function(List<String>? current)? itemsSwapper;
  final SmartSearchController<String>? Function(
    SmartSearchController<String>? current,
  )?
  controllerSwapper;

  const _SwappableSliverSmartSearchList({
    this.initialController,
    this.initialItems,
    this.itemsSwapper,
    this.controllerSwapper,
  });

  @override
  State<_SwappableSliverSmartSearchList> createState() =>
      _SwappableSliverSmartSearchListState();
}

class _SwappableSliverSmartSearchListState
    extends State<_SwappableSliverSmartSearchList> {
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
          SliverSmartSearchList<String>.controller(
            controller: _controller!,
            itemBuilder: (context, item, index, {searchTerms = const []}) {
              return ListTile(title: Text(item));
            },
          ),
        ],
      );
    }
    return CustomScrollView(
      slivers: [
        SliverSmartSearchList<String>(
          items: _items ?? const [],
          searchableFields: (item) => [item],
          itemBuilder: (context, item, index, {searchTerms = const []}) {
            return ListTile(title: Text(item));
          },
        ),
      ],
    );
  }
}

void main() {
  group('SmartSearchList controller swap lifecycle', () {
    testWidgets('ext→ext: swapping external controllers transfers state', (
      tester,
    ) async {
      final controllerA = SmartSearchController<String>();
      controllerA.setItems(['Alpha', 'Bravo']);

      final controllerB = SmartSearchController<String>();
      controllerB.setItems(['Charlie', 'Delta']);

      final wrapper = _SwappableSmartSearchList(
        initialController: controllerA,
        controllerSwapper: (current) =>
            identical(current, controllerA) ? controllerB : controllerA,
      );

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: wrapper)));
      await tester.pumpAndSettle();

      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Bravo'), findsOneWidget);

      // Swap to controllerB via didUpdateWidget
      final state = tester.state<_SwappableSmartSearchListState>(
        find.byType(_SwappableSmartSearchList),
      );
      state.swap();
      await tester.pumpAndSettle();

      expect(find.text('Charlie'), findsOneWidget);
      expect(find.text('Delta'), findsOneWidget);
      expect(find.text('Alpha'), findsNothing);

      controllerA.dispose();
      controllerB.dispose();
    });

    testWidgets('ext→null: removing external controller creates internal', (
      tester,
    ) async {
      final controller = SmartSearchController<String>();
      controller.setItems(['Ext1', 'Ext2']);

      final wrapper = _SwappableSmartSearchList(
        initialController: controller,
        controllerSwapper: (_) => null,
        itemsSwapper: (_) => ['Int1', 'Int2'],
      );

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: wrapper)));
      await tester.pumpAndSettle();

      expect(find.text('Ext1'), findsOneWidget);

      // Swap to offline mode (no controller)
      final state = tester.state<_SwappableSmartSearchListState>(
        find.byType(_SwappableSmartSearchList),
      );
      state.swap();
      await tester.pumpAndSettle();

      expect(find.text('Int1'), findsOneWidget);
      expect(find.text('Int2'), findsOneWidget);
      expect(find.text('Ext1'), findsNothing);

      controller.dispose();
    });

    testWidgets('null→ext: adding external controller replaces internal', (
      tester,
    ) async {
      final controller = SmartSearchController<String>();
      controller.setItems(['FromCtrl']);

      final wrapper = _SwappableSmartSearchList(
        initialItems: ['FromItems'],
        controllerSwapper: (_) => controller,
      );

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: wrapper)));
      await tester.pumpAndSettle();

      expect(find.text('FromItems'), findsOneWidget);

      // Swap to controller mode
      final state = tester.state<_SwappableSmartSearchListState>(
        find.byType(_SwappableSmartSearchList),
      );
      state.swap();
      await tester.pumpAndSettle();

      expect(find.text('FromCtrl'), findsOneWidget);
      expect(find.text('FromItems'), findsNothing);

      controller.dispose();
    });

    testWidgets('null→null: swapping items without controller works', (
      tester,
    ) async {
      final wrapper = _SwappableSmartSearchList(
        initialItems: ['First1', 'First2'],
        itemsSwapper: (current) =>
            current?.first == 'First1' ? ['Second1'] : ['First1', 'First2'],
      );

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: wrapper)));
      await tester.pumpAndSettle();

      expect(find.text('First1'), findsOneWidget);
      expect(find.text('First2'), findsOneWidget);

      // Swap items via didUpdateWidget
      final state = tester.state<_SwappableSmartSearchListState>(
        find.byType(_SwappableSmartSearchList),
      );
      state.swap();
      await tester.pumpAndSettle();

      expect(find.text('Second1'), findsOneWidget);
      expect(find.text('First2'), findsNothing);
    });
  });

  group('SliverSmartSearchList controller swap lifecycle', () {
    testWidgets('ext→ext: swapping external controllers transfers state', (
      tester,
    ) async {
      final controllerA = SmartSearchController<String>();
      controllerA.setItems(['Alpha', 'Bravo']);

      final controllerB = SmartSearchController<String>();
      controllerB.setItems(['Charlie', 'Delta']);

      final wrapper = _SwappableSliverSmartSearchList(
        initialController: controllerA,
        controllerSwapper: (current) =>
            identical(current, controllerA) ? controllerB : controllerA,
      );

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: wrapper)));
      await tester.pumpAndSettle();

      expect(find.text('Alpha'), findsOneWidget);

      // Swap to controllerB
      final state = tester.state<_SwappableSliverSmartSearchListState>(
        find.byType(_SwappableSliverSmartSearchList),
      );
      state.swap();
      await tester.pumpAndSettle();

      expect(find.text('Charlie'), findsOneWidget);
      expect(find.text('Alpha'), findsNothing);

      controllerA.dispose();
      controllerB.dispose();
    });

    testWidgets('ext→null: removing external controller creates internal', (
      tester,
    ) async {
      final controller = SmartSearchController<String>();
      controller.setItems(['SliverExt1']);

      final wrapper = _SwappableSliverSmartSearchList(
        initialController: controller,
        controllerSwapper: (_) => null,
        itemsSwapper: (_) => ['SliverInt1'],
      );

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: wrapper)));
      await tester.pumpAndSettle();

      expect(find.text('SliverExt1'), findsOneWidget);

      // Swap to offline mode
      final state = tester.state<_SwappableSliverSmartSearchListState>(
        find.byType(_SwappableSliverSmartSearchList),
      );
      state.swap();
      await tester.pumpAndSettle();

      expect(find.text('SliverInt1'), findsOneWidget);
      expect(find.text('SliverExt1'), findsNothing);

      controller.dispose();
    });

    testWidgets('null→ext: adding external controller replaces internal', (
      tester,
    ) async {
      final controller = SmartSearchController<String>();
      controller.setItems(['SliverCtrl']);

      final wrapper = _SwappableSliverSmartSearchList(
        initialItems: ['SliverItems'],
        controllerSwapper: (_) => controller,
      );

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: wrapper)));
      await tester.pumpAndSettle();

      expect(find.text('SliverItems'), findsOneWidget);

      // Swap to controller mode
      final state = tester.state<_SwappableSliverSmartSearchListState>(
        find.byType(_SwappableSliverSmartSearchList),
      );
      state.swap();
      await tester.pumpAndSettle();

      expect(find.text('SliverCtrl'), findsOneWidget);
      expect(find.text('SliverItems'), findsNothing);

      controller.dispose();
    });

    testWidgets('null→null: swapping items without controller works', (
      tester,
    ) async {
      final wrapper = _SwappableSliverSmartSearchList(
        initialItems: ['SFirst1'],
        itemsSwapper: (current) =>
            current?.first == 'SFirst1' ? ['SSecond1'] : ['SFirst1'],
      );

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: wrapper)));
      await tester.pumpAndSettle();

      expect(find.text('SFirst1'), findsOneWidget);

      // Swap items
      final state = tester.state<_SwappableSliverSmartSearchListState>(
        find.byType(_SwappableSliverSmartSearchList),
      );
      state.swap();
      await tester.pumpAndSettle();

      expect(find.text('SSecond1'), findsOneWidget);
    });
  });
}
