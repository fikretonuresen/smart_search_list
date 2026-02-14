import 'package:flutter/material.dart';
import 'package:smart_search_list/smart_search_list.dart';

import '../models.dart';

class GroupedGridExample extends StatelessWidget {
  const GroupedGridExample({super.key});

  static final _products = [
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
      name: 'Samsung Galaxy',
      price: 899.0,
      category: 'Electronics',
      inStock: true,
      rating: 4.6,
    ),
    Product(
      id: '5',
      name: 'Running Shoes',
      price: 129.0,
      category: 'Sports',
      inStock: true,
      rating: 4.3,
    ),
    Product(
      id: '6',
      name: 'Yoga Mat',
      price: 49.0,
      category: 'Sports',
      inStock: true,
      rating: 4.6,
    ),
    Product(
      id: '7',
      name: 'Tennis Racket',
      price: 189.0,
      category: 'Sports',
      inStock: false,
      rating: 4.4,
    ),
    Product(
      id: '8',
      name: 'Flutter in Action',
      price: 39.0,
      category: 'Books',
      inStock: true,
      rating: 4.9,
    ),
    Product(
      id: '9',
      name: 'Clean Code',
      price: 34.0,
      category: 'Books',
      inStock: true,
      rating: 4.7,
    ),
    Product(
      id: '10',
      name: 'Desk Lamp',
      price: 35.0,
      category: 'Home',
      inStock: true,
      rating: 4.1,
    ),
    Product(
      id: '11',
      name: 'Plant Pot',
      price: 15.0,
      category: 'Home',
      inStock: true,
      rating: 4.0,
    ),
    Product(
      id: '12',
      name: 'Wall Clock',
      price: 28.0,
      category: 'Home',
      inStock: true,
      rating: 4.3,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Grouped Grid')),
      body: SmartSearchGrid<Product>(
        items: _products,
        searchableFields: (p) => [p.name, p.category],
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
                  Row(
                    children: [
                      Text(
                        '\$${product.price.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const Spacer(),
                      Icon(
                        product.inStock ? Icons.check_circle : Icons.cancel,
                        color: product.inStock ? Colors.green : Colors.red,
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
        gridConfig: GridConfiguration(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.6,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          padding: const EdgeInsets.all(8),
        ),
        groupBy: (product) => product.category,
        groupComparator: (a, b) => (a as String).compareTo(b as String),
        searchConfig: const SearchConfiguration(hintText: 'Search products...'),
      ),
    );
  }
}
