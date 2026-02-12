## 0.7.1 - 2026-02-12

README rewrite for pub.dev readiness with problem-solution opening, vertical GIF layout, and .controller() example.

### Documentation
- **README overhaul**: Rewrote for pub.dev -- problem-solution opening paragraph, vertical GIF layout with captions at 320px, simplified installation to `flutter pub add`
- **Controller example**: Added `.controller()` Quick Start section showing external filter, sort, and setItems usage
- **Removed badges**: Deferred pub.dev badges until after first publish to avoid broken shield images
- **Removed Platform Support section**: Folded "all platforms" into Features list (pub.dev shows this in sidebar)
- **Added Example App section**: Prominent link to the 14-demo example app

### Bug Fixes
- **Spanish localization typo**: Fixed `'Borrar busqueda'` to `'Borrar búsqueda'` in README and accessibility example

### Backward Compatibility
- No breaking changes. No library code changes.

## 0.7.0 - 2026-02-12

Named constructors replace nullable params and runtime assertions with compile-time mode enforcement.

### Breaking Changes
- **Named constructors**: `SmartSearchList` and `SliverSmartSearchList` now use three constructors:
  - `SmartSearchList(items:, searchableFields:, ...)` -- offline mode with client-side search
  - `SmartSearchList.async(asyncLoader:, ...)` -- async mode where the server handles search
  - `SmartSearchList.controller(controller:, ...)` -- fully controller-driven rendering
- **`controller` parameter removed from default and `.async()` constructors**: External controllers are now exclusive to `.controller()`. This enforces clean mode separation -- each constructor serves exactly one data pattern.
- **`cacheResults` and `maxCacheSize` removed from `.controller()`**: These only apply to internally-created controllers. Configure caching on your controller directly.
- **`SmartSearchController.searchableFields`**: Changed from `required` to optional (nullable). Required only for offline search mode.
- **Removed assertions**: The two runtime assertions ("Provide either items OR asyncLoader" and "Provide items, asyncLoader, or a controller") are removed. The compiler now enforces these constraints.

### Migration
- **Offline mode** (items + searchableFields): No change required. The default constructor signature is identical.
- **Offline + external controller** (items + controller): Change to `.controller(controller: ...,` and call `controller.setItems(...)` yourself. Pass `searchableFields` to the controller constructor. Pass `debounceDelay`, `caseSensitive`, `minSearchLength`, `fuzzySearchEnabled`, and `fuzzyThreshold` to the controller constructor instead of `searchConfig`.
- **Async mode** (asyncLoader): Change `SmartSearchList(asyncLoader: ..., searchableFields: ...,` to `SmartSearchList.async(asyncLoader: ...,` and remove `searchableFields:`.
- **Async + external controller** (asyncLoader + controller): Change to `.controller(controller: ...,` and call `controller.setAsyncLoader(...)` yourself. You must also call `controller.search('')` to trigger the initial load — the widget no longer does this automatically for external controllers.
- **Controller-only mode** (controller without items/asyncLoader): Change to `SmartSearchList.controller(controller: ...,` and remove `searchableFields:`.
- **SmartSearchController**: If you were passing `searchableFields` in async-only usage, you can now omit it.

### Documentation
- **README GIFs**: Added basic search, fuzzy search, and async pagination demo GIFs

### Backward Compatibility
- The default constructor signature is unchanged for offline mode -- existing offline code compiles without modification.
- This is a breaking change for async, controller, and mixed-mode usage patterns.

## 0.6.1 - 2026-02-10

Dartdoc overhaul, bug fixes, and sliver test coverage.

### Bug Fixes
- **`RichText` replaced with `Text.rich`**: `SearchHighlightText` now uses `Text.rich` for proper `SelectionArea` participation and `textScaler` accessibility support
- **Scroll listener leak**: `SmartSearchList` now always removes scroll listeners before disposal, not just for external controllers
- **Controller swap safety**: `didUpdateWidget` in both widgets now correctly handles external-to-null and null-to-external controller transitions without dangling references
- **Assertion consistency**: `SmartSearchList` constructor assertions now match `SliverSmartSearchList` — rejects `items` + `asyncLoader` simultaneously even when controller is provided
- **`_searchTerms` performance**: `SliverSmartSearchList` now computes search terms once per build instead of once per item

### Documentation
- Complete dartdoc audit: ~70 missing doc comments added across all public classes, methods, fields, and typedefs
- Effective Dart compliance: fragment summaries converted to complete sentences, third-person verb forms, redundant docs trimmed
- Cross-references converted to bracket refs with imports for clickable pub.dev links
- Filter/sort async vs offline behavior clarified, `ItemBuilder.searchTerms` lifecycle documented
- Aligned `SliverSmartSearchList` docs with `SmartSearchList` for `asyncLoader`, `groupBy`, and `accessibilityConfig`

### Tests
- 31 new `SliverSmartSearchList` tests covering rendering, search, grouped views, empty/error/loading states, interactions, controller lifecycle, `didUpdateWidget`, async data, filtering, and sorting
- 187 tests total (up from 156)

### Backward Compatibility
- No public API changes — all fixes are internal behavior and documentation
- Existing code continues to work without modifications

---

## 0.6.0 - 2026-02-10

Bug fixes and widget tests. Widgets now react to prop changes, cache key correctness fix, and first widget-level test coverage.

### Bug Fixes
- **`didUpdateWidget` support**: `SmartSearchList` and `SliverSmartSearchList` now react to parent rebuilds — changing `items`, `asyncLoader`, `caseSensitive`, `minSearchLength`, `fuzzySearchEnabled`, `fuzzyThreshold`, or swapping an external controller after initial build now works correctly
- **Cache key fix**: Calling `setFilter` with the same key but a different predicate no longer returns stale cached results — cache key now includes a filter predicate version counter

### Tests
- 11 widget-level test scenarios covering rendering, filtering, empty/error states, `didUpdateWidget` (items and async loader swap), selection, grouping, pagination, and disposal safety

### Backward Compatibility
- No public API changes — all fixes are internal behavior corrections
- Existing code continues to work without modifications

---

## 0.5.1 - 2026-02-01

Improved screen reader announcements for more reliable TalkBack/VoiceOver support.

### Improvements
- **Screen reader announcements**: Replaced `Semantics(liveRegion: true)` with `SemanticsService.sendAnnouncement()` for more reliable TalkBack and VoiceOver feedback
- **Removed live region widget**: Result count announcements no longer require an extra `SizedBox` in the widget tree

### Requirements
- Minimum Flutter version bumped from 3.13.0 to **3.35.0** (required for `SemanticsService.sendAnnouncement`)

### Backward Compatibility
- No public API changes — all parameters and behavior remain the same
- Existing code continues to work without modifications on Flutter 3.35+

---

## 0.5.0 - 2026-02-01

Accessibility support with TalkBack/VoiceOver and full localization control.

### New Features
- **AccessibilityConfiguration**: New configuration class for semantic labels and screen reader behavior
  - `searchFieldLabel` — custom label for the search text field
  - `clearButtonLabel` — custom tooltip for the clear button (default: `'Clear search'`)
  - `searchButtonLabel` — custom tooltip for the search button in onSubmit mode (default: `'Search'`)
  - `resultsAnnouncementBuilder` — customizable announcement text for result count changes (supports localization)
  - `searchSemanticsEnabled` — opt-out flag to disable all automatic semantics
- **Live Region Announcements**: Result count changes are announced to screen readers via `Semantics(liveRegion: true)` — compatible with Android 16+ (which deprecated imperative `SemanticsService.announce`)
- **Semantic Headers**: `DefaultGroupHeader` now includes `Semantics(header: true)` for proper screen reader navigation
- **Icon Tooltips**: Clear and search `IconButton`s in `DefaultSearchField` now have tooltips for assistive technology

### API Changes
- `SmartSearchList` gains `accessibilityConfig` parameter (default: `const AccessibilityConfiguration()`)
- `SliverSmartSearchList` gains `accessibilityConfig` parameter
- `DefaultSearchField` gains `accessibilityConfig` parameter
- New export: `AccessibilityConfiguration`

### Example Updates
- New **Accessibility** example demonstrating localized labels and custom announcement text

### Backward Compatibility
- All new parameters are optional with sensible defaults
- Existing code continues to work without modifications

---

## 0.4.0 - 2026-02-01

Fuzzy search with typo-tolerant matching, scored ranking, and built-in highlight widget.

### New Features
- **Fuzzy Search**: Zero-dependency 3-phase matching algorithm for offline lists
  - **Phase 1 — Exact substring** (score 1.0): standard `indexOf` fast path
  - **Phase 2 — Ordered subsequence** (score 0.01–0.99): handles missing characters ("apl" → "Apple", "bnna" → "Banana") with consecutive-run scoring
  - **Phase 3 — Bounded Levenshtein** (score 0.01–0.59): handles extra/wrong characters and transpositions ("apole" → "Apple", "appel" → "Apple") with `maxEditDistance = 2`
  - Score-and-sort pipeline: exact matches always rank first, fuzzy matches scored by consecutive runs, density, position, and word boundaries
  - Configurable via `SearchConfiguration.fuzzySearchEnabled` (default: `false`) and `SearchConfiguration.fuzzyThreshold` (default: `0.3`)
- **SearchHighlightText Widget**: Built-in widget for highlighting matched characters
  - Works with both exact substring and fuzzy matching
  - Accepts `text` + `searchTerms`, renders highlighted `TextSpan`
  - Customizable `matchStyle`, `highlightColor`, `maxLines`, `overflow`
- **FuzzyMatcher**: Public utility class for custom fuzzy matching
  - `FuzzyMatcher.match(query, text)` — returns score + match indices
  - `FuzzyMatcher.matchFields(query, fields)` — best score across multiple fields
  - `FuzzyMatchResult` with score and `matchIndices` for highlighting

### API Changes
- `SearchConfiguration` gains `fuzzySearchEnabled` and `fuzzyThreshold` parameters
- `SmartSearchController` gains `fuzzySearchEnabled`, `fuzzyThreshold` fields and `updateFuzzySearchEnabled()`, `updateFuzzyThreshold()` methods
- New export: `FuzzyMatcher`, `FuzzyMatchResult`, `SearchHighlightText`

### Performance Note
- Fuzzy search (especially Phase 3) is computationally heavier than plain substring search
- For lists > 5,000 items, test performance on target devices or increase `fuzzyThreshold` to `0.6+` to skip expensive edit-distance matches
- Subsequence matching (Phase 2) is O(m+n) per item and fast for any list size
- Edit-distance fallback (Phase 3) only runs when Phases 1 and 2 fail — gibberish queries are rejected quickly by length and ratio guards

### Example Updates
- New **Fuzzy Search** example: toggle fuzzy on/off, adjust threshold, SearchHighlightText demo

### Backward Compatibility
- All new parameters are optional with sensible defaults
- Fuzzy search is opt-in (`fuzzySearchEnabled: false` by default)
- Existing code continues to work without modifications

---

## 0.3.0 - 2026-01-31

Progress indicator builder and consistent state builder naming.

### New Features
- **Progress Indicator Builder**: New `progressIndicatorBuilder` parameter on `SmartSearchList`
  - Shows an inline widget (e.g., thin progress bar, shimmer) below the search field during async operations
  - Unlike `loadingStateBuilder` (which replaces the entire list), this renders alongside existing content
  - Receives `(BuildContext context, bool isLoading)` — return `SizedBox.shrink()` when not loading
- New `ProgressIndicatorBuilder` typedef

### Bug Fixes
- **Sliver searchTerms fix**: `SliverSmartSearchList` now correctly forwards `searchTerms` to `itemBuilder` in grouped mode — previously, items inside grouped slivers received empty search terms, breaking highlighting

### Improvements
- Cleaned up package description and documentation tone

### Breaking Changes
All state builders renamed for consistency — the `*StateBuilder` suffix now clearly indicates builders that replace the entire list area:
- `loadingBuilder` → `loadingStateBuilder`
- `errorBuilder` → `errorStateBuilder`
- `emptyBuilder` → `emptyStateBuilder`
- `emptySearchBuilder` → `emptySearchStateBuilder`
- `LoadingBuilder` → `LoadingStateBuilder`
- `ErrorBuilder` → `ErrorStateBuilder`
- `EmptyBuilder` → `EmptyStateBuilder`
- `EmptySearchBuilder` → `EmptySearchStateBuilder`

### Migration
Find-and-replace in your code:
- `loadingBuilder:` → `loadingStateBuilder:`
- `errorBuilder:` → `errorStateBuilder:`
- `emptyBuilder:` → `emptyStateBuilder:`
- `emptySearchBuilder:` → `emptySearchStateBuilder:`

---

## 0.2.0 - 2026-01-31

Multi-select, grouped lists, and search trigger modes.

### New Features
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

### API Changes
- New `SearchTriggerMode` enum: `{ onEdit, onSubmit }`
- New `SelectionConfiguration` class with `enabled`, `showCheckbox`, `position`
- New `CheckboxPosition` enum: `{ leading, trailing }`
- New `GroupHeaderBuilder` typedef
- `SearchConfiguration` gains `triggerMode` parameter
- `SmartSearchList` gains `selectionConfig`, `groupBy`, `groupHeaderBuilder`, `groupComparator`, `onSelectionChanged`
- `SliverSmartSearchList` gains the same plus `groupHeaderExtent` for sticky header size
- `SmartSearchController` gains multi-select methods and `searchImmediate()`
- `DefaultSearchField` gains `onSubmitted` callback for submit mode

### Breaking Changes
- Minimum Flutter version bumped from 3.10.0 to **3.13.0** (required for `SliverMainAxisGroup`)

### Example Updates
- New **Multi-Select** example: checkbox list with select all/deselect all
- New **Grouped List** example: products grouped by category with search

### Backward Compatibility
- All new parameters are optional with sensible defaults
- Existing code continues to work without modifications

---

## 0.1.1 - 2026-01-31

Search term highlighting support and below-search widget slot.

### New Features
- **Search Term Highlighting**: `ItemBuilder` now receives `searchTerms` parameter for highlighting matched text
- **Below Search Widget**: New `belowSearchWidget` parameter for filters, chips, or custom controls
- **Pull to Refresh Examples**: All example pages now demonstrate pull-to-refresh functionality

### API Changes
- `ItemBuilder<T>` now includes optional `searchTerms` parameter:
  ```dart
  itemBuilder: (context, item, index, {searchTerms = const []}) {
    // Use searchTerms for highlighting
  }
  ```
- Added `belowSearchWidget` parameter to `SmartSearchList`

### Example Updates
- All examples updated with search terms highlighting support
- Pull-to-refresh enabled across all example pages
- Improved user experience with better visual feedback

### Backward Compatibility
- All changes are backward compatible
- Existing code continues to work without modifications
- `searchTerms` parameter is optional and defaults to empty list

---

## 0.1.0 - 2026-01-31

Initial release. A high-performance, zero-dependency searchable list package for Flutter.

### Features
- **High Performance**: Tested with 10,000+ items at 60 FPS
- **Memory Safe**: Proper disposal patterns, no memory leaks
- **Two Empty States**: Different messages for "no data" vs "no search results"
- **Fully Customizable**: Builder patterns for all UI components
- **Async Support**: Built-in pagination and pull-to-refresh
- **Zero Dependencies**: Only uses Flutter SDK

### Core Components
- `SmartSearchList<T>` — Main widget with offline and async modes
- `SmartSearchController<T>` — Robust controller with disposal safety
- `SearchConfiguration` — Flexible search behavior configuration
- `ListConfiguration` — List appearance and behavior options
- `PaginationConfiguration` — Pagination settings

### Reliability
- Race condition prevention with request IDs
- Debounced search (300ms default)
- Proper `_isDisposed` checks throughout
- Automatic cleanup of timers and listeners

### Builder Patterns
All UI components are customizable:
- `searchFieldBuilder` — Custom search field
- `itemBuilder` — List item rendering (required)
- `loadingStateBuilder` — Loading state
- `errorStateBuilder` — Error state with retry
- `emptyStateBuilder` — Empty state (no data)
- `emptySearchStateBuilder` — Empty search results
- `separatorBuilder` — List separators

### Example App
Complete example app with 7 demonstrations:
- Basic offline list with configuration options
- E-commerce products with filters/sorting
- Async API loading with pagination
- Empty states (no data vs no search results)
- Sliver integration for CustomScrollView
- Advanced configuration with external controller
- Performance test with 10K items
