
import 'package:escape_room_admin/core/theme/app_theme.dart';
import 'package:escape_room_admin/shared/widgets/app_drawer.dart';
import 'package:escape_room_admin/shared/widgets/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

import 'package:escape_room_admin/features/dashboard/data/scenario_provider.dart';
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
                          style: (isMobile ? Theme.of(context).textTheme.titleLarge : Theme.of(context).textTheme.headlineSmall)?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.white,
                                letterSpacing: 2,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isMobile ? 'PERFORMANCES LIVE' : 'SUIVI DES PERFORMANCES EN TEMPS RÉEL',
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
                  if (!isMobile) _GlobalStat(label: 'SALLES ACTIVES', value: '01 / 06', icon: Icons.sensors_rounded),
                ],
              ),
              SizedBox(height: isMobile ? 32 : 40),
              Expanded(
                child: scenariosAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed)),
                  error: (err, stack) => Center(child: Text('Erreur: $err', style: const TextStyle(color: AppTheme.primaryRed))),
                  data: (scenarios) {
                    if (scenarios.isEmpty) {
                      return const Center(child: Text('Aucun scénario trouvé', style: TextStyle(color: AppTheme.grayText)));
                    }
                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isMobile ? 1 : (Responsive.isTablet(context) ? 2 : 3),
                        mainAxisSpacing: isMobile ? 20 : 24,
                        crossAxisSpacing: isMobile ? 20 : 24,
                        childAspectRatio: isMobile ? 1.1 : 1.7,
                      ),
                      itemCount: scenarios.length,
                      itemBuilder: (context, index) {
                        final scenario = scenarios[index];
                        return FadeInSlide(
                          duration: const Duration(milliseconds: 600),
                          delay: index * 0.08,
                          child: HoverScaleCard(
                            onTap: () {
                              context.go('/dashboard/${scenario.id}');
                            },
                            child: _DashboardCard(
                              name: scenario.name,
                              active: scenario.isActive,
                              successRate: 0.5, // Placeholder
                              avgTime: '${scenario.estimatedTime}:00',
                              difficulty: scenario.difficulty,
                              image: scenario.image,
                            ),
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
              Text(value, style: const TextStyle(color: AppTheme.white, fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
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
  final double successRate;
  final String avgTime;
  final int difficulty;
  final String image;

  const _DashboardCard({
    required this.name,
    required this.active,
    required this.successRate,
    required this.avgTime,
    required this.difficulty,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
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
            // Background Image
            Opacity(
              opacity: 0.15,
              child: Image.asset(
                image,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppTheme.secondaryBlack.withOpacity(0.8),
                    AppTheme.secondaryBlack.withOpacity(0.3),
                  ],
                ),
              ),
            ),
            Padding(
            padding: EdgeInsets.all(Responsive.isMobile(context) ? 12.0 : 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          color: AppTheme.white,
                          fontSize: Responsive.isMobile(context) ? 14 : 18,
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
                SizedBox(height: Responsive.isMobile(context) ? 12 : 24),
                const Spacer(),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    _StatBlock(
                      label: 'Taux de succès',
                      value: '${(successRate * 100).toInt()}%',
                      icon: Icons.auto_graph_rounded,
                      color: AppTheme.successGreen,
                    ),
                    _StatBlock(
                      label: 'Temps Moyen',
                      value: avgTime,
                      icon: Icons.timer_outlined,
                      color: AppTheme.warningOrange,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _DifficultyBar(level: difficulty),
              ],
            ),
          ),
          // Subtle background "ID" overlay
          Positioned(
            right: -10,
            bottom: -5,
            child: Opacity(
              opacity: 0.03,
              child: Text(
                'DATA.0${name.length}',
                style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBlock({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: AppTheme.grayText),
            const SizedBox(width: 4),
            Text(label.toUpperCase(), style: const TextStyle(color: AppTheme.grayText, fontSize: 8, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
      ],
    );
  }
}

class _DifficultyBar extends StatelessWidget {
  final int level;
  const _DifficultyBar({required this.level});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('NIVEAU DE DIFFICULTÉ', style: TextStyle(color: AppTheme.grayText, fontSize: 8, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            final isFilled = index < level;
            return Expanded(
              child: Container(
                height: 4,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: isFilled ? AppTheme.primaryRed : AppTheme.grayBorder.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: isFilled ? [BoxShadow(color: AppTheme.primaryRed.withOpacity(0.3), blurRadius: 4)] : null,
                ),
              ),
            );
          }),
        ),
      ],
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
        const SizedBox(width: 8),
        const Text(
          'LIVE',
          style: TextStyle(color: AppTheme.primaryRed, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
      ],
    );
  }
}
