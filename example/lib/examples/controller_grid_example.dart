import 'package:flutter/material.dart';
import 'package:smart_search_list/smart_search_list.dart';

import '../models.dart';

/// Demonstrates [SmartSearchGrid.controller] with an external controller
/// and a configuration panel for toggling search settings at runtime.
class ControllerGridExample extends StatefulWidget {
  const ControllerGridExample({super.key});

  @override
  State<ControllerGridExample> createState() => _ControllerGridExampleState();
}

class _ControllerGridExampleState extends State<ControllerGridExample> {
  late SmartSearchController<Product> _controller;
  bool _caseSensitive = false;
  int _minSearchLength = 0;

  static final List<Product> _products = [
    Product(
      id: '1',
      name: 'MacBook Pro',
      price: 2499.0,
      category: 'Electronics',
      inStock: true,
      rating: 4.8,
    ),
    Product(
      id: '2',
      name: 'iPhone 15',
      price: 999.0,
      category: 'Electronics',
      inStock: true,
      rating: 4.7,
    ),
    Product(
      id: '3',
      name: 'AirPods Pro',
      price: 249.0,
      category: 'Electronics',
      inStock: false,
      rating: 4.5,
    ),
    Product(
      id: '4',
      name: 'Running Shoes',
      price: 129.0,
      category: 'Sports',
      inStock: true,
      rating: 4.3,
    ),
    Product(
      id: '5',
      name: 'Yoga Mat',
      price: 49.0,
      category: 'Sports',
      inStock: true,
      rating: 4.6,
    ),
    Product(
      id: '6',
      name: 'Flutter in Action',
      price: 39.0,
      category: 'Books',
      inStock: true,
      rating: 4.9,
    ),
    Product(
      id: '7',
      name: 'Clean Code',
      price: 34.0,
      category: 'Books',
      inStock: true,
      rating: 4.7,
    ),
    Product(
      id: '8',
      name: 'Desk Lamp',
      price: 35.0,
      category: 'Home',
      inStock: true,
      rating: 4.1,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = SmartSearchController<Product>(
      searchableFields: (p) => [p.name, p.category],
      caseSensitive: _caseSensitive,
      minSearchLength: _minSearchLength,
    );
    _controller.setItems(_products);
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
        title: const Text('Controller Grid'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16.0),
            child: ExpansionTile(
              title: Text(
                'Search Configuration',
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
                        title: const Text('Case Sensitive'),
                        subtitle: const Text(
                          'Try searching "macbook" vs "MacBook"',
                        ),
                        value: _caseSensitive,
                        onChanged: (value) {
                          setState(() => _caseSensitive = value);
                          _controller.updateCaseSensitive(value);
                        },
                      ),
                      const SizedBox(height: 8),
                      Text('Min Search Length: $_minSearchLength'),
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
                                  'Filters: ${_controller.activeFilters.length}',
                                );
                              },
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _controller.setFilter(
                              'in_stock',
                              (p) => p.inStock,
                            ),
                            child: const Text('In Stock'),
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
              ],
            ),
          ),
          Expanded(
            child: SmartSearchGrid<Product>.controller(
              controller: _controller,
              itemBuilder: (context, product, index, {searchTerms = const []}) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: Theme.of(context).textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.category,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '\$${product.price.toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Icon(
                              product.inStock
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: product.inStock
                                  ? Colors.green
                                  : Colors.red,
                              size: 18,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              gridConfig: const GridConfiguration(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                padding: EdgeInsets.all(8),
              ),
              searchConfig: const SearchConfiguration(
                hintText: 'Search products...',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
