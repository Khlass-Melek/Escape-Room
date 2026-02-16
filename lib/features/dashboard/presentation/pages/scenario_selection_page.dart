
import 'package:escape_room_admin/core/theme/app_theme.dart';
import 'package:escape_room_admin/shared/widgets/app_drawer.dart';
import 'package:escape_room_admin/shared/widgets/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class ScenarioSelectionPage extends ConsumerWidget {
  const ScenarioSelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mock Data for Scenarios with Stats
    final scenarios = [
      {
        'id': '1', 
        'name': 'SAW I', 
        'active': true, 
        'progress': 0.7, 
        'successRate': 0.45, 
        'avgTime': '52:10',
        'difficulty': 4
      },
      {
        'id': '2', 
        'name': 'SAW II', 
        'active': false, 
        'progress': 0.0, 
        'successRate': 0.38, 
        'avgTime': '58:45',
        'difficulty': 5
      },
      {
        'id': '3', 
        'name': 'Pirates des Caraïbes', 
        'active': true, 
        'progress': 0.3, 
        'successRate': 0.65, 
        'avgTime': '45:30',
        'difficulty': 3
      },
      {
        'id': '4', 
        'name': 'Le Cannibale', 
        'active': false, 
        'progress': 0.0, 
        'successRate': 0.42, 
        'avgTime': '54:20',
        'difficulty': 4
      },
      {
        'id': '5', 
        'name': 'Guantanamo', 
        'active': false, 
        'progress': 0.0, 
        'successRate': 0.50, 
        'avgTime': '48:15',
        'difficulty': 3
      },
      {
        'id': '6', 
        'name': 'Mafia', 
        'active': false, 
        'progress': 0.0, 
        'successRate': 0.55, 
        'avgTime': '50:00',
        'difficulty': 3
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de Bord'),
        backgroundColor: AppTheme.secondaryBlack,
      ),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aperçu des Scénarios',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const Gap(24),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 350,
                  mainAxisSpacing: 24,
                  crossAxisSpacing: 24,
                  childAspectRatio: 0.9,
                ),
                itemCount: scenarios.length,
                itemBuilder: (context, index) {
                  final scenario = scenarios[index];
                  final isActive = scenario['active'] as bool;

                  return FadeInSlide(
                    duration: const Duration(milliseconds: 600),
                    delay: index * 0.1,
                    child: HoverScaleCard(
                      onTap: () {
                        context.go('/dashboard/${scenario['id']}');
                      },
                      child: _ScenarioCard(
                        name: scenario['name'] as String,
                        isActive: isActive,
                        progress: scenario['progress'] as double,
                        successRate: scenario['successRate'] as double,
                        avgTime: scenario['avgTime'] as String,
                        difficulty: scenario['difficulty'] as int,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  final String name;
  final bool isActive;
  final double progress;
  final double successRate;
  final String avgTime;
  final int difficulty;

  const _ScenarioCard({
    required this.name,
    required this.isActive,
    required this.progress,
    required this.successRate,
    required this.avgTime,
    required this.difficulty,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: isActive 
        ? RoundedRectangleBorder(
            side: const BorderSide(color: AppTheme.primaryRed, width: 2),
            borderRadius: BorderRadius.circular(20))
        : RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRed.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.primaryRed),
                    ),
                    child: const Text(
                      'EN COURS',
                      style: TextStyle(color: AppTheme.primaryRed, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.successGreen),
                    ),
                    child: const Text(
                      'DISPONIBLE',
                      style: TextStyle(color: AppTheme.successGreen, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const Divider(color: AppTheme.grayBorder, height: 24),
            
            // Stats Row
            Expanded(
              child: Row(
                children: [
                  // Success Rate Circle
                  CircularPercentIndicator(
                    radius: 30.0,
                    lineWidth: 6.0,
                    percent: successRate,
                    center: Text(
                      "${(successRate * 100).toInt()}%",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.white, fontSize: 12),
                    ),
                    progressColor: successRate > 0.5 ? AppTheme.successGreen : AppTheme.warningOrange,
                    backgroundColor: AppTheme.grayBorder,
                    footer: const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text("Succès", style: TextStyle(fontSize: 10, color: AppTheme.grayText)),
                    ),
                  ),
                  const Gap(16),
                  // Details Column
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _StatRow(icon: Icons.timer, label: "Moyenne", value: avgTime),
                        const Gap(8),
                        _StatRow(icon: Icons.star, label: "Difficulté", value: "$difficulty/5"),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Active Progress Bar
            if (isActive) ...[
              const Gap(12),
              Text(
                'Progression: ${(progress * 100).toInt()}%',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const Gap(4),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: AppTheme.grayBorder,
                color: AppTheme.primaryRed,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.grayText),
        const Gap(4),
        Text(
          "$label:",
          style: const TextStyle(fontSize: 12, color: AppTheme.grayText),
        ),
        const Gap(4),
        Text(
          value,
          style: const TextStyle(fontSize: 12, color: AppTheme.white, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}