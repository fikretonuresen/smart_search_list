import 'package:flutter/material.dart';
import 'package:smart_search_list/smart_search_list.dart';

import '../models.dart';

/// Async API loading with pagination and error handling
class AsyncApiExample extends StatefulWidget {
  const AsyncApiExample({super.key});

  @override
  State<AsyncApiExample> createState() => _AsyncApiExampleState();
}

class _AsyncApiExampleState extends State<AsyncApiExample> {
  bool _simulateErrors = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Async API Loading'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          TextButton(
            onPressed: () => setState(() => _simulateErrors = !_simulateErrors),
            child: Text(_simulateErrors ? 'Fix Errors' : 'Simulate Errors'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Info card
          Card(
            margin: const EdgeInsets.all(16.0),
            child: ExpansionTile(
              title: Text(
                'Async API Demo',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              shape: const Border(),
              collapsedShape: const Border(),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _simulateErrors
                            ? 'Error simulation enabled - API calls will fail randomly'
                            : 'Normal mode - API calls work properly',
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Search to trigger API calls. Pull down to refresh.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SmartSearchList<ApiUser>.async(
              asyncLoader: (query, {int page = 0, int pageSize = 20}) =>
                  _simulateApiCall(query, page: page, pageSize: pageSize),
              itemBuilder: (context, user, index, {searchTerms = const []}) {
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        user.name.split(' ').map((n) => n[0]).join(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(user.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.email),
                        Text('${user.company} - ${user.position}'),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
              progressIndicatorBuilder: (context, isLoading) {
                if (!isLoading) return const SizedBox.shrink();
                return const LinearProgressIndicator(minHeight: 2);
              },
              searchConfig: const SearchConfiguration(
                hintText: 'Search users...',
                padding: EdgeInsets.all(16.0),
                debounceDelay: Duration(
                  milliseconds: 500,
                ), // Slower for API calls
              ),
              paginationConfig: const PaginationConfiguration(
                pageSize: 10,
                enabled: true,
              ),
              listConfig: const ListConfiguration(pullToRefresh: true),
              onRefresh: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Refreshing data...'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              errorStateBuilder: (context, error, retry) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text('API Error!', style: TextStyle(fontSize: 18)),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: retry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<List<ApiUser>> _simulateApiCall(
    String query, {
    int page = 0,
    int pageSize = 10,
  }) async {
    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 500 + (page * 200)));

    // Simulate errors if enabled
    if (_simulateErrors && DateTime.now().millisecond % 3 == 0) {
      throw Exception('Simulated network error - API unavailable');
    }

    // Simulate some users
    final allUsers = _generateMockUsers(100);

    // Filter by query
    List<ApiUser> filtered = allUsers;
    if (query.isNotEmpty) {
      filtered = allUsers.where((user) {
        return user.name.toLowerCase().contains(query.toLowerCase()) ||
            user.email.toLowerCase().contains(query.toLowerCase()) ||
            user.company.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }

    // Simulate pagination
    final start = page * pageSize;
    final end = (start + pageSize).clamp(0, filtered.length);

    if (start >= filtered.length) return [];

    return filtered.sublist(start, end);
  }

  static List<ApiUser> _generateMockUsers(int count) {
    const names = [
      'John Doe',
      'Jane Smith',
      'Bob Johnson',
      'Alice Brown',
      'Charlie Davis',
    ];
    const companies = ['Google', 'Apple', 'Microsoft', 'Amazon', 'Meta'];
    const positions = [
      'Engineer',
      'Designer',
      'Manager',
      'Analyst',
      'Developer',
    ];

    return List.generate(count, (i) {
      final name = names[i % names.length];
      final company = companies[i % companies.length];
      final position = positions[i % positions.length];

      return ApiUser(
        id: 'user_$i',
        name: '$name ${i + 1}',
        email:
            '${name.toLowerCase().replaceAll(' ', '.')}${i + 1}@${company.toLowerCase()}.com',
        company: company,
        position: position,
      );
    });
  }
}
