# Smart Search List

Every Flutter app with a list eventually needs search, filtering, sorting, and pagination. Building that properly means debouncing, async race conditions, disposal safety, empty states, accessibility -- roughly 200 lines of boilerplate per screen. Smart Search List handles all of it with a single widget. Zero dependencies.

<p align="center">
  <img src="https://raw.githubusercontent.com/fikretonuresen/smart_search_list/main/doc/images/basic_search.gif" width="320" alt="Basic offline search with instant filtering">
  <br><em>Offline search -- instant multi-field filtering</em>
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/fikretonuresen/smart_search_list/main/doc/images/fuzzy_search.gif" width="320" alt="Fuzzy search with typo tolerance and character highlighting">
  <br><em>Fuzzy search -- typo-tolerant matching with character highlighting</em>
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/fikretonuresen/smart_search_list/main/doc/images/async_pagination.gif" width="320" alt="Async loading with pagination and search">
  <br><em>Async loading -- API pagination with search</em>
</p>

## Features

- Offline list filtering with multi-field search
- Async data loading with pagination and pull-to-refresh
- Fuzzy search with typo tolerance and scored ranking (opt-in)
- Built-in search term highlighting widget
- Multi-select with checkboxes and programmatic selection
- Grouped lists with section headers (sticky headers in slivers)
- TalkBack/VoiceOver accessible with localizable labels
- All platforms -- Android, iOS, Web, macOS, Windows, Linux

## Installation

```
flutter pub add smart_search_list
```

Requires Flutter 3.35.0 or higher.

## Upgrading from v0.6.x

v0.7.0 introduced named constructors for compile-time mode enforcement. Migration is straightforward:

- **Offline lists** (items + searchableFields): No change needed. The default constructor is identical.
- **Async loading** (asyncLoader): Change to `SmartSearchList.async(asyncLoader: ...)` and remove `searchableFields:`.
- **External controller**: Change to `SmartSearchList.controller(controller: ...)`. Pass `searchableFields`, `debounceDelay`, and fuzzy/case settings to the controller constructor instead of `searchConfig`.

See the [CHANGELOG](CHANGELOG.md) for full migration details with code examples.

## Quick Start

### Offline List

```dart
SmartSearchList<String>(
  items: ['Apple', 'Banana', 'Cherry', 'Date'],
  searchableFields: (item) => [item],
  itemBuilder: (context, item, index, {searchTerms = const []}) {
    return ListTile(title: Text(item));
  },
)
```

### Async Loading

```dart
SmartSearchList<Product>.async(
  asyncLoader: (query, {page = 0, pageSize = 20}) async {
    return await api.searchProducts(query, page: page);
  },
  itemBuilder: (context, product, index, {searchTerms = const []}) {
    return ProductCard(product: product);
  },
  paginationConfig: const PaginationConfiguration(
    pageSize: 20,
    enabled: true,
  ),
)
```

### External Controller

Use `.controller()` when you need programmatic access to search, filter, and sort state from outside the widget:

```dart
final controller = SmartSearchController<Product>(
  searchableFields: (p) => [p.name, p.category],
);

// Apply filters and sorting externally
controller.setFilter('in-stock', (p) => p.inStock);
controller.setSortBy((a, b) => a.price.compareTo(b.price));
controller.setItems(products);

SmartSearchList<Product>.controller(
  controller: controller,
  itemBuilder: (context, product, index, {searchTerms = const []}) {
    return ListTile(title: Text(product.name));
  },
)
```

## Search Highlighting

Use the built-in `SearchHighlightText` widget. It handles both exact and fuzzy matches:

```dart
itemBuilder: (context, item, index, {searchTerms = const []}) {
  return ListTile(
    title: SearchHighlightText(
      text: item,
      searchTerms: searchTerms,
      fuzzySearchEnabled: true,
      highlightColor: Colors.yellow.withValues(alpha: 0.3),
    ),
  );
},
```

## Fuzzy Search

Enable typo-tolerant matching with a single flag. Uses a 3-phase cascade: exact substring, ordered subsequence, then bounded edit distance (max 2 edits). Results are scored -- exact matches rank first.

```dart
searchConfig: const SearchConfiguration(
  fuzzySearchEnabled: true,
  fuzzyThreshold: 0.3,
),
```

### Threshold Guide

| Threshold | Behavior |
|-----------|----------|
| `0.1` | Very lenient -- includes weak fuzzy matches |
| `0.3` | **Default** -- good balance for most use cases |
| `0.5` | Moderate -- filters out edit-distance matches |
| `0.6+` | Strict -- only exact and strong subsequence |
| `1.0` | Exact substring only |

For lists over 5,000 items, test performance on target devices. Raising the threshold to 0.6+ skips the expensive edit-distance phase. Using `SearchTriggerMode.onSubmit` also helps by reducing search frequency.

## Multi-Select

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
  onSelectionChanged: (selected) {
    // selected is a Set<String> of currently checked items
    // Example: setState(() => _selectedItems = selected);
  },
)
```

Programmatic control via the controller: `selectAll()`, `deselectAll()`, `selectWhere((item) => ...)`, `toggleSelection(item)`.

## Grouped Lists

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

## Customization

Every UI component is replaceable via builders:

```dart
SmartSearchList<T>(
  items: myItems,
  searchableFields: (item) => [item.name],
  itemBuilder: (context, item, index, {searchTerms = const []}) => ...,
  searchFieldBuilder: (context, controller, focusNode, onClear) {
    return CustomSearchField(controller: controller);
  },
  loadingStateBuilder: (context) => const CircularProgressIndicator(),
  errorStateBuilder: (context, error, onRetry) {
    return ErrorWidget(error: error, onRetry: onRetry);
  },
  emptyStateBuilder: (context) => const Text('No data'),
  emptySearchStateBuilder: (context, query) => Text('No results for "$query"'),
  progressIndicatorBuilder: (context, isLoading) {
    if (!isLoading) return const SizedBox.shrink();
    return const LinearProgressIndicator(minHeight: 2);
  },
  belowSearchWidget: Wrap(
    spacing: 8,
    children: [
      FilterChip(label: Text('In Stock'), onSelected: (_) {}),
      FilterChip(label: Text('On Sale'), onSelected: (_) {}),
    ],
  ),
)
```

## Configuration

```dart
SmartSearchList<T>(
  items: myItems,
  searchableFields: (item) => [item.name],
  itemBuilder: (context, item, index, {searchTerms = const []}) => ...,
  searchConfig: const SearchConfiguration(
    enabled: true,
    autofocus: false,
    debounceDelay: Duration(milliseconds: 300),
    hintText: 'Search...',
    caseSensitive: false,
    minSearchLength: 0,
    triggerMode: SearchTriggerMode.onEdit, // or .onSubmit
    fuzzySearchEnabled: false,
    fuzzyThreshold: 0.3,
  ),
  listConfig: const ListConfiguration(
    pullToRefresh: true,
    shrinkWrap: false,
    itemExtent: 72.0, // fixed height for better scroll performance
  ),
  paginationConfig: const PaginationConfiguration(
    pageSize: 20,
    enabled: true,
    triggerDistance: 200.0,
  ),
)
```

## Accessibility

TalkBack and VoiceOver work out of the box. Default widgets include semantic labels, tooltips, and result count announcements via `SemanticsService.sendAnnouncement()`.

Customize labels for localization:

```dart
SmartSearchList<String>(
  accessibilityConfig: AccessibilityConfiguration(
    searchFieldLabel: 'Buscar frutas',
    clearButtonLabel: 'Borrar búsqueda',
    searchButtonLabel: 'Buscar',
    resultsAnnouncementBuilder: (count) {
      if (count == 0) return 'Sin resultados';
      return '$count resultados encontrados';
    },
  ),
  // ...
)
```

Set `searchSemanticsEnabled: false` to disable all automatic semantics if you handle accessibility in your own builders.

## Example App

The [example app](example/) includes 14 demos covering every feature: basic search, async pagination, fuzzy search, multi-select, grouped lists, sliver integration, accessibility, and more.

```
cd example && flutter run
```

## License

Apache 2.0. See [LICENSE](LICENSE).
