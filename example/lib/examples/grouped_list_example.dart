import 'package:flutter/material.dart';
import 'package:smart_search_list/smart_search_list.dart';

import '../models.dart';

class GroupedListExample extends StatelessWidget {
  const GroupedListExample({super.key});

  static final _products = [
    // Electronics (4 items)
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
    // Sports (4 items)
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
      name: 'Water Bottle',
      price: 25.0,
      category: 'Sports',
      inStock: true,
      rating: 4.2,
    ),
    Product(
      id: '8',
      name: 'Tennis Racket',
      price: 189.0,
      category: 'Sports',
      inStock: false,
      rating: 4.4,
    ),
    // Books (4 items)
    Product(
      id: '9',
      name: 'The Great Gatsby',
      price: 12.0,
      category: 'Books',
      inStock: true,
      rating: 4.4,
    ),
    Product(
      id: '10',
      name: 'Italian Kitchen',
      price: 29.0,
      category: 'Books',
      inStock: false,
      rating: 4.1,
    ),
    Product(
      id: '11',
      name: 'Flutter in Action',
      price: 39.0,
      category: 'Books',
      inStock: true,
      rating: 4.9,
    ),
    Product(
      id: '12',
      name: 'Clean Code',
      price: 34.0,
      category: 'Books',
      inStock: true,
      rating: 4.7,
    ),
    // Clothing (4 items)
    Product(
      id: '13',
      name: 'T-Shirt',
      price: 19.0,
      category: 'Clothing',
      inStock: true,
      rating: 4.0,
    ),
    Product(
      id: '14',
      name: 'Jeans',
      price: 59.0,
      category: 'Clothing',
      inStock: true,
      rating: 4.3,
    ),
    Product(
      id: '15',
      name: 'Hoodie',
      price: 45.0,
      category: 'Clothing',
      inStock: true,
      rating: 4.5,
    ),
    Product(
      id: '16',
      name: 'Sneakers',
      price: 99.0,
      category: 'Clothing',
      inStock: false,
      rating: 4.2,
    ),
    // Home (4 items)
    Product(
      id: '17',
      name: 'Desk Lamp',
      price: 35.0,
      category: 'Home',
      inStock: true,
      rating: 4.1,
    ),
    Product(
      id: '18',
      name: 'Plant Pot',
      price: 15.0,
      category: 'Home',
      inStock: true,
      rating: 4.0,
    ),
    Product(
      id: '19',
      name: 'Wall Clock',
      price: 28.0,
      category: 'Home',
      inStock: true,
      rating: 4.3,
    ),
    Product(
      id: '20',
      name: 'Throw Pillow',
      price: 22.0,
      category: 'Home',
      inStock: false,
      rating: 3.9,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Grouped List')),
      body: SmartSearchList<Product>(
        items: _products,
        searchableFields: (p) => [p.name, p.category],
        itemBuilder: (context, product, index, {searchTerms = const []}) {
          return ListTile(
            title: Text(product.name),
            subtitle: Text(
              '${product.category} - \$${product.price.toStringAsFixed(2)}',
            ),
            trailing: product.inStock
                ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                : const Icon(Icons.cancel, color: Colors.red, size: 20),
          );
        },
        groupBy: (product) => product.category,
        groupComparator: (a, b) => (a as String).compareTo(b as String),
        searchConfig: const SearchConfiguration(
          hintText: 'Search products (try "MacBook" or "Xylophone")...',
        ),
      ),
    );
  }
}
