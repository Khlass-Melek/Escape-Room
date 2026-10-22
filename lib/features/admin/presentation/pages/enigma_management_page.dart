import 'package:escape_room_admin/core/theme/app_theme.dart';
import 'package:escape_room_admin/features/admin/data/enigma_provider.dart';
import 'package:escape_room_admin/features/admin/presentation/widgets/enigma_form_dialog.dart';
import 'package:escape_room_admin/shared/utils/responsive.dart';
import 'package:escape_room_admin/shared/widgets/app_drawer.dart';
import 'package:escape_room_admin/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class EnigmaManagementPage extends ConsumerWidget {
  const EnigmaManagementPage({super.key});

  void _showAddDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const EnigmaFormDialog(),
    );

    if (result != null) {
      ref.read(enigmaProvider.notifier).addEnigma(
            result['name'] as String,
            result['type'] as String,
            result['description'] as String,
            result['difficulty'] as String,
            result['isActive'] as bool,
            result['configuration'] as Map<String, dynamic>,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Énigme créée avec succès')),
        );
      }
    }
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, enigma) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => EnigmaFormDialog(existingEnigma: enigma),
    );

    if (result != null) {
      ref.read(enigmaProvider.notifier).updateEnigma(
            enigma.id,
            result['name'] as String,
            result['type'] as String,
            result['description'] as String,
            result['difficulty'] as String,
            result['isActive'] as bool,
            result['configuration'] as Map<String, dynamic>,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Énigme mise à jour avec succès')),
        );
      }
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, enigma) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.secondaryBlack,
        title: const Text('Supprimer', style: TextStyle(color: AppTheme.white)),
        content: const Text(
          'Voulez-vous vraiment supprimer "\${enigma.name}"?',
          style: TextStyle(color: AppTheme.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler', style: TextStyle(color: AppTheme.grayText)),
          ),
          TextButton(
            onPressed: () {
              ref.read(enigmaProvider.notifier).deleteEnigma(enigma.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Énigme supprimée')),
              );
            },
            child: const Text('Supprimer', style: TextStyle(color: AppTheme.primaryRed)),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'facile':
        return Colors.green;
      case 'moyen':
        return Colors.orange;
      case 'difficile':
        return Colors.red;
      default:
        return AppTheme.grayText;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);

    return Scaffold(
      backgroundColor: AppTheme.primaryBlack,
      appBar: !isDesktop
          ? AppBar(
              backgroundColor: AppTheme.secondaryBlack,
              title: const Text('Gestion des Énigmes', style: TextStyle(color: AppTheme.white)),
              iconTheme: const IconThemeData(color: AppTheme.white),
            )
          : null,
      drawer: !isDesktop ? const AppDrawer() : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop) const AppDrawer(),
          Expanded(
            child: CustomScrollView(
              slivers: [
                if (isDesktop)
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryBlack,
                        border: Border(
                          bottom: BorderSide(color: AppTheme.grayBorder, width: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.extension_outlined, color: AppTheme.primaryRed, size: 28),
                          const Gap(12),
                          const Text(
                            'Gestion des Énigmes',
                            style: TextStyle(
                              color: AppTheme.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const Spacer(),
                          PrimaryButton(
                            label: 'Ajouter une Énigme',
                            icon: Icons.add,
                            onPressed: () => _showAddDialog(context, ref),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (!isDesktop)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: PrimaryButton(
                        label: 'Ajouter une Énigme',
                        icon: Icons.add,
                        onPressed: () => _showAddDialog(context, ref),
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: EdgeInsets.all(isDesktop ? 24 : 16),
                  sliver: _buildEnigmasGrid(context, ref, isDesktop || isTablet),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnigmasGrid(BuildContext context, WidgetRef ref, bool isWideScreen) {
    final enigmaStateAsync = ref.watch(enigmaProvider);

    return enigmaStateAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(top: 100),
            child: CircularProgressIndicator(color: AppTheme.primaryRed),
          ),
        ),
      ),
      error: (err, stack) => SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 100),
            child: Text(
              'Erreur: $err',
              style: const TextStyle(color: AppTheme.primaryRed, fontSize: 16),
            ),
          ),
        ),
      ),
      data: (enigmaState) {
        final enigmas = enigmaState.enigmas;

    if (enigmas.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 100),
            child: Text(
              'Aucune énigme trouvée',
              style: TextStyle(color: AppTheme.grayText.withValues(alpha: 0.5), fontSize: 18),
            ),
          ),
        ),
      );
    }

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWideScreen ? 3 : 1,
        childAspectRatio: isWideScreen ? 1.4 : 2.5,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final enigma = enigmas[index];
          return Card(
            color: AppTheme.secondaryBlack,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppTheme.grayBorder, width: 0.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          enigma.name,
                          style: const TextStyle(
                            color: AppTheme.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: enigma.isActive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: enigma.isActive ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          enigma.isActive ? 'Actif' : 'Inactif',
                          style: TextStyle(
                            color: enigma.isActive ? Colors.green : Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(8),
                  Text(
                    enigma.type,
                    style: const TextStyle(color: AppTheme.primaryRed, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Text(
                      enigma.description,
                      style: const TextStyle(color: AppTheme.grayText, fontSize: 14),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Gap(16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.monitor_heart, color: _getDifficultyColor(enigma.difficulty), size: 16),
                          const Gap(6),
                          Text(
                            enigma.difficulty,
                            style: TextStyle(color: _getDifficultyColor(enigma.difficulty), fontSize: 14),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.power_settings_new, color: AppTheme.white, size: 20),
                            tooltip: 'Basculer Statut',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => ref.read(enigmaProvider.notifier).toggleEnigmaStatus(enigma.id),
                          ),
                          const Gap(12),
                          IconButton(
                            icon: const Icon(Icons.edit, color: AppTheme.grayText, size: 20),
                            tooltip: 'Modifier',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _showEditDialog(context, ref, enigma),
                          ),
                          const Gap(12),
                          IconButton(
                            icon: const Icon(Icons.delete, color: AppTheme.primaryRed, size: 20),
                            tooltip: 'Supprimer',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _confirmDelete(context, ref, enigma),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
        childCount: enigmas.length,
      ),
    );
    }); // Closes the `.when()`
  }
}
