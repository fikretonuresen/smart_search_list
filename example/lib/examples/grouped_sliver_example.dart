import 'package:flutter/material.dart';
import 'package:smart_search_list/smart_search_list.dart';

import '../models.dart';

class GroupedSliverExample extends StatefulWidget {
  const GroupedSliverExample({super.key});

  @override
  State<GroupedSliverExample> createState() => _GroupedSliverExampleState();
}

class _GroupedSliverExampleState extends State<GroupedSliverExample> {
  final _controller = SmartSearchController<Product>(
    searchableFields: (p) => [p.name, p.category],
  );
  final _textController = TextEditingController();

  // Reuse the same products but more items per group for scroll testing
  static final _products = [
    // Electronics
    ...List.generate(
      8,
      (i) => Product(
        id: 'e$i',
        name: 'Electronic Item ${i + 1}',
        price: 100.0 + i * 50,
        category: 'Electronics',
        inStock: i % 3 != 0,
        rating: 4.0 + i * 0.1,
      ),
    ),
    // Sports
    ...List.generate(
      8,
      (i) => Product(
        id: 's$i',
        name: 'Sports Item ${i + 1}',
        price: 20.0 + i * 15,
        category: 'Sports',
        inStock: i % 2 == 0,
        rating: 3.8 + i * 0.15,
      ),
    ),
    // Books
    ...List.generate(
      8,
      (i) => Product(
        id: 'b$i',
        name: 'Book Title ${i + 1}',
        price: 10.0 + i * 5,
        category: 'Books',
        inStock: true,
        rating: 4.2 + i * 0.05,
      ),
    ),
    // Clothing
    ...List.generate(
      8,
      (i) => Product(
        id: 'c$i',
        name: 'Clothing Item ${i + 1}',
        price: 15.0 + i * 10,
        category: 'Clothing',
        inStock: i % 4 != 0,
        rating: 3.9 + i * 0.1,
      ),
    ),
    // Home
    ...List.generate(
      8,
      (i) => Product(
        id: 'h$i',
        name: 'Home Item ${i + 1}',
        price: 8.0 + i * 12,
        category: 'Home',
        inStock: i % 3 == 0,
        rating: 4.0 + i * 0.08,
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller.setItems(_products);
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sticky Grouped Headers')),
      body: Column(
        children: [
          // Manual search field since SliverSmartSearchList doesn't include one
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Search (try "Item 1" or "Xylophone")...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _textController.clear();
                    _controller.searchImmediate('');
                  },
                ),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12.0)),
                ),
              ),
              onChanged: (query) => _controller.search(query),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Group headers stick to the top while scrolling.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverSmartSearchList<Product>(
                  controller: _controller,
                  searchableFields: (p) => [p.name, p.category],
                  itemBuilder: (context, product, index, {searchTerms = const []}) {
                    return ListTile(
                      title: Text(product.name),
                      subtitle: Text(
                        '${product.category} - \$${product.price.toStringAsFixed(2)}',
                      ),
                      trailing: product.inStock
                          ? const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 20,
                            )
                          : const Icon(
                              Icons.cancel,
                              color: Colors.red,
                              size: 20,
                            ),
                    );
                  },
                  groupBy: (product) => product.category,
                  groupComparator: (a, b) =>
                      (a as String).compareTo(b as String),
                  groupHeaderExtent: 44.0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
