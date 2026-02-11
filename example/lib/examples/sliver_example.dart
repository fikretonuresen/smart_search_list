import 'package:flutter/material.dart';
import 'package:smart_search_list/smart_search_list.dart';

/// SliverSmartSearchList integrated with CustomScrollView
class SliverExample extends StatelessWidget {
  const SliverExample({super.key});

  static final List<String> _categories = [
    'Technology',
    'Science',
    'Business',
    'Entertainment',
    'Sports',
    'Health',
    'Travel',
    'Food',
    'Fashion',
    'Education',
    'Politics',
    'Environment',
    'Art',
    'Music',
    'Books',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Sliver Integration Demo'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primaryContainer,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: ExpansionTile(
                  title: Text(
                    'SliverSmartSearchList Demo',
                    style: Theme.of(context).textTheme.titleLarge,
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
                            'This demonstrates SliverSmartSearchList integrated with '
                            'CustomScrollView, working alongside SliverAppBar and other slivers.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverSmartSearchList<String>(
            items: _categories,
            searchableFields: (item) => [item],
            itemBuilder: (context, item, index, {searchTerms = const []}) {
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 4.0,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Colors.primaries[index % Colors.primaries.length],
                    child: Text(
                      item[0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(item),
                  subtitle: Text('Category #${index + 1}'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Selected: $item')));
                  },
                ),
              );
            },
            searchConfig: const SearchConfiguration(
              hintText: 'Search categories...',
              padding: EdgeInsets.all(16.0),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'This footer shows that SliverSmartSearchList works perfectly '
                    'within CustomScrollView alongside other slivers.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
