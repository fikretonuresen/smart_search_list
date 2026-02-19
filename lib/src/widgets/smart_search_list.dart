import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../core/smart_search_controller.dart';
import '../models/accessibility_configuration.dart';
import '../models/search_configuration.dart';
import 'default_widgets.dart';
import 'sliver_smart_search_list.dart';
import 'smart_search_state.dart';

/// A highly customizable searchable list widget.
///
/// Supports offline, async, and controller-driven data sources with search,
/// filter, sort, and pagination capabilities.
///
/// Three constructors target different use cases:
/// - [SmartSearchList.new] — offline mode with client-side search.
/// - [SmartSearchList.async] — async mode where the server handles search.
/// - [SmartSearchList.controller] — fully controller-driven rendering.
///
/// This widget uses a [Column] with [Flexible] internally, so it must receive
/// a bounded height constraint from its parent. Do not place it inside a
/// [ListView] or [SingleChildScrollView] — use [SliverSmartSearchList] for
/// [CustomScrollView] integration instead.
///
/// Example (offline):
/// ```dart
/// SmartSearchList<String>(
///   items: ['Apple', 'Banana', 'Cherry'],
///   searchableFields: (item) => [item],
///   itemBuilder: (context, item, index, {searchTerms = const []}) {
///     return ListTile(title: Text(item));
///   },
/// )
/// ```
///
/// Example (async):
/// ```dart
/// SmartSearchList<Product>.async(
///   asyncLoader: (query, {page = 0, pageSize = 20}) async {
///     return await api.searchProducts(query, page: page);
///   },
///   itemBuilder: (context, product, index, {searchTerms = const []}) {
///     return ProductCard(product: product);
///   },
/// )
/// ```
class SmartSearchList<T extends Object> extends SmartSearchWidgetBase<T> {
  /// Builder for a custom search field. If null, [DefaultSearchField] is used.
  final SearchFieldBuilder? searchFieldBuilder;

  /// Builder for item separators. If null, no separators are shown.
  final SeparatorBuilder? separatorBuilder;

  /// Builder for sort controls.
  final SortBuilder<T>? sortBuilder;

  /// Builder for filter controls.
  final FilterBuilder<T>? filterBuilder;

  /// Builder for an inline progress indicator shown during async operations.
  ///
  /// Rendered between the search field (and [belowSearchWidget]) and the list.
  /// Receives the current loading state so you can show/hide a progress bar,
  /// shimmer, etc. Return [SizedBox.shrink] when not loading.
  final ProgressIndicatorBuilder? progressIndicatorBuilder;

  /// Called on pull-to-refresh.
  ///
  /// **Not available on [SliverSmartSearchList].** For pull-to-refresh in a
  /// [CustomScrollView], wrap it with a [RefreshIndicator] and call
  /// [SmartSearchController.refresh] directly.
  final VoidCallback? onRefresh;

  /// Widget to display below search field (for filters, chips, etc.).
  final Widget? belowSearchWidget;

  /// Scroll controller.
  final ScrollController? scrollController;

  /// List appearance configuration (scroll physics, padding, etc.).
  final ListConfiguration listConfig;

  // Private constructor — all mode-specific fields are nullable.
  //
  // MAINTAINER NOTE: When adding a new parameter here, you MUST also add it
  // to every public constructor that should expose it:
  //   - SmartSearchList()           — offline mode (all params)
  //   - SmartSearchList.async()     — async mode (no items, searchableFields)
  //   - SmartSearchList.controller()— external controller (no items,
  //       searchableFields, asyncLoader, cacheResults, maxCacheSize)
  // Also update SliverSmartSearchList's matching constructors for parity.
  const SmartSearchList._({
    super.key,
    super.items,
    super.asyncLoader,
    super.searchableFields,
    required super.itemBuilder,
    super.controller,
    this.searchFieldBuilder,
    this.separatorBuilder,
    super.loadingStateBuilder,
    super.errorStateBuilder,
    super.emptyStateBuilder,
    super.emptySearchStateBuilder,
    this.sortBuilder,
    this.filterBuilder,
    this.progressIndicatorBuilder,
    super.searchConfig,
    this.listConfig = const ListConfiguration(),
    super.paginationConfig,
    super.onItemTap,
    super.onSearchChanged,
    this.onRefresh,
    this.belowSearchWidget,
    this.scrollController,
    super.cacheResults,
    super.maxCacheSize,
    super.selectionConfig,
    super.onSelectionChanged,
    super.groupBy,
    super.groupHeaderBuilder,
    super.groupComparator,
    super.accessibilityConfig,
  });

  /// Creates an offline searchable list with client-side search.
  ///
  /// Provide [items] as the data source and [searchableFields] to define which
  /// text fields are matched during search. The widget creates and manages its
  /// own [SmartSearchController] internally.
  ///
  /// To drive search, filter, and sort programmatically via an external
  /// controller, use [SmartSearchList.controller] instead.
  const SmartSearchList({
    Key? key,
    required List<T> items,
    required List<String> Function(T item) searchableFields,
    required ItemBuilder<T> itemBuilder,
    SearchFieldBuilder? searchFieldBuilder,
    SeparatorBuilder? separatorBuilder,
    LoadingStateBuilder? loadingStateBuilder,
    ErrorStateBuilder? errorStateBuilder,
    EmptyStateBuilder? emptyStateBuilder,
    EmptySearchStateBuilder? emptySearchStateBuilder,
    SortBuilder<T>? sortBuilder,
    FilterBuilder<T>? filterBuilder,
    ProgressIndicatorBuilder? progressIndicatorBuilder,
    SearchConfiguration searchConfig = const SearchConfiguration(),
    ListConfiguration listConfig = const ListConfiguration(),
    PaginationConfiguration? paginationConfig,
    void Function(T item, int index)? onItemTap,
    void Function(String query)? onSearchChanged,
    VoidCallback? onRefresh,
    Widget? belowSearchWidget,
    ScrollController? scrollController,
    bool cacheResults = true,
    int maxCacheSize = 100,
    SelectionConfiguration? selectionConfig,
    void Function(Set<T> selectedItems)? onSelectionChanged,
    Object Function(T item)? groupBy,
    GroupHeaderBuilder? groupHeaderBuilder,
    Comparator<Object>? groupComparator,
    AccessibilityConfiguration accessibilityConfig =
        const AccessibilityConfiguration(),
  }) : this._(
         key: key,
         items: items,
         searchableFields: searchableFields,
         itemBuilder: itemBuilder,
         searchFieldBuilder: searchFieldBuilder,
         separatorBuilder: separatorBuilder,
         loadingStateBuilder: loadingStateBuilder,
         errorStateBuilder: errorStateBuilder,
         emptyStateBuilder: emptyStateBuilder,
         emptySearchStateBuilder: emptySearchStateBuilder,
         sortBuilder: sortBuilder,
         filterBuilder: filterBuilder,
         progressIndicatorBuilder: progressIndicatorBuilder,
         searchConfig: searchConfig,
         listConfig: listConfig,
         paginationConfig: paginationConfig,
         onItemTap: onItemTap,
         onSearchChanged: onSearchChanged,
         onRefresh: onRefresh,
         belowSearchWidget: belowSearchWidget,
         scrollController: scrollController,
         cacheResults: cacheResults,
         maxCacheSize: maxCacheSize,
         selectionConfig: selectionConfig,
         onSelectionChanged: onSelectionChanged,
         groupBy: groupBy,
         groupHeaderBuilder: groupHeaderBuilder,
         groupComparator: groupComparator,
         accessibilityConfig: accessibilityConfig,
       );

  /// Creates an async searchable list that loads data from a remote source.
  ///
  /// The [asyncLoader] is called with a search query, page index (zero-based),
  /// and page size. It is called with an empty string on initial load — handle
  /// `''` as "load all".
  ///
  /// Search matching is delegated to the server; [searchableFields] is not
  /// accepted. The widget creates and manages its own [SmartSearchController]
  /// internally.
  ///
  /// To drive search programmatically via an external controller, use
  /// [SmartSearchList.controller] with [SmartSearchController.setAsyncLoader].
  const SmartSearchList.async({
    Key? key,
    required Future<List<T>> Function(String query, {int page, int pageSize})
    asyncLoader,
    required ItemBuilder<T> itemBuilder,
    SearchFieldBuilder? searchFieldBuilder,
    SeparatorBuilder? separatorBuilder,
    LoadingStateBuilder? loadingStateBuilder,
    ErrorStateBuilder? errorStateBuilder,
    EmptyStateBuilder? emptyStateBuilder,
    EmptySearchStateBuilder? emptySearchStateBuilder,
    SortBuilder<T>? sortBuilder,
    FilterBuilder<T>? filterBuilder,
    ProgressIndicatorBuilder? progressIndicatorBuilder,
    SearchConfiguration searchConfig = const SearchConfiguration(),
    ListConfiguration listConfig = const ListConfiguration(),
    PaginationConfiguration? paginationConfig,
    void Function(T item, int index)? onItemTap,
    void Function(String query)? onSearchChanged,
    VoidCallback? onRefresh,
    Widget? belowSearchWidget,
    ScrollController? scrollController,
    bool cacheResults = true,
    int maxCacheSize = 100,
    SelectionConfiguration? selectionConfig,
    void Function(Set<T> selectedItems)? onSelectionChanged,
    Object Function(T item)? groupBy,
    GroupHeaderBuilder? groupHeaderBuilder,
    Comparator<Object>? groupComparator,
    AccessibilityConfiguration accessibilityConfig =
        const AccessibilityConfiguration(),
  }) : this._(
         key: key,
         asyncLoader: asyncLoader,
         itemBuilder: itemBuilder,
         searchFieldBuilder: searchFieldBuilder,
         separatorBuilder: separatorBuilder,
         loadingStateBuilder: loadingStateBuilder,
         errorStateBuilder: errorStateBuilder,
         emptyStateBuilder: emptyStateBuilder,
         emptySearchStateBuilder: emptySearchStateBuilder,
         sortBuilder: sortBuilder,
         filterBuilder: filterBuilder,
         progressIndicatorBuilder: progressIndicatorBuilder,
         searchConfig: searchConfig,
         listConfig: listConfig,
         paginationConfig: paginationConfig,
         onItemTap: onItemTap,
         onSearchChanged: onSearchChanged,
         onRefresh: onRefresh,
         belowSearchWidget: belowSearchWidget,
         scrollController: scrollController,
         cacheResults: cacheResults,
         maxCacheSize: maxCacheSize,
         selectionConfig: selectionConfig,
         onSelectionChanged: onSelectionChanged,
         groupBy: groupBy,
         groupHeaderBuilder: groupHeaderBuilder,
         groupComparator: groupComparator,
         accessibilityConfig: accessibilityConfig,
       );

  /// Creates a searchable list driven entirely by an external [controller].
  ///
  /// The controller is responsible for providing data (via
  /// [SmartSearchController.setItems] or [SmartSearchController.setAsyncLoader]).
  /// The widget renders whatever the controller provides.
  ///
  /// Behavioral search properties (debounce, case sensitivity, min length,
  /// fuzzy settings) must be configured on the [controller] directly — the
  /// [searchConfig] parameter only affects UI properties (hint text, autofocus,
  /// trigger mode) on this constructor.
  ///
  /// You are responsible for disposing the controller.
  const SmartSearchList.controller({
    Key? key,
    required SmartSearchController<T> controller,
    required ItemBuilder<T> itemBuilder,
    SearchFieldBuilder? searchFieldBuilder,
    SeparatorBuilder? separatorBuilder,
    LoadingStateBuilder? loadingStateBuilder,
    ErrorStateBuilder? errorStateBuilder,
    EmptyStateBuilder? emptyStateBuilder,
    EmptySearchStateBuilder? emptySearchStateBuilder,
    SortBuilder<T>? sortBuilder,
    FilterBuilder<T>? filterBuilder,
    ProgressIndicatorBuilder? progressIndicatorBuilder,
    SearchConfiguration searchConfig = const SearchConfiguration(),
    ListConfiguration listConfig = const ListConfiguration(),
    PaginationConfiguration? paginationConfig,
    void Function(T item, int index)? onItemTap,
    void Function(String query)? onSearchChanged,
    VoidCallback? onRefresh,
    Widget? belowSearchWidget,
    ScrollController? scrollController,
    SelectionConfiguration? selectionConfig,
    void Function(Set<T> selectedItems)? onSelectionChanged,
    Object Function(T item)? groupBy,
    GroupHeaderBuilder? groupHeaderBuilder,
    Comparator<Object>? groupComparator,
    AccessibilityConfiguration accessibilityConfig =
        const AccessibilityConfiguration(),
  }) : this._(
         key: key,
         controller: controller,
         itemBuilder: itemBuilder,
         searchFieldBuilder: searchFieldBuilder,
         separatorBuilder: separatorBuilder,
         loadingStateBuilder: loadingStateBuilder,
         errorStateBuilder: errorStateBuilder,
         emptyStateBuilder: emptyStateBuilder,
         emptySearchStateBuilder: emptySearchStateBuilder,
         sortBuilder: sortBuilder,
         filterBuilder: filterBuilder,
         progressIndicatorBuilder: progressIndicatorBuilder,
         searchConfig: searchConfig,
         listConfig: listConfig,
         paginationConfig: paginationConfig,
         onItemTap: onItemTap,
         onSearchChanged: onSearchChanged,
         onRefresh: onRefresh,
         belowSearchWidget: belowSearchWidget,
         scrollController: scrollController,
         selectionConfig: selectionConfig,
         onSelectionChanged: onSelectionChanged,
         groupBy: groupBy,
         groupHeaderBuilder: groupHeaderBuilder,
         groupComparator: groupComparator,
         accessibilityConfig: accessibilityConfig,
       );

  @override
  State<SmartSearchList<T>> createState() => _SmartSearchListState<T>();
}

class _SmartSearchListState<T extends Object> extends State<SmartSearchList<T>>
    with SmartSearchStateMixin<T, SmartSearchList<T>> {
  late ScrollController _scrollController;
  late TextEditingController _searchTextController;
  late FocusNode _focusNode;

  bool _scrollControllerCreatedInternally = false;

  @override
  void initState() {
    super.initState();

    // Mixin: controller + a11y listener
    initController();

    // Scroll controller
    if (widget.scrollController != null) {
      _scrollController = widget.scrollController!;
    } else {
      _scrollController = ScrollController();
      _scrollControllerCreatedInternally = true;
    }

    // Text controller and focus node
    _searchTextController = TextEditingController();
    _focusNode = FocusNode();

    // Scroll listeners
    if (widget.paginationConfig?.enabled == true) {
      _scrollController.addListener(_onScroll);
    }
    if (widget.searchConfig.closeKeyboardOnScroll) {
      _scrollController.addListener(_handleKeyboardOnScroll);
    }

    // Search text listener
    _searchTextController.addListener(_onSearchTextChanged);

    // Mixin: data init
    initializeData();
  }

  @override
  void didUpdateWidget(covariant SmartSearchList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Mixin: config updates
    updateControllerConfig(oldWidget);

    // Scroll controller swap: detach listeners from old, attach to new.
    // SliverSmartSearchList does not have this — the parent CustomScrollView
    // owns the scroll controller there.
    if (widget.scrollController != oldWidget.scrollController) {
      _scrollController.removeListener(_onScroll);
      _scrollController.removeListener(_handleKeyboardOnScroll);

      if (_scrollControllerCreatedInternally) {
        _scrollController.dispose();
        _scrollControllerCreatedInternally = false;
      }

      if (widget.scrollController != null) {
        _scrollController = widget.scrollController!;
      } else {
        _scrollController = ScrollController();
        _scrollControllerCreatedInternally = true;
      }

      if (widget.paginationConfig?.enabled == true) {
        _scrollController.addListener(_onScroll);
      }
      if (widget.searchConfig.closeKeyboardOnScroll) {
        _scrollController.addListener(_handleKeyboardOnScroll);
      }
    }

    // Mixin: controller swap (AnimatedBuilder manages the rebuild listener)
    handleControllerSwap(oldWidget);
    handleAccessibilityToggle(oldWidget);
  }

  void _onSearchTextChanged() {
    if (isDisposed) return;

    final query = _searchTextController.text;
    if (widget.searchConfig.triggerMode != SearchTriggerMode.onSubmit) {
      controller.search(query);
    }
    widget.onSearchChanged?.call(query);
  }

  void _onSearchSubmitted(String query) {
    if (isDisposed) return;
    controller.searchImmediate(query);
  }

  void _onScroll() {
    if (isDisposed || widget.paginationConfig == null) return;

    final position = _scrollController.position;
    final triggerDistance = widget.paginationConfig!.triggerDistance;

    if (position.pixels >= position.maxScrollExtent - triggerDistance) {
      controller.loadMore();
    }
  }

  void _handleKeyboardOnScroll() {
    if (isDisposed) return;

    if (_scrollController.hasClients &&
        _scrollController.position.userScrollDirection !=
            ScrollDirection.idle) {
      FocusScope.of(context).unfocus();
    }
  }

  void _clearSearch() {
    if (isDisposed) return;

    _searchTextController.clear();
    controller.clearSearch();
  }

  Future<void> _handleRefresh() async {
    if (isDisposed) return;

    widget.onRefresh?.call();
    await controller.refresh();
  }

  @override
  void dispose() {
    // Remove listeners
    _searchTextController.removeListener(_onSearchTextChanged);

    // Unconditionally remove scroll listeners — config may have changed
    // between initState and dispose, and removeListener is safe to call
    // even if the listener was never added.
    _scrollController.removeListener(_onScroll);
    _scrollController.removeListener(_handleKeyboardOnScroll);

    // Only dispose the scroll controller if we created it internally
    if (_scrollControllerCreatedInternally) {
      _scrollController.dispose();
    }

    // Dispose controllers
    _searchTextController.dispose();
    _focusNode.dispose();

    // Mixin: controller cleanup
    disposeController();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // AnimatedBuilder manages its own listener on controller, so
    // didUpdateWidget does not need to remove/re-add a manual listener
    // on controller swap (unlike SliverSmartSearchList which uses setState).
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Column(
          mainAxisSize: widget.listConfig.shrinkWrap
              ? MainAxisSize.min
              : MainAxisSize.max,
          children: [
            // Search field
            if (widget.searchConfig.enabled) _buildSearchField(),

            // Below search widget
            if (widget.belowSearchWidget != null) widget.belowSearchWidget!,

            // Inline progress indicator
            if (widget.progressIndicatorBuilder != null)
              widget.progressIndicatorBuilder!(
                context,
                controller.isLoading || controller.isLoadingMore,
              ),

            // Sort and filter controls
            if (widget.sortBuilder != null || widget.filterBuilder != null)
              _buildControls(),

            // Main list
            Flexible(
              fit: widget.listConfig.shrinkWrap ? FlexFit.loose : FlexFit.tight,
              flex: widget.listConfig.shrinkWrap ? 0 : 1,
              child: _buildList(),
            ),
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

  Widget _buildControls() {
    return Row(
      children: [
        if (widget.filterBuilder != null)
          Expanded(
            child: widget.filterBuilder!(
              context,
              controller.activeFilters,
              (key, predicate) => controller.setFilter(key, predicate),
              (key) => controller.removeFilter(key),
            ),
          ),
        if (widget.sortBuilder != null)
          widget.sortBuilder!(
            context,
            controller.currentComparator,
            (comparator) => controller.setSortBy(comparator),
          ),
      ],
    );
  }

  Widget _buildList() {
    // Mixin: check loading/error/empty states
    final stateWidget = buildStateWidget(context);
    if (stateWidget != null) return stateWidget;

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
    final searchTerms = computeSearchTerms();

    // Grouped rendering
    if (widget.groupBy != null) {
      return _buildGroupedListView(searchTerms);
    }

    // Flat list rendering
    final itemCount = controller.isLoadingMore
        ? controller.items.length + 1
        : controller.items.length;

    if (widget.separatorBuilder != null) {
      return ListView.separated(
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
        itemBuilder: (context, index) => buildItem(context, index, searchTerms),
      );
    }

    return ListView.builder(
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
      itemBuilder: (context, index) => buildItem(context, index, searchTerms),
    );
  }

  Widget _buildGroupedListView(List<String> searchTerms) {
    final groups = computeGroups();

    return ListView.builder(
      controller: _scrollController,
      physics: widget.listConfig.physics,
      padding: widget.listConfig.padding,
      shrinkWrap: widget.listConfig.shrinkWrap,
      reverse: widget.listConfig.reverse,
      scrollDirection: widget.listConfig.scrollDirection,
      cacheExtent: widget.listConfig.cacheExtent,
      clipBehavior: widget.listConfig.clipBehavior,
      itemCount: _totalGroupedItemCount(groups.order, groups.map),
      itemBuilder: (context, flatIndex) {
        return _groupedItemBuilder(
          context,
          flatIndex,
          groups.order,
          groups.map,
          searchTerms,
        );
      },
    );
  }

  int _totalGroupedItemCount(
    List<Object> groupOrder,
    Map<Object, List<IndexedItem<T>>> groupMap,
  ) {
    int count = 0;
    for (final key in groupOrder) {
      count += 1 + groupMap[key]!.length; // 1 header + items
    }
    if (controller.isLoadingMore) count += 1;
    return count;
  }

  Widget _groupedItemBuilder(
    BuildContext context,
    int flatIndex,
    List<Object> groupOrder,
    Map<Object, List<IndexedItem<T>>> groupMap,
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
        return buildItem(context, indexed.index, searchTerms);
      }
      current += groupItems.length;
    }

    // Loading more indicator at bottom
    return const DefaultLoadMoreWidget();
  }
}
