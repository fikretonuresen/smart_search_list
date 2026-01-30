import 'package:flutter/material.dart';
import '../models/search_configuration.dart';

/// Default search field widget
///
/// Provides a clean, Material Design search field with clear button
class DefaultSearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final SearchConfiguration configuration;
  final VoidCallback onClear;

  const DefaultSearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.configuration,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: configuration.padding,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: configuration.autofocus,
            keyboardType: configuration.keyboardType,
            textInputAction: configuration.textInputAction,
            decoration: configuration.decoration ??
                InputDecoration(
                  hintText: configuration.hintText,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: configuration.showClearButton &&
                          controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: onClear,
                        )
                      : null,
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12.0)),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
          );
        },
      ),
    );
  }
}

/// Default loading widget
///
/// Shows a centered circular progress indicator
class DefaultLoadingWidget extends StatelessWidget {
  const DefaultLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

/// Default error widget
///
/// Shows error icon, message, and retry button
class DefaultErrorWidget extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

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

/// Default empty widget for when there's no data initially
///
/// Shows "No items to display" message
class DefaultEmptyWidget extends StatelessWidget {
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

/// Default empty search widget for when search returns no results
///
/// Shows "No results found for 'query'" message
class DefaultEmptySearchWidget extends StatelessWidget {
  final String searchQuery;

  const DefaultEmptySearchWidget({
    super.key,
    required this.searchQuery,
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

/// Default load more widget
///
/// Shows loading indicator at bottom of list during pagination
class DefaultLoadMoreWidget extends StatelessWidget {
  const DefaultLoadMoreWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
