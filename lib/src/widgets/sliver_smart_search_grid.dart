import 'package:flutter/material.dart';
import '../core/smart_search_controller.dart';
import '../models/accessibility_configuration.dart';
import '../models/grid_configuration.dart';
import '../models/search_configuration.dart';
import 'default_widgets.dart';
import 'smart_search_grid.dart';
import 'smart_search_state.dart';

/// A sliver version of [SmartSearchGrid] for use in [CustomScrollView].
///
/// Emits slivers instead of managing its own scroll view, so it can be
/// composed with other slivers (e.g. [SliverAppBar]) inside a
/// [CustomScrollView].
///
/// Unlike [SmartSearchGrid], this widget does **not** include a built-in
/// search field, sort/filter builders, progress indicator builder, or scroll
/// controller. The parent [CustomScrollView] (or a companion sliver) should
/// provide the search input and drive the [SmartSearchController] externally.
///
/// Three constructors target different use cases:
/// - [SliverSmartSearchGrid.new] — offline mode with client-side search.
/// - [SliverSmartSearchGrid.async] — async mode where the server handles search.
/// - [SliverSmartSearchGrid.controller] — fully controller-driven rendering.
///
/// Example (offline):
/// ```dart
/// CustomScrollView(
///   slivers: [
///     SliverAppBar(title: Text('My Grid')),
///     SliverSmartSearchGrid<String>(
///       items: ['Apple', 'Banana', 'Cherry'],
///       searchableFields: (item) => [item],
///       itemBuilder: (context, item, index, {searchTerms = const []}) =>
///           Card(child: Center(child: Text(item))),
///       gridConfig: GridConfiguration(
///         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
///           crossAxisCount: 2,
///         ),
///       ),
///     ),
///   ],
/// )
/// ```
class SliverSmartSearchGrid<T extends Object> extends SmartSearchWidgetBase<T> {
  /// Grid appearance configuration (delegate, scroll physics, padding, etc.).
  final GridConfiguration gridConfig;

  /// Fixed extent for sticky group headers (default: 48.0).
  ///
  /// This value is used as both `maxExtent` and `minExtent` in the underlying
  /// [SliverPersistentHeaderDelegate], so the header does not shrink or grow
  /// during scrolling.
  final double groupHeaderExtent;

  // Private constructor — all mode-specific fields are nullable.
  const SliverSmartSearchGrid._({
    super.key,
    super.items,
    super.asyncLoader,
    super.searchableFields,
    required super.itemBuilder,
    super.controller,
    super.loadingStateBuilder,
    super.errorStateBuilder,
    super.emptyStateBuilder,
    super.emptySearchStateBuilder,
    super.searchConfig,
    required this.gridConfig,
    super.paginationConfig,
    super.onItemTap,
    super.onSearchChanged,
    super.cacheResults,
    super.maxCacheSize,
    super.selectionConfig,
    super.onSelectionChanged,
    super.groupBy,
    super.groupHeaderBuilder,
    super.groupComparator,
    this.groupHeaderExtent = 48.0,
    super.accessibilityConfig,
  });

  /// Creates an offline sliver searchable grid with client-side search.
  ///
  /// Provide [items] as the data source and [searchableFields] to define which
  /// text fields are matched during search. The widget creates and manages its
  /// own [SmartSearchController] internally.
  const SliverSmartSearchGrid({
    Key? key,
    required List<T> items,
    required List<String> Function(T item) searchableFields,
    required ItemBuilder<T> itemBuilder,
    required GridConfiguration gridConfig,
    LoadingStateBuilder? loadingStateBuilder,
    ErrorStateBuilder? errorStateBuilder,
    EmptyStateBuilder? emptyStateBuilder,
    EmptySearchStateBuilder? emptySearchStateBuilder,
    SearchConfiguration searchConfig = const SearchConfiguration(),
    PaginationConfiguration? paginationConfig,
    void Function(T item, int index)? onItemTap,
    void Function(String query)? onSearchChanged,
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
         gridConfig: gridConfig,
         loadingStateBuilder: loadingStateBuilder,
         errorStateBuilder: errorStateBuilder,
         emptyStateBuilder: emptyStateBuilder,
         emptySearchStateBuilder: emptySearchStateBuilder,
         searchConfig: searchConfig,
         paginationConfig: paginationConfig,
         onItemTap: onItemTap,
         onSearchChanged: onSearchChanged,
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

  /// Creates an async sliver searchable grid that loads data from a remote source.
  ///
  /// The [asyncLoader] is called with a search query, page index (zero-based),
  /// and page size. Search matching is delegated to the server;
  /// [searchableFields] is not accepted.
  const SliverSmartSearchGrid.async({
    Key? key,
    required Future<List<T>> Function(String query, {int page, int pageSize})
    asyncLoader,
    required ItemBuilder<T> itemBuilder,
    required GridConfiguration gridConfig,
    LoadingStateBuilder? loadingStateBuilder,
    ErrorStateBuilder? errorStateBuilder,
    EmptyStateBuilder? emptyStateBuilder,
    EmptySearchStateBuilder? emptySearchStateBuilder,
    SearchConfiguration searchConfig = const SearchConfiguration(),
    PaginationConfiguration? paginationConfig,
    void Function(T item, int index)? onItemTap,
    void Function(String query)? onSearchChanged,
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
         gridConfig: gridConfig,
         loadingStateBuilder: loadingStateBuilder,
         errorStateBuilder: errorStateBuilder,
         emptyStateBuilder: emptyStateBuilder,
         emptySearchStateBuilder: emptySearchStateBuilder,
         searchConfig: searchConfig,
         paginationConfig: paginationConfig,
         onItemTap: onItemTap,
         onSearchChanged: onSearchChanged,
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

  /// Creates a sliver searchable grid driven entirely by an external [controller].
  ///
  /// The controller is responsible for providing data (via
  /// [SmartSearchController.setItems] or [SmartSearchController.setAsyncLoader]).
  /// The widget renders whatever the controller provides.
  ///
  /// You are responsible for disposing the controller.
  const SliverSmartSearchGrid.controller({
    Key? key,
    required SmartSearchController<T> controller,
    required ItemBuilder<T> itemBuilder,
    required GridConfiguration gridConfig,
    LoadingStateBuilder? loadingStateBuilder,
    ErrorStateBuilder? errorStateBuilder,
    EmptyStateBuilder? emptyStateBuilder,
    EmptySearchStateBuilder? emptySearchStateBuilder,
    SearchConfiguration searchConfig = const SearchConfiguration(),
    PaginationConfiguration? paginationConfig,
    void Function(T item, int index)? onItemTap,
    void Function(String query)? onSearchChanged,
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
         gridConfig: gridConfig,
         loadingStateBuilder: loadingStateBuilder,
         errorStateBuilder: errorStateBuilder,
         emptyStateBuilder: emptyStateBuilder,
         emptySearchStateBuilder: emptySearchStateBuilder,
         searchConfig: searchConfig,
         paginationConfig: paginationConfig,
         onItemTap: onItemTap,
         onSearchChanged: onSearchChanged,
         selectionConfig: selectionConfig,
         onSelectionChanged: onSelectionChanged,
         groupBy: groupBy,
         groupHeaderBuilder: groupHeaderBuilder,
         groupComparator: groupComparator,
         groupHeaderExtent: groupHeaderExtent,
         accessibilityConfig: accessibilityConfig,
       );

  @override
  State<SliverSmartSearchGrid<T>> createState() =>
      _SliverSmartSearchGridState<T>();
}

class _SliverSmartSearchGridState<T extends Object>
    extends State<SliverSmartSearchGrid<T>>
    with SmartSearchStateMixin<T, SliverSmartSearchGrid<T>> {
  /// Tracks the last query value to detect changes and fire [onSearchChanged].
  String _lastSearchQuery = '';

  @override
  void initState() {
    super.initState();

    // Mixin: controller + a11y listener
    initController();

    _lastSearchQuery = controller.searchQuery;

    // Listen to controller changes (setState-based rebuild for slivers)
    controller.addListener(_onControllerChanged);

    // Mixin: data init
    initializeData();
  }

  @override
  void didUpdateWidget(covariant SliverSmartSearchGrid<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Mixin: config updates
    updateControllerConfig(oldWidget);

    // Mixin: controller swap with widget-specific listener management
    handleControllerSwap(
      oldWidget,
      onDetach: () {
        controller.removeListener(_onControllerChanged);
      },
      onAttach: () {
        _lastSearchQuery = controller.searchQuery;
        controller.addListener(_onControllerChanged);
      },
    );
    handleAccessibilityToggle(oldWidget);
  }

  void _onControllerChanged() {
    if (!isDisposed && mounted) {
      final currentQuery = controller.searchQuery;
      final queryChanged = currentQuery != _lastSearchQuery;
      if (queryChanged) {
        _lastSearchQuery = currentQuery;
      }
      setState(() {});
      if (queryChanged) {
        widget.onSearchChanged?.call(currentQuery);
      }
    }
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);

    // Mixin: controller cleanup
    disposeController();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildSliver();
  }

  Widget _buildSliver() {
    final stateWidget = buildStateWidget(context);
    if (stateWidget != null) {
      return SliverFillRemaining(child: stateWidget);
    }

    return widget.groupBy != null ? _buildGroupedSlivers() : _buildSliverGrid();
  }

  /// Builds the flat (non-grouped) grid as a [SliverGrid], optionally wrapped
  /// in [SliverPadding], with an optional [SliverToBoxAdapter] for the
  /// load-more indicator. Mirrors [SmartSearchGrid._buildGridSliver].
  Widget _buildSliverGrid() {
    final searchTerms = computeSearchTerms();

    Widget sliverGrid = SliverGrid(
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
      sliverGrid = SliverPadding(
        padding: widget.gridConfig.padding!,
        sliver: sliverGrid,
      );
    }

    if (!controller.isLoadingMore) return sliverGrid;

    return SliverMainAxisGroup(
      slivers: [
        sliverGrid,
        const SliverToBoxAdapter(child: DefaultLoadMoreWidget()),
      ],
    );
  }

  Widget _buildGroupedSlivers() {
    final searchTerms = computeSearchTerms();
    final groups = computeGroups();

    final slivers = <Widget>[];

    for (final key in groups.order) {
      final groupItems = groups.map[key]!;
      slivers.add(
        SliverMainAxisGroup(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: GroupHeaderDelegate(
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
            _buildGroupGrid(groupItems, searchTerms),
          ],
        ),
      );
    }

    if (controller.isLoadingMore) {
      slivers.add(const SliverToBoxAdapter(child: DefaultLoadMoreWidget()));
    }

    return SliverMainAxisGroup(slivers: slivers);
  }

  /// Builds a per-group [SliverGrid], optionally wrapped in [SliverPadding].
  /// Mirrors [SmartSearchGrid._addGroupedSlivers] padding logic.
  Widget _buildGroupGrid(
    List<IndexedItem<T>> groupItems,
    List<String> searchTerms,
  ) {
    Widget gridSliver = SliverGrid(
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
      gridSliver = SliverPadding(
        padding: widget.gridConfig.padding!,
        sliver: gridSliver,
      );
    }

    return gridSliver;
  }
}
