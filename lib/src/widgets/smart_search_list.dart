import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../core/smart_search_controller.dart';
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
///   itemBuilder: (context, item, index) => ListTile(title: Text(item)),
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
  final LoadingBuilder? loadingBuilder;
  final ErrorBuilder? errorBuilder;
  final EmptyBuilder? emptyBuilder;
  final EmptySearchBuilder? emptySearchBuilder;
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

  /// Widget to display below search field (for filters, chips, etc)
  final Widget? belowSearchWidget;

  /// Scroll controller
  final ScrollController? scrollController;

  /// Performance options
  final bool cacheResults;
  final int maxCacheSize;

  const SmartSearchList({
    super.key,
    this.items,
    this.asyncLoader,
    required this.searchableFields,
    required this.itemBuilder,
    this.controller,
    this.searchFieldBuilder,
    this.separatorBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
    this.emptySearchBuilder,
    this.sortBuilder,
    this.filterBuilder,
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

    // Initialize data
    _initializeData();
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
    _controller.search(query);
    widget.onSearchChanged?.call(query);
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
    );
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
      return widget.loadingBuilder?.call(context) ??
          const DefaultLoadingWidget();
    }

    // Handle error state
    if (_controller.error != null) {
      return widget.errorBuilder?.call(
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
        return widget.emptySearchBuilder?.call(
              context,
              _controller.searchQuery,
            ) ??
            DefaultEmptySearchWidget(
              searchQuery: _controller.searchQuery,
            );
      }
      // Initial empty state (no data)
      else {
        return widget.emptyBuilder?.call(context) ?? const DefaultEmptyWidget();
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
    final itemCount = _controller.isLoadingMore
        ? _controller.items.length + 1
        : _controller.items.length;

    // Compute search terms once for all items
    final searchTerms =
        _controller.searchQuery.split(' ').where((s) => s.isNotEmpty).toList();

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

  Widget _itemBuilder(
      BuildContext context, int index, List<String> searchTerms) {
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
