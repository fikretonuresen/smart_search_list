import 'package:flutter/material.dart';

/// Configuration for grid layout behavior.
///
/// Parallel to [ListConfiguration] for list widgets. Controls grid layout,
/// scroll behavior, and interactions.
///
/// Example:
/// ```dart
/// GridConfiguration(
///   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
///     crossAxisCount: 2,
///     childAspectRatio: 0.7,
///   ),
/// )
/// ```
class GridConfiguration {
  /// Delegate that controls the layout of children in the grid.
  ///
  /// Use [SliverGridDelegateWithFixedCrossAxisCount] for a fixed number of
  /// columns, or [SliverGridDelegateWithMaxCrossAxisExtent] for columns
  /// based on a maximum width.
  final SliverGridDelegate gridDelegate;

  /// Whether the user can pull down on the grid to trigger a data refresh.
  ///
  /// Only applies to [SmartSearchGrid]. Has no effect on
  /// [SliverSmartSearchGrid] — wrap your [CustomScrollView] in a
  /// [RefreshIndicator] instead.
  final bool pullToRefresh;

  /// Scroll physics applied to the grid (e.g., [BouncingScrollPhysics]).
  ///
  /// When null, the platform default is used.
  final ScrollPhysics? physics;

  /// Padding inserted around the scrollable grid content.
  final EdgeInsets? padding;

  /// Whether the grid should size itself to fit its children.
  ///
  /// When true, the grid takes only as much vertical space as its content
  /// requires. Avoid this for large datasets as it defeats lazy rendering.
  final bool shrinkWrap;

  /// Whether the grid scrolls in the reverse reading direction.
  final bool reverse;

  /// The axis along which the grid scrolls.
  final Axis scrollDirection;

  /// Whether to wrap each child in an [AutomaticKeepAlive] widget.
  final bool addAutomaticKeepAlives;

  /// Whether to wrap each child in a [RepaintBoundary].
  final bool addRepaintBoundaries;

  /// Whether to wrap each child in an [IndexedSemantics] widget.
  final bool addSemanticIndexes;

  /// Extra scroll extent to keep rendered beyond the visible viewport.
  ///
  /// Larger values pre-render more off-screen items, reducing pop-in at
  /// the cost of memory. When null, the framework default is used.
  final double? cacheExtent;

  /// How to clip children that overflow the grid bounds.
  final Clip clipBehavior;

  /// Creates a grid configuration with the given options.
  ///
  /// The [gridDelegate] parameter is required and controls the grid layout.
  /// All other parameters are optional with sensible defaults.
  const GridConfiguration({
    required this.gridDelegate,
    this.pullToRefresh = true,
    this.physics,
    this.padding,
    this.shrinkWrap = false,
    this.reverse = false,
    this.scrollDirection = Axis.vertical,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.cacheExtent,
    this.clipBehavior = Clip.hardEdge,
  });

  /// Returns a copy with the given fields replaced.
  GridConfiguration copyWith({
    SliverGridDelegate? gridDelegate,
    bool? pullToRefresh,
    ScrollPhysics? physics,
    EdgeInsets? padding,
    bool? shrinkWrap,
    bool? reverse,
    Axis? scrollDirection,
    bool? addAutomaticKeepAlives,
    bool? addRepaintBoundaries,
    bool? addSemanticIndexes,
    double? cacheExtent,
    Clip? clipBehavior,
  }) {
    return GridConfiguration(
      gridDelegate: gridDelegate ?? this.gridDelegate,
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
      cacheExtent: cacheExtent ?? this.cacheExtent,
      clipBehavior: clipBehavior ?? this.clipBehavior,
    );
  }
}
