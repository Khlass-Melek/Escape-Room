import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
class ScenarioSelectionPage extends StatelessWidget {
  const ScenarioSelectionPage({super.key});

  // Mock data - later fetch from API / WS
  static const List<Map<String, String>> scenarios = [
    {'id': 'halloween-2025', 'name': 'Halloween Horror 2025'},
    {'id': 'pirates', 'name': 'Pirates Treasure'},
    {'id': 'escape-prison', 'name': 'Prison Break'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Scenario to Monitor')),
      body: ListView.builder(
        itemCount: scenarios.length,
        itemBuilder: (context, index) {
          final scenario = scenarios[index];
          return ListTile(
            title: Text(scenario['name']!),
            onTap: () {
              context.go('/dashboard/${scenario['id']}');
            },
          );
        },
      ),
    );
  }
}