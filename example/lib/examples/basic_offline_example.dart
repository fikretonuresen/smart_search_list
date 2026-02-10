import 'package:flutter/material.dart';
import 'package:smart_search_list/smart_search_list.dart';

/// Basic offline list with configuration options
class BasicOfflineExample extends StatefulWidget {
  const BasicOfflineExample({super.key});

  @override
  State<BasicOfflineExample> createState() => _BasicOfflineExampleState();
}

class _BasicOfflineExampleState extends State<BasicOfflineExample> {
  bool _caseSensitive = false;
  int _minSearchLength = 0;

  static final List<String> _fruits = [
    'Apple',
    'Apricot',
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
    'Grapefruit',
    'Guava',
    'Kiwi',
    'Lemon',
    'Lime',
    'Mango',
    'Orange',
    'Papaya',
    'Peach',
    'Pear',
    'Pineapple',
    'Plum',
    'Pomegranate',
    'Raspberry',
    'Strawberry',
    'Watermelon',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Basic Offline List'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Configuration controls
          Card(
            margin: const EdgeInsets.all(16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search Configuration',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Case Sensitive'),
                    subtitle: Text(
                      _caseSensitive
                          ? 'Try "Apple" vs "apple"'
                          : 'Search ignores case',
                    ),
                    value: _caseSensitive,
                    onChanged: (value) =>
                        setState(() => _caseSensitive = value),
                  ),
                  const SizedBox(height: 8),
                  Text('Min Search Length: $_minSearchLength'),
                  Slider(
                    value: _minSearchLength.toDouble(),
                    min: 0,
                    max: 3,
                    divisions: 3,
                    label: _minSearchLength.toString(),
                    onChanged: (value) =>
                        setState(() => _minSearchLength = value.round()),
                  ),
                ],
              ),
            ),
          ),
          // Search list
          Expanded(
            child: SmartSearchList<String>(
              key: ValueKey(
                '$_caseSensitive-$_minSearchLength',
              ), // Force recreation on config change
              items: _fruits,
              searchableFields: (item) => [item],
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      item[0],
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(item),
                  subtitle: Text('Fruit #${index + 1}'),
                );
              },
              searchConfig: SearchConfiguration(
                hintText: 'Search fruits...',
                padding: const EdgeInsets.all(16.0),
                caseSensitive: _caseSensitive,
                minSearchLength: _minSearchLength,
              ),
              listConfig: const ListConfiguration(pullToRefresh: true),
              onRefresh: () async {
                final messenger = ScaffoldMessenger.of(context);
                await Future.delayed(const Duration(seconds: 1));
                messenger.showSnackBar(
                  const SnackBar(content: Text('Refreshed!')),
                );
              },
              onItemTap: (item, index) {
                // This demonstrates the onItemTap callback
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Callback: $item at index $index')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
