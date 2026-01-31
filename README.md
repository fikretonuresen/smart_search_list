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
- 🔎 **Search Term Highlighting** - Matched terms passed to itemBuilder for custom highlighting
- 🧩 **Below Search Widget** - Slot for filters, chips, or controls below the search field
- ⚙️ **Dynamic Configuration** - Update search settings at runtime via controller
- ☑️ **Multi-Select** - Built-in selection with checkboxes, select all, and predicate-based selection
- 📂 **Grouped Lists** - Group items into sections with headers via a `groupBy` function
- 🎯 **Search Trigger Modes** - Choose between live search (onEdit) or submit-based search (onSubmit)
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
  smart_search_list: ^0.2.0
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

  // Widget below search field (filters, chips, etc.)
  belowSearchWidget: Wrap(
    spacing: 8,
    children: [
      FilterChip(label: Text('In Stock'), onSelected: (_) {}),
      FilterChip(label: Text('On Sale'), onSelected: (_) {}),
    ],
  ),
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

### Search Term Highlighting

The `itemBuilder` receives `searchTerms` — a list of matched words you can use to highlight text:

```dart
SmartSearchList<String>(
  items: fruits,
  searchableFields: (item) => [item],
  itemBuilder: (context, item, index, {searchTerms = const []}) {
    if (searchTerms.isEmpty) return ListTile(title: Text(item));

    return ListTile(
      title: _highlightText(item, searchTerms),
    );
  },
)

Widget _highlightText(String text, List<String> terms) {
  // Split text and bold matched terms
  final spans = <TextSpan>[];
  final lowerText = text.toLowerCase();
  int start = 0;

  for (final term in terms) {
    final idx = lowerText.indexOf(term.toLowerCase(), start);
    if (idx >= 0) {
      if (idx > start) spans.add(TextSpan(text: text.substring(start, idx)));
      spans.add(TextSpan(
        text: text.substring(idx, idx + term.length),
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
      ));
      start = idx + term.length;
    }
  }
  if (start < text.length) spans.add(TextSpan(text: text.substring(start)));

  return RichText(text: TextSpan(children: spans, style: const TextStyle(color: Colors.black)));
}
```

### Dynamic Configuration

Update search settings at runtime using controller methods:

```dart
final controller = SmartSearchController<Product>(
  searchableFields: (p) => [p.name],
);

// Toggle case sensitivity
controller.updateCaseSensitive(true);

// Set minimum search length
controller.updateMinSearchLength(3);
```

### Multi-Select

Enable item selection with built-in checkboxes:

```dart
SmartSearchList<String>(
  items: ['Apple', 'Banana', 'Cherry'],
  searchableFields: (item) => [item],
  itemBuilder: (context, item, index, {searchTerms = const []}) {
    return ListTile(title: Text(item));
  },
  selectionConfig: const SelectionConfiguration(
    enabled: true,
    showCheckbox: true,
    position: CheckboxPosition.leading,
  ),
  onSelectionChanged: (selectedItems) {
    print('Selected: ${selectedItems.length} items');
  },
)
```

Programmatic selection via controller:

```dart
controller.selectAll();
controller.deselectAll();
controller.selectWhere((item) => item.startsWith('A'));
controller.toggleSelection(item);
```

### Grouped Lists

Group items into sections with headers:

```dart
SmartSearchList<Product>(
  items: products,
  searchableFields: (p) => [p.name, p.category],
  itemBuilder: (context, product, index, {searchTerms = const []}) {
    return ListTile(title: Text(product.name));
  },
  groupBy: (product) => product.category,
  groupComparator: (a, b) => (a as String).compareTo(b as String),
)
```

Sticky headers are supported in `SliverSmartSearchList` via `SliverMainAxisGroup`.

### Search Trigger Modes

Control when search fires:

```dart
// Live search (default) — triggers on every keystroke
SmartSearchList<T>(
  searchConfig: const SearchConfiguration(
    triggerMode: SearchTriggerMode.onEdit,
  ),
  // ...
)

// Submit-based search — triggers only on Enter/Search button
SmartSearchList<T>(
  searchConfig: const SearchConfiguration(
    triggerMode: SearchTriggerMode.onSubmit,
  ),
  // ...
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
