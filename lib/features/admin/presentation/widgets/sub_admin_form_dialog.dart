import 'package:escape_room_admin/core/theme/app_theme.dart';
import 'package:escape_room_admin/features/auth/domain/models/user.dart';
import 'package:escape_room_admin/shared/widgets/primary_button.dart';
import 'package:escape_room_admin/shared/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class SubAdminFormDialog extends StatefulWidget {
  final User? existingUser;

  const SubAdminFormDialog({super.key, this.existingUser});

  @override
  State<SubAdminFormDialog> createState() => _SubAdminFormDialogState();
}

class _SubAdminFormDialogState extends State<SubAdminFormDialog> {
  late final TextEditingController _usernameController;
  late String _selectedRole;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.existingUser?.username ?? '');
    _selectedRole = widget.existingUser?.role ?? 'sous_admin';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_usernameController.text.trim().isEmpty) return;

    Navigator.of(context).pop({
      'username': _usernameController.text.trim(),
      'role': _selectedRole,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingUser != null;

    return Dialog(
      backgroundColor: AppTheme.secondaryBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.grayBorder, width: 1),
      ),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEditing ? 'Modifier Sous-Admin' : 'Créer Sous-Admin',
              style: const TextStyle(
                color: AppTheme.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(24),
            CustomTextField(
              controller: _usernameController,
              label: "Nom d'utilisateur",
              hint: "Entrez le nom",
            ),
            const Gap(16),
            const Text(
              'Rôle / Privilège',
              style: TextStyle(color: AppTheme.grayText, fontSize: 14),
            ),
            const Gap(8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlack,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.grayBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedRole,
                  dropdownColor: AppTheme.primaryBlack,
                  icon: const Icon(Icons.arrow_drop_down, color: AppTheme.white),
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: 'sous_admin',
                      child: Text('Sous-Admin', style: TextStyle(color: AppTheme.white)),
                    ),
                    DropdownMenuItem(
                      value: 'game_master',
                      child: Text('Game Master', style: TextStyle(color: AppTheme.white)),
                    ),
                    DropdownMenuItem(
                      value: 'viewer',
                      child: Text('Spectateur (Viewer)', style: TextStyle(color: AppTheme.white)),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedRole = val);
                    }
                  },
                ),
              ),
            ),
            const Gap(32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler', style: TextStyle(color: AppTheme.grayText)),
                ),
                const Gap(16),
                PrimaryButton(
                  label: isEditing ? 'Enregistrer' : 'Créer',
                  onPressed: _submit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
