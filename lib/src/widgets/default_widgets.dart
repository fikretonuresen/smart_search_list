import 'package:flutter/material.dart';
import '../models/accessibility_configuration.dart';
import '../models/search_configuration.dart';

/// A Material Design search text field with clear and submit buttons.
class DefaultSearchField extends StatelessWidget {
  /// The text editing controller for the search field.
  final TextEditingController controller;

  /// The focus node for the search field.
  final FocusNode focusNode;

  /// The search configuration controlling appearance and behavior.
  final SearchConfiguration configuration;

  /// Callback invoked when the user clears the search field.
  final VoidCallback onClear;

  /// Called when the user submits the search (presses Enter/Search on keyboard).
  /// Only wired when [SearchTriggerMode.onSubmit] is active.
  final ValueChanged<String>? onSubmitted;

  /// Accessibility configuration for semantic labels and tooltips.
  final AccessibilityConfiguration accessibilityConfig;

  /// Creates a default Material Design search field.
  const DefaultSearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.configuration,
    required this.onClear,
    this.onSubmitted,
    this.accessibilityConfig = const AccessibilityConfiguration(),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: configuration.padding,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final isSubmitMode =
              configuration.triggerMode == SearchTriggerMode.onSubmit;

          // Build suffix icons
          Widget? suffixIcon;
          final suffixChildren = <Widget>[];

          if (isSubmitMode) {
            suffixChildren.add(
              IconButton(
                icon: const Icon(Icons.search),
                tooltip: accessibilityConfig.searchButtonLabel ?? 'Search',
                onPressed: () => onSubmitted?.call(controller.text),
              ),
            );
          }

          if (configuration.showClearButton && controller.text.isNotEmpty) {
            suffixChildren.add(
              IconButton(
                icon: const Icon(Icons.clear),
                tooltip: accessibilityConfig.clearButtonLabel ?? 'Clear search',
                onPressed: onClear,
              ),
            );
          }

          if (suffixChildren.length == 1) {
            suffixIcon = suffixChildren.first;
          } else if (suffixChildren.length > 1) {
            suffixIcon = Row(
              mainAxisSize: MainAxisSize.min,
              children: suffixChildren,
            );
          }

          // Build the base decoration
          final effectiveDecoration =
              configuration.decoration ??
              InputDecoration(
                hintText: configuration.hintText,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: suffixIcon,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12.0)),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              );

          // Apply semantic label if provided
          final decorationWithLabel =
              accessibilityConfig.searchFieldLabel != null &&
                  configuration.decoration == null
              ? effectiveDecoration.copyWith(
                  labelText: accessibilityConfig.searchFieldLabel,
                )
              : effectiveDecoration;

          return TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: configuration.autofocus,
            keyboardType: configuration.keyboardType,
            textInputAction: isSubmitMode
                ? TextInputAction.search
                : configuration.textInputAction,
            onSubmitted: isSubmitMode ? onSubmitted : null,
            decoration: decorationWithLabel,
          );
        },
      ),
    );
  }
}

/// Displays a centered circular progress indicator for loading states.
class DefaultLoadingWidget extends StatelessWidget {
  /// Creates a default loading indicator.
  const DefaultLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

/// Displays an error icon, message, and retry button.
class DefaultErrorWidget extends StatelessWidget {
  /// The error object to display.
  final Object error;

  /// Callback invoked when the user taps "Try again".
  final VoidCallback onRetry;

  /// Creates a default error display.
  const DefaultErrorWidget({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Default empty widget for when there's no data initially.
///
/// Shows "No items to display" message.
class DefaultEmptyWidget extends StatelessWidget {
  /// Creates a default empty state display.
  const DefaultEmptyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No items to display',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are currently no items available.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Default empty search widget for when search returns no results.
///
/// Shows "No results found for 'query'" message.
class DefaultEmptySearchWidget extends StatelessWidget {
  /// The search query that returned no results.
  final String searchQuery;

  /// Creates a default empty search results display.
  const DefaultEmptySearchWidget({super.key, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              searchQuery.isEmpty
                  ? 'Try a different search term.'
                  : 'No items match "$searchQuery".\nTry a different search term.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Default group header widget for grouped lists.
///
/// Displays the group value as a section header with item count.
class DefaultGroupHeader extends StatelessWidget {
  /// The group value (typically a String like a category name).
  final Object groupValue;

  /// Number of items in this group.
  final int itemCount;

  /// Creates a default group header.
  const DefaultGroupHeader({
    super.key,
    required this.groupValue,
    required this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      header: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        color: theme.colorScheme.surfaceContainerHighest,
        child: Text(
          '$groupValue ($itemCount)',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Displays a centered progress indicator for pagination loading.
///
/// Shows loading indicator at bottom of list during pagination.
class DefaultLoadMoreWidget extends StatelessWidget {
  /// Creates a default pagination loading indicator.
  const DefaultLoadMoreWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
