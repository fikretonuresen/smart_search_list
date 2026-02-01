/// Configuration for accessibility and screen reader behavior.
///
/// Controls semantic labels, screen reader announcements, and other
/// assistive technology features.
///
/// Example:
/// ```dart
/// AccessibilityConfiguration(
///   searchFieldLabel: 'Search products',
///   resultsAnnouncementBuilder: (count) => '$count products found',
/// )
/// ```
///
/// For localization, provide a custom [resultsAnnouncementBuilder]:
/// ```dart
/// // Turkish
/// resultsAnnouncementBuilder: (count) => '$count sonuc bulundu',
/// // German
/// resultsAnnouncementBuilder: (count) => '$count Ergebnisse gefunden',
/// ```
class AccessibilityConfiguration {
  /// Whether screen reader semantics are enabled for the search field
  /// and result announcements.
  ///
  /// When true (default), the package adds semantic labels to the search
  /// field and announces result count changes to screen readers.
  ///
  /// Set to false if you handle all accessibility in your own builders.
  final bool searchSemanticsEnabled;

  /// Semantic label for the search text field.
  ///
  /// This is read by TalkBack/VoiceOver when the search field is focused.
  /// If null, falls back to the search field's hint text.
  ///
  /// Example: `'Search products'`, `'Filter employees'`
  final String? searchFieldLabel;

  /// Builds the announcement string for result count changes.
  ///
  /// Called whenever the filtered result count changes after a search
  /// settles. The returned string is announced to screen readers via
  /// `SemanticsService.sendAnnouncement()`.
  ///
  /// If null, defaults to `'$count results found'`.
  ///
  /// Use this for localization:
  /// ```dart
  /// resultsAnnouncementBuilder: (count) {
  ///   if (count == 0) return 'No results';
  ///   if (count == 1) return '1 result found';
  ///   return '$count results found';
  /// },
  /// ```
  final String Function(int count)? resultsAnnouncementBuilder;

  /// Semantic label for the clear search button.
  ///
  /// If null, defaults to `'Clear search'`.
  final String? clearButtonLabel;

  /// Semantic label for the search submit button (onSubmit mode).
  ///
  /// If null, defaults to `'Search'`.
  final String? searchButtonLabel;

  const AccessibilityConfiguration({
    this.searchSemanticsEnabled = true,
    this.searchFieldLabel,
    this.resultsAnnouncementBuilder,
    this.clearButtonLabel,
    this.searchButtonLabel,
  });

  /// Default announcement text for the given result count.
  String buildResultsAnnouncement(int count) {
    if (resultsAnnouncementBuilder != null) {
      return resultsAnnouncementBuilder!(count);
    }
    if (count == 0) return 'No results found';
    if (count == 1) return '1 result found';
    return '$count results found';
  }

  /// Create a copy with modified values
  AccessibilityConfiguration copyWith({
    bool? searchSemanticsEnabled,
    String? searchFieldLabel,
    String Function(int count)? resultsAnnouncementBuilder,
    String? clearButtonLabel,
    String? searchButtonLabel,
  }) {
    return AccessibilityConfiguration(
      searchSemanticsEnabled:
          searchSemanticsEnabled ?? this.searchSemanticsEnabled,
      searchFieldLabel: searchFieldLabel ?? this.searchFieldLabel,
      resultsAnnouncementBuilder:
          resultsAnnouncementBuilder ?? this.resultsAnnouncementBuilder,
      clearButtonLabel: clearButtonLabel ?? this.clearButtonLabel,
      searchButtonLabel: searchButtonLabel ?? this.searchButtonLabel,
    );
  }
}
