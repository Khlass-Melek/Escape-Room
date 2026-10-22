import 'package:escape_room_admin/core/theme/app_theme.dart';
import 'package:escape_room_admin/features/admin/data/sub_admin_provider.dart';
import 'package:escape_room_admin/features/admin/presentation/widgets/sub_admin_form_dialog.dart';
import 'package:escape_room_admin/features/admin/presentation/widgets/sub_admin_history_dialog.dart';
import 'package:escape_room_admin/shared/utils/responsive.dart';
import 'package:escape_room_admin/shared/widgets/app_drawer.dart';
import 'package:escape_room_admin/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class SubAdminManagementPage extends ConsumerWidget {
  const SubAdminManagementPage({super.key});

  void _showAddDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const SubAdminFormDialog(),
    );

    if (result != null) {
      ref.read(subAdminProvider.notifier).addSubAdmin(
            result['username']!,
            result['role']!,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sous-Admin créé avec succès')),
        );
      }
    }
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, int index, user) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => SubAdminFormDialog(existingUser: user),
    );

    if (result != null) {
      ref.read(subAdminProvider.notifier).updateSubAdmin(
            user.id,
            result['username']!,
            result['role']!,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sous-Admin mis à jour avec succès')),
        );
      }
    }
  }

  void _showHistoryDialog(BuildContext context, WidgetRef ref, user) {
    final logs = ref.read(subAdminProvider.notifier).getLogsForAdmin(user.id);
    showDialog(
      context: context,
      builder: (_) => SubAdminHistoryDialog(user: user, logs: logs),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.secondaryBlack,
        title: const Text('Supprimer', style: TextStyle(color: AppTheme.white)),
        content: const Text(
          'Voulez-vous vraiment supprimer \${user.username}?',
          style: TextStyle(color: AppTheme.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler', style: TextStyle(color: AppTheme.grayText)),
          ),
          TextButton(
            onPressed: () {
              ref.read(subAdminProvider.notifier).deleteSubAdmin(user.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sous-Admin supprimé')),
              );
            },
            child: const Text('Supprimer', style: TextStyle(color: AppTheme.primaryRed)),
          ),
        ],
      ),
    );
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
              title: const Text('Gestion des Sous-Admins', style: TextStyle(color: AppTheme.white)),
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
                          const Icon(Icons.admin_panel_settings, color: AppTheme.primaryRed, size: 28),
                          const Gap(12),
                          const Text(
                            'Gestion des Sous-Admins',
                            style: TextStyle(
                              color: AppTheme.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const Spacer(),
                          PrimaryButton(
                            label: 'Ajouter un Sous-Admin',
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
                        label: 'Ajouter un Sous-Admin',
                        icon: Icons.add,
                        onPressed: () => _showAddDialog(context, ref),
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: EdgeInsets.all(isDesktop ? 24 : 16),
                  sliver: _buildSubAdminList(context, ref, isDesktop || isTablet),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubAdminList(BuildContext context, WidgetRef ref, bool isWideScreen) {
    final subAdminStateAsync = ref.watch(subAdminProvider);

    return subAdminStateAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(top: 100),
            child: CircularProgressIndicator(color: AppTheme.primaryRed),
          ),
        ),
      ),
      error: (error, stack) => SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 100),
            child: Text(
              'Erreur: $error',
              style: const TextStyle(color: AppTheme.primaryRed, fontSize: 16),
            ),
          ),
        ),
      ),
      data: (subAdminState) {
        final users = subAdminState.subAdmins;

    if (users.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 100),
            child: Text(
              'Aucun sous-admin trouvé',
              style: TextStyle(color: AppTheme.grayText.withValues(alpha: 0.5), fontSize: 18),
            ),
          ),
        ),
      );
    }

    if (isWideScreen) {
      return SliverToBoxAdapter(
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.secondaryBlack,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.grayBorder, width: 0.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - (300 + 48)),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(AppTheme.primaryBlack.withValues(alpha: 0.5)),
                  dataRowMaxHeight: 70,
                  dataRowMinHeight: 70,
                  horizontalMargin: 24,
                  columnSpacing: 24,
                  columns: const [
                    DataColumn(label: Text("Nom d'utilisateur", style: TextStyle(color: AppTheme.grayText, fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Rôle', style: TextStyle(color: AppTheme.grayText, fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Actions', style: TextStyle(color: AppTheme.grayText, fontWeight: FontWeight.bold))),
                  ],
                  rows: users.asMap().entries.map((entry) {
                    final index = entry.key;
                    final user = entry.value;
                    return DataRow(
                      cells: [
                        DataCell(
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppTheme.primaryRed.withValues(alpha: 0.2),
                                child: Text(
                                  user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                                  style: const TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const Gap(16),
                              Text(user.username, style: const TextStyle(color: AppTheme.white)),
                            ],
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlack.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.grayBorder),
                            ),
                            child: Text(
                              user.role,
                              style: const TextStyle(color: AppTheme.grayText, fontSize: 12),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: AppTheme.grayText, size: 20),
                                tooltip: 'Modifier Privilèges',
                                onPressed: () => _showEditDialog(context, ref, index, user),
                              ),
                              IconButton(
                                icon: const Icon(Icons.history, color: AppTheme.grayText, size: 20),
                                tooltip: 'Voir Historique',
                                onPressed: () => _showHistoryDialog(context, ref, user),
                              ),
                              if (user.role != 'super_admin') // Prevent deleting super admins
                                IconButton(
                                  icon: const Icon(Icons.delete, color: AppTheme.primaryRed, size: 20),
                                  tooltip: 'Supprimer',
                                  onPressed: () => _confirmDelete(context, ref, user),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      // Mobile List View
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final user = users[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.secondaryBlack,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.grayBorder, width: 0.5),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryRed.withValues(alpha: 0.2),
                  child: Text(
                    user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(user.username, style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(user.role, style: const TextStyle(color: AppTheme.grayText)),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: AppTheme.grayText, size: 20),
                      onPressed: () => _showEditDialog(context, ref, index, user),
                    ),
                    IconButton(
                      icon: const Icon(Icons.history, color: AppTheme.grayText, size: 20),
                      onPressed: () => _showHistoryDialog(context, ref, user),
                    ),
                    if (user.role != 'super_admin')
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppTheme.primaryRed, size: 20),
                        onPressed: () => _confirmDelete(context, ref, user),
                      ),
                  ],
                ),
              ),
            );
          },
          childCount: users.length,
        ),
      );
    }
    }); // This closes the `when` method block
  }
}
