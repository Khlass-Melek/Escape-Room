
import 'package:escape_room_admin/core/theme/app_theme.dart';
import 'package:escape_room_admin/shared/widgets/app_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:escape_room_admin/features/dashboard/data/scenario_provider.dart';
import 'package:go_router/go_router.dart';

import 'package:escape_room_admin/shared/utils/responsive.dart';

class ScenariosListPage extends ConsumerWidget {
  const ScenariosListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenariosAsync = ref.watch(scenarioProvider);
    final bool isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: AppBar(
        title: Text(isMobile ? 'SCÉNARIOS' : 'CATALOGUE DES SCÉNARIOS', 
          style: const TextStyle(letterSpacing: 2, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.secondaryBlack,
        elevation: 10,
      ),
      drawer: const AppDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              AppTheme.secondaryBlack.withOpacity(0.4),
              AppTheme.primaryBlack,
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.movie_filter_rounded, color: AppTheme.primaryRed, size: isMobile ? 24 : 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      isMobile ? 'EXPÉRIENCES' : 'SÉLECTIONNEZ UNE EXPÉRIENCE',
                      style: (isMobile ? Theme.of(context).textTheme.titleLarge : Theme.of(context).textTheme.headlineSmall)?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.white,
                            letterSpacing: 1.5,
                          ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 24 : 32),
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
                        mainAxisSpacing: isMobile ? 20 : 32,
                        crossAxisSpacing: isMobile ? 20 : 32,
                        childAspectRatio: isMobile ? 1.4 : 1.65,
                      ),
                      itemCount: scenarios.length,
                      itemBuilder: (context, index) {
                        final scenario = scenarios[index];
                        return _ScenarioCard(
                          name: scenario.name,
                          isActive: scenario.isActive,
                          players: scenario.players,
                          time: '${scenario.estimatedTime} min',
                          image: scenario.image,
                          onTap: () {
                            context.go('/dashboard/${scenario.id}');
                          },
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

class _ScenarioCard extends StatefulWidget {
  final String name;
  final bool isActive;
  final String players;
  final String time;
  final String image;
  final VoidCallback onTap;

  const _ScenarioCard({
    required this.name,
    required this.isActive,
    required this.players,
    required this.time,
    required this.image,
    required this.onTap,
  });

  @override
  State<_ScenarioCard> createState() => _ScenarioCardState();
}

class _ScenarioCardState extends State<_ScenarioCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()..translate(0.0, _isHovered ? -15.0 : 0.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _isHovered ? AppTheme.primaryRed.withOpacity(0.2) : Colors.black.withOpacity(0.6),
                blurRadius: _isHovered ? 30 : 20,
                offset: Offset(0, _isHovered ? 12 : 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background Image with Ken Burns-ish effect on hover
                AnimatedScale(
                  scale: _isHovered ? 1.1 : 1.0,
                  duration: const Duration(seconds: 2),
                  curve: Curves.linearToEaseOut,
                  child: Image.asset(
                    widget.image,
                    fit: BoxFit.cover,
                  ),
                ),

                // Dynamic Gradient Overlay
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.4, 0.8, 1.0],
                      colors: [
                        Colors.black.withOpacity(0.2),
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                        Colors.black,
                      ],
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Status Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: widget.isActive ? AppTheme.primaryRed : AppTheme.successGreen,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: (widget.isActive ? AppTheme.primaryRed : AppTheme.successGreen).withOpacity(0.4),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  widget.isActive ? Icons.emergency_rounded : Icons.check_circle_rounded,
                                  size: 10,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  widget.isActive ? 'EN COURS' : 'DISPONIBLE',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Bottom Content
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _InfoIcon(icon: Icons.people_outline_rounded, label: widget.players),
                              const SizedBox(width: 16),
                              _InfoIcon(icon: Icons.timer_outlined, label: widget.time),
                            ],
                          ),
                          const SizedBox(height: 16),
                          AnimatedOpacity(
                            opacity: _isHovered ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text(
                                  'VISUALISER LA SALLE',
                                  style: TextStyle(
                                    color: AppTheme.primaryBlack,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Selection Glow Effect
                if (_isHovered)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.primaryRed.withOpacity(0.5), width: 2),
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoIcon extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.white.withOpacity(0.7), size: 14),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.white.withOpacity(0.7),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
