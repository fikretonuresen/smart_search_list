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
