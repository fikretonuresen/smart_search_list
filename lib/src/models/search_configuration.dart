import 'package:flutter/material.dart';

/// Controls when search is triggered.
///
/// - [onEdit]: Search triggers on every text change (debounced). Default behavior.
/// - [onSubmit]: Search triggers only when the user presses the keyboard
///   submit button or taps the search icon.
enum SearchTriggerMode {
  /// Search triggers on every text change, debounced by [SearchConfiguration.debounceDelay].
  onEdit,

  /// Search triggers only on explicit submit (keyboard action or search button tap).
  onSubmit,
}

/// Position of selection checkbox relative to item content.
enum CheckboxPosition {
  /// Checkbox appears before the item content.
  leading,

  /// Checkbox appears after the item content.
  trailing,
}

/// Configuration for multi-select behavior.
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
  /// Whether multi-select is enabled.
  final bool enabled;

  /// Whether to show a default checkbox for each item.
  ///
  /// Set to false if you handle selection visuals in your own `itemBuilder`.
  final bool showCheckbox;

  /// Position of the default checkbox.
  final CheckboxPosition position;

  /// Creates a selection configuration.
  const SelectionConfiguration({
    this.enabled = true,
    this.showCheckbox = true,
    this.position = CheckboxPosition.leading,
  });

  /// Returns a copy with the given fields replaced.
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

/// Builder function for a custom search field.
typedef SearchFieldBuilder =
    Widget Function(
      BuildContext context,
      TextEditingController textController,
      FocusNode focusNode,
      VoidCallback onClear,
    );

/// Builder function for list items.
///
/// The [searchTerms] parameter contains the individual words from the current
/// search query, split by whitespace. For example, the query `"red apple"`
/// produces `['red', 'apple']`. Pass these to [SearchHighlightText] or use
/// them in your own highlighting logic.
///
/// **When [searchTerms] is empty:** The list is always `[]` (never `null`)
/// when the search query is empty or contains only whitespace. This applies
/// to both offline and async modes.
///
/// **When [searchTerms] is populated:** Contains one or more non-empty
/// strings whenever the user has typed a search query. In async mode, the
/// terms reflect the query string even though matching was handled by the
/// async loader, so you can still use them for client-side highlighting.
typedef ItemBuilder<T> =
    Widget Function(
      BuildContext context,
      T item,
      int index, {
      List<String> searchTerms,
    });

/// Builder function for separators.
typedef SeparatorBuilder = Widget Function(BuildContext context, int index);

/// Builder for the full-screen loading state shown when data is first loading
/// and no items exist yet.
///
/// This replaces the entire list area. For an inline indicator (e.g., a thin
/// progress bar shown while items already exist), see [ProgressIndicatorBuilder].
typedef LoadingStateBuilder = Widget Function(BuildContext context);

/// Builder for the full-screen error state shown when an async operation fails.
///
/// This replaces the entire list area with an error message and retry action.
typedef ErrorStateBuilder =
    Widget Function(BuildContext context, Object error, VoidCallback onRetry);

/// Builder for the full-screen empty state shown when no data exists.
///
/// This replaces the entire list area. For empty search results (data exists
/// but nothing matches the query), see [EmptySearchStateBuilder].
typedef EmptyStateBuilder = Widget Function(BuildContext context);

/// Builder for the full-screen empty state shown when a search returns no results.
///
/// This replaces the entire list area. Unlike [EmptyStateBuilder] (no data at all),
/// this is shown when data exists but the current search query matches nothing.
typedef EmptySearchStateBuilder =
    Widget Function(BuildContext context, String searchQuery);

/// Builder function for sort controls.
typedef SortBuilder<T> =
    Widget Function(
      BuildContext context,
      int Function(T, T)? currentComparator,
      void Function(int Function(T, T)?) onSortChanged,
    );

/// Builder function for group section headers.
///
/// Called for each group when [SmartSearchList.groupBy] is provided.
/// [groupValue] is the value returned by the `groupBy` function.
/// [itemCount] is the number of items in this group.
typedef GroupHeaderBuilder =
    Widget Function(BuildContext context, Object groupValue, int itemCount);

/// Builder for an inline progress indicator shown during async operations.
///
/// Unlike [LoadingStateBuilder] which replaces the entire list when no items
/// exist, this builder is always rendered (between the search field and list
/// content) and receives the current loading state. Use it to show a thin
/// progress bar, shimmer, or any visual indicator while data is being fetched.
///
/// Return [SizedBox.shrink] when [isLoading] is false to hide the indicator.
///
/// Example:
/// ```dart
/// progressIndicatorBuilder: (context, isLoading) {
///   if (!isLoading) return const SizedBox.shrink();
///   return const LinearProgressIndicator();
/// },
/// ```
typedef ProgressIndicatorBuilder =
    Widget Function(BuildContext context, bool isLoading);

/// Builder function for filter controls.
typedef FilterBuilder<T> =
    Widget Function(
      BuildContext context,
      Map<String, bool Function(T)> activeFilters,
      void Function(String key, bool Function(T) predicate) onFilterChanged,
      void Function(String key) onFilterRemoved,
    );

/// Configuration for search behavior.
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
  /// Whether the search field is visible in the UI.
  ///
  /// When `false`, the search text field is hidden but the underlying
  /// controller continues to work normally. Data loading and filtering
  /// still function; only the search UI is suppressed.
  final bool enabled;

  /// Whether the search field requests focus automatically when first built.
  final bool autofocus;

  /// Whether to show a clear button that resets the search query.
  final bool showClearButton;

  /// Duration to wait after the last keystroke before triggering a search.
  ///
  /// Prevents excessive searches during rapid typing. For async data
  /// loaders, 300 ms or more is recommended.
  final Duration debounceDelay;

  /// Placeholder text shown inside the search field when it is empty.
  final String hintText;

  /// Keyboard type shown to the user when the search field is focused.
  final TextInputType keyboardType;

  /// Action button displayed on the soft keyboard (e.g., "search", "done").
  final TextInputAction textInputAction;

  /// Whether search matching distinguishes between upper- and lower-case.
  ///
  /// Only affects offline mode. Async loaders handle casing themselves.
  final bool caseSensitive;

  /// Whether scrolling the list dismisses the on-screen keyboard.
  final bool closeKeyboardOnScroll;

  /// Number of characters the user must type before a search is executed.
  ///
  /// Useful for async loaders where very short queries are too broad.
  /// A query shorter than this value is treated as empty.
  final int minSearchLength;

  /// Outer padding applied around the search field widget.
  final EdgeInsets padding;

  /// Custom [InputDecoration] applied to the search [TextField].
  ///
  /// When provided, this replaces the default decoration entirely.
  final InputDecoration? decoration;

  /// Controls when search is triggered.
  ///
  /// [SearchTriggerMode.onEdit] (default): debounced search on every keystroke.
  /// [SearchTriggerMode.onSubmit]: search only on explicit submit action.
  final SearchTriggerMode triggerMode;

  /// Whether fuzzy (subsequence) matching is enabled for offline search.
  ///
  /// When true, items that contain the query characters in order (but not
  /// necessarily consecutively) are included in results. Results are ranked
  /// by match quality — exact substring matches always score highest.
  ///
  /// Only affects offline mode. Async loaders handle their own matching.
  ///
  /// Defaults to `false`.
  final bool fuzzySearchEnabled;

  /// Minimum score (0.0 – 1.0) a fuzzy match must reach to be included.
  ///
  /// Lower values return more results (more lenient).
  /// Higher values return fewer, tighter matches.
  ///
  /// Has no effect when [fuzzySearchEnabled] is `false`.
  ///
  /// Defaults to `0.3`.
  final double fuzzyThreshold;

  /// Creates a search configuration with the given options.
  ///
  /// All parameters are optional with sensible defaults.
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
    this.fuzzySearchEnabled = false,
    this.fuzzyThreshold = 0.3,
  }) : assert(
         fuzzyThreshold >= 0.0 && fuzzyThreshold <= 1.0,
         'fuzzyThreshold must be between 0.0 and 1.0',
       ),
       assert(minSearchLength >= 0, 'minSearchLength must be non-negative');

  /// Returns a copy with the given fields replaced.
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
    bool? fuzzySearchEnabled,
    double? fuzzyThreshold,
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
      fuzzySearchEnabled: fuzzySearchEnabled ?? this.fuzzySearchEnabled,
      fuzzyThreshold: fuzzyThreshold ?? this.fuzzyThreshold,
    );
  }
}

/// Configuration for list behavior.
///
/// Controls list appearance, scroll behavior, and interactions.
///
/// Example:
/// ```dart
/// const ListConfiguration(
///   pullToRefresh: true,
///   physics: const BouncingScrollPhysics(),
///   padding: EdgeInsets.all(16.0),
/// )
/// ```
class ListConfiguration {
  /// Whether the user can pull down on the list to trigger a data refresh.
  final bool pullToRefresh;

  /// Scroll physics applied to the list (e.g., [BouncingScrollPhysics]).
  ///
  /// When null, the platform default is used.
  final ScrollPhysics? physics;

  /// Padding inserted around the scrollable list content.
  final EdgeInsets? padding;

  /// Whether the list should size itself to fit its children.
  ///
  /// When true, the list takes only as much vertical space as its content
  /// requires. Avoid this for large datasets as it defeats lazy rendering.
  final bool shrinkWrap;

  /// Whether the list scrolls in the reverse reading direction.
  final bool reverse;

  /// The axis along which the list scrolls.
  final Axis scrollDirection;

  /// Whether to wrap each child in an [AutomaticKeepAlive] widget.
  final bool addAutomaticKeepAlives;

  /// Whether to wrap each child in a [RepaintBoundary].
  final bool addRepaintBoundaries;

  /// Whether to wrap each child in an [IndexedSemantics] widget.
  final bool addSemanticIndexes;

  /// Fixed height (or width, if horizontal) for every item, in logical pixels.
  ///
  /// Setting this allows the scroll machinery to skip per-child layout,
  /// improving performance for large lists with uniform item sizes.
  ///
  /// Only takes effect when no `separatorBuilder` is provided, because
  /// [ListView.separated] does not support `itemExtent`.
  final double? itemExtent;

  /// Extra scroll extent to keep rendered beyond the visible viewport.
  ///
  /// Larger values pre-render more off-screen items, reducing pop-in at
  /// the cost of memory. When null, the framework default is used.
  final double? cacheExtent;

  /// How to clip children that overflow the list bounds.
  final Clip clipBehavior;

  /// Creates a list configuration.
  ///
  /// All parameters map to [ListView] properties with sensible defaults.
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

  /// Returns a copy with the given fields replaced.
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

/// Configuration for pagination behavior.
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
  /// Number of items to request in each page load.
  final int pageSize;

  /// Scroll distance from the bottom edge, in logical pixels, at which
  /// the next page load is triggered.
  final double triggerDistance;

  /// Whether automatic page loading on scroll is active.
  final bool enabled;

  /// Creates a pagination configuration.
  const PaginationConfiguration({
    this.pageSize = 20,
    this.triggerDistance = 200.0,
    this.enabled = true,
  }) : assert(pageSize > 0, 'pageSize must be positive'),
       assert(triggerDistance >= 0, 'triggerDistance must be non-negative');

  /// Whether this configuration has valid values.
  bool get isValid => pageSize > 0 && triggerDistance >= 0;

  /// Returns a copy with the given fields replaced.
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
