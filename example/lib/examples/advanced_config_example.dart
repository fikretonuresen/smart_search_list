import 'package:flutter/material.dart';
import 'package:smart_search_list/smart_search_list.dart';

/// Advanced Configuration with external controller
class AdvancedConfigExample extends StatefulWidget {
  const AdvancedConfigExample({super.key});

  @override
  State<AdvancedConfigExample> createState() => _AdvancedConfigExampleState();
}

class _AdvancedConfigExampleState extends State<AdvancedConfigExample> {
  late SmartSearchController<String> _controller;
  bool _caseSensitive = false;
  int _minSearchLength = 0;

  static final List<String> _items = [
    'Apple iPhone 15',
    'apple MacBook Pro',
    'APPLE iPad Air',
    'Samsung Galaxy S24',
    'samsung Tablet',
    'SAMSUNG Watch',
    'Google Pixel 8',
    'google Chrome',
    'GOOGLE Assistant',
  ];

  @override
  void initState() {
    super.initState();
    _controller = SmartSearchController<String>(
      searchableFields: (item) => [item],
      caseSensitive: _caseSensitive,
      minSearchLength: _minSearchLength,
    );
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
        title: const Text('Advanced Configuration'),
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
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Case Sensitive Search'),
                    subtitle: const Text('Try searching "apple" vs "APPLE"'),
                    value: _caseSensitive,
                    onChanged: (value) {
                      setState(() => _caseSensitive = value);
                      _controller.updateCaseSensitive(value);
                    },
                  ),
                  const SizedBox(height: 8),
                  Text('Minimum Search Length: $_minSearchLength'),
                  Slider(
                    value: _minSearchLength.toDouble(),
                    min: 0,
                    max: 5,
                    divisions: 5,
                    label: _minSearchLength.toString(),
                    onChanged: (value) {
                      setState(() => _minSearchLength = value.round());
                      _controller.updateMinSearchLength(value.round());
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ListenableBuilder(
                          listenable: _controller,
                          builder: (context, _) {
                            return Text(
                              'Active Filters: ${_controller.activeFilters.length}',
                            );
                          },
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _controller.setFilter(
                          'apple_only',
                          (item) => item.toLowerCase().contains('apple'),
                        ),
                        child: const Text('Filter Apple'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _controller.clearFilters(),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Smart search list with external controller
          Expanded(
            child: SmartSearchList<String>(
              controller: _controller, // Using external controller
              searchableFields: (item) => [item],
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: item.toLowerCase().contains('apple')
                        ? Colors.red
                        : item.toLowerCase().contains('samsung')
                        ? Colors.blue
                        : Colors.green,
                    child: Text(
                      item.split(' ')[0][0],
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(item),
                  subtitle: Text('Brand: ${item.split(' ')[0]}'),
                );
              },
              searchConfig: SearchConfiguration(
                hintText: 'Search products...',
                padding: const EdgeInsets.all(16.0),
                caseSensitive: _caseSensitive,
                minSearchLength: _minSearchLength,
              ),
              loadingStateBuilder: (context) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading products...'),
                    ],
                  ),
                );
              },
              errorStateBuilder: (context, error, retry) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text('Something went wrong!'),
                      const SizedBox(height: 8),
                      Text(error.toString()),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: retry,
                        child: const Text('Retry'),
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
                  const SnackBar(content: Text('Advanced config refreshed!')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
