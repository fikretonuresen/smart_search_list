import 'package:flutter/material.dart';
import 'package:smart_search_list/smart_search_list.dart';

class MultiSelectExample extends StatefulWidget {
  const MultiSelectExample({super.key});

  @override
  State<MultiSelectExample> createState() => _MultiSelectExampleState();
}

class _MultiSelectExampleState extends State<MultiSelectExample> {
  final _controller = SmartSearchController<String>(
    searchableFields: (item) => [item],
  );

  // 50 items so we have enough to scroll off-screen
  final _items = List.generate(50, (i) {
    const names = [
      'Apple',
      'Banana',
      'Cherry',
      'Date',
      'Elderberry',
      'Fig',
      'Grape',
      'Honeydew',
      'Kiwi',
      'Lemon',
      'Mango',
      'Nectarine',
      'Orange',
      'Papaya',
      'Quince',
      'Raspberry',
      'Strawberry',
      'Tangerine',
      'Watermelon',
      'Zucchini',
      'Artichoke',
      'Broccoli',
      'Carrot',
      'Daikon',
      'Endive',
    ];
    return '${names[i % names.length]} ${i + 1}';
  });

  @override
  void initState() {
    super.initState();
    _controller.setItems(_items);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multi-Select'),
        actions: [
          IconButton(
            icon: const Icon(Icons.select_all),
            tooltip: 'Select All',
            onPressed: () => _controller.selectAll(),
          ),
          IconButton(
            icon: const Icon(Icons.deselect),
            tooltip: 'Deselect All',
            onPressed: () => _controller.deselectAll(),
          ),
        ],
      ),
      body: SmartSearchList<String>.controller(
        controller: _controller,
        itemBuilder: (context, item, index, {searchTerms = const []}) {
          return ListTile(title: Text(item), subtitle: Text('Index: $index'));
        },
        selectionConfig: const SelectionConfiguration(
          enabled: true,
          showCheckbox: true,
          position: CheckboxPosition.leading,
        ),
        onSelectionChanged: (selected) {
          // Trigger rebuild for the banner
          setState(() {});
        },
        belowSearchWidget: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final selected = _controller.selectedItems;
            if (selected.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Text(
                  'Select items using checkboxes. Selection persists across searches.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              );
            }
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                '${selected.length} selected: ${selected.take(5).join(", ")}${selected.length > 5 ? "..." : ""}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontSize: 13,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
