import 'package:flutter/material.dart';
import 'package:smart_search_list/smart_search_list.dart';

/// Empty States Demo - Shows both no-data and no-results states
class EmptyStatesExample extends StatefulWidget {
  const EmptyStatesExample({super.key});

  @override
  State<EmptyStatesExample> createState() => _EmptyStatesExampleState();
}

class _EmptyStatesExampleState extends State<EmptyStatesExample> {
  bool _showData = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Empty States Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          TextButton(
            onPressed: () => setState(() => _showData = !_showData),
            child: Text(_showData ? 'Remove Data' : 'Add Data'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Explanation card
          Card(
            margin: const EdgeInsets.all(16.0),
            child: ExpansionTile(
              title: Text(
                'Two Different Empty States',
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
                      const Text(
                        '"No data" state: When list is initially empty\n'
                        '"No search results" state: When search finds nothing\n'
                        'Toggle data with the button above to see both states',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Smart search list
          Expanded(
            child: SmartSearchList<String>(
              key: ValueKey(
                _showData,
              ), // Force recreation when data availability changes
              items: _showData ? ['Apple', 'Banana', 'Cherry'] : [],
              searchableFields: (item) => [item],
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return ListTile(
                  title: Text(item),
                  subtitle: Text('Item #${index + 1}'),
                );
              },
              searchConfig: const SearchConfiguration(
                hintText: 'Try searching for "xyz" with data present...',
                padding: EdgeInsets.all(16.0),
              ),
              emptyStateBuilder: (context) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Data Available',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This list is currently empty.\nTap "Add Data" to see some items.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                );
              },
              emptySearchStateBuilder: (context, searchQuery) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Results Found',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No items match "$searchQuery".\nTry a different search term.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                );
              },
              listConfig: const ListConfiguration(pullToRefresh: true),
              onRefresh: () async {
                final messenger = ScaffoldMessenger.of(context);
                await Future.delayed(const Duration(seconds: 1));
                messenger.showSnackBar(
                  const SnackBar(content: Text('Empty states refreshed!')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
