## 0.2.0

🎯 **Feature Release** - Multi-select, grouped lists, and search trigger modes.

### ✨ New Features
- **Multi-Select Support**: Select/deselect items with checkboxes via `SelectionConfiguration`
  - Controller methods: `toggleSelection()`, `selectAll()`, `deselectAll()`, `selectWhere()`, `isSelected()`
  - Configurable checkbox position (leading/trailing) and visibility
  - `onSelectionChanged` callback for reacting to selection changes
- **Grouped Lists**: Group items into sections with headers via `groupBy` function
  - Automatic grouping — provide a `groupBy: (item) => item.category` function
  - `DefaultGroupHeader` with group name and item count
  - Custom `groupHeaderBuilder` for full control
  - `groupComparator` for ordering groups
  - Empty groups auto-removed after search/filter
  - Sticky headers in `SliverSmartSearchList` via `SliverMainAxisGroup`
- **Search Trigger Modes**: Control when search fires via `SearchTriggerMode` enum
  - `onEdit` (default): debounced search on every keystroke
  - `onSubmit`: search only on keyboard submit or search button tap
  - `searchImmediate()` method for bypassing debounce programmatically

### 🔧 API Changes
- New `SearchTriggerMode` enum: `{ onEdit, onSubmit }`
- New `SelectionConfiguration` class with `enabled`, `showCheckbox`, `position`
- New `CheckboxPosition` enum: `{ leading, trailing }`
- New `GroupHeaderBuilder` typedef
- `SearchConfiguration` gains `triggerMode` parameter
- `SmartSearchList` gains `selectionConfig`, `groupBy`, `groupHeaderBuilder`, `groupComparator`, `onSelectionChanged`
- `SliverSmartSearchList` gains the same plus `groupHeaderExtent` for sticky header size
- `SmartSearchController` gains multi-select methods and `searchImmediate()`
- `DefaultSearchField` gains `onSubmitted` callback for submit mode

### ⚠️ Breaking Changes
- Minimum Flutter version bumped from 3.10.0 to **3.13.0** (required for `SliverMainAxisGroup`)

### 🎨 Example Updates
- New **Multi-Select** example: checkbox list with select all/deselect all
- New **Grouped List** example: products grouped by category with search

### ⚡ Backward Compatibility
- All new parameters are optional with sensible defaults
- Existing code continues to work without modifications

---

## 0.1.1

🚀 **Enhanced Features Release** - Added search term highlighting support and below-search widget slot.

### ✨ New Features
- **Search Term Highlighting**: `ItemBuilder` now receives `searchTerms` parameter for highlighting matched text
- **Below Search Widget**: New `belowSearchWidget` parameter for filters, chips, or custom controls
- **Pull to Refresh Examples**: All example pages now demonstrate pull-to-refresh functionality

### 🔧 API Changes  
- `ItemBuilder<T>` now includes optional `searchTerms` parameter:
  ```dart
  itemBuilder: (context, item, index, {searchTerms = const []}) {
    // Use searchTerms for highlighting
  }
  ```
- Added `belowSearchWidget` parameter to `SmartSearchList`

### 🎨 Example Updates
- All examples updated with search terms highlighting support
- Pull-to-refresh enabled across all example pages  
- Improved user experience with better visual feedback

### ⚡ Backward Compatibility
- All changes are backward compatible
- Existing code continues to work without modifications
- `searchTerms` parameter is optional and defaults to empty list

---

## 0.1.0

🧪 **Initial testing release** - A searchable list package designed to be better than `searchable_listview`. Ready for production testing and feedback.

> **Note**: This is a testing release. The package is technically solid but needs real-world validation. Please test in your apps and provide feedback before we publish the stable 1.0.0 version.

### ✨ Features
- **High Performance**: Tested with 10,000+ items at 60 FPS
- **Memory Safe**: Proper disposal patterns, no memory leaks
- **Two Empty States**: Different messages for "no data" vs "no search results"  
- **Fully Customizable**: Builder patterns for all UI components
- **Async Support**: Built-in pagination and pull-to-refresh
- **Zero Dependencies**: Only uses Flutter SDK

### 🎯 Core Components
- `SmartSearchList<T>` - Main widget with offline and async modes
- `SmartSearchController<T>` - Robust controller with disposal safety
- `SearchConfiguration` - Flexible search behavior configuration
- `ListConfiguration` - List appearance and behavior options
- `PaginationConfiguration` - Pagination settings

### 🛡️ Reliability Features
- Race condition prevention with request IDs
- Debounced search (300ms default) 
- Proper `_isDisposed` checks throughout
- Automatic cleanup of timers and listeners

### 🎨 Builder Patterns
All UI components are customizable:
- `searchFieldBuilder` - Custom search field
- `itemBuilder` - List item rendering (required)
- `loadingBuilder` - Loading state
- `errorBuilder` - Error state with retry
- `emptyBuilder` - Empty state (no data)
- `emptySearchBuilder` - Empty search results
- `separatorBuilder` - List separators

### 📱 Example Apps
Complete example app with 7 comprehensive demonstrations:
- Basic offline list with configuration options
- E-commerce products with filters/sorting
- Async API loading with pagination  
- Empty states (no data vs no search results)
- Sliver integration for CustomScrollView
- Advanced configuration with external controller
- Performance test with 10K items

### 🔧 Recent Updates
- Added dynamic configuration update methods to `SmartSearchController`
- Fixed Advanced Configuration example with proper state management
- Improved filter count display with reactive UI updates

### 🔄 Migration
Easy migration from `searchable_listview` - see README for examples.
