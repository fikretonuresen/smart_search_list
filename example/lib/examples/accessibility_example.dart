import 'package:flutter/material.dart';
import 'package:smart_search_list/smart_search_list.dart';

class AccessibilityExample extends StatefulWidget {
  const AccessibilityExample({super.key});

  @override
  State<AccessibilityExample> createState() => _AccessibilityExampleState();
}

class _AccessibilityExampleState extends State<AccessibilityExample> {
  bool _useSpanish = true;

  static const _fruits = [
    'Apple',
    'Apricot',
    'Banana',
    'Blackberry',
    'Blueberry',
    'Cherry',
    'Coconut',
    'Cranberry',
    'Date',
    'Elderberry',
    'Fig',
    'Grape',
    'Grapefruit',
    'Guava',
    'Kiwi',
    'Lemon',
    'Lime',
    'Mango',
    'Orange',
    'Papaya',
    'Peach',
    'Pear',
    'Pineapple',
    'Plum',
    'Pomegranate',
    'Raspberry',
    'Strawberry',
    'Watermelon',
  ];

  AccessibilityConfiguration get _a11yConfig {
    if (_useSpanish) {
      return AccessibilityConfiguration(
        searchFieldLabel: 'Buscar frutas',
        clearButtonLabel: 'Borrar busqueda',
        searchButtonLabel: 'Buscar',
        resultsAnnouncementBuilder: (count) {
          if (count == 0) return 'Sin resultados';
          if (count == 1) return '1 resultado encontrado';
          return '$count resultados encontrados';
        },
      );
    }
    return const AccessibilityConfiguration();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accessibility'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Accessibility & Localization',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enable TalkBack (Android) or VoiceOver (iOS) to hear '
                    'semantic labels and result count announcements.',
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Spanish Labels'),
                    subtitle: Text(
                      _useSpanish
                          ? '"Buscar frutas", "Sin resultados"'
                          : 'English defaults: "Search...", "No results found"',
                    ),
                    value: _useSpanish,
                    onChanged: (v) => setState(() => _useSpanish = v),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SmartSearchList<String>(
              key: ValueKey(_useSpanish),
              items: _fruits,
              searchableFields: (item) => [item],
              itemBuilder: (context, item, index, {searchTerms = const []}) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      item[0],
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  title: Text(item),
                  subtitle: Text('Fruit #${index + 1}'),
                );
              },
              searchConfig: SearchConfiguration(
                hintText: _useSpanish ? 'Buscar...' : 'Search...',
              ),
              accessibilityConfig: _a11yConfig,
              listConfig: const ListConfiguration(pullToRefresh: true),
            ),
          ),
        ],
      ),
    );
  }
}
