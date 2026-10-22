import 'package:escape_room_admin/core/theme/app_theme.dart';
import 'package:escape_room_admin/features/dashboard/data/game_report_provider.dart';
import 'package:escape_room_admin/features/dashboard/data/scenario_provider.dart';
import 'package:escape_room_admin/features/dashboard/presentation/widgets/game_report_form.dart';
import 'package:escape_room_admin/shared/widgets/app_drawer.dart';
import 'package:escape_room_admin/shared/widgets/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class PendingReportsPage extends ConsumerWidget {
  const PendingReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(gameReportProvider);
    final scenariosAsync = ref.watch(scenarioProvider);

    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        title: const Text('RAPPORTS EN ATTENTE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 16)),
        backgroundColor: AppTheme.secondaryBlack,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryRed),
              icon: const Icon(Icons.add_chart_rounded, size: 18),
              label: const Text('NOUVEAU RAPPORT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              onPressed: () => showDialog(
                context: context,
                builder: (ctx) => const GameReportForm(),
              ),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: reportsAsync.when(
        data: (reports) {
          final pending = reports.where((r) => r.status == 'pending').toList();
          
          if (pending.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: AppTheme.successGreen.withValues(alpha: 0.5), size: 64),
                  const Gap(16),
                  const Text('TOUS LES RAPPORTS SONT À JOUR', style: TextStyle(color: AppTheme.grayText, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pending.length,
            itemBuilder: (context, index) {
              final report = pending[index];
              final scenario = scenariosAsync.value?.firstWhere((s) => s.id == report.scenarioId, orElse: () => scenariosAsync.value!.first);
              
              return FadeInSlide(
                delay: index * 0.1,
                child: Card(
                  color: AppTheme.secondaryBlack,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppTheme.grayBorder, width: 0.5)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppTheme.primaryRed.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.pending_actions_rounded, color: AppTheme.primaryRed),
                    ),
                    title: Text(scenario?.name ?? 'Chargement...', style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold)),
                    subtitle: Text('Session du ${_formatDate(report.createdAt)}', style: const TextStyle(color: AppTheme.grayText, fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.grayText, size: 16),
                    onTap: () => showDialog(
                      context: context,
                      builder: (ctx) => GameReportForm(initialReport: report),
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Erreur: $e')),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
