
import 'package:escape_room_admin/core/theme/app_theme.dart';
import 'package:escape_room_admin/shared/widgets/app_drawer.dart';
import 'package:escape_room_admin/shared/widgets/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:escape_room_admin/features/dashboard/data/scenario_provider.dart';
import 'package:escape_room_admin/features/dashboard/data/game_report_provider.dart';
import 'package:escape_room_admin/shared/utils/responsive.dart';

class DashboardHomePage extends ConsumerWidget {
  const DashboardHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenariosAsync = ref.watch(scenarioProvider);
    final bool isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        title: Text(isMobile ? 'COMMANDEMENT' : 'CENTRE DE COMMANDEMENT',
            style: const TextStyle(letterSpacing: 2, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.secondaryBlack,
        elevation: 0,
      ),
      drawer: const AppDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.secondaryBlack.withOpacity(0.3),
              AppTheme.primaryBlack,
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isMobile) ...[
                _GlobalStat(label: 'SALLES ACTIVES', value: '01 / 06', icon: Icons.sensors_rounded, isFullWidth: true),
                const Gap(24),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ÉTAT DES MISSIONS',
                          style: (isMobile
                                  ? Theme.of(context).textTheme.titleLarge
                                  : Theme.of(context).textTheme.headlineSmall)
                              ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.white,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isMobile ? 'STATISTIQUES LIVE' : 'STATISTIQUES DYNAMIQUES EN TEMPS RÉEL',
                          style: TextStyle(
                            color: AppTheme.primaryRed.withOpacity(0.7),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isMobile)
                    _GlobalStat(label: 'SALLES ACTIVES', value: '01 / 06', icon: Icons.sensors_rounded),
                ],
              ),
              SizedBox(height: isMobile ? 32 : 40),
              Expanded(
                child: scenariosAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed)),
                  error: (err, stack) =>
                      Center(child: Text('Erreur: $err', style: const TextStyle(color: AppTheme.primaryRed))),
                  data: (scenarios) {
                    if (scenarios.isEmpty) {
                      return const Center(
                          child: Text('Aucun scénario trouvé', style: TextStyle(color: AppTheme.grayText)));
                    }
                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isMobile ? 1 : (Responsive.isTablet(context) ? 2 : 3),
                        mainAxisSpacing: isMobile ? 20 : 24,
                        crossAxisSpacing: isMobile ? 20 : 24,
                        childAspectRatio: isMobile ? 0.78 : (Responsive.isTablet(context) ? 0.8 : 1.4),
                      ),
                      itemCount: scenarios.length,
                      itemBuilder: (context, index) {
                        final scenario = scenarios[index];
                        final stats = ref.watch(scenarioStatsProvider(scenario.id));

                        return FadeInSlide(
                          duration: const Duration(milliseconds: 600),
                          delay: index * 0.08,
                          child: _DashboardCard(
                            name: scenario.name,
                            active: scenario.isActive,
                            image: scenario.image,
                            stats: stats,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlobalStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isFullWidth;

  const _GlobalStat({required this.label, required this.value, required this.icon, this.isFullWidth = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.grayBorder, width: 0.5),
      ),
      child: Row(
        mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.primaryRed, size: 24),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppTheme.grayText, fontSize: 9, fontWeight: FontWeight.bold)),
              Text(value,
                  style: const TextStyle(
                      color: AppTheme.white, fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String name;
  final bool active;
  final String image;
  final Map<String, dynamic> stats;

  const _DashboardCard({
    required this.name,
    required this.active,
    required this.image,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final double successRate = (stats['successRate'] as double? ?? 0.0);
    final String avgTime = stats['avgTime'] as String? ?? '--:--';
    final int totalGames = stats['totalGames'] as int? ?? 0;
    final int successCount = stats['successCount'] as int? ?? 0;
    final int failCount = stats['failCount'] as int? ?? 0;
    final double avgClues = stats['avgClues'] as double? ?? 0.0;
    final double avgPlayers = stats['avgPlayers'] as double? ?? 0.0;
    final double avgCompletion = stats['avgCompletion'] as double? ?? 0.0;
    final int dynamicDifficulty = stats['dynamicDifficulty'] as int? ?? 0;
    final bool hasData = totalGames > 0;

    final bool isMobile = Responsive.isMobile(context);


    final Color successColor =
        successRate >= 0.6 ? AppTheme.successGreen : (successRate >= 0.35 ? AppTheme.warningOrange : AppTheme.primaryRed);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlack,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active ? AppTheme.primaryRed.withOpacity(0.5) : AppTheme.grayBorder,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background image
            Positioned.fill(
              child: Opacity(
                opacity: 0.12,
                child: Image.asset(image, fit: BoxFit.cover),
              ),
            ),
            // Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.secondaryBlack.withOpacity(0.92),
                      AppTheme.primaryBlack.withOpacity(0.85),
                    ],
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header: name + live badge ──────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            color: AppTheme.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (active) const _LivePulser(),
                    ],
                  ),

                  const Gap(6),

                  // ── Dynamic difficulty stars ───────────────────────────
                  _DynamicDifficultyRow(level: dynamicDifficulty, hasData: hasData),

                  const Gap(10),
                  Divider(color: AppTheme.grayBorder.withOpacity(0.5), height: 1),
                  const Gap(10),

                  // ── Big success rate ───────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TAUX DE RÉUSSITE',
                            style: TextStyle(color: AppTheme.grayText, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                          ),
                          const Gap(2),
                          Text(
                            hasData ? '${(successRate * 100).toInt()}%' : '--%',
                            style: TextStyle(
                              color: successColor,
                              fontSize: 44,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'monospace',
                              height: 1,
                              shadows: [Shadow(color: successColor.withOpacity(0.35), blurRadius: 16)],
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _MiniStat(icon: Icons.timer_outlined, label: 'TEMPS MOY.', value: avgTime, color: AppTheme.warningOrange),
                          const Gap(6),
                          _MiniStat(icon: Icons.sports_esports_rounded, label: 'PARTIES', value: totalGames.toString(), color: AppTheme.white),
                        ],
                      ),
                    ],
                  ),

                  const Gap(10),
                  Divider(color: AppTheme.grayBorder.withOpacity(0.5), height: 1),
                  const Gap(10),

                  // ── 2×2 stats grid — fills remaining space ──────────────
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: isMobile ? 1.4 : (Responsive.isTablet(context) ? 1.7 : 2.2),
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _BigStatTile(icon: Icons.check_circle_outline_rounded, label: 'RÉUSSIES', value: successCount.toString(), color: AppTheme.successGreen),
                        _BigStatTile(icon: Icons.cancel_outlined, label: 'ÉCHOUÉES', value: failCount.toString(), color: AppTheme.primaryRed),
                        _BigStatTile(icon: Icons.lightbulb_outline_rounded, label: 'INDICES / P.', value: avgClues.toStringAsFixed(1), color: AppTheme.warningOrange),
                        _BigStatTile(icon: Icons.percent_rounded, label: 'COMPLÉTION', value: '${avgCompletion.toInt()}%', color: AppTheme.white),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dynamic difficulty row (replaces static bar) ────────────────────────────
class _DynamicDifficultyRow extends StatelessWidget {
  final int level; // 0 = no data, 1–5 = difficulty
  final bool hasData;
  const _DynamicDifficultyRow({required this.level, required this.hasData});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('DIFFICULTÉ (DYNAMIQUE)',
            style: TextStyle(color: AppTheme.grayText, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const Gap(8),
        if (!hasData)
          const Text('N/A', style: TextStyle(color: AppTheme.grayText, fontSize: 9))
        else
          ...List.generate(5, (i) {
            final filled = i < level;
            Color starColor;
            if (level <= 2) {
              starColor = AppTheme.successGreen;
            } else if (level == 3) {
              starColor = AppTheme.warningOrange;
            } else {
              starColor = AppTheme.primaryRed;
            }
            return Icon(
              filled ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 14,
              color: filled ? starColor : AppTheme.grayBorder,
            );
          }),
      ],
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _MiniStat({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.grayText, fontSize: 7, fontWeight: FontWeight.bold)),
        const Gap(2),
        Row(
          children: [
            Icon(icon, size: 11, color: color),
            const Gap(3),
            Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
          ],
        ),
      ],
    );
  }
}

class _SmallStatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _SmallStatTile({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlack.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.grayBorder.withOpacity(0.4), width: 0.5),
      ),
      child: Column(
        children: [
          Icon(icon, size: 12, color: color.withOpacity(0.8)),
          const Gap(3),
          Text(value,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
          const Gap(1),
          Text(label, style: const TextStyle(color: AppTheme.grayText, fontSize: 7, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Big 2×2 grid tile ────────────────────────────────────────────────────────
class _BigStatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _BigStatTile({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryBlack.withOpacity(0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 0.8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: isMobile ? 22 : 28, color: color.withOpacity(0.85)),
          Gap(isMobile ? 4 : 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: isMobile ? 20 : 28,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
              shadows: [Shadow(color: color.withOpacity(0.3), blurRadius: 10)],
            ),
          ),
          Gap(isMobile ? 2 : 4),
          Text(
            label,
            style: TextStyle(color: AppTheme.grayText, fontSize: isMobile ? 7 : 9, fontWeight: FontWeight.bold, letterSpacing: 1),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LivePulser extends StatefulWidget {
  const _LivePulser();
  @override
  State<_LivePulser> createState() => _LivePulserState();
}

class _LivePulserState extends State<_LivePulser> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FadeTransition(
          opacity: _controller,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: AppTheme.primaryRed, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 6),
        const Text('LIVE',
            style: TextStyle(color: AppTheme.primaryRed, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ],
    );
  }
}
