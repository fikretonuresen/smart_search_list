import 'package:flutter/material.dart';
import '../core/smart_search_controller.dart';
import '../models/accessibility_configuration.dart';
import '../models/search_configuration.dart';
import 'default_widgets.dart';
import 'smart_search_list.dart';
import 'smart_search_state.dart';

/// A sliver version of [SmartSearchList] for use in [CustomScrollView].
///
/// Emits slivers instead of managing its own scroll view, so it can be
/// composed with other slivers (e.g. [SliverAppBar]) inside a
/// [CustomScrollView].
///
/// Unlike [SmartSearchList], this widget does **not** use a [Column] with
/// [Flexible] and does **not** include a built-in search field, sort/filter
/// builders, separator builder, progress indicator builder, or scroll
/// controller. The parent [CustomScrollView] (or a companion sliver) should
/// provide the search input and drive the [SmartSearchController] externally.
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
class SliverSmartSearchList<T extends Object> extends SmartSearchWidgetBase<T> {
  /// List appearance configuration (scroll physics, padding, etc.).
  final ListConfiguration listConfig;

  /// Fixed extent for sticky group headers (default: 48.0).
  ///
  /// This value is used as both `maxExtent` and `minExtent` in the underlying
  /// [SliverPersistentHeaderDelegate], so the header does not shrink or grow
  /// during scrolling.
  final double groupHeaderExtent;

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
    this.listConfig = const ListConfiguration(),
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
    extends State<SliverSmartSearchList<T>>
    with SmartSearchStateMixin<T, SliverSmartSearchList<T>> {
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
  void didUpdateWidget(covariant SliverSmartSearchList<T> oldWidget) {
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
    // No scroll listeners to remove — the parent CustomScrollView owns
    // the scroll controller (contrast with SmartSearchList.dispose).
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
    // Mixin: check loading/error/empty states
    final stateWidget = buildStateWidget(context);
    if (stateWidget != null) {
      return SliverFillRemaining(child: stateWidget);
    }

    return widget.groupBy != null ? _buildGroupedSlivers() : _buildSliverList();
  }

  Widget _buildSliverList() {
    final itemCount = controller.isLoadingMore
        ? controller.items.length + 1
        : controller.items.length;

    final searchTerms = computeSearchTerms();

    Widget sliverList = SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => buildItem(context, index, searchTerms),
        childCount: itemCount,
        addAutomaticKeepAlives: widget.listConfig.addAutomaticKeepAlives,
        addRepaintBoundaries: widget.listConfig.addRepaintBoundaries,
        addSemanticIndexes: widget.listConfig.addSemanticIndexes,
      ),
    );

    if (widget.listConfig.padding != null) {
      sliverList = SliverPadding(
        padding: widget.listConfig.padding!,
        sliver: sliverList,
      );
    }

    return sliverList;
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
            _buildGroupListSliver(groupItems, searchTerms),
          ],
        ),
      );
    }

    // Loading more indicator
    if (controller.isLoadingMore) {
      slivers.add(const SliverToBoxAdapter(child: DefaultLoadMoreWidget()));
    }

    // build() must return a single Widget, so wrap all group slivers in a
    // SliverMainAxisGroup.
    return SliverMainAxisGroup(slivers: slivers);
  }

  /// Builds a per-group [SliverList], optionally wrapped in [SliverPadding].
  /// Mirrors [SliverSmartSearchGrid._buildGroupGrid] padding logic.
  Widget _buildGroupListSliver(
    List<IndexedItem<T>> groupItems,
    List<String> searchTerms,
  ) {
    Widget listSliver = SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final indexed = groupItems[index];
          return buildItem(context, indexed.index, searchTerms);
        },
        childCount: groupItems.length,
        addAutomaticKeepAlives: widget.listConfig.addAutomaticKeepAlives,
        addRepaintBoundaries: widget.listConfig.addRepaintBoundaries,
        addSemanticIndexes: widget.listConfig.addSemanticIndexes,
      ),
    );

    if (widget.listConfig.padding != null) {
      listSliver = SliverPadding(
        padding: widget.listConfig.padding!,
        sliver: listSliver,
      );
    }

    return listSliver;
  }
}
