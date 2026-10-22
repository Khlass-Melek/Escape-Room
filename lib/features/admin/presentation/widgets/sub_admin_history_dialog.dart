import 'package:escape_room_admin/core/theme/app_theme.dart';
import 'package:escape_room_admin/features/admin/data/sub_admin_provider.dart';
import 'package:escape_room_admin/features/auth/domain/models/user.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class SubAdminHistoryDialog extends StatelessWidget {
  final User user;
  final List<AdminLog> logs;

  const SubAdminHistoryDialog({super.key, required this.user, required this.logs});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.secondaryBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.grayBorder, width: 1),
      ),
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Historique: \${user.username}',
                  style: TextStyle(
                    color: AppTheme.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.grayText),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Gap(16),
            Expanded(
              child: logs.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucun historique disponible.',
                        style: TextStyle(color: AppTheme.grayText),
                      ),
                    )
                  : ListView.separated(
                      itemCount: logs.length,
                      separatorBuilder: (context, index) => const Divider(
                        color: AppTheme.grayBorder,
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          leading: const CircleAvatar(
                            backgroundColor: AppTheme.primaryRed,
                            radius: 16,
                            child: Icon(Icons.history, size: 16, color: AppTheme.white),
                          ),
                          title: Text(
                            log.action,
                            style: const TextStyle(color: AppTheme.white, fontSize: 14),
                          ),
                          subtitle: Text(
                            DateFormat('dd MMM yyyy, HH:mm').format(log.timestamp),
                            style: const TextStyle(color: AppTheme.grayText, fontSize: 12),
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
