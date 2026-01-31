import 'package:flutter/material.dart';
import 'package:smart_search_list/smart_search_list.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Search List Examples',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ExampleHomePage(),
    );
  }
}

class ExampleHomePage extends StatelessWidget {
  const ExampleHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Smart Search List Examples'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildExampleCard(
            context,
            'Basic Offline List',
            'Simple searchable list with 1000 items',
            Icons.list,
            () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BasicOfflineExample(),
                )),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            'E-commerce Products',
            'Advanced features: search, filter, sort',
            Icons.shopping_cart,
            () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EcommerceExample(),
                )),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            'Async API Loading',
            'Real async data with pagination',
            Icons.cloud_download,
            () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AsyncApiExample(),
                )),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            'Performance Test',
            'Test with 10,000 items',
            Icons.speed,
            () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PerformanceTestExample(),
                )),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            'Sliver Integration',
            'CustomScrollView with SliverSmartSearchList',
            Icons.view_list,
            () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SliverExample(),
                )),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            'Empty States Demo',
            'Two different empty states comparison',
            Icons.inbox,
            () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EmptyStatesExample(),
                )),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            'Advanced Configuration',
            'External controller and custom builders',
            Icons.settings,
            () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdvancedConfigExample(),
                )),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            'Multi-Select',
            'Select items with checkboxes, filter + selection',
            Icons.checklist,
            () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MultiSelectExample(),
                )),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            'Grouped List',
            'Items grouped by category with headers',
            Icons.category,
            () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GroupedListExample(),
                )),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            'Grouped Sliver (Sticky Headers)',
            'SliverSmartSearchList with sticky group headers',
            Icons.view_day,
            () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GroupedSliverExample(),
                )),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            'Search Trigger Modes',
            'Toggle between onEdit and onSubmit modes',
            Icons.keyboard,
            () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SearchTriggerModeExample(),
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}

/// Example 1: Basic offline list with configuration options
class BasicOfflineExample extends StatefulWidget {
  const BasicOfflineExample({super.key});

  @override
  State<BasicOfflineExample> createState() => _BasicOfflineExampleState();
}

class _BasicOfflineExampleState extends State<BasicOfflineExample> {
  bool _caseSensitive = false;
  int _minSearchLength = 0;

  static final List<String> _fruits = [
    'Apple',
    'Apricot',
    'Banana',
    'Blackberry',
    'Blueberry',
    'Cherry',
    'Coconut',
    'Cranberry',
    'Date',
    'Elderberry',
    'Fig',
    'Grape',
    'Grapefruit',
    'Guava',
    'Kiwi',
    'Lemon',
    'Lime',
    'Mango',
    'Orange',
    'Papaya',
    'Peach',
    'Pear',
    'Pineapple',
    'Plum',
    'Pomegranate',
    'Raspberry',
    'Strawberry',
    'Watermelon',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Basic Offline List'),
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
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Case Sensitive'),
                    subtitle: Text(_caseSensitive
                        ? 'Try "Apple" vs "apple"'
                        : 'Search ignores case'),
                    value: _caseSensitive,
                    onChanged: (value) =>
                        setState(() => _caseSensitive = value),
                  ),
                  const SizedBox(height: 8),
                  Text('Min Search Length: $_minSearchLength'),
                  Slider(
                    value: _minSearchLength.toDouble(),
                    min: 0,
                    max: 3,
                    divisions: 3,
                    label: _minSearchLength.toString(),
                    onChanged: (value) =>
                        setState(() => _minSearchLength = value.round()),
                  ),
                ],
              ),
            ),
          ),
          // Search list
          Expanded(
            child: SmartSearchList<String>(
              key: ValueKey(
                  '$_caseSensitive-$_minSearchLength'), // Force recreation on config change
              items: _fruits,
              searchableFields: (item) => [item],
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      item[0],
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(item),
                  subtitle: Text('Fruit #${index + 1}'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Selected: $item')),
                    );
                  },
                );
              },
              searchConfig: SearchConfiguration(
                hintText: 'Search fruits...',
                padding: const EdgeInsets.all(16.0),
                caseSensitive: _caseSensitive,
                minSearchLength: _minSearchLength,
              ),
              listConfig: const ListConfiguration(
                pullToRefresh: true,
              ),
              onRefresh: () async {
                final messenger = ScaffoldMessenger.of(context);
                await Future.delayed(const Duration(seconds: 1));
                messenger.showSnackBar(
                  const SnackBar(content: Text('Refreshed!')),
                );
              },
              onItemTap: (item, index) {
                // This demonstrates the onItemTap callback
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Callback: $item at index $index')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Example 2: E-commerce products with filters and sorting
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
        rating: 4.5),
    Product(
        id: '2',
        name: 'MacBook Pro',
        price: 1999.99,
        category: 'Electronics',
        inStock: true,
        rating: 4.8),
    Product(
        id: '3',
        name: 'AirPods Pro',
        price: 249.99,
        category: 'Electronics',
        inStock: false,
        rating: 4.6),
    Product(
        id: '4',
        name: 'Nike Air Max',
        price: 129.99,
        category: 'Shoes',
        inStock: true,
        rating: 4.3),
    Product(
        id: '5',
        name: 'Adidas Ultraboost',
        price: 179.99,
        category: 'Shoes',
        inStock: true,
        rating: 4.4),
    Product(
        id: '6',
        name: 'Levi\'s Jeans',
        price: 79.99,
        category: 'Clothing',
        inStock: true,
        rating: 4.2),
    Product(
        id: '7',
        name: 'Patagonia Jacket',
        price: 199.99,
        category: 'Clothing',
        inStock: false,
        rating: 4.7),
    Product(
        id: '8',
        name: 'Sony WH-1000XM4',
        price: 349.99,
        category: 'Electronics',
        inStock: true,
        rating: 4.9),
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
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortDialog,
          ),
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
                      '${product.category} • \$${product.price.toStringAsFixed(2)}'),
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
                              )),
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
                    color:
                        product.inStock ? Colors.green[700] : Colors.red[700],
                    fontSize: 12,
                  ),
                ),
                backgroundColor:
                    product.inStock ? Colors.green[50] : Colors.red[50],
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
        listConfig: const ListConfiguration(
          pullToRefresh: true,
        ),
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
                _controller.setFilter('electronics',
                    (product) => product.category == 'Electronics');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('High Rating (4.5+)'),
              onTap: () {
                _controller.setFilter(
                    'high-rating', (product) => product.rating >= 4.5);
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

/// Example 3: Async API loading with pagination and error handling
class AsyncApiExample extends StatefulWidget {
  const AsyncApiExample({super.key});

  @override
  State<AsyncApiExample> createState() => _AsyncApiExampleState();
}

class _AsyncApiExampleState extends State<AsyncApiExample> {
  bool _simulateErrors = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Async API Loading'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          TextButton(
            onPressed: () => setState(() => _simulateErrors = !_simulateErrors),
            child: Text(_simulateErrors ? 'Fix Errors' : 'Simulate Errors'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Info card
          Card(
            margin: const EdgeInsets.all(16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Async API Demo',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _simulateErrors
                        ? '🔥 Error simulation enabled - API calls will fail randomly'
                        : '✅ Normal mode - API calls work properly',
                  ),
                  const SizedBox(height: 4),
                  const Text(
                      '• Search to trigger API calls\n• Pull down to refresh'),
                ],
              ),
            ),
          ),
          Expanded(
            child: SmartSearchList<ApiUser>(
              asyncLoader: (query, {int page = 0, int pageSize = 20}) =>
                  _simulateApiCall(query, page: page, pageSize: pageSize),
              searchableFields: (user) => [user.name, user.email, user.company],
              itemBuilder: (context, user, index, {searchTerms = const []}) {
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        user.name.split(' ').map((n) => n[0]).join(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(user.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.email),
                        Text('${user.company} • ${user.position}'),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
              progressIndicatorBuilder: (context, isLoading) {
                if (!isLoading) return const SizedBox.shrink();
                return const LinearProgressIndicator(minHeight: 2);
              },
              searchConfig: const SearchConfiguration(
                hintText: 'Search users...',
                padding: EdgeInsets.all(16.0),
                debounceDelay:
                    Duration(milliseconds: 500), // Slower for API calls
              ),
              paginationConfig: const PaginationConfiguration(
                pageSize: 10,
                enabled: true,
              ),
              listConfig: const ListConfiguration(
                pullToRefresh: true,
              ),
              onRefresh: () async {
                // Add some visual feedback
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Refreshing data...'),
                    duration: Duration(seconds: 1),
                  ),
                );
                // Note: refresh is handled automatically by the controller
              },
              errorStateBuilder: (context, error, retry) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text('API Error!', style: TextStyle(fontSize: 18)),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: retry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<List<ApiUser>> _simulateApiCall(
    String query, {
    int page = 0,
    int pageSize = 10,
  }) async {
    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 500 + (page * 200)));

    // Simulate errors if enabled
    if (_simulateErrors && DateTime.now().millisecond % 3 == 0) {
      throw Exception('Simulated network error - API unavailable');
    }

    // Simulate some users
    final allUsers = _generateMockUsers(100);

    // Filter by query
    List<ApiUser> filtered = allUsers;
    if (query.isNotEmpty) {
      filtered = allUsers.where((user) {
        return user.name.toLowerCase().contains(query.toLowerCase()) ||
            user.email.toLowerCase().contains(query.toLowerCase()) ||
            user.company.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }

    // Simulate pagination
    final start = page * pageSize;
    final end = (start + pageSize).clamp(0, filtered.length);

    if (start >= filtered.length) return [];

    return filtered.sublist(start, end);
  }

  static List<ApiUser> _generateMockUsers(int count) {
    const names = [
      'John Doe',
      'Jane Smith',
      'Bob Johnson',
      'Alice Brown',
      'Charlie Davis'
    ];
    const companies = ['Google', 'Apple', 'Microsoft', 'Amazon', 'Meta'];
    const positions = [
      'Engineer',
      'Designer',
      'Manager',
      'Analyst',
      'Developer'
    ];

    return List.generate(count, (i) {
      final name = names[i % names.length];
      final company = companies[i % companies.length];
      final position = positions[i % positions.length];

      return ApiUser(
        id: 'user_$i',
        name: '$name ${i + 1}',
        email:
            '${name.toLowerCase().replaceAll(' ', '.')}${i + 1}@${company.toLowerCase()}.com',
        company: company,
        position: position,
      );
    });
  }
}

/// Example 4: Performance test with 10,000 items
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
            leading: CircleAvatar(
              child: Text('${index + 1}'),
            ),
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
      'Theta'
    ];
    const suffixes = [
      'One',
      'Two',
      'Three',
      'Four',
      'Five',
      'Six',
      'Seven',
      'Eight'
    ];

    return List.generate(count, (i) {
      final prefix = prefixes[i % prefixes.length];
      final suffix = suffixes[(i ~/ prefixes.length) % suffixes.length];
      return '$prefix $suffix $i';
    });
  }
}

// Data models
class Product {
  final String id;
  final String name;
  final double price;
  final String category;
  final bool inStock;
  final double rating;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.inStock,
    required this.rating,
  });
}

class ApiUser {
  final String id;
  final String name;
  final String email;
  final String company;
  final String position;

  ApiUser({
    required this.id,
    required this.name,
    required this.email,
    required this.company,
    required this.position,
  });
}

/// Example 5: SliverSmartSearchList integrated with CustomScrollView
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
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SliverSmartSearchList Demo',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This demonstrates SliverSmartSearchList integrated with '
                        'CustomScrollView, working alongside SliverAppBar and other slivers.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverSmartSearchList<String>(
            items: _categories,
            searchableFields: (item) => [item],
            itemBuilder: (context, item, index, {searchTerms = const []}) {
              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Selected: $item')),
                    );
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

/// Example 6: Empty States Demo - Shows both no-data and no-results states
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
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Two Different Empty States',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• "No data" state: When list is initially empty\n'
                    '• "No search results" state: When search finds nothing\n'
                    '• Toggle data with the button above to see both states',
                  ),
                ],
              ),
            ),
          ),
          // Smart search list
          Expanded(
            child: SmartSearchList<String>(
              key: ValueKey(
                  _showData), // Force recreation when data availability changes
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
              listConfig: const ListConfiguration(
                pullToRefresh: true,
              ),
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

/// Example 7: Advanced Configuration with external controller
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
              listConfig: const ListConfiguration(
                pullToRefresh: true,
              ),
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

// =============================================================================
// Example 8: Multi-Select
// QA Tests:
//   1. Tap Test: Tap item -> checkbox animates immediately
//   2. Count Test: Select 3, scroll away, scroll back -> still checked
//   3. Filter Edge Case: Select "Apple", search "Banana", select "Banana",
//      clear search -> both Apple AND Banana must be selected
//   4. Select All: Tap "Select All", rapid scroll -> every item checked
// =============================================================================

class MultiSelectExample extends StatefulWidget {
  const MultiSelectExample({super.key});

  @override
  State<MultiSelectExample> createState() => _MultiSelectExampleState();
}

class _MultiSelectExampleState extends State<MultiSelectExample> {
  final _controller = SmartSearchController<String>(
    searchableFields: (item) => [item],
  );

  // 50 items so we have enough to scroll off-screen
  final _items = List.generate(50, (i) {
    const names = [
      'Apple',
      'Banana',
      'Cherry',
      'Date',
      'Elderberry',
      'Fig',
      'Grape',
      'Honeydew',
      'Kiwi',
      'Lemon',
      'Mango',
      'Nectarine',
      'Orange',
      'Papaya',
      'Quince',
      'Raspberry',
      'Strawberry',
      'Tangerine',
      'Watermelon',
      'Zucchini',
      'Artichoke',
      'Broccoli',
      'Carrot',
      'Daikon',
      'Endive',
    ];
    return '${names[i % names.length]} ${i + 1}';
  });

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multi-Select'),
        actions: [
          IconButton(
            icon: const Icon(Icons.select_all),
            tooltip: 'Select All',
            onPressed: () => _controller.selectAll(),
          ),
          IconButton(
            icon: const Icon(Icons.deselect),
            tooltip: 'Deselect All',
            onPressed: () => _controller.deselectAll(),
          ),
        ],
      ),
      body: SmartSearchList<String>(
        items: _items,
        controller: _controller,
        searchableFields: (item) => [item],
        itemBuilder: (context, item, index, {searchTerms = const []}) {
          return ListTile(
            title: Text(item),
            subtitle: Text('Index: $index'),
          );
        },
        selectionConfig: const SelectionConfiguration(
          enabled: true,
          showCheckbox: true,
          position: CheckboxPosition.leading,
        ),
        onSelectionChanged: (selected) {
          // Trigger rebuild for the banner
          setState(() {});
        },
        belowSearchWidget: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final selected = _controller.selectedItems;
            if (selected.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Text(
                  'QA: Select items, search to filter, verify selection persists.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              );
            }
            return Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                '${selected.length} selected: ${selected.take(5).join(", ")}${selected.length > 5 ? "..." : ""}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontSize: 13,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// =============================================================================
// Example 9: Grouped List (non-sliver, no sticky headers)
// QA Tests:
//   1. Logic Check: Items under correct group headers
//   2. Sorting Check: Groups in alphabetical order (comparator)
//   3. Empty Group Check: Search "Xylophone" -> no stray headers, just empty state
//   4. Filter removes groups: Search "MacBook" -> only Electronics header shown
// =============================================================================

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
        rating: 4.8),
    Product(
        id: '2',
        name: 'iPhone 15',
        price: 999.0,
        category: 'Electronics',
        inStock: true,
        rating: 4.7),
    Product(
        id: '3',
        name: 'AirPods Pro',
        price: 249.0,
        category: 'Electronics',
        inStock: false,
        rating: 4.5),
    Product(
        id: '4',
        name: 'Samsung Galaxy',
        price: 899.0,
        category: 'Electronics',
        inStock: true,
        rating: 4.6),
    // Sports (4 items)
    Product(
        id: '5',
        name: 'Running Shoes',
        price: 129.0,
        category: 'Sports',
        inStock: true,
        rating: 4.3),
    Product(
        id: '6',
        name: 'Yoga Mat',
        price: 49.0,
        category: 'Sports',
        inStock: true,
        rating: 4.6),
    Product(
        id: '7',
        name: 'Water Bottle',
        price: 25.0,
        category: 'Sports',
        inStock: true,
        rating: 4.2),
    Product(
        id: '8',
        name: 'Tennis Racket',
        price: 189.0,
        category: 'Sports',
        inStock: false,
        rating: 4.4),
    // Books (4 items)
    Product(
        id: '9',
        name: 'The Great Gatsby',
        price: 12.0,
        category: 'Books',
        inStock: true,
        rating: 4.4),
    Product(
        id: '10',
        name: 'Italian Kitchen',
        price: 29.0,
        category: 'Books',
        inStock: false,
        rating: 4.1),
    Product(
        id: '11',
        name: 'Flutter in Action',
        price: 39.0,
        category: 'Books',
        inStock: true,
        rating: 4.9),
    Product(
        id: '12',
        name: 'Clean Code',
        price: 34.0,
        category: 'Books',
        inStock: true,
        rating: 4.7),
    // Clothing (4 items)
    Product(
        id: '13',
        name: 'T-Shirt',
        price: 19.0,
        category: 'Clothing',
        inStock: true,
        rating: 4.0),
    Product(
        id: '14',
        name: 'Jeans',
        price: 59.0,
        category: 'Clothing',
        inStock: true,
        rating: 4.3),
    Product(
        id: '15',
        name: 'Hoodie',
        price: 45.0,
        category: 'Clothing',
        inStock: true,
        rating: 4.5),
    Product(
        id: '16',
        name: 'Sneakers',
        price: 99.0,
        category: 'Clothing',
        inStock: false,
        rating: 4.2),
    // Home (4 items)
    Product(
        id: '17',
        name: 'Desk Lamp',
        price: 35.0,
        category: 'Home',
        inStock: true,
        rating: 4.1),
    Product(
        id: '18',
        name: 'Plant Pot',
        price: 15.0,
        category: 'Home',
        inStock: true,
        rating: 4.0),
    Product(
        id: '19',
        name: 'Wall Clock',
        price: 28.0,
        category: 'Home',
        inStock: true,
        rating: 4.3),
    Product(
        id: '20',
        name: 'Throw Pillow',
        price: 22.0,
        category: 'Home',
        inStock: false,
        rating: 3.9),
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
                '${product.category} - \$${product.price.toStringAsFixed(2)}'),
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

// =============================================================================
// Example 10: Grouped Sliver with Sticky Headers
// QA Tests:
//   1. Sticky Physics: Scroll slowly. First group header sticks to top until
//      next group header pushes it out. If it scrolls off, sticky is broken.
//   2. Search: Type "Running" -> only Sports group with "Running Shoes" shown.
//   3. Empty: Search "Xylophone" -> "No results" empty state, no stray headers.
// =============================================================================

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
            )),
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
            )),
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
            )),
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
            )),
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
            )),
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
              'QA: Scroll slowly. Headers should STICK to top until pushed by next header.',
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
                  itemBuilder: (context, product, index,
                      {searchTerms = const []}) {
                    return ListTile(
                      title: Text(product.name),
                      subtitle: Text(
                          '${product.category} - \$${product.price.toStringAsFixed(2)}'),
                      trailing: product.inStock
                          ? const Icon(Icons.check_circle,
                              color: Colors.green, size: 20)
                          : const Icon(Icons.cancel,
                              color: Colors.red, size: 20),
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

// =============================================================================
// Example 11: Search Trigger Modes
// QA Tests:
//   1. onEdit mode: Type "A", wait 300ms -> list filters automatically
//   2. onSubmit mode: Type "App" -> nothing happens. Press keyboard
//      Search/Done -> list filters. Tap search icon button -> list filters.
// =============================================================================

class SearchTriggerModeExample extends StatefulWidget {
  const SearchTriggerModeExample({super.key});

  @override
  State<SearchTriggerModeExample> createState() =>
      _SearchTriggerModeExampleState();
}

class _SearchTriggerModeExampleState extends State<SearchTriggerModeExample> {
  SearchTriggerMode _mode = SearchTriggerMode.onEdit;

  final _fruits = [
    'Apple',
    'Apricot',
    'Avocado',
    'Banana',
    'Blackberry',
    'Blueberry',
    'Cherry',
    'Coconut',
    'Cranberry',
    'Date',
    'Elderberry',
    'Fig',
    'Grape',
    'Guava',
    'Honeydew',
    'Kiwi',
    'Lemon',
    'Lime',
    'Lychee',
    'Mango',
    'Nectarine',
    'Orange',
    'Papaya',
    'Peach',
    'Pear',
    'Pineapple',
    'Plum',
    'Pomegranate',
    'Quince',
    'Raspberry',
    'Strawberry',
    'Tangerine',
    'Watermelon',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Trigger Modes'),
      ),
      body: Column(
        children: [
          // Mode toggle
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SegmentedButton<SearchTriggerMode>(
              segments: const [
                ButtonSegment(
                  value: SearchTriggerMode.onEdit,
                  label: Text('onEdit (live)'),
                  icon: Icon(Icons.edit),
                ),
                ButtonSegment(
                  value: SearchTriggerMode.onSubmit,
                  label: Text('onSubmit'),
                  icon: Icon(Icons.keyboard_return),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (modes) {
                setState(() => _mode = modes.first);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              _mode == SearchTriggerMode.onEdit
                  ? 'QA: Type "App" — list should filter after ~300ms automatically.'
                  : 'QA: Type "App" — NOTHING should happen. Press Enter or tap search icon to trigger.',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            // Key forces widget rebuild when mode changes
            child: SmartSearchList<String>(
              key: ValueKey(_mode),
              items: _fruits,
              searchableFields: (item) => [item],
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return ListTile(
                  title: Text(item),
                );
              },
              searchConfig: SearchConfiguration(
                triggerMode: _mode,
                hintText: _mode == SearchTriggerMode.onEdit
                    ? 'Type to search (live)...'
                    : 'Type then press Enter to search...',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
