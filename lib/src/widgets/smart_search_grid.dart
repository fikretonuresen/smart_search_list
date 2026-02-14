import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../core/smart_search_controller.dart';
import '../models/accessibility_configuration.dart';
import '../models/grid_configuration.dart';
import '../models/search_configuration.dart';
import 'default_widgets.dart';
import 'sliver_smart_search_grid.dart';
import 'smart_search_state.dart';

/// A highly customizable searchable grid widget.
///
/// Displays items in a grid layout with search, filter, sort, and pagination
/// capabilities. Parallel to [SmartSearchList] but renders items in a grid
/// layout instead of a list.
///
/// Three constructors target different use cases:
/// - [SmartSearchGrid.new] — offline mode with client-side search.
/// - [SmartSearchGrid.async] — async mode where the server handles search.
/// - [SmartSearchGrid.controller] — fully controller-driven rendering.
///
/// This widget uses a [Column] with [Expanded] internally, so it must receive
/// a bounded height constraint from its parent. Do not place it inside a
/// [ListView] or [SingleChildScrollView] — use [SliverSmartSearchGrid] for
/// [CustomScrollView] integration instead.
///
/// Example (offline):
/// ```dart
/// SmartSearchGrid<Product>(
///   items: products,
///   searchableFields: (p) => [p.name, p.category],
///   itemBuilder: (context, product, index, {searchTerms = const []}) {
///     return ProductCard(product: product);
///   },
///   gridConfig: GridConfiguration(
///     gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
///       crossAxisCount: 2,
///       childAspectRatio: 0.7,
///     ),
///   ),
/// )
/// ```
class SmartSearchGrid<T extends Object> extends SmartSearchWidgetBase<T> {
  /// Builder for a custom search field. If null, [DefaultSearchField] is used.
  final SearchFieldBuilder? searchFieldBuilder;

  /// Builder for sort controls.
  final SortBuilder<T>? sortBuilder;

  /// Builder for filter controls.
  final FilterBuilder<T>? filterBuilder;

  /// Builder for an inline progress indicator shown during async operations.
  ///
  /// Rendered between the search field (and [belowSearchWidget]) and the grid.
  /// Receives the current loading state so you can show/hide a progress bar,
  /// shimmer, etc. Return [SizedBox.shrink] when not loading.
  final ProgressIndicatorBuilder? progressIndicatorBuilder;

  /// Called on pull-to-refresh.
  ///
  /// **Not available on [SliverSmartSearchGrid].** For pull-to-refresh in a
  /// [CustomScrollView], wrap it with a [RefreshIndicator] and call
  /// [SmartSearchController.refresh] directly.
  final VoidCallback? onRefresh;

  /// Widget to display below search field (for filters, chips, etc.).
  final Widget? belowSearchWidget;

  /// Scroll controller.
  final ScrollController? scrollController;

  /// Grid appearance configuration (delegate, scroll physics, padding, etc.).
  final GridConfiguration gridConfig;

  // Private constructor — all mode-specific fields are nullable.
  const SmartSearchGrid._({
    super.key,
    super.items,
    super.asyncLoader,
    super.searchableFields,
    required super.itemBuilder,
    super.controller,
    this.searchFieldBuilder,
    super.loadingStateBuilder,
    super.errorStateBuilder,
    super.emptyStateBuilder,
    super.emptySearchStateBuilder,
    this.sortBuilder,
    this.filterBuilder,
    this.progressIndicatorBuilder,
    super.searchConfig,
    required this.gridConfig,
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

  /// Creates an offline searchable grid with client-side search.
  ///
  /// Provide [items] as the data source and [searchableFields] to define which
  /// text fields are matched during search. The widget creates and manages its
  /// own [SmartSearchController] internally.
  ///
  /// To drive search, filter, and sort programmatically via an external
  /// controller, use [SmartSearchGrid.controller] instead.
  const SmartSearchGrid({
    Key? key,
    required List<T> items,
    required List<String> Function(T item) searchableFields,
    required ItemBuilder<T> itemBuilder,
    required GridConfiguration gridConfig,
    SearchFieldBuilder? searchFieldBuilder,
    LoadingStateBuilder? loadingStateBuilder,
    ErrorStateBuilder? errorStateBuilder,
    EmptyStateBuilder? emptyStateBuilder,
    EmptySearchStateBuilder? emptySearchStateBuilder,
    SortBuilder<T>? sortBuilder,
    FilterBuilder<T>? filterBuilder,
    ProgressIndicatorBuilder? progressIndicatorBuilder,
    SearchConfiguration searchConfig = const SearchConfiguration(),
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
         gridConfig: gridConfig,
         searchFieldBuilder: searchFieldBuilder,
         loadingStateBuilder: loadingStateBuilder,
         errorStateBuilder: errorStateBuilder,
         emptyStateBuilder: emptyStateBuilder,
         emptySearchStateBuilder: emptySearchStateBuilder,
         sortBuilder: sortBuilder,
         filterBuilder: filterBuilder,
         progressIndicatorBuilder: progressIndicatorBuilder,
         searchConfig: searchConfig,
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

  /// Creates an async searchable grid that loads data from a remote source.
  ///
  /// The [asyncLoader] is called with a search query, page index (zero-based),
  /// and page size. It is called with an empty string on initial load — handle
  /// `''` as "load all".
  ///
  /// Search matching is delegated to the server; [searchableFields] is not
  /// accepted. The widget creates and manages its own [SmartSearchController]
  /// internally.
  const SmartSearchGrid.async({
    Key? key,
    required Future<List<T>> Function(String query, {int page, int pageSize})
    asyncLoader,
    required ItemBuilder<T> itemBuilder,
    required GridConfiguration gridConfig,
    SearchFieldBuilder? searchFieldBuilder,
    LoadingStateBuilder? loadingStateBuilder,
    ErrorStateBuilder? errorStateBuilder,
    EmptyStateBuilder? emptyStateBuilder,
    EmptySearchStateBuilder? emptySearchStateBuilder,
    SortBuilder<T>? sortBuilder,
    FilterBuilder<T>? filterBuilder,
    ProgressIndicatorBuilder? progressIndicatorBuilder,
    SearchConfiguration searchConfig = const SearchConfiguration(),
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
         gridConfig: gridConfig,
         searchFieldBuilder: searchFieldBuilder,
         loadingStateBuilder: loadingStateBuilder,
         errorStateBuilder: errorStateBuilder,
         emptyStateBuilder: emptyStateBuilder,
         emptySearchStateBuilder: emptySearchStateBuilder,
         sortBuilder: sortBuilder,
         filterBuilder: filterBuilder,
         progressIndicatorBuilder: progressIndicatorBuilder,
         searchConfig: searchConfig,
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

  /// Creates a searchable grid driven entirely by an external [controller].
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
  const SmartSearchGrid.controller({
    Key? key,
    required SmartSearchController<T> controller,
    required ItemBuilder<T> itemBuilder,
    required GridConfiguration gridConfig,
    SearchFieldBuilder? searchFieldBuilder,
    LoadingStateBuilder? loadingStateBuilder,
    ErrorStateBuilder? errorStateBuilder,
    EmptyStateBuilder? emptyStateBuilder,
    EmptySearchStateBuilder? emptySearchStateBuilder,
    SortBuilder<T>? sortBuilder,
    FilterBuilder<T>? filterBuilder,
    ProgressIndicatorBuilder? progressIndicatorBuilder,
    SearchConfiguration searchConfig = const SearchConfiguration(),
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
         gridConfig: gridConfig,
         searchFieldBuilder: searchFieldBuilder,
         loadingStateBuilder: loadingStateBuilder,
         errorStateBuilder: errorStateBuilder,
         emptyStateBuilder: emptyStateBuilder,
         emptySearchStateBuilder: emptySearchStateBuilder,
         sortBuilder: sortBuilder,
         filterBuilder: filterBuilder,
         progressIndicatorBuilder: progressIndicatorBuilder,
         searchConfig: searchConfig,
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
  State<SmartSearchGrid<T>> createState() => _SmartSearchGridState<T>();
}

class _SmartSearchGridState<T extends Object> extends State<SmartSearchGrid<T>>
    with SmartSearchStateMixin<T, SmartSearchGrid<T>> {
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
  void didUpdateWidget(covariant SmartSearchGrid<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Mixin: config updates
    updateControllerConfig(oldWidget);

    // Scroll controller swap
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
    _searchTextController.removeListener(_onSearchTextChanged);

    _scrollController.removeListener(_onScroll);
    _scrollController.removeListener(_handleKeyboardOnScroll);

    if (_scrollControllerCreatedInternally) {
      _scrollController.dispose();
    }

    _searchTextController.dispose();
    _focusNode.dispose();

    // Mixin: controller cleanup
    disposeController();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Column(
          children: [
            if (widget.searchConfig.enabled) _buildSearchField(),
            if (widget.belowSearchWidget != null) widget.belowSearchWidget!,
            if (widget.progressIndicatorBuilder != null)
              widget.progressIndicatorBuilder!(
                context,
                controller.isLoading || controller.isLoadingMore,
              ),
            if (widget.sortBuilder != null || widget.filterBuilder != null)
              _buildControls(),
            Expanded(child: _buildGrid()),
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

  Widget _buildGrid() {
    final stateWidget = buildStateWidget(context);
    if (stateWidget != null) return stateWidget;

    Widget gridWidget = _buildGridView();

    if (widget.gridConfig.pullToRefresh) {
      gridWidget = RefreshIndicator(
        onRefresh: _handleRefresh,
        child: gridWidget,
      );
    }

    return gridWidget;
  }

  /// Builds the grid content as a [CustomScrollView] with sliver children.
  ///
  /// Using slivers internally (rather than [GridView.builder]) lets the
  /// load-more indicator span the full width below the grid rows instead
  /// of occupying a single grid cell. The same approach is used for grouped
  /// grids, keeping the architecture consistent with [SliverSmartSearchGrid].
  Widget _buildGridView() {
    final searchTerms = computeSearchTerms();
    final slivers = <Widget>[];

    if (widget.groupBy != null) {
      _addGroupedSlivers(slivers, searchTerms);
    } else {
      slivers.add(_buildGridSliver(searchTerms));
    }

    if (controller.isLoadingMore) {
      slivers.add(const SliverToBoxAdapter(child: DefaultLoadMoreWidget()));
    }

    return CustomScrollView(
      controller: _scrollController,
      physics: widget.gridConfig.physics,
      shrinkWrap: widget.gridConfig.shrinkWrap,
      reverse: widget.gridConfig.reverse,
      scrollDirection: widget.gridConfig.scrollDirection,
      cacheExtent: widget.gridConfig.cacheExtent,
      clipBehavior: widget.gridConfig.clipBehavior,
      slivers: slivers,
    );
  }

  /// Builds the flat (non-grouped) grid as a [SliverGrid], optionally wrapped
  /// in [SliverPadding], with an optional [SliverToBoxAdapter] for the
  /// load-more indicator. Mirrors [SliverSmartSearchGrid._buildSliverGrid].
  Widget _buildGridSliver(List<String> searchTerms) {
    final sliver = SliverGrid(
      gridDelegate: widget.gridConfig.gridDelegate,
      delegate: SliverChildBuilderDelegate(
        (context, index) => buildItem(context, index, searchTerms),
        childCount: controller.items.length,
        addAutomaticKeepAlives: widget.gridConfig.addAutomaticKeepAlives,
        addRepaintBoundaries: widget.gridConfig.addRepaintBoundaries,
        addSemanticIndexes: widget.gridConfig.addSemanticIndexes,
      ),
    );

    if (widget.gridConfig.padding != null) {
      return SliverPadding(padding: widget.gridConfig.padding!, sliver: sliver);
    }

    return sliver;
  }

  void _addGroupedSlivers(List<Widget> slivers, List<String> searchTerms) {
    final groups = computeGroups();

    for (final key in groups.order) {
      final groupItems = groups.map[key]!;

      slivers.add(
        SliverToBoxAdapter(
          child:
              widget.groupHeaderBuilder?.call(
                context,
                key,
                groupItems.length,
              ) ??
              DefaultGroupHeader(groupValue: key, itemCount: groupItems.length),
        ),
      );

      final gridSliver = SliverGrid(
        gridDelegate: widget.gridConfig.gridDelegate,
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final indexed = groupItems[index];
            return buildItem(context, indexed.index, searchTerms);
          },
          childCount: groupItems.length,
          addAutomaticKeepAlives: widget.gridConfig.addAutomaticKeepAlives,
          addRepaintBoundaries: widget.gridConfig.addRepaintBoundaries,
          addSemanticIndexes: widget.gridConfig.addSemanticIndexes,
        ),
      );

      if (widget.gridConfig.padding != null) {
        slivers.add(
          SliverPadding(
            padding: widget.gridConfig.padding!,
            sliver: gridSliver,
          ),
        );
      } else {
        slivers.add(gridSliver);
      }
    }
  }
}
