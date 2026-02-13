import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import '../core/smart_search_controller.dart';
import '../models/accessibility_configuration.dart';
import '../models/search_configuration.dart';
import 'default_widgets.dart';
import 'smart_search_list.dart';

/// A sliver version of [SmartSearchList] for use in [CustomScrollView].
///
/// Emits slivers instead of managing its own scroll view, so it can be
/// composed with other slivers (e.g. [SliverAppBar]) inside a
/// [CustomScrollView].
///
/// Unlike [SmartSearchList], this widget does **not** include a built-in
/// search field, sort/filter builders, separator builder, progress indicator
/// builder, or scroll controller. The parent [CustomScrollView] (or a
/// companion sliver) should provide the search input and drive the
/// [SmartSearchController] externally.
///
/// Three constructors target different use cases:
/// - [SliverSmartSearchList.new] — offline mode with client-side search.
/// - [SliverSmartSearchList.async] — async mode where the server handles search.
/// - [SliverSmartSearchList.controller] — fully controller-driven rendering.
///
/// Example (offline):
/// ```dart
/// CustomScrollView(
///   slivers: [
///     SliverAppBar(title: Text('My List')),
///     SliverSmartSearchList<String>(
///       items: ['Apple', 'Banana', 'Cherry'],
///       searchableFields: (item) => [item],
///       itemBuilder: (context, item, index, {searchTerms = const []}) =>
///           ListTile(title: Text(item)),
///     ),
///   ],
/// )
/// ```
class SliverSmartSearchList<T extends Object> extends StatefulWidget {
  /// Items for offline mode.
  final List<T>? items;

  /// Async data loader for server-driven search.
  ///
  /// Called with an empty string on initial load — handle `''` as "load all".
  /// The `page` parameter is **zero-indexed**: the first page is `0`, the
  /// second is `1`, and so on. `pageSize` reflects the configured page size
  /// (default 20).
  final Future<List<T>> Function(String query, {int page, int pageSize})?
  asyncLoader;

  /// Function to extract searchable text from items.
  ///
  /// Required for offline mode (client-side search). Not used in async mode
  /// where the server handles search matching.
  final List<String> Function(T item)? searchableFields;

  /// Builds each item in the list.
  final ItemBuilder<T> itemBuilder;

  /// Optional external controller. When provided, you are responsible for
  /// disposing it — the widget only disposes controllers it creates internally.
  final SmartSearchController<T>? controller;

  /// Builder for the loading state, displayed via [SliverFillRemaining]
  /// to fill the remaining viewport space.
  final LoadingStateBuilder? loadingStateBuilder;

  /// Builder for the error state, displayed via [SliverFillRemaining]
  /// to fill the remaining viewport space.
  final ErrorStateBuilder? errorStateBuilder;

  /// Builder for the empty state (no data), displayed via
  /// [SliverFillRemaining] to fill the remaining viewport space.
  final EmptyStateBuilder? emptyStateBuilder;

  /// Builder for the empty search state (no results), displayed via
  /// [SliverFillRemaining] to fill the remaining viewport space.
  final EmptySearchStateBuilder? emptySearchStateBuilder;

  /// Search behavior configuration.
  ///
  /// Only behavioral properties (debounce, case sensitivity, min length, fuzzy
  /// settings) are forwarded to the controller. UI properties like hintText,
  /// decoration, and padding are ignored since this widget has no search field.
  final SearchConfiguration searchConfig;

  /// List appearance configuration (scroll physics, padding, etc.).
  final ListConfiguration listConfig;

  /// Pagination configuration. If null, pagination is disabled.
  final PaginationConfiguration? paginationConfig;

  /// Called when a list item is tapped.
  final void Function(T item, int index)? onItemTap;

  /// Called when the search query changes.
  ///
  /// **Note:** This callback is **not invoked** by [SliverSmartSearchList]
  /// because this widget does not manage a search text field. To observe
  /// query changes, listen to [SmartSearchController] directly instead.
  /// The parameter is retained for API compatibility with [SmartSearchList].
  final void Function(String query)? onSearchChanged;

  /// Called on pull-to-refresh.
  ///
  /// **Note:** This callback is **not invoked** by [SliverSmartSearchList]
  /// because this widget does not include a [RefreshIndicator]. To support
  /// pull-to-refresh in a [CustomScrollView], wrap the scroll view with a
  /// [RefreshIndicator] yourself and call [SmartSearchController.refresh].
  /// The parameter is retained for API compatibility with [SmartSearchList].
  final VoidCallback? onRefresh;

  /// Whether to cache async search results. Defaults to `true`.
  final bool cacheResults;

  /// Maximum number of cached results. Defaults to `100`.
  final int maxCacheSize;

  /// Multi-select configuration. When non-null, multi-select mode is enabled.
  final SelectionConfiguration? selectionConfig;

  /// Called when selection changes (multi-select mode).
  final void Function(Set<T> selectedItems)? onSelectionChanged;

  /// Groups items by the returned value. When non-null, items are displayed
  /// in sections with sticky headers using [SliverMainAxisGroup].
  ///
  /// The returned value is used as a [Map] key internally, so it must have
  /// correct [Object.==] and [Object.hashCode] implementations. Built-in
  /// types like [String] and [int] satisfy this. Custom objects must override
  /// both operators to ensure consistent grouping.
  final Object Function(T item)? groupBy;

  /// Builder for group section headers. If null, [DefaultGroupHeader] is used.
  final GroupHeaderBuilder? groupHeaderBuilder;

  /// Comparator for ordering groups. If null, groups appear in insertion order.
  final Comparator<Object>? groupComparator;

  /// Fixed extent for sticky group headers (default: 48.0).
  ///
  /// This value is used as both `maxExtent` and `minExtent` in the underlying
  /// [SliverPersistentHeaderDelegate], so the header does not shrink or grow
  /// during scrolling.
  final double groupHeaderExtent;

  /// Accessibility configuration for screen reader semantics.
  ///
  /// Controls semantic labels on the search field and screen reader
  /// announcements when result counts change.
  final AccessibilityConfiguration accessibilityConfig;

  // Private constructor — all mode-specific fields are nullable.
  //
  // MAINTAINER NOTE: When adding a new parameter here, you MUST also add it
  // to every public constructor that should expose it:
  //   - SliverSmartSearchList()           — offline mode (all params)
  //   - SliverSmartSearchList.async()     — async mode (no items,
  //       searchableFields)
  //   - SliverSmartSearchList.controller()— external controller (no items,
  //       searchableFields, asyncLoader, cacheResults, maxCacheSize)
  // Also update SmartSearchList's matching constructors for parity.
  const SliverSmartSearchList._({
    super.key,
    this.items,
    this.asyncLoader,
    this.searchableFields,
    required this.itemBuilder,
    this.controller,
    this.loadingStateBuilder,
    this.errorStateBuilder,
    this.emptyStateBuilder,
    this.emptySearchStateBuilder,
    this.searchConfig = const SearchConfiguration(),
    this.listConfig = const ListConfiguration(),
    this.paginationConfig,
    this.onItemTap,
    this.onSearchChanged,
    this.onRefresh,
    this.cacheResults = true,
    this.maxCacheSize = 100,
    this.selectionConfig,
    this.onSelectionChanged,
    this.groupBy,
    this.groupHeaderBuilder,
    this.groupComparator,
    this.groupHeaderExtent = 48.0,
    this.accessibilityConfig = const AccessibilityConfiguration(),
  });

  /// Creates an offline sliver searchable list with client-side search.
  ///
  /// Provide [items] as the data source and [searchableFields] to define which
  /// text fields are matched during search. The widget creates and manages its
  /// own [SmartSearchController] internally.
  ///
  /// To drive search, filter, and sort programmatically via an external
  /// controller, use [SliverSmartSearchList.controller] instead.
  const SliverSmartSearchList({
    Key? key,
    required List<T> items,
    required List<String> Function(T item) searchableFields,
    required ItemBuilder<T> itemBuilder,
    LoadingStateBuilder? loadingStateBuilder,
    ErrorStateBuilder? errorStateBuilder,
    EmptyStateBuilder? emptyStateBuilder,
    EmptySearchStateBuilder? emptySearchStateBuilder,
    SearchConfiguration searchConfig = const SearchConfiguration(),
    ListConfiguration listConfig = const ListConfiguration(),
    PaginationConfiguration? paginationConfig,
    void Function(T item, int index)? onItemTap,
    void Function(String query)? onSearchChanged,
    VoidCallback? onRefresh,
    bool cacheResults = true,
    int maxCacheSize = 100,
    SelectionConfiguration? selectionConfig,
    void Function(Set<T> selectedItems)? onSelectionChanged,
    Object Function(T item)? groupBy,
    GroupHeaderBuilder? groupHeaderBuilder,
    Comparator<Object>? groupComparator,
    double groupHeaderExtent = 48.0,
    AccessibilityConfiguration accessibilityConfig =
        const AccessibilityConfiguration(),
  }) : this._(
         key: key,
         items: items,
         searchableFields: searchableFields,
         itemBuilder: itemBuilder,
         loadingStateBuilder: loadingStateBuilder,
         errorStateBuilder: errorStateBuilder,
         emptyStateBuilder: emptyStateBuilder,
         emptySearchStateBuilder: emptySearchStateBuilder,
         searchConfig: searchConfig,
         listConfig: listConfig,
         paginationConfig: paginationConfig,
         onItemTap: onItemTap,
         onSearchChanged: onSearchChanged,
         onRefresh: onRefresh,
         cacheResults: cacheResults,
         maxCacheSize: maxCacheSize,
         selectionConfig: selectionConfig,
         onSelectionChanged: onSelectionChanged,
         groupBy: groupBy,
         groupHeaderBuilder: groupHeaderBuilder,
         groupComparator: groupComparator,
         groupHeaderExtent: groupHeaderExtent,
         accessibilityConfig: accessibilityConfig,
       );

  /// Creates an async sliver searchable list that loads data from a remote source.
  ///
  /// The [asyncLoader] is called with a search query, page index (zero-based),
  /// and page size. Search matching is delegated to the server;
  /// [searchableFields] is not accepted. The widget creates and manages its own
  /// [SmartSearchController] internally.
  ///
  /// To drive search programmatically via an external controller, use
  /// [SliverSmartSearchList.controller] with
  /// [SmartSearchController.setAsyncLoader].
  const SliverSmartSearchList.async({
    Key? key,
    required Future<List<T>> Function(String query, {int page, int pageSize})
    asyncLoader,
    required ItemBuilder<T> itemBuilder,
    LoadingStateBuilder? loadingStateBuilder,
    ErrorStateBuilder? errorStateBuilder,
    EmptyStateBuilder? emptyStateBuilder,
    EmptySearchStateBuilder? emptySearchStateBuilder,
    SearchConfiguration searchConfig = const SearchConfiguration(),
    ListConfiguration listConfig = const ListConfiguration(),
    PaginationConfiguration? paginationConfig,
    void Function(T item, int index)? onItemTap,
    void Function(String query)? onSearchChanged,
    VoidCallback? onRefresh,
    bool cacheResults = true,
    int maxCacheSize = 100,
    SelectionConfiguration? selectionConfig,
    void Function(Set<T> selectedItems)? onSelectionChanged,
    Object Function(T item)? groupBy,
    GroupHeaderBuilder? groupHeaderBuilder,
    Comparator<Object>? groupComparator,
    double groupHeaderExtent = 48.0,
    AccessibilityConfiguration accessibilityConfig =
        const AccessibilityConfiguration(),
  }) : this._(
         key: key,
         asyncLoader: asyncLoader,
         itemBuilder: itemBuilder,
         loadingStateBuilder: loadingStateBuilder,
         errorStateBuilder: errorStateBuilder,
         emptyStateBuilder: emptyStateBuilder,
         emptySearchStateBuilder: emptySearchStateBuilder,
         searchConfig: searchConfig,
         listConfig: listConfig,
         paginationConfig: paginationConfig,
         onItemTap: onItemTap,
         onSearchChanged: onSearchChanged,
         onRefresh: onRefresh,
         cacheResults: cacheResults,
         maxCacheSize: maxCacheSize,
         selectionConfig: selectionConfig,
         onSelectionChanged: onSelectionChanged,
         groupBy: groupBy,
         groupHeaderBuilder: groupHeaderBuilder,
         groupComparator: groupComparator,
         groupHeaderExtent: groupHeaderExtent,
         accessibilityConfig: accessibilityConfig,
       );

  /// Creates a sliver searchable list driven entirely by an external [controller].
  ///
  /// The controller is responsible for providing data (via
  /// [SmartSearchController.setItems] or [SmartSearchController.setAsyncLoader]).
  /// The widget renders whatever the controller provides.
  ///
  /// All search properties (debounce, case sensitivity, min length, fuzzy
  /// settings) must be configured on the [controller] directly. The
  /// [searchConfig] parameter has no effect on this constructor — behavioral
  /// properties are not forwarded to an external controller, and this widget
  /// has no search field for UI properties to apply to.
  ///
  /// You are responsible for disposing the controller.
  const SliverSmartSearchList.controller({
    Key? key,
    required SmartSearchController<T> controller,
    required ItemBuilder<T> itemBuilder,
    LoadingStateBuilder? loadingStateBuilder,
    ErrorStateBuilder? errorStateBuilder,
    EmptyStateBuilder? emptyStateBuilder,
    EmptySearchStateBuilder? emptySearchStateBuilder,
    SearchConfiguration searchConfig = const SearchConfiguration(),
    ListConfiguration listConfig = const ListConfiguration(),
    PaginationConfiguration? paginationConfig,
    void Function(T item, int index)? onItemTap,
    void Function(String query)? onSearchChanged,
    VoidCallback? onRefresh,
    SelectionConfiguration? selectionConfig,
    void Function(Set<T> selectedItems)? onSelectionChanged,
    Object Function(T item)? groupBy,
    GroupHeaderBuilder? groupHeaderBuilder,
    Comparator<Object>? groupComparator,
    double groupHeaderExtent = 48.0,
    AccessibilityConfiguration accessibilityConfig =
        const AccessibilityConfiguration(),
  }) : this._(
         key: key,
         controller: controller,
         itemBuilder: itemBuilder,
         loadingStateBuilder: loadingStateBuilder,
         errorStateBuilder: errorStateBuilder,
         emptyStateBuilder: emptyStateBuilder,
         emptySearchStateBuilder: emptySearchStateBuilder,
         searchConfig: searchConfig,
         listConfig: listConfig,
         paginationConfig: paginationConfig,
         onItemTap: onItemTap,
         onSearchChanged: onSearchChanged,
         onRefresh: onRefresh,
         selectionConfig: selectionConfig,
         onSelectionChanged: onSelectionChanged,
         groupBy: groupBy,
         groupHeaderBuilder: groupHeaderBuilder,
         groupComparator: groupComparator,
         groupHeaderExtent: groupHeaderExtent,
         accessibilityConfig: accessibilityConfig,
       );

  @override
  State<SliverSmartSearchList<T>> createState() =>
      _SliverSmartSearchListState<T>();
}

class _SliverSmartSearchListState<T extends Object>
    extends State<SliverSmartSearchList<T>> {
  late SmartSearchController<T> _controller;

  bool _isDisposed = false;
  bool _controllerCreatedInternally = false;
  int? _lastAnnouncedCount;

  @override
  void initState() {
    super.initState();

    // Validate pagination config
    assert(
      widget.paginationConfig == null || widget.paginationConfig!.isValid,
      'Invalid pagination configuration',
    );

    // Initialize controller
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = SmartSearchController<T>(
        searchableFields: widget.searchableFields,
        debounceDelay: widget.searchConfig.debounceDelay,
        cacheResults: widget.cacheResults,
        maxCacheSize: widget.maxCacheSize,
        caseSensitive: widget.searchConfig.caseSensitive,
        minSearchLength: widget.searchConfig.minSearchLength,
        pageSize: widget.paginationConfig?.pageSize ?? 20,
        fuzzySearchEnabled: widget.searchConfig.fuzzySearchEnabled,
        fuzzyThreshold: widget.searchConfig.fuzzyThreshold,
      );
      _controllerCreatedInternally = true;
    }
    assert(
      !_controller.isDisposed,
      'Controller must not be disposed at initState',
    );

    // Listen to controller changes
    _controller.addListener(_onControllerChanged);

    // Setup accessibility announcement listener
    if (widget.accessibilityConfig.searchSemanticsEnabled) {
      _controller.addListener(_onControllerChangedForAnnouncement);
    }

    // Initialize data
    _initializeData();
  }

  @override
  void didUpdateWidget(covariant SliverSmartSearchList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only update internally-managed controller
    if (_controllerCreatedInternally) {
      // Items changed → re-set (uses reference equality, so a new list
      // with identical elements will still trigger a re-filter)
      if (widget.items != oldWidget.items && widget.items != null) {
        _controller.setItems(widget.items!);
      }

      // Async loader changed → re-set and reload (refresh clears cache
      // so stale results from the old loader aren't returned)
      if (widget.asyncLoader != oldWidget.asyncLoader &&
          widget.asyncLoader != null) {
        _controller.setAsyncLoader(widget.asyncLoader!);
        _controller.refresh();
      }

      // Search config changes → forward to controller update methods
      if (widget.searchConfig.caseSensitive !=
          oldWidget.searchConfig.caseSensitive) {
        _controller.updateCaseSensitive(widget.searchConfig.caseSensitive);
      }
      if (widget.searchConfig.minSearchLength !=
          oldWidget.searchConfig.minSearchLength) {
        _controller.updateMinSearchLength(widget.searchConfig.minSearchLength);
      }
      if (widget.searchConfig.fuzzySearchEnabled !=
          oldWidget.searchConfig.fuzzySearchEnabled) {
        _controller.updateFuzzySearchEnabled(
          widget.searchConfig.fuzzySearchEnabled,
        );
      }
      if (widget.searchConfig.fuzzyThreshold !=
          oldWidget.searchConfig.fuzzyThreshold) {
        _controller.updateFuzzyThreshold(widget.searchConfig.fuzzyThreshold);
      }
    }

    // External controller swap: detach old, attach new
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_onControllerChangedForAnnouncement);
      oldWidget.controller?.removeListener(_onControllerChanged);
      if (widget.controller != null) {
        // Switching to a new external controller
        if (_controllerCreatedInternally) {
          _controller.dispose();
          _controllerCreatedInternally = false;
        }
        _controller = widget.controller!;
      } else {
        // Switching from external to null → create a new internal controller
        _controller = SmartSearchController<T>(
          searchableFields: widget.searchableFields,
          debounceDelay: widget.searchConfig.debounceDelay,
          cacheResults: widget.cacheResults,
          maxCacheSize: widget.maxCacheSize,
          caseSensitive: widget.searchConfig.caseSensitive,
          minSearchLength: widget.searchConfig.minSearchLength,
          pageSize: widget.paginationConfig?.pageSize ?? 20,
          fuzzySearchEnabled: widget.searchConfig.fuzzySearchEnabled,
          fuzzyThreshold: widget.searchConfig.fuzzyThreshold,
        );
        _controllerCreatedInternally = true;
        _initializeData();
      }
      assert(
        !_controller.isDisposed,
        'Controller must not be disposed after swap',
      );
      assert(
        (widget.controller != null) != _controllerCreatedInternally,
        '_controllerCreatedInternally must be consistent with widget.controller',
      );
      _controller.addListener(_onControllerChanged);
      if (widget.accessibilityConfig.searchSemanticsEnabled) {
        _controller.addListener(_onControllerChangedForAnnouncement);
      }
    }

    // Accessibility toggle outside controller-swap block: handles the case
    // where searchSemanticsEnabled changes without the controller changing.
    if (widget.controller == oldWidget.controller &&
        widget.accessibilityConfig.searchSemanticsEnabled !=
            oldWidget.accessibilityConfig.searchSemanticsEnabled) {
      if (widget.accessibilityConfig.searchSemanticsEnabled) {
        _controller.addListener(_onControllerChangedForAnnouncement);
      } else {
        _controller.removeListener(_onControllerChangedForAnnouncement);
      }
    }
  }

  void _onControllerChanged() {
    if (!_isDisposed && mounted) {
      setState(() {});
    }
  }

  void _initializeData() {
    if (_isDisposed) return;

    if (widget.items != null) {
      // Offline mode
      _controller.setItems(widget.items!);
    } else if (widget.asyncLoader != null) {
      // Async mode
      _controller.setAsyncLoader(widget.asyncLoader!);
      _controller.search(''); // Initial load
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    // No scroll listeners to remove — the parent CustomScrollView owns
    // the scroll controller (contrast with SmartSearchList.dispose).
    _controller.removeListener(_onControllerChangedForAnnouncement);
    _controller.removeListener(_onControllerChanged);

    if (_controllerCreatedInternally) {
      _controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildSliver();
  }

  /// Search terms extracted from the current query for highlighting.
  ///
  /// Note: this getter recomputes on every access (Dart getters are not
  /// cached). Call it once per build and pass the result down.
  List<String> get _searchTerms =>
      _controller.searchQuery.split(' ').where((s) => s.isNotEmpty).toList();

  Widget _buildSliver() {
    // Handle loading state (initial load)
    if (_controller.isLoading && _controller.items.isEmpty) {
      return SliverFillRemaining(
        child:
            widget.loadingStateBuilder?.call(context) ??
            const DefaultLoadingWidget(),
      );
    }

    // Handle error state
    if (_controller.error != null) {
      return SliverFillRemaining(
        child:
            widget.errorStateBuilder?.call(
              context,
              _controller.error!,
              () => _controller.retry(),
            ) ??
            DefaultErrorWidget(
              error: _controller.error!,
              onRetry: () => _controller.retry(),
            ),
      );
    }

    // Handle empty state
    if (_controller.items.isEmpty) {
      // User searched but found nothing
      if (_controller.hasSearched && _controller.searchQuery.isNotEmpty) {
        return SliverFillRemaining(
          child:
              widget.emptySearchStateBuilder?.call(
                context,
                _controller.searchQuery,
              ) ??
              DefaultEmptySearchWidget(searchQuery: _controller.searchQuery),
        );
      }
      // Initial empty state (no data)
      else {
        return SliverFillRemaining(
          child:
              widget.emptyStateBuilder?.call(context) ??
              const DefaultEmptyWidget(),
        );
      }
    }

    return widget.groupBy != null ? _buildGroupedSlivers() : _buildSliverList();
  }

  /// Announces result count changes to screen readers via
  /// [SemanticsService.sendAnnouncement].
  void _onControllerChangedForAnnouncement() {
    if (_isDisposed) return;

    final count = _controller.items.length;
    final isSearchActive = _controller.hasSearched && !_controller.isLoading;

    if (!isSearchActive || count == _lastAnnouncedCount) return;

    _lastAnnouncedCount = count;
    final message = widget.accessibilityConfig.buildResultsAnnouncement(count);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed || !mounted) return;
      SemanticsService.sendAnnouncement(
        View.of(context),
        message,
        Directionality.of(context),
      );
    });
  }

  Widget _buildSliverList() {
    final itemCount = _controller.isLoadingMore
        ? _controller.items.length + 1
        : _controller.items.length;

    // Compute search terms once for all items (the getter recomputes on
    // every access, so we cache the result here).
    final searchTerms = _searchTerms;

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _itemBuilder(context, index, searchTerms),
        childCount: itemCount,
        addAutomaticKeepAlives: widget.listConfig.addAutomaticKeepAlives,
        addRepaintBoundaries: widget.listConfig.addRepaintBoundaries,
        addSemanticIndexes: widget.listConfig.addSemanticIndexes,
      ),
    );
  }

  Widget _buildGroupedSlivers() {
    final items = _controller.items;
    final groupBy = widget.groupBy!;

    // Compute search terms once for all items (the getter recomputes on
    // every access, so we cache the result here).
    final searchTerms = _searchTerms;

    // Build grouped data preserving order
    final groupOrder = <Object>[];
    final groupMap = <Object, List<_SliverIndexedItem<T>>>{};

    for (var i = 0; i < items.length; i++) {
      final key = groupBy(items[i]);
      if (!groupMap.containsKey(key)) {
        groupOrder.add(key);
        groupMap[key] = [];
      }
      groupMap[key]!.add(_SliverIndexedItem(items[i], i));
    }

    // Sort groups if comparator provided
    if (widget.groupComparator != null) {
      groupOrder.sort(widget.groupComparator!);
    }

    // Build sliver groups with sticky headers using SliverMainAxisGroup
    final slivers = <Widget>[];

    for (final key in groupOrder) {
      final groupItems = groupMap[key]!;
      slivers.add(
        SliverMainAxisGroup(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _GroupHeaderDelegate(
                maxExtent: widget.groupHeaderExtent,
                minExtent: widget.groupHeaderExtent,
                child:
                    widget.groupHeaderBuilder?.call(
                      context,
                      key,
                      groupItems.length,
                    ) ??
                    DefaultGroupHeader(
                      groupValue: key,
                      itemCount: groupItems.length,
                    ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final indexed = groupItems[index];
                  return _itemBuilder(context, indexed.index, searchTerms);
                },
                childCount: groupItems.length,
                addAutomaticKeepAlives:
                    widget.listConfig.addAutomaticKeepAlives,
                addRepaintBoundaries: widget.listConfig.addRepaintBoundaries,
                addSemanticIndexes: widget.listConfig.addSemanticIndexes,
              ),
            ),
          ],
        ),
      );
    }

    // Loading more indicator
    if (_controller.isLoadingMore) {
      slivers.add(const SliverToBoxAdapter(child: DefaultLoadMoreWidget()));
    }

    // build() must return a single Widget, so wrap all group slivers in a
    // SliverMainAxisGroup.
    return SliverMainAxisGroup(slivers: slivers);
  }

  Widget _itemBuilder(
    BuildContext context,
    int index,
    List<String> searchTerms,
  ) {
    // Handle loading more indicator
    if (index >= _controller.items.length) {
      return const DefaultLoadMoreWidget();
    }

    final item = _controller.items[index];

    Widget itemWidget = widget.itemBuilder(
      context,
      item,
      index,
      searchTerms: searchTerms,
    );

    // Wrap with selection checkbox if enabled
    if (widget.selectionConfig != null && widget.selectionConfig!.enabled) {
      final isSelected = _controller.isSelected(item);
      if (widget.selectionConfig!.showCheckbox) {
        final checkbox = Checkbox(
          value: isSelected,
          onChanged: (_) {
            _controller.toggleSelection(item);
            widget.onSelectionChanged?.call(_controller.selectedItems);
          },
        );

        if (widget.selectionConfig!.position == CheckboxPosition.leading) {
          itemWidget = Row(
            children: [
              checkbox,
              Expanded(child: itemWidget),
            ],
          );
        } else {
          itemWidget = Row(
            children: [
              Expanded(child: itemWidget),
              checkbox,
            ],
          );
        }
      }
    }

    // Add tap handling if needed
    if (widget.onItemTap != null) {
      itemWidget = GestureDetector(
        onTap: () => widget.onItemTap!(item, index),
        child: itemWidget,
      );
    }

    return itemWidget;
  }
}

/// Internal helper for tracking original index in grouped sliver views.
class _SliverIndexedItem<T> {
  final T item;
  final int index;
  const _SliverIndexedItem(this.item, this.index);
}

/// Delegate for sticky group headers in sliver grouped lists.
class _GroupHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  @override
  final double maxExtent;

  @override
  final double minExtent;

  _GroupHeaderDelegate({
    required this.child,
    required this.maxExtent,
    required this.minExtent,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _GroupHeaderDelegate oldDelegate) {
    return child != oldDelegate.child ||
        maxExtent != oldDelegate.maxExtent ||
        minExtent != oldDelegate.minExtent;
  }
}
