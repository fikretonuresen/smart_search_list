import 'package:flutter/material.dart';
import 'package:smart_search_list/smart_search_list.dart';

/// Performance test with 10,000 items
class PerformanceTestExample extends StatelessWidget {
  const PerformanceTestExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Test - 10K Items'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SmartSearchList<String>(
        items: _generateLargeDataset(10000),
        searchableFields: (item) => [item],
        itemBuilder: (context, item, index, {searchTerms = const []}) {
          return ListTile(
            leading: CircleAvatar(child: Text('${index + 1}')),
            title: Text(item),
            subtitle: Text('Item #${index + 1} of 10,000'),
          );
        },
        searchConfig: const SearchConfiguration(
          hintText: 'Search 10,000 items...',
          padding: EdgeInsets.all(16.0),
        ),
        listConfig: const ListConfiguration(
          itemExtent: 72.0, // Fixed height for better performance
          pullToRefresh: true,
        ),
        onRefresh: () async {
          final messenger = ScaffoldMessenger.of(context);
          await Future.delayed(const Duration(seconds: 1));
          messenger.showSnackBar(
            const SnackBar(content: Text('Performance test refreshed!')),
          );
        },
      ),
    );
  }

  static List<String> _generateLargeDataset(int count) {
    const prefixes = [
      'Alpha',
      'Beta',
      'Gamma',
      'Delta',
      'Epsilon',
      'Zeta',
      'Eta',
      'Theta',
    ];
    const suffixes = [
      'One',
      'Two',
      'Three',
      'Four',
      'Five',
      'Six',
      'Seven',
      'Eight',
    ];

    return List.generate(count, (i) {
      final prefix = prefixes[i % prefixes.length];
      final suffix = suffixes[(i ~/ prefixes.length) % suffixes.length];
      return '$prefix $suffix $i';
    });
  }
}
