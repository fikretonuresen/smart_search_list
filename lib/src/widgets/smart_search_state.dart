import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import '../core/smart_search_controller.dart';
import '../models/accessibility_configuration.dart';
import '../models/search_configuration.dart';
import 'default_widgets.dart';

/// Abstract base class for all Smart Search widgets.
///
/// Holds the fields shared across [SmartSearchList], [SliverSmartSearchList],
/// [SmartSearchGrid], and [SliverSmartSearchGrid]. Concrete subclasses add
/// layout-specific parameters (e.g. [ListConfiguration], [GridConfiguration]).
abstract class SmartSearchWidgetBase<T extends Object> extends StatefulWidget {
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

  /// Builds each item in the list or grid.
  final ItemBuilder<T> itemBuilder;

  /// Optional external controller. When provided, you are responsible for
  /// disposing it — the widget only disposes controllers it creates internally.
  final SmartSearchController<T>? controller;

  /// Builder for the loading state shown while data is loading.
  final LoadingStateBuilder? loadingStateBuilder;

  /// Builder for the error state shown when loading fails.
  final ErrorStateBuilder? errorStateBuilder;

  /// Builder for the empty state shown when there is no data.
  final EmptyStateBuilder? emptyStateBuilder;

  /// Builder for the empty search state shown when no results match.
  final EmptySearchStateBuilder? emptySearchStateBuilder;

  /// Search behavior configuration (debounce, hint text, case sensitivity, etc.).
  final SearchConfiguration searchConfig;

  /// Pagination configuration. If null, pagination is disabled.
  final PaginationConfiguration? paginationConfig;

  /// Called when an item is tapped.
  final void Function(T item, int index)? onItemTap;

  /// Called when the search query changes.
  ///
  /// Exact timing depends on the widget variant: in [SmartSearchList] and
  /// [SmartSearchGrid] this fires on every text-field keystroke (pre-debounce).
  /// In [SliverSmartSearchList] and [SliverSmartSearchGrid] this fires only
  /// when the controller's query value actually changes (post-debounce).
  final void Function(String query)? onSearchChanged;

  /// Whether to cache async search results. Defaults to `true`.
  final bool cacheResults;

  /// Maximum number of cached results. Defaults to `100`.
  final int maxCacheSize;

  /// Multi-select configuration. When non-null, multi-select mode is enabled.
  final SelectionConfiguration? selectionConfig;

  /// Called when selection changes (multi-select mode).
  final void Function(Set<T> selectedItems)? onSelectionChanged;

  /// Groups items by the returned value. When non-null, items are displayed
  /// in sections with headers.
  ///
  /// In [SmartSearchList] and [SmartSearchGrid], group headers scroll with
  /// the content and are **not** sticky. For sticky (pinned) group headers,
  /// use [SliverSmartSearchList] or [SliverSmartSearchGrid].
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

  /// Accessibility configuration for screen reader semantics.
  final AccessibilityConfiguration accessibilityConfig;

  /// Creates a [SmartSearchWidgetBase] with the given shared fields.
  const SmartSearchWidgetBase({
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
    this.paginationConfig,
    this.onItemTap,
    this.onSearchChanged,
    this.cacheResults = true,
    this.maxCacheSize = 100,
    this.selectionConfig,
    this.onSelectionChanged,
    this.groupBy,
    this.groupHeaderBuilder,
    this.groupComparator,
    this.accessibilityConfig = const AccessibilityConfiguration(),
  });
}

/// Shared lifecycle, item building, and state management logic for all
/// Smart Search widget State classes.
///
/// Each concrete State class mixes this in and handles layout-specific
/// concerns (search field, scroll controller, list vs grid rendering).
mixin SmartSearchStateMixin<
  T extends Object,
  W extends SmartSearchWidgetBase<T>
>
    on State<W> {
  late SmartSearchController<T> _controller;
  bool _isDisposed = false;
  bool _controllerCreatedInternally = false;
  int? _lastAnnouncedCount;

  /// The active [SmartSearchController] for this widget.
  SmartSearchController<T> get controller => _controller;

  /// Whether this State has been disposed.
  bool get isDisposed => _isDisposed;

  /// Whether the controller was created internally by this widget.
  bool get controllerCreatedInternally => _controllerCreatedInternally;

  /// Initialises the controller and accessibility listener.
  /// Call from [initState].
  void initController() {
    assert(
      widget.paginationConfig == null || widget.paginationConfig!.isValid,
      'Invalid pagination configuration',
    );

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

    if (widget.accessibilityConfig.searchSemanticsEnabled) {
      _controller.addListener(_onControllerChangedForAnnouncement);
    }
  }

  /// Sets items or async loader on the controller.
  /// Call from [initState] after [initController].
  void initializeData() {
    if (_isDisposed) return;

    if (widget.items != null) {
      _controller.setItems(widget.items!);
    } else if (widget.asyncLoader != null) {
      _controller.setAsyncLoader(widget.asyncLoader!);
      _controller.search('');
    }
  }

  /// Forwards widget configuration changes to an internally-managed
  /// controller. Call from [didUpdateWidget].
  void updateControllerConfig(W oldWidget) {
    if (!_controllerCreatedInternally) return;

    if (widget.items != oldWidget.items && widget.items != null) {
      _controller.setItems(widget.items!);
    }

    if (widget.asyncLoader != oldWidget.asyncLoader &&
        widget.asyncLoader != null) {
      _controller.setAsyncLoader(widget.asyncLoader!);
      _controller.refresh();
    }

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

  /// Handles external controller swap in [didUpdateWidget].
  ///
  /// [onDetach] is called after removing the announcement listener from the
  /// old controller — use it to remove widget-specific listeners (e.g. the
  /// setState listener in sliver variants).
  ///
  /// [onAttach] is called after installing the new controller but before
  /// adding the announcement listener — use it to add widget-specific
  /// listeners and reset query tracking.
  void handleControllerSwap(
    W oldWidget, {
    void Function()? onDetach,
    void Function()? onAttach,
  }) {
    if (widget.controller != oldWidget.controller) {
      // Remove from the *active* controller — oldWidget.controller is null
      // when the active controller was created internally.
      _controller.removeListener(_onControllerChangedForAnnouncement);
      onDetach?.call();

      if (widget.controller != null) {
        if (_controllerCreatedInternally) {
          _controller.dispose();
          _controllerCreatedInternally = false;
        }
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
        initializeData();
      }
      assert(
        !_controller.isDisposed,
        'Controller must not be disposed after swap',
      );
      assert(
        (widget.controller != null) != _controllerCreatedInternally,
        '_controllerCreatedInternally must be consistent with widget.controller',
      );
      onAttach?.call();
      if (widget.accessibilityConfig.searchSemanticsEnabled) {
        _controller.addListener(_onControllerChangedForAnnouncement);
      }
    }
  }

  /// Toggles the accessibility announcement listener when
  /// [AccessibilityConfiguration.searchSemanticsEnabled] changes without
  /// the controller itself changing. Call from [didUpdateWidget].
  void handleAccessibilityToggle(W oldWidget) {
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

  /// Removes announcement listener and optionally disposes the controller.
  /// Call from [dispose].
  void disposeController() {
    _isDisposed = true;
    _controller.removeListener(_onControllerChangedForAnnouncement);
    if (_controllerCreatedInternally) {
      _controller.dispose();
    }
  }

  /// Announces result count changes to screen readers.
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

  /// Splits the current search query into individual terms.
  List<String> computeSearchTerms() {
    return _controller.searchQuery
        .split(' ')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// Builds a single item widget with selection and tap wrapping.
  Widget buildItem(BuildContext context, int index, List<String> searchTerms) {
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

    if (widget.onItemTap != null) {
      itemWidget = GestureDetector(
        onTap: () => widget.onItemTap!(item, index),
        child: itemWidget,
      );
    }

    return itemWidget;
  }

  /// Returns a state widget (loading, error, or empty) if the controller
  /// is not in a data-ready state, or `null` if items are available.
  Widget? buildStateWidget(BuildContext context) {
    if (_controller.isLoading && _controller.items.isEmpty) {
      return widget.loadingStateBuilder?.call(context) ??
          const DefaultLoadingWidget();
    }

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

    if (_controller.items.isEmpty) {
      if (_controller.hasSearched && _controller.searchQuery.isNotEmpty) {
        return widget.emptySearchStateBuilder?.call(
              context,
              _controller.searchQuery,
            ) ??
            DefaultEmptySearchWidget(searchQuery: _controller.searchQuery);
      }
      return widget.emptyStateBuilder?.call(context) ??
          const DefaultEmptyWidget();
    }

    return null;
  }

  /// Groups items using the widget's [groupBy] function.
  ({List<Object> order, Map<Object, List<IndexedItem<T>>> map})
  computeGroups() {
    final items = _controller.items;
    final groupBy = widget.groupBy!;

    final groupOrder = <Object>[];
    final groupMap = <Object, List<IndexedItem<T>>>{};

    for (var i = 0; i < items.length; i++) {
      final key = groupBy(items[i]);
      if (!groupMap.containsKey(key)) {
        groupOrder.add(key);
        groupMap[key] = [];
      }
      groupMap[key]!.add(IndexedItem(items[i], i));
    }

    if (widget.groupComparator != null) {
      groupOrder.sort(widget.groupComparator!);
    }

    return (order: groupOrder, map: groupMap);
  }
}

/// Tracks an item and its original index within the flat controller list.
class IndexedItem<T> {
  /// The item.
  final T item;

  /// The item's index in [SmartSearchController.items].
  final int index;

  /// Creates an [IndexedItem].
  const IndexedItem(this.item, this.index);
}

/// Delegate for sticky group headers in sliver grouped views.
class GroupHeaderDelegate extends SliverPersistentHeaderDelegate {
  /// The header content widget.
  final Widget child;

  @override
  final double maxExtent;

  @override
  final double minExtent;

  /// Creates a [GroupHeaderDelegate].
  GroupHeaderDelegate({
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
  bool shouldRebuild(covariant GroupHeaderDelegate oldDelegate) {
    return child != oldDelegate.child ||
        maxExtent != oldDelegate.maxExtent ||
        minExtent != oldDelegate.minExtent;
  }
}
