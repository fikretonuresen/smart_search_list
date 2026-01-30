import 'package:flutter/material.dart';
import '../core/smart_search_controller.dart';
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
  final LoadingBuilder? loadingBuilder;
  final ErrorBuilder? errorBuilder;
  final EmptyBuilder? emptyBuilder;
  final EmptySearchBuilder? emptySearchBuilder;

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

  const SliverSmartSearchList({
    super.key,
    this.items,
    this.asyncLoader,
    required this.searchableFields,
    required this.itemBuilder,
    this.controller,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
    this.emptySearchBuilder,
    this.searchConfig = const SearchConfiguration(),
    this.listConfig = const ListConfiguration(),
    this.paginationConfig,
    this.onItemTap,
    this.onSearchChanged,
    this.onRefresh,
    this.cacheResults = true,
    this.maxCacheSize = 100,
  }) : assert(
          (items != null && asyncLoader == null) ||
              (items == null && asyncLoader != null),
          'Provide either items OR asyncLoader, not both',
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

  @override
  void dispose() {
    _isDisposed = true;

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
        return _buildSliver();
      },
    );
  }

  Widget _buildSliver() {
    // Handle loading state (initial load)
    if (_controller.isLoading && _controller.items.isEmpty) {
      return SliverFillRemaining(
        child: widget.loadingBuilder?.call(context) ??
            const DefaultLoadingWidget(),
      );
    }

    // Handle error state
    if (_controller.error != null) {
      return SliverFillRemaining(
        child: widget.errorBuilder?.call(
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
          child: widget.emptySearchBuilder?.call(
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
          child:
              widget.emptyBuilder?.call(context) ?? const DefaultEmptyWidget(),
        );
      }
    }

    // Build the main list
    return _buildSliverList();
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

  Widget _itemBuilder(BuildContext context, int index) {
    // Handle loading more indicator
    if (index >= _controller.items.length) {
      return const DefaultLoadMoreWidget();
    }

    final item = _controller.items[index];

    Widget itemWidget = widget.itemBuilder(context, item, index);

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
