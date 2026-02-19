import 'package:flutter/material.dart';
import 'package:smart_search_list/smart_search_list.dart';

import '../models.dart';

/// Async grid loading with pagination — demonstrates SmartSearchGrid.async().
class AsyncGridExample extends StatelessWidget {
  const AsyncGridExample({super.key});

  static final _allProducts = List.generate(
    60,
    (i) => Product(
      id: '${i + 1}',
      name: 'Product ${i + 1}',
      price: 10.0 + (i * 7.3 % 200),
      category: ['Electronics', 'Sports', 'Books', 'Home'][i % 4],
      inStock: i % 5 != 0,
      rating: 3.5 + (i % 10) * 0.15,
    ),
  );

  static Future<List<Product>> _fetchProducts(
    String query, {
    int page = 0,
    int pageSize = 20,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final filtered = query.isEmpty
        ? _allProducts
        : _allProducts
              .where(
                (p) =>
                    p.name.toLowerCase().contains(query.toLowerCase()) ||
                    p.category.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();

    final start = page * pageSize;
    if (start >= filtered.length) return [];
    final end = (start + pageSize).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Async Grid')),
      body: SmartSearchGrid<Product>.async(
        asyncLoader: _fetchProducts,
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
                        product.inStock ? Icons.check_circle : Icons.cancel,
                        color: product.inStock ? Colors.green : Colors.red,
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
        paginationConfig: const PaginationConfiguration(
          pageSize: 12,
          enabled: true,
        ),
        searchConfig: const SearchConfiguration(hintText: 'Search products...'),
      ),
    );
  }
}
