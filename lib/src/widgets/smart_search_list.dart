import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../core/smart_search_controller.dart';
import '../models/accessibility_configuration.dart';
import '../models/search_configuration.dart';
import 'default_widgets.dart';

/// A highly customizable searchable list widget
///
/// Supports both offline and async data sources with search, filter, sort,
/// and pagination capabilities.
///
/// Example:
/// ```dart
/// SmartSearchList<String>(
///   items: ['Apple', 'Banana', 'Cherry'],
///   searchableFields: (item) => [item],
///   itemBuilder: (context, item, index, {searchTerms = const []}) {
///     return ListTile(title: Text(item));
///   },
/// )
/// ```
class SmartSearchList<T extends Object> extends StatefulWidget {
  /// Items for offline mode (provide either this OR asyncLoader)
  final List<T>? items;

  /// Async data loader (provide either this OR items)
  final Future<List<T>> Function(String query, {int page, int pageSize})?
  asyncLoader;

  /// Function to extract searchable text from items
  final List<String> Function(T item) searchableFields;

  /// Required: Builder for list items
  final ItemBuilder<T> itemBuilder;

  /// Optional: External controller
  final SmartSearchController<T>? controller;

  /// Builder functions for customization
  final SearchFieldBuilder? searchFieldBuilder;
  final SeparatorBuilder? separatorBuilder;
  final LoadingStateBuilder? loadingStateBuilder;
  final ErrorStateBuilder? errorStateBuilder;
  final EmptyStateBuilder? emptyStateBuilder;
  final EmptySearchStateBuilder? emptySearchStateBuilder;
  final SortBuilder<T>? sortBuilder;
  final FilterBuilder<T>? filterBuilder;

  /// Configuration objects
  final SearchConfiguration searchConfig;
  final ListConfiguration listConfig;
  final PaginationConfiguration? paginationConfig;

  /// Callbacks
  final void Function(T item, int index)? onItemTap;
  final void Function(String query)? onSearchChanged;
  final VoidCallback? onRefresh;

  /// Called when selection changes (multi-select mode)
  final void Function(Set<T> selectedItems)? onSelectionChanged;

  /// Builder for an inline progress indicator shown during async operations.
  ///
  /// Rendered between the search field (and [belowSearchWidget]) and the list.
  /// Receives the current loading state so you can show/hide a progress bar,
  /// shimmer, etc. Return [SizedBox.shrink] when not loading.
  final ProgressIndicatorBuilder? progressIndicatorBuilder;

  /// Widget to display below search field (for filters, chips, etc)
  final Widget? belowSearchWidget;

  /// Scroll controller
  final ScrollController? scrollController;

  /// Performance options
  final bool cacheResults;
  final int maxCacheSize;

  /// Multi-select configuration. When non-null, multi-select mode is enabled.
  final SelectionConfiguration? selectionConfig;

  /// Groups items by the returned value. When non-null, items are displayed
  /// in sections with headers.
  final Object Function(T item)? groupBy;

  /// Builder for group section headers. If null, [DefaultGroupHeader] is used.
  final GroupHeaderBuilder? groupHeaderBuilder;

  /// Comparator for ordering groups. If null, groups appear in insertion order.
  final Comparator<Object>? groupComparator;

  /// Accessibility configuration for screen reader semantics.
  ///
  /// Controls semantic labels on the search field and screen reader announcements
  /// announcements when result counts change.
  final AccessibilityConfiguration accessibilityConfig;

  const SmartSearchList({
    super.key,
    this.items,
    this.asyncLoader,
    required this.searchableFields,
    required this.itemBuilder,
    this.controller,
    this.searchFieldBuilder,
    this.separatorBuilder,
    this.loadingStateBuilder,
    this.errorStateBuilder,
    this.emptyStateBuilder,
    this.emptySearchStateBuilder,
    this.sortBuilder,
    this.filterBuilder,
    this.progressIndicatorBuilder,
    this.searchConfig = const SearchConfiguration(),
    this.listConfig = const ListConfiguration(),
    this.paginationConfig,
    this.onItemTap,
    this.onSearchChanged,
    this.onRefresh,
    this.belowSearchWidget,
    this.scrollController,
    this.cacheResults = true,
    this.maxCacheSize = 100,
    this.selectionConfig,
    this.onSelectionChanged,
    this.groupBy,
    this.groupHeaderBuilder,
    this.groupComparator,
    this.accessibilityConfig = const AccessibilityConfiguration(),
  }) : assert(
         controller != null ||
             ((items != null && asyncLoader == null) ||
                 (items == null && asyncLoader != null)),
         'Provide either items OR asyncLoader, not both (unless using external controller)',
       );

  @override
  State<SmartSearchList<T>> createState() => _SmartSearchListState<T>();
}

class _SmartSearchListState<T extends Object>
    extends State<SmartSearchList<T>> {
  late SmartSearchController<T> _controller;
  late ScrollController _scrollController;
  late TextEditingController _searchTextController;
  late FocusNode _focusNode;

  bool _isDisposed = false;
  bool _controllerCreatedInternally = false;

  /// Tracks the last result count announced to avoid duplicate announcements.
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

    // Initialize scroll controller
    _scrollController = widget.scrollController ?? ScrollController();

    // Initialize text controller and focus node
    _searchTextController = TextEditingController();
    _focusNode = FocusNode();

    // Setup scroll listener for pagination
    if (widget.paginationConfig?.enabled == true) {
      _scrollController.addListener(_onScroll);
    }

    // Setup keyboard dismiss on scroll
    if (widget.searchConfig.closeKeyboardOnScroll) {
      _scrollController.addListener(_handleKeyboardOnScroll);
    }

    // Setup search text listener
    _searchTextController.addListener(_onSearchTextChanged);

    // Setup accessibility announcement listener
    if (widget.accessibilityConfig.searchSemanticsEnabled) {
      _controller.addListener(_onControllerChangedForAnnouncement);
    }

    // Initialize data
    _initializeData();
  }

  @override
  void didUpdateWidget(covariant SmartSearchList<T> oldWidget) {
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
        _controller
            .updateFuzzySearchEnabled(widget.searchConfig.fuzzySearchEnabled);
      }
      if (widget.searchConfig.fuzzyThreshold !=
          oldWidget.searchConfig.fuzzyThreshold) {
        _controller.updateFuzzyThreshold(widget.searchConfig.fuzzyThreshold);
      }
    }

    // External controller swap: detach old, attach new
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_onControllerChangedForAnnouncement);
      if (widget.controller != null) {
        _controller = widget.controller!;
        if (widget.accessibilityConfig.searchSemanticsEnabled) {
          _controller.addListener(_onControllerChangedForAnnouncement);
        }
      }
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

  void _onSearchTextChanged() {
    if (_isDisposed) return;

    final query = _searchTextController.text;
    // In onSubmit mode, don't trigger search on text change
    if (widget.searchConfig.triggerMode != SearchTriggerMode.onSubmit) {
      _controller.search(query);
    }
    widget.onSearchChanged?.call(query);
  }

  void _onSearchSubmitted(String query) {
    if (_isDisposed) return;
    _controller.searchImmediate(query);
  }

  void _onScroll() {
    if (_isDisposed || widget.paginationConfig == null) return;

    final position = _scrollController.position;
    final triggerDistance = widget.paginationConfig!.triggerDistance;

    if (position.pixels >= position.maxScrollExtent - triggerDistance) {
      _controller.loadMore();
    }
  }

  void _handleKeyboardOnScroll() {
    if (_isDisposed) return;

    if (_scrollController.hasClients &&
        _scrollController.position.userScrollDirection !=
            ScrollDirection.idle) {
      FocusScope.of(context).unfocus();
    }
  }

  void _clearSearch() {
    if (_isDisposed) return;

    _searchTextController.clear();
    _controller.clearSearch();
  }

  Future<void> _handleRefresh() async {
    if (_isDisposed) return;

    widget.onRefresh?.call();
    await _controller.refresh();
  }

  @override
  void dispose() {
    _isDisposed = true;

    // Remove listeners
    _controller.removeListener(_onControllerChangedForAnnouncement);
    _searchTextController.removeListener(_onSearchTextChanged);

    if (widget.scrollController == null) {
      _scrollController.dispose();
    } else {
      if (widget.paginationConfig?.enabled == true) {
        _scrollController.removeListener(_onScroll);
      }
      if (widget.searchConfig.closeKeyboardOnScroll) {
        _scrollController.removeListener(_handleKeyboardOnScroll);
      }
    }

    // Dispose controllers
    _searchTextController.dispose();
    _focusNode.dispose();

    if (_controllerCreatedInternally) {
      _controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Column(
          children: [
            // Search field
            if (widget.searchConfig.enabled) _buildSearchField(),

            // Below search widget
            if (widget.belowSearchWidget != null) widget.belowSearchWidget!,

            // Inline progress indicator
            if (widget.progressIndicatorBuilder != null)
              widget.progressIndicatorBuilder!(
                context,
                _controller.isLoading || _controller.isLoadingMore,
              ),

            // Sort and filter controls
            if (widget.sortBuilder != null || widget.filterBuilder != null)
              _buildControls(),

            // Main list
            Expanded(child: _buildList()),
          ],
        );
      },
    );
  }

  Widget _buildSearchField() {
    if (widget.searchFieldBuilder != null) {
      return widget.searchFieldBuilder!(
        context,
        _searchTextController,
        _focusNode,
        _clearSearch,
      );
    }

    return DefaultSearchField(
      controller: _searchTextController,
      focusNode: _focusNode,
      configuration: widget.searchConfig,
      onClear: _clearSearch,
      onSubmitted: widget.searchConfig.triggerMode == SearchTriggerMode.onSubmit
          ? _onSearchSubmitted
          : null,
      accessibilityConfig: widget.accessibilityConfig,
    );
  }

  /// Announces result count changes to screen readers via
  /// [SemanticsService.sendAnnouncement]. Called from the controller listener
  /// so it fires after search/filter operations settle.
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

  Widget _buildControls() {
    return Row(
      children: [
        if (widget.filterBuilder != null)
          Expanded(
            child: widget.filterBuilder!(
              context,
              _controller.activeFilters,
              (key, predicate) => _controller.setFilter(key, predicate),
              (key) => _controller.removeFilter(key),
            ),
          ),
        if (widget.sortBuilder != null)
          widget.sortBuilder!(
            context,
            _controller.currentComparator,
            (comparator) => _controller.setSortBy(comparator),
          ),
      ],
    );
  }

  Widget _buildList() {
    // Handle loading state (initial load)
    if (_controller.isLoading && _controller.items.isEmpty) {
      return widget.loadingStateBuilder?.call(context) ??
          const DefaultLoadingWidget();
    }

    // Handle error state
    if (_controller.error != null) {
      return widget.errorStateBuilder?.call(
            context,
            _controller.error!,
            () => _controller.retry(),
          ) ??
          DefaultErrorWidget(
            error: _controller.error!,
            onRetry: () => _controller.retry(),
          );
    }

    // Handle empty state
    if (_controller.items.isEmpty) {
      // User searched but found nothing
      if (_controller.hasSearched && _controller.searchQuery.isNotEmpty) {
        return widget.emptySearchStateBuilder?.call(
              context,
              _controller.searchQuery,
            ) ??
            DefaultEmptySearchWidget(searchQuery: _controller.searchQuery);
      }
      // Initial empty state (no data)
      else {
        return widget.emptyStateBuilder?.call(context) ??
            const DefaultEmptyWidget();
      }
    }

    // Build the main list
    Widget listWidget = _buildListView();

    // Add pull-to-refresh if enabled
    if (widget.listConfig.pullToRefresh) {
      listWidget = RefreshIndicator(
        onRefresh: _handleRefresh,
        child: listWidget,
      );
    }

    return listWidget;
  }

  Widget _buildListView() {
    // Compute search terms once for all items
    final searchTerms = _controller.searchQuery
        .split(' ')
        .where((s) => s.isNotEmpty)
        .toList();

    // Grouped rendering
    if (widget.groupBy != null) {
      return _buildGroupedListView(searchTerms);
    }

    // Flat list rendering (original behavior)
    final itemCount = _controller.isLoadingMore
        ? _controller.items.length + 1
        : _controller.items.length;

    Widget listView;

    if (widget.separatorBuilder != null) {
      listView = ListView.separated(
        controller: _scrollController,
        physics: widget.listConfig.physics,
        padding: widget.listConfig.padding,
        shrinkWrap: widget.listConfig.shrinkWrap,
        reverse: widget.listConfig.reverse,
        scrollDirection: widget.listConfig.scrollDirection,
        addAutomaticKeepAlives: widget.listConfig.addAutomaticKeepAlives,
        addRepaintBoundaries: widget.listConfig.addRepaintBoundaries,
        addSemanticIndexes: widget.listConfig.addSemanticIndexes,
        cacheExtent: widget.listConfig.cacheExtent,
        clipBehavior: widget.listConfig.clipBehavior,
        itemCount: itemCount,
        separatorBuilder: widget.separatorBuilder!,
        itemBuilder: (context, index) =>
            _itemBuilder(context, index, searchTerms),
      );
    } else {
      listView = ListView.builder(
        controller: _scrollController,
        physics: widget.listConfig.physics,
        padding: widget.listConfig.padding,
        shrinkWrap: widget.listConfig.shrinkWrap,
        reverse: widget.listConfig.reverse,
        scrollDirection: widget.listConfig.scrollDirection,
        addAutomaticKeepAlives: widget.listConfig.addAutomaticKeepAlives,
        addRepaintBoundaries: widget.listConfig.addRepaintBoundaries,
        addSemanticIndexes: widget.listConfig.addSemanticIndexes,
        itemExtent: widget.listConfig.itemExtent,
        cacheExtent: widget.listConfig.cacheExtent,
        clipBehavior: widget.listConfig.clipBehavior,
        itemCount: itemCount,
        itemBuilder: (context, index) =>
            _itemBuilder(context, index, searchTerms),
      );
    }

    return listView;
  }

  Widget _buildGroupedListView(List<String> searchTerms) {
    final items = _controller.items;
    final groupBy = widget.groupBy!;

    // Build grouped data preserving order
    final groupOrder = <Object>[];
    final groupMap = <Object, List<_IndexedItem<T>>>{};

    for (var i = 0; i < items.length; i++) {
      final key = groupBy(items[i]);
      if (!groupMap.containsKey(key)) {
        groupOrder.add(key);
        groupMap[key] = [];
      }
      groupMap[key]!.add(_IndexedItem(items[i], i));
    }

    // Sort groups if comparator provided
    if (widget.groupComparator != null) {
      groupOrder.sort(widget.groupComparator!);
    }

    return ListView.builder(
      controller: _scrollController,
      physics: widget.listConfig.physics,
      padding: widget.listConfig.padding,
      shrinkWrap: widget.listConfig.shrinkWrap,
      reverse: widget.listConfig.reverse,
      scrollDirection: widget.listConfig.scrollDirection,
      cacheExtent: widget.listConfig.cacheExtent,
      clipBehavior: widget.listConfig.clipBehavior,
      itemCount: _totalGroupedItemCount(groupOrder, groupMap),
      itemBuilder: (context, flatIndex) {
        return _groupedItemBuilder(
          context,
          flatIndex,
          groupOrder,
          groupMap,
          searchTerms,
        );
      },
    );
  }

  int _totalGroupedItemCount(
    List<Object> groupOrder,
    Map<Object, List<_IndexedItem<T>>> groupMap,
  ) {
    int count = 0;
    for (final key in groupOrder) {
      count += 1 + groupMap[key]!.length; // 1 header + items
    }
    if (_controller.isLoadingMore) count += 1;
    return count;
  }

  Widget _groupedItemBuilder(
    BuildContext context,
    int flatIndex,
    List<Object> groupOrder,
    Map<Object, List<_IndexedItem<T>>> groupMap,
    List<String> searchTerms,
  ) {
    int current = 0;
    for (final key in groupOrder) {
      final groupItems = groupMap[key]!;
      if (flatIndex == current) {
        // This is a group header
        return widget.groupHeaderBuilder?.call(
              context,
              key,
              groupItems.length,
            ) ??
            DefaultGroupHeader(groupValue: key, itemCount: groupItems.length);
      }
      current += 1; // header
      if (flatIndex < current + groupItems.length) {
        final itemIndex = flatIndex - current;
        final indexed = groupItems[itemIndex];
        return _itemBuilder(context, indexed.index, searchTerms);
      }
      current += groupItems.length;
    }

    // Loading more indicator at bottom
    return const DefaultLoadMoreWidget();
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

/// Internal helper for tracking original index in grouped views
class _IndexedItem<T> {
  final T item;
  final int index;
  const _IndexedItem(this.item, this.index);
}
