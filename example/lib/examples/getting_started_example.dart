import 'package:flutter/material.dart';
import 'package:smart_search_list/smart_search_list.dart';

class GettingStartedExample extends StatelessWidget {
  const GettingStartedExample({super.key});

  static const _countries = [
    'Argentina',
    'Australia',
    'Austria',
    'Belgium',
    'Brazil',
    'Canada',
    'Chile',
    'China',
    'Colombia',
    'Czech Republic',
    'Denmark',
    'Egypt',
    'Finland',
    'France',
    'Germany',
    'Greece',
    'India',
    'Indonesia',
    'Ireland',
    'Italy',
    'Japan',
    'Kenya',
    'Mexico',
    'Netherlands',
    'New Zealand',
    'Nigeria',
    'Norway',
    'Peru',
    'Poland',
    'Portugal',
    'Russia',
    'South Africa',
    'South Korea',
    'Spain',
    'Sweden',
    'Switzerland',
    'Thailand',
    'Turkey',
    'United Kingdom',
    'United States',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Getting Started')),
      body: SmartSearchList<String>(
        items: _countries,
        searchableFields: (item) => [item],
        itemBuilder: (context, item, index, {searchTerms = const []}) {
          return ListTile(title: Text(item));
        },
      ),
    );
  }
}
