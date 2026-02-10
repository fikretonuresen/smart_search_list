import 'package:flutter/material.dart';
import 'package:smart_search_list/smart_search_list.dart';

import '../models.dart';

/// E-commerce products with filters and sorting
class EcommerceExample extends StatefulWidget {
  const EcommerceExample({super.key});

  @override
  State<EcommerceExample> createState() => _EcommerceExampleState();
}

class _EcommerceExampleState extends State<EcommerceExample> {
  late SmartSearchController<Product> _controller;

  static final List<Product> _products = [
    Product(
      id: '1',
      name: 'iPhone 15',
      price: 999.99,
      category: 'Electronics',
      inStock: true,
      rating: 4.5,
    ),
    Product(
      id: '2',
      name: 'MacBook Pro',
      price: 1999.99,
      category: 'Electronics',
      inStock: true,
      rating: 4.8,
    ),
    Product(
      id: '3',
      name: 'AirPods Pro',
      price: 249.99,
      category: 'Electronics',
      inStock: false,
      rating: 4.6,
    ),
    Product(
      id: '4',
      name: 'Nike Air Max',
      price: 129.99,
      category: 'Shoes',
      inStock: true,
      rating: 4.3,
    ),
    Product(
      id: '5',
      name: 'Adidas Ultraboost',
      price: 179.99,
      category: 'Shoes',
      inStock: true,
      rating: 4.4,
    ),
    Product(
      id: '6',
      name: 'Levi\'s Jeans',
      price: 79.99,
      category: 'Clothing',
      inStock: true,
      rating: 4.2,
    ),
    Product(
      id: '7',
      name: 'Patagonia Jacket',
      price: 199.99,
      category: 'Clothing',
      inStock: false,
      rating: 4.7,
    ),
    Product(
      id: '8',
      name: 'Sony WH-1000XM4',
      price: 349.99,
      category: 'Electronics',
      inStock: true,
      rating: 4.9,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = SmartSearchController<Product>(
      searchableFields: (product) => [product.name, product.category],
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
        title: const Text('E-commerce Products'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(icon: const Icon(Icons.sort), onPressed: _showSortDialog),
        ],
      ),
      body: SmartSearchList<Product>(
        controller: _controller,
        searchableFields: (product) => [product.name, product.category],
        itemBuilder: (context, product, index, {searchTerms = const []}) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: product.inStock ? Colors.green : Colors.red,
                child: Text(
                  product.name[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(product.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${product.category} • \$${product.price.toStringAsFixed(2)}',
                  ),
                  Row(
                    children: [
                      ...List.generate(
                        5,
                        (i) => Icon(
                          Icons.star,
                          size: 16,
                          color: i < product.rating.floor()
                              ? Colors.amber
                              : Colors.grey[300],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text('${product.rating}'),
                    ],
                  ),
                ],
              ),
              trailing: Chip(
                label: Text(
                  product.inStock ? 'In Stock' : 'Out of Stock',
                  style: TextStyle(
                    color: product.inStock
                        ? Colors.green[700]
                        : Colors.red[700],
                    fontSize: 12,
                  ),
                ),
                backgroundColor: product.inStock
                    ? Colors.green[50]
                    : Colors.red[50],
              ),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Selected: ${product.name}')),
                );
              },
            ),
          );
        },
        searchConfig: const SearchConfiguration(
          hintText: 'Search products...',
          padding: EdgeInsets.all(16.0),
        ),
        listConfig: const ListConfiguration(pullToRefresh: true),
        onRefresh: () async {
          final messenger = ScaffoldMessenger.of(context);
          await Future.delayed(const Duration(seconds: 1));
          messenger.showSnackBar(
            const SnackBar(content: Text('Products refreshed!')),
          );
        },
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Products'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('In Stock Only'),
              onTap: () {
                _controller.setFilter('in-stock', (product) => product.inStock);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Electronics'),
              onTap: () {
                _controller.setFilter(
                  'electronics',
                  (product) => product.category == 'Electronics',
                );
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('High Rating (4.5+)'),
              onTap: () {
                _controller.setFilter(
                  'high-rating',
                  (product) => product.rating >= 4.5,
                );
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Clear Filters'),
              onTap: () {
                _controller.clearFilters();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort Products'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Price: Low to High'),
              onTap: () {
                _controller.setSortBy((a, b) => a.price.compareTo(b.price));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Price: High to Low'),
              onTap: () {
                _controller.setSortBy((a, b) => b.price.compareTo(a.price));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Rating: High to Low'),
              onTap: () {
                _controller.setSortBy((a, b) => b.rating.compareTo(a.rating));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Name: A to Z'),
              onTap: () {
                _controller.setSortBy((a, b) => a.name.compareTo(b.name));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Clear Sort'),
              onTap: () {
                _controller.setSortBy(null);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
