import 'package:flutter/material.dart';
import '../core/smart_search_controller.dart';
import '../models/accessibility_configuration.dart';
import '../models/search_configuration.dart';
import 'default_widgets.dart';

/// A sliver version of SmartSearchList for use in CustomScrollView
///
/// Provides the same search, filter, sort, and pagination capabilities
/// but returns slivers for use in CustomScrollView.
///
/// Example:
/// ```dart
/// CustomScrollView(
///   slivers: [
///     SliverAppBar(title: Text('My List')),
///     SliverSmartSearchList<String>(
///       items: ['Apple', 'Banana', 'Cherry'],
///       searchableFields: (item) => [item],
///       itemBuilder: (context, item, index) => ListTile(title: Text(item)),
///     ),
///   ],
/// )
/// ```
class SliverSmartSearchList<T extends Object> extends StatefulWidget {
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
  final LoadingStateBuilder? loadingStateBuilder;
  final ErrorStateBuilder? errorStateBuilder;
  final EmptyStateBuilder? emptyStateBuilder;
  final EmptySearchStateBuilder? emptySearchStateBuilder;

  /// Configuration objects
  final SearchConfiguration searchConfig;
  final ListConfiguration listConfig;
  final PaginationConfiguration? paginationConfig;

  /// Callbacks
  final void Function(T item, int index)? onItemTap;
  final void Function(String query)? onSearchChanged;
  final VoidCallback? onRefresh;

  /// Performance options
  final bool cacheResults;
  final int maxCacheSize;

  /// Multi-select configuration. When non-null, multi-select mode is enabled.
  final SelectionConfiguration? selectionConfig;

  /// Called when selection changes (multi-select mode)
  final void Function(Set<T> selectedItems)? onSelectionChanged;

  /// Groups items by the returned value. When non-null, items are displayed
  /// in sections with sticky headers using SliverMainAxisGroup.
  final Object Function(T item)? groupBy;

  /// Builder for group section headers. If null, [DefaultGroupHeader] is used.
  final GroupHeaderBuilder? groupHeaderBuilder;

  /// Comparator for ordering groups. If null, groups appear in insertion order.
  final Comparator<Object>? groupComparator;

  /// Maximum extent for sticky group headers (default: 48.0)
  final double groupHeaderExtent;

  /// Accessibility configuration for screen reader semantics.
  final AccessibilityConfiguration accessibilityConfig;

  const SliverSmartSearchList({
    super.key,
    this.items,
    this.asyncLoader,
    required this.searchableFields,
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
  })  : assert(
          items == null || asyncLoader == null,
          'Provide either items OR asyncLoader, not both',
        ),
        assert(
          items != null || asyncLoader != null || controller != null,
          'Provide items, asyncLoader, or a controller',
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

    // Listen to controller changes
    _controller.addListener(_onControllerChanged);

    // Initialize data
    _initializeData();
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

  /// Compute search terms once per build for highlighting
  List<String> get _searchTerms =>
      _controller.searchQuery.split(' ').where((s) => s.isNotEmpty).toList();

  Widget _buildSliver() {
    // Handle loading state (initial load)
    if (_controller.isLoading && _controller.items.isEmpty) {
      return SliverFillRemaining(
        child: widget.loadingStateBuilder?.call(context) ??
            const DefaultLoadingWidget(),
      );
    }

    // Handle error state
    if (_controller.error != null) {
      return SliverFillRemaining(
        child: widget.errorStateBuilder?.call(
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
          child: widget.emptySearchStateBuilder?.call(
                context,
                _controller.searchQuery,
              ) ??
              DefaultEmptySearchWidget(
                searchQuery: _controller.searchQuery,
              ),
        );
      }
      // Initial empty state (no data)
      else {
        return SliverFillRemaining(
          child: widget.emptyStateBuilder?.call(context) ??
              const DefaultEmptyWidget(),
        );
      }
    }

    // Build the main list with optional live region
    final listSliver =
        widget.groupBy != null ? _buildGroupedSlivers() : _buildSliverList();

    if (!widget.accessibilityConfig.searchSemanticsEnabled) {
      return listSliver;
    }

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(child: _buildLiveRegion()),
        listSliver,
      ],
    );
  }

  Widget _buildLiveRegion() {
    final count = _controller.items.length;
    final isSearchActive = _controller.hasSearched && !_controller.isLoading;

    String announcement;
    if (!isSearchActive) {
      announcement = '';
    } else if (count != _lastAnnouncedCount) {
      _lastAnnouncedCount = count;
      announcement = widget.accessibilityConfig.buildResultsAnnouncement(count);
    } else {
      announcement = widget.accessibilityConfig.buildResultsAnnouncement(count);
    }

    return Semantics(
      liveRegion: true,
      label: announcement,
      child: const SizedBox.shrink(),
    );
  }

  Widget _buildSliverList() {
    final itemCount = _controller.isLoadingMore
        ? _controller.items.length + 1
        : _controller.items.length;

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        _itemBuilder,
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
                child: widget.groupHeaderBuilder
                        ?.call(context, key, groupItems.length) ??
                    DefaultGroupHeader(
                        groupValue: key, itemCount: groupItems.length),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final indexed = groupItems[index];
                  return _itemBuilder(context, indexed.index);
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
      slivers.add(
        const SliverToBoxAdapter(child: DefaultLoadMoreWidget()),
      );
    }

    // MultiSliver requires returning a single widget. Use SliverMainAxisGroup
    // to wrap multiple groups, or return them via a helper.
    // Since build() already returns a single Widget, we need a wrapper.
    return SliverMainAxisGroup(slivers: slivers);
  }

  Widget _itemBuilder(BuildContext context, int index) {
    // Handle loading more indicator
    if (index >= _controller.items.length) {
      return const DefaultLoadMoreWidget();
    }

    final item = _controller.items[index];

    Widget itemWidget = widget.itemBuilder(
      context,
      item,
      index,
      searchTerms: _searchTerms,
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
            children: [checkbox, Expanded(child: itemWidget)],
          );
        } else {
          itemWidget = Row(
            children: [Expanded(child: itemWidget), checkbox],
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

/// Internal helper for tracking original index in grouped sliver views
class _SliverIndexedItem<T> {
  final T item;
  final int index;
  const _SliverIndexedItem(this.item, this.index);
}

/// Delegate for sticky group headers in sliver grouped lists
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
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _GroupHeaderDelegate oldDelegate) {
    return child != oldDelegate.child ||
        maxExtent != oldDelegate.maxExtent ||
        minExtent != oldDelegate.minExtent;
  }
}
