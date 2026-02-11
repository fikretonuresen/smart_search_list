import 'package:flutter/material.dart';
import 'package:smart_search_list/smart_search_list.dart';

class FuzzySearchExample extends StatefulWidget {
  const FuzzySearchExample({super.key});

  @override
  State<FuzzySearchExample> createState() => _FuzzySearchExampleState();
}

class _FuzzySearchExampleState extends State<FuzzySearchExample> {
  bool _fuzzyEnabled = true;
  double _threshold = 0.3;

  static const _items = [
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
    'Grapefruit',
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
    'Raspberry',
    'Strawberry',
    'Tangerine',
    'Watermelon',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fuzzy Search'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Controls
          Card(
            margin: const EdgeInsets.all(16.0),
            child: ExpansionTile(
              title: Text(
                'Fuzzy Search Settings',
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
                      SwitchListTile(
                        title: const Text('Fuzzy Search'),
                        subtitle: Text(
                          _fuzzyEnabled
                              ? 'Try "apl" to find Apple'
                              : 'Exact substring matching only',
                        ),
                        value: _fuzzyEnabled,
                        onChanged: (v) => setState(() => _fuzzyEnabled = v),
                      ),
                      Text(
                        'Threshold: ${_threshold.toStringAsFixed(1)} (${_threshold < 0.3
                            ? "lenient"
                            : _threshold > 0.6
                            ? "strict"
                            : "balanced"})',
                      ),
                      Slider(
                        value: _threshold,
                        min: 0.1,
                        max: 0.9,
                        divisions: 8,
                        label: _threshold.toStringAsFixed(1),
                        onChanged: (v) => setState(() => _threshold = v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: SmartSearchList<String>(
              key: ValueKey('$_fuzzyEnabled-$_threshold'),
              items: _items,
              searchableFields: (item) => [item],
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      item[0],
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  title: SearchHighlightText(
                    text: item,
                    searchTerms: searchTerms,
                    fuzzySearchEnabled: _fuzzyEnabled,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  subtitle: Text('Fruit #${index + 1}'),
                );
              },
              searchConfig: SearchConfiguration(
                hintText: _fuzzyEnabled
                    ? 'Try "apl", "bnna", "strwbry"...'
                    : 'Exact search only...',
                fuzzySearchEnabled: _fuzzyEnabled,
                fuzzyThreshold: _threshold,
              ),
              listConfig: const ListConfiguration(pullToRefresh: true),
            ),
          ),
        ],
      ),
    );
  }
}
