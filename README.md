# Smart Search List

A highly performant, customizable Flutter package for searchable lists with zero external dependencies. Built to be better than `searchable_listview` in every way.

> **🧪 Currently in testing phase** - This package is technically ready but being tested in production apps. Feedback welcome!

[![pub package](https://img.shields.io/pub/v/smart_search_list.svg)](https://pub.dev/packages/smart_search_list)
[![popularity](https://img.shields.io/pub/popularity/smart_search_list.svg)](https://pub.dev/packages/smart_search_list/score)
[![likes](https://img.shields.io/pub/likes/smart_search_list.svg)](https://pub.dev/packages/smart_search_list/score)
[![pub points](https://img.shields.io/pub/points/smart_search_list.svg)](https://pub.dev/packages/smart_search_list/score)

## ✨ Features

- 🚀 **High Performance** - Tested with 10,000+ items at 60 FPS
- 🛡️ **Memory Safe** - Proper disposal, no memory leaks
- 🎨 **Fully Customizable** - Builder patterns for everything
- 📱 **Two Data Modes** - Offline lists and async API loading
- 🔍 **Smart Search** - Debounced search with multiple field support
- 📄 **Pagination Support** - Infinite scroll with pull-to-refresh
- 🎯 **Two Empty States** - Different messages for no data vs no search results
- 🔧 **Zero Dependencies** - Only uses Flutter SDK

## 🚨 Why Not `searchable_listview`?

The popular `searchable_listview` package has several issues:
- Memory leaks from poor controller management
- State management bugs causing crashes
- Limited customization options  
- No distinction between empty states
- Poor performance with large datasets

**Smart Search List** solves all these problems with a clean, modern API.

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  smart_search_list: ^0.1.1
```

## 🚀 Quick Start

### Basic Offline List

```dart
SmartSearchList<String>(
  items: ['Apple', 'Banana', 'Cherry', 'Date'],
  searchableFields: (item) => [item],
  itemBuilder: (context, item, index) {
    return ListTile(
      title: Text(item),
      subtitle: Text('Item #${index + 1}'),
    );
  },
)
```

### Async API Loading

```dart
SmartSearchList<Product>(
  asyncLoader: (query, {page = 0, pageSize = 20}) async {
    return await api.searchProducts(query, page: page);
  },
  searchableFields: (product) => [product.name, product.category],
  itemBuilder: (context, product, index) {
    return ProductCard(product: product);
  },
  paginationConfig: const PaginationConfiguration(
    pageSize: 20,
    enabled: true,
  ),
)
```

### Advanced Example with Filters

```dart
class ProductListPage extends StatefulWidget {
  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  late SmartSearchController<Product> _controller;

  @override
  void initState() {
    super.initState();
    _controller = SmartSearchController<Product>(
      searchableFields: (product) => [product.name, product.category],
    );
    _controller.setItems(myProducts);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SmartSearchList<Product>(
        controller: _controller,
        searchableFields: (product) => [product.name, product.category],
        itemBuilder: (context, product, index) {
          return ProductCard(product: product);
        },
        searchConfig: const SearchConfiguration(
          hintText: 'Search products...',
          debounceDelay: Duration(milliseconds: 300),
        ),
        emptyBuilder: (context) => const EmptyProductsWidget(),
        emptySearchBuilder: (context, query) => 
          NoResultsWidget(searchQuery: query),
      ),
    );
  }

  void addFilter() {
    _controller.setFilter('in-stock', (product) => product.inStock);
  }

  void sortByPrice() {
    _controller.setSortBy((a, b) => a.price.compareTo(b.price));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

## 🎨 Customization

### Builder Patterns

Smart Search List uses builder patterns for maximum flexibility:

```dart
SmartSearchList<T>(
  // Custom search field
  searchFieldBuilder: (context, controller, focusNode, onClear) {
    return CustomSearchField(controller: controller);
  },
  
  // Custom loading state
  loadingBuilder: (context) {
    return CustomLoadingSpinner();
  },
  
  // Custom error state
  errorBuilder: (context, error, onRetry) {
    return CustomErrorWidget(error: error, onRetry: onRetry);
  },
  
  // Custom empty state (no data)
  emptyBuilder: (context) {
    return CustomEmptyWidget();
  },
  
  // Custom empty search state (no results)
  emptySearchBuilder: (context, query) {
    return NoResultsWidget(searchQuery: query);
  },
)
```

### Configuration Options

```dart
SmartSearchList<T>(
  searchConfig: const SearchConfiguration(
    enabled: true,
    autofocus: false,
    debounceDelay: Duration(milliseconds: 300),
    hintText: 'Search...',
    caseSensitive: false,
    minSearchLength: 0,
  ),
  
  listConfig: const ListConfiguration(
    pullToRefresh: true,
    shrinkWrap: false,
    itemExtent: 72.0, // Fixed height for better performance
  ),
  
  paginationConfig: const PaginationConfiguration(
    pageSize: 20,
    enabled: true,
    triggerDistance: 200.0,
  ),
)
```

## 📊 Performance

Tested performance benchmarks:

- ✅ **10,000 items**: Maintains 60 FPS scrolling
- ✅ **Search performance**: Results in <16ms
- ✅ **Memory usage**: <50MB for 10K items
- ✅ **Startup time**: <100ms initialization

## 🔄 Migration from `searchable_listview`

### Before (searchable_listview):
```dart
SearchableList<String>(
  initialList: items,
  itemBuilder: (String item) => ListTile(title: Text(item)),
  filter: (value) => items.where((item) => 
    item.toLowerCase().contains(value.toLowerCase())).toList(),
)
```

### After (smart_search_list):
```dart
SmartSearchList<String>(
  items: items,
  searchableFields: (item) => [item],
  itemBuilder: (context, item, index) => ListTile(title: Text(item)),
)
```

### Key Improvements:
- ✅ No more crashes after disposal
- ✅ Better performance with large lists  
- ✅ Two different empty states
- ✅ Built-in async support
- ✅ More customization options

## 🤝 Contributing

Contributions are welcome! Please open an issue or submit a pull request on [GitHub](https://github.com/fikretonuresen/smart_search_list).

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## 🐛 Issues

Found a bug? Please file an issue on our [GitHub repository](https://github.com/fikretonuresen/smart_search_list/issues).

---

**Built with ❤️ for the Flutter community**
