import 'package:flutter/material.dart';
import 'package:smart_search_list/smart_search_list.dart';

class SearchTriggerModeExample extends StatefulWidget {
  const SearchTriggerModeExample({super.key});

  @override
  State<SearchTriggerModeExample> createState() =>
      _SearchTriggerModeExampleState();
}

class _SearchTriggerModeExampleState extends State<SearchTriggerModeExample> {
  SearchTriggerMode _mode = SearchTriggerMode.onEdit;

  final _fruits = [
    'Apple',
    'Apricot',
    'Avocado',
    'Banana',
    'Blackberry',
    'Blueberry',
    'Cherry',
    'Coconut',
    'Cranberry',
    'Date',
    'Elderberry',
    'Fig',
    'Grape',
    'Guava',
    'Honeydew',
    'Kiwi',
    'Lemon',
    'Lime',
    'Lychee',
    'Mango',
    'Nectarine',
    'Orange',
    'Papaya',
    'Peach',
    'Pear',
    'Pineapple',
    'Plum',
    'Pomegranate',
    'Quince',
    'Raspberry',
    'Strawberry',
    'Tangerine',
    'Watermelon',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Trigger Modes')),
      body: Column(
        children: [
          // Mode toggle
          Card(
            margin: const EdgeInsets.all(16.0),
            child: ExpansionTile(
              title: Text(
                'Search Trigger Mode',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              shape: const Border(),
              collapsedShape: const Border(),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SegmentedButton<SearchTriggerMode>(
                        segments: const [
                          ButtonSegment(
                            value: SearchTriggerMode.onEdit,
                            label: Text('onEdit (live)'),
                            icon: Icon(Icons.edit),
                          ),
                          ButtonSegment(
                            value: SearchTriggerMode.onSubmit,
                            label: Text('onSubmit'),
                            icon: Icon(Icons.keyboard_return),
                          ),
                        ],
                        selected: {_mode},
                        onSelectionChanged: (modes) {
                          setState(() => _mode = modes.first);
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _mode == SearchTriggerMode.onEdit
                            ? 'List filters automatically as you type.'
                            : 'Type your query, then press Enter or tap the search icon.',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            // Key forces widget rebuild when mode changes
            child: SmartSearchList<String>(
              key: ValueKey(_mode),
              items: _fruits,
              searchableFields: (item) => [item],
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return ListTile(title: Text(item));
              },
              searchConfig: SearchConfiguration(
                triggerMode: _mode,
                hintText: _mode == SearchTriggerMode.onEdit
                    ? 'Type to search (live)...'
                    : 'Type then press Enter to search...',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
