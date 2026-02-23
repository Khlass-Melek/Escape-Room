import 'package:escape_room_admin/core/theme/app_theme.dart';
import 'package:escape_room_admin/features/admin/domain/models/enigma.dart';
import 'package:escape_room_admin/shared/widgets/primary_button.dart';
import 'package:escape_room_admin/shared/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class EnigmaFormDialog extends StatefulWidget {
  final Enigma? existingEnigma;

  const EnigmaFormDialog({super.key, this.existingEnigma});

  @override
  State<EnigmaFormDialog> createState() => _EnigmaFormDialogState();
}

class _EnigmaFormDialogState extends State<EnigmaFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late String _selectedType;
  late String _selectedDifficulty;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingEnigma?.name ?? '');
    _descriptionController = TextEditingController(text: widget.existingEnigma?.description ?? '');
    
    // Default values if creating a new enigma
    _selectedType = widget.existingEnigma?.type ?? 'Logique';
    _selectedDifficulty = widget.existingEnigma?.difficulty ?? 'Moyen';
    _isActive = widget.existingEnigma?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameController.text.trim().isEmpty || _descriptionController.text.trim().isEmpty) return;

    Navigator.of(context).pop({
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'type': _selectedType,
      'difficulty': _selectedDifficulty,
      'isActive': _isActive,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingEnigma != null;

    return Dialog(
      backgroundColor: AppTheme.secondaryBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.grayBorder, width: 1),
      ),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEditing ? 'Modifier Énigme' : 'Créer Énigme',
                style: const TextStyle(
                  color: AppTheme.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Gap(24),
              CustomTextField(
                controller: _nameController,
                label: "Nom de l'énigme",
                hint: 'Ex: Tableau Électrique',
              ),
              const Gap(16),
              const Text(
                'Type',
                style: TextStyle(color: AppTheme.grayText, fontSize: 14),
              ),
              const Gap(8),
              _buildDropdown(
                value: _selectedType,
                items: ['Logique', 'Câblage', 'Tic Tac Toe', 'Mécanique', 'Code PIN'],
                onChanged: (val) => setState(() => _selectedType = val!),
              ),
              const Gap(16),
              const Text(
                'Difficulté',
                style: TextStyle(color: AppTheme.grayText, fontSize: 14),
              ),
              const Gap(8),
              _buildDropdown(
                value: _selectedDifficulty,
                items: ['Facile', 'Moyen', 'Difficile'],
                onChanged: (val) => setState(() => _selectedDifficulty = val!),
              ),
              const Gap(16),
              CustomTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: "Entrez les détails de l'énigme...",
              ),
              const Gap(16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Statut',
                    style: TextStyle(color: AppTheme.grayText, fontSize: 14),
                  ),
                  Switch(
                    value: _isActive,
                    activeColor: AppTheme.primaryRed,
                    onChanged: (val) => setState(() => _isActive = val),
                  ),
                ],
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
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.grayBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: AppTheme.primaryBlack,
          icon: const Icon(Icons.arrow_drop_down, color: AppTheme.white),
          isExpanded: true,
          items: items.map((item) => DropdownMenuItem(
                value: item,
                child: Text(item, style: const TextStyle(color: AppTheme.white)),
              )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
