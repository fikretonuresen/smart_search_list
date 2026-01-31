import 'package:flutter/material.dart';

/// Controls when search is triggered
///
/// - [onEdit]: Search triggers on every text change (debounced). Default behavior.
/// - [onSubmit]: Search triggers only when the user presses the keyboard
///   submit button or taps the search icon.
enum SearchTriggerMode {
  /// Search triggers on every text change, debounced by [SearchConfiguration.debounceDelay]
  onEdit,

  /// Search triggers only on explicit submit (keyboard action or search button tap)
  onSubmit,
}

/// Position of selection checkbox relative to item content
enum CheckboxPosition {
  /// Checkbox appears before the item content
  leading,

  /// Checkbox appears after the item content
  trailing,
}

/// Configuration for multi-select behavior
///
/// Example:
/// ```dart
/// const SelectionConfiguration(
///   enabled: true,
///   showCheckbox: true,
///   position: CheckboxPosition.leading,
/// )
/// ```
class SelectionConfiguration {
  /// Whether multi-select is enabled
  final bool enabled;

  /// Whether to show a default checkbox for each item
  ///
  /// Set to false if you handle selection visuals in your own [itemBuilder].
  final bool showCheckbox;

  /// Position of the default checkbox
  final CheckboxPosition position;

  const SelectionConfiguration({
    this.enabled = true,
    this.showCheckbox = true,
    this.position = CheckboxPosition.leading,
  });

  /// Create a copy with modified values
  SelectionConfiguration copyWith({
    bool? enabled,
    bool? showCheckbox,
    CheckboxPosition? position,
  }) {
    return SelectionConfiguration(
      enabled: enabled ?? this.enabled,
      showCheckbox: showCheckbox ?? this.showCheckbox,
      position: position ?? this.position,
    );
  }
}

/// Builder function for custom search field
typedef SearchFieldBuilder = Widget Function(
  BuildContext context,
  TextEditingController textController,
  FocusNode focusNode,
  VoidCallback onClear,
);

/// Builder function for list items
typedef ItemBuilder<T> = Widget Function(
  BuildContext context,
  T item,
  int index, {
  List<String> searchTerms,
});

/// Builder function for separators
typedef SeparatorBuilder = Widget Function(BuildContext context, int index);

/// Builder function for loading state
typedef LoadingBuilder = Widget Function(BuildContext context);

/// Builder function for error state
typedef ErrorBuilder = Widget Function(
  BuildContext context,
  Object error,
  VoidCallback onRetry,
);

/// Builder function for empty state (no data)
typedef EmptyBuilder = Widget Function(BuildContext context);

/// Builder function for empty search results
typedef EmptySearchBuilder = Widget Function(
  BuildContext context,
  String searchQuery,
);

/// Builder function for sort controls
typedef SortBuilder<T> = Widget Function(
  BuildContext context,
  int Function(T, T)? currentComparator,
  void Function(int Function(T, T)?) onSortChanged,
);

/// Builder function for group section headers
///
/// Called for each group when [SmartSearchList.groupBy] is provided.
/// [groupValue] is the value returned by the `groupBy` function.
/// [itemCount] is the number of items in this group.
typedef GroupHeaderBuilder = Widget Function(
  BuildContext context,
  Object groupValue,
  int itemCount,
);

/// Builder function for filter controls
typedef FilterBuilder<T> = Widget Function(
  BuildContext context,
  Map<String, bool Function(T)> activeFilters,
  void Function(String key, bool Function(T) predicate) onFilterChanged,
  void Function(String key) onFilterRemoved,
);

/// Configuration for search behavior
///
/// Controls search field appearance, debouncing, and interaction behavior.
///
/// Example:
/// ```dart
/// const SearchConfiguration(
///   enabled: true,
///   autofocus: false,
///   debounceDelay: Duration(milliseconds: 300),
///   hintText: 'Search products...',
/// )
/// ```
class SearchConfiguration {
  /// Whether search is enabled
  final bool enabled;

  /// Whether search field should autofocus
  final bool autofocus;

  /// Whether to show clear button
  final bool showClearButton;

  /// Debounce delay for search
  final Duration debounceDelay;

  /// Hint text for search field
  final String hintText;

  /// Text input type
  final TextInputType keyboardType;

  /// Text input action
  final TextInputAction textInputAction;

  /// Whether search is case sensitive
  final bool caseSensitive;

  /// Whether to close keyboard on scroll
  final bool closeKeyboardOnScroll;

  /// Minimum characters to trigger search
  final int minSearchLength;

  /// Padding around search field
  final EdgeInsets padding;

  /// Input decoration for search field
  final InputDecoration? decoration;

  /// Controls when search is triggered
  ///
  /// [SearchTriggerMode.onEdit] (default): debounced search on every keystroke.
  /// [SearchTriggerMode.onSubmit]: search only on explicit submit action.
  final SearchTriggerMode triggerMode;

  const SearchConfiguration({
    this.enabled = true,
    this.autofocus = false,
    this.showClearButton = true,
    this.debounceDelay = const Duration(milliseconds: 300),
    this.hintText = 'Search...',
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.search,
    this.caseSensitive = false,
    this.closeKeyboardOnScroll = true,
    this.minSearchLength = 0,
    this.padding = const EdgeInsets.all(16.0),
    this.decoration,
    this.triggerMode = SearchTriggerMode.onEdit,
  });

  /// Create a copy with modified values
  SearchConfiguration copyWith({
    bool? enabled,
    bool? autofocus,
    bool? showClearButton,
    Duration? debounceDelay,
    String? hintText,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool? caseSensitive,
    bool? closeKeyboardOnScroll,
    int? minSearchLength,
    EdgeInsets? padding,
    InputDecoration? decoration,
    SearchTriggerMode? triggerMode,
  }) {
    return SearchConfiguration(
      enabled: enabled ?? this.enabled,
      autofocus: autofocus ?? this.autofocus,
      showClearButton: showClearButton ?? this.showClearButton,
      debounceDelay: debounceDelay ?? this.debounceDelay,
      hintText: hintText ?? this.hintText,
      keyboardType: keyboardType ?? this.keyboardType,
      textInputAction: textInputAction ?? this.textInputAction,
      caseSensitive: caseSensitive ?? this.caseSensitive,
      closeKeyboardOnScroll:
          closeKeyboardOnScroll ?? this.closeKeyboardOnScroll,
      minSearchLength: minSearchLength ?? this.minSearchLength,
      padding: padding ?? this.padding,
      decoration: decoration ?? this.decoration,
      triggerMode: triggerMode ?? this.triggerMode,
    );
  }
}

/// Configuration for list behavior
///
/// Controls list appearance, scroll behavior, and interactions.
///
/// Example:
/// ```dart
/// const ListConfiguration(
///   pullToRefresh: true,
///   physics: BouncingScrollPhysics(),
///   padding: EdgeInsets.all(16.0),
/// )
/// ```
class ListConfiguration {
  /// Whether pull-to-refresh is enabled
  final bool pullToRefresh;

  /// Scroll physics
  final ScrollPhysics? physics;

  /// Padding around the list
  final EdgeInsets? padding;

  /// Whether list should shrink wrap
  final bool shrinkWrap;

  /// Whether list is reversed
  final bool reverse;

  /// Scroll direction
  final Axis scrollDirection;

  /// Whether to add automatic keep alives
  final bool addAutomaticKeepAlives;

  /// Whether to add repaint boundaries
  final bool addRepaintBoundaries;

  /// Whether to add semantic indexes
  final bool addSemanticIndexes;

  /// Fixed item extent for better performance
  final double? itemExtent;

  /// Cache extent for off-screen items
  final double? cacheExtent;

  /// Clip behavior
  final Clip clipBehavior;

  const ListConfiguration({
    this.pullToRefresh = true,
    this.physics,
    this.padding,
    this.shrinkWrap = false,
    this.reverse = false,
    this.scrollDirection = Axis.vertical,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.itemExtent,
    this.cacheExtent,
    this.clipBehavior = Clip.hardEdge,
  });

  /// Create a copy with modified values
  ListConfiguration copyWith({
    bool? pullToRefresh,
    ScrollPhysics? physics,
    EdgeInsets? padding,
    bool? shrinkWrap,
    bool? reverse,
    Axis? scrollDirection,
    bool? addAutomaticKeepAlives,
    bool? addRepaintBoundaries,
    bool? addSemanticIndexes,
    double? itemExtent,
    double? cacheExtent,
    Clip? clipBehavior,
  }) {
    return ListConfiguration(
      pullToRefresh: pullToRefresh ?? this.pullToRefresh,
      physics: physics ?? this.physics,
      padding: padding ?? this.padding,
      shrinkWrap: shrinkWrap ?? this.shrinkWrap,
      reverse: reverse ?? this.reverse,
      scrollDirection: scrollDirection ?? this.scrollDirection,
      addAutomaticKeepAlives:
          addAutomaticKeepAlives ?? this.addAutomaticKeepAlives,
      addRepaintBoundaries: addRepaintBoundaries ?? this.addRepaintBoundaries,
      addSemanticIndexes: addSemanticIndexes ?? this.addSemanticIndexes,
      itemExtent: itemExtent ?? this.itemExtent,
      cacheExtent: cacheExtent ?? this.cacheExtent,
      clipBehavior: clipBehavior ?? this.clipBehavior,
    );
  }
}

/// Configuration for pagination behavior
///
/// Controls when and how additional pages are loaded.
///
/// Example:
/// ```dart
/// const PaginationConfiguration(
///   pageSize: 20,
///   triggerDistance: 200.0,
///   enabled: true,
/// )
/// ```
class PaginationConfiguration {
  /// Number of items per page
  final int pageSize;

  /// Distance from bottom to trigger next page load
  final double triggerDistance;

  /// Whether pagination is enabled
  final bool enabled;

  const PaginationConfiguration({
    this.pageSize = 20,
    this.triggerDistance = 200.0,
    this.enabled = true,
  });

  /// Validate configuration values
  bool get isValid => pageSize > 0 && triggerDistance >= 0;

  /// Create a copy with modified values
  PaginationConfiguration copyWith({
    int? pageSize,
    double? triggerDistance,
    bool? enabled,
  }) {
    return PaginationConfiguration(
      pageSize: pageSize ?? this.pageSize,
      triggerDistance: triggerDistance ?? this.triggerDistance,
      enabled: enabled ?? this.enabled,
    );
  }
}
