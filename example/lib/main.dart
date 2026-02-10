import 'package:flutter/material.dart';

import 'examples/getting_started_example.dart';
import 'examples/basic_offline_example.dart';
import 'examples/ecommerce_example.dart';
import 'examples/fuzzy_search_example.dart';
import 'examples/async_api_example.dart';
import 'examples/multi_select_example.dart';
import 'examples/grouped_list_example.dart';
import 'examples/sliver_example.dart';
import 'examples/grouped_sliver_example.dart';
import 'examples/empty_states_example.dart';
import 'examples/search_trigger_mode_example.dart';
import 'examples/advanced_config_example.dart';
import 'examples/performance_test_example.dart';
import 'examples/accessibility_example.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Search List Examples',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ExampleHomePage(),
    );
  }
}

class ExampleHomePage extends StatelessWidget {
  const ExampleHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Smart Search List Examples'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildExampleCard(
            context,
            'Getting Started',
            'Minimal searchable list - just items and a search field',
            Icons.rocket_launch,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GettingStartedExample()),
            ),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            'Basic Offline List',
            'Simple searchable list with configuration options',
            Icons.list,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BasicOfflineExample()),
            ),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            'E-commerce Products',
            'Advanced features: search, filter, sort',
            Icons.shopping_cart,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EcommerceExample()),
            ),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            'Fuzzy Search',
            'Typo-tolerant search with highlighted matches',
            Icons.auto_fix_high,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FuzzySearchExample()),
            ),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            'Async API Loading',
            'Real async data with pagination',
            Icons.cloud_download,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AsyncApiExample()),
            ),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            'Multi-Select',
            'Select items with checkboxes, filter + selection',
            Icons.checklist,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MultiSelectExample()),
            ),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            'Grouped List',
            'Items grouped by category with headers',
            Icons.category,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GroupedListExample()),
            ),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            'Sliver Integration',
            'CustomScrollView with SliverSmartSearchList',
            Icons.view_list,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SliverExample()),
            ),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            'Grouped Sliver (Sticky Headers)',
            'SliverSmartSearchList with sticky group headers',
            Icons.view_day,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GroupedSliverExample()),
            ),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            'Empty States Demo',
            'Two different empty states comparison',
            Icons.inbox,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EmptyStatesExample()),
            ),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            'Search Trigger Modes',
            'Toggle between onEdit and onSubmit modes',
            Icons.keyboard,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SearchTriggerModeExample(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            'Advanced Configuration',
            'External controller and custom builders',
            Icons.settings,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdvancedConfigExample()),
            ),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            'Performance Test (10K Items)',
            'Test with 10,000 items at 60 FPS',
            Icons.speed,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PerformanceTestExample()),
            ),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            'Accessibility',
            'Localized labels and screen reader support',
            Icons.accessibility_new,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccessibilityExample()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
