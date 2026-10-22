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
  late Map<String, dynamic> _configuration;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingEnigma?.name ?? '');
    _descriptionController = TextEditingController(text: widget.existingEnigma?.description ?? '');
    
    // Default values if creating a new enigma
    _selectedType = widget.existingEnigma?.type ?? 'Logique';
    _selectedDifficulty = widget.existingEnigma?.difficulty ?? 'Moyen';
    _isActive = widget.existingEnigma?.isActive ?? true;

    if (widget.existingEnigma != null && widget.existingEnigma!.configuration.isNotEmpty) {
      // Deep copy to avoid modifying the original until saved
      _configuration = Map<String, dynamic>.from(widget.existingEnigma!.configuration);
    } else {
      _configuration = _getDefaultConfigForType(_selectedType);
    }
  }

  Map<String, dynamic> _getDefaultConfigForType(String type) {
    switch (type) {
      case 'Tic Tac Toe':
        return {'ia_difficulty': 'Moyen'};
      case 'Reconnaissance Vocale':
        return {'target_phrase': ''};
      case 'Capteur Sonore':
        return {
          't1': 300,
          't2': 1000,
        };
      case 'Câblage':
        return {
          'connections': {
            'Source 1': 'A',
            'Source 2': 'B',
            'Source 3': 'C',
            'Source 4': 'D',
          }
        };
      case 'Interrupteurs Binaires':
        return {'switches': List.filled(9, 0)};
      case 'Capteurs de Poids':
        return {'target_weight_grams': 1000};
      case 'Plante Eau':
        return {'water_threshold': 50};
      default:
        return {};
    }
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
      'configuration': _configuration,
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
        width: 600, // widening it to accommodate grid config inputs
        height: 800, // making it taller
        padding: const EdgeInsets.all(24),
        child: Column(
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
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                      items: [
                        'Logique',
                        'Câblage',
                        'Tic Tac Toe',
                        'Mécanique',
                        'Code PIN',
                        'Reconnaissance Vocale',
                        'Capteur Sonore',
                        'Interrupteurs Binaires',
                        'Capteurs de Poids',
                        'Plante Eau'
                      ],
                      onChanged: (val) {
                        if (val != null && val != _selectedType) {
                          setState(() {
                            _selectedType = val;
                            _configuration = _getDefaultConfigForType(_selectedType);
                          });
                        }
                      },
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
                    const Gap(24),
                    // -- DYNAMIC CONFIGURATION UI --
                    if (_configuration.isNotEmpty) ...[
                      const Divider(color: AppTheme.grayBorder),
                      const Gap(16),
                      const Text(
                        'Configuration Spécifique',
                        style: TextStyle(color: AppTheme.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Gap(16),
                      _buildConfigurationUI(),
                      const Gap(24),
                      const Divider(color: AppTheme.grayBorder),
                      const Gap(16),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Statut',
                          style: TextStyle(color: AppTheme.grayText, fontSize: 14),
                        ),
                        Switch(
                          value: _isActive,
                          activeThumbColor: AppTheme.primaryRed,
                          onChanged: (val) => setState(() => _isActive = val),
                        ),
                      ],
                    ),
                    const Gap(16),
                  ],
                ),
              ),
            ),
            const Gap(16),
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

  Widget _buildConfigurationUI() {
    switch (_selectedType) {
      case 'Tic Tac Toe':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Niveau de difficulté de l'IA", style: TextStyle(color: AppTheme.grayText, fontSize: 14)),
            const Gap(8),
            _buildDropdown(
              value: _configuration['ia_difficulty'] as String? ?? 'Moyen',
              items: ['Facile', 'Moyen', 'Difficile', 'Imbattable'],
              onChanged: (val) => setState(() => _configuration['ia_difficulty'] = val),
            ),
          ],
        );
      case 'Reconnaissance Vocale':
        final defaultPhrases = "open the door now, i know the word, get me out fast, security is now disabled, secret code is accepted, end of the game, unlock the main system, access granted for all, the key is free, launch the central program";
        return TextFormField(
          initialValue: (_configuration['target_phrase'] == null || (_configuration['target_phrase'] as String).trim().isEmpty) ? defaultPhrases : _configuration['target_phrase'] as String,
          style: const TextStyle(color: AppTheme.white),
          decoration: const InputDecoration(
            labelText: 'Phrase(s) cible(s) (séparées par des virgules)',
            labelStyle: TextStyle(color: AppTheme.grayText),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.grayBorder)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryRed)),
          ),
          onChanged: (val) => _configuration['target_phrase'] = val,
        );
      case 'Capteur Sonore':
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextFormField(
                initialValue: _configuration['t1']?.toString() ?? '300',
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.white),
                decoration: const InputDecoration(
                  labelText: 'Seuil 1 - Clignotement (ex: 300)',
                  labelStyle: TextStyle(color: AppTheme.grayText),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.grayBorder)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryRed)),
                ),
                onChanged: (val) => _configuration['t1'] = int.tryParse(val) ?? 300,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextFormField(
                initialValue: _configuration['t2']?.toString() ?? '1000',
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.white),
                decoration: const InputDecoration(
                  labelText: 'Seuil 2 - Éteint 2min (ex: 1000)',
                  labelStyle: TextStyle(color: AppTheme.grayText),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.grayBorder)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryRed)),
                ),
                onChanged: (val) => _configuration['t2'] = int.tryParse(val) ?? 1000,
              ),
            ),
          ],
        );
      case 'Câblage':
        final connections = _configuration['connections'] as Map<String, dynamic>? ?? {};
        // S'assurer que les 4 sources existent
        for (int i = 1; i <= 4; i++) {
          connections.putIfAbsent('Source $i', () => ['A', 'B', 'C', 'D'][i - 1]);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Combinaison correcte (4 câbles)',
              style: TextStyle(color: AppTheme.grayText),
            ),
            const Gap(4),
            const Text(
              'Sources : GPIO 13, 12, 14, 26  |  Destinations A=GPIO33  B=GPIO32  C=GPIO27  D=GPIO25',
              style: TextStyle(color: AppTheme.grayText, fontSize: 10),
            ),
            const Gap(12),
            ...['Source 1', 'Source 2', 'Source 3', 'Source 4'].map((source) {
              String currentValue = connections[source] as String? ?? 'A';
              if (!['A', 'B', 'C', 'D'].contains(currentValue)) {
                currentValue = 'A';
                connections[source] = currentValue;
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(child: Text(source, style: const TextStyle(color: AppTheme.white))),
                    const Icon(Icons.arrow_forward, color: AppTheme.grayText, size: 20),
                    const Gap(16),
                    Expanded(
                      flex: 2,
                      child: _buildDropdown(
                        value: currentValue,
                        items: ['A', 'B', 'C', 'D'],
                        onChanged: (val) => setState(() => connections[source] = val),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      case 'Interrupteurs Binaires':
        final switches = _configuration['switches'] as List<dynamic>? ?? List.filled(9, 0);
        return Column(
          children: [
            const Text('Configuration de la matrice 3x3 (Correcte)', style: TextStyle(color: AppTheme.grayText)),
            const Gap(16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2,
              ),
              itemCount: 9,
              itemBuilder: (context, index) {
                final isTrue = switches[index] == 1;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      switches[index] = isTrue ? 0 : 1;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isTrue ? AppTheme.primaryRed : AppTheme.primaryBlack,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.grayBorder),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      isTrue ? '1' : '0',
                      style: TextStyle(
                        color: isTrue ? AppTheme.white : AppTheme.grayText,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      case 'Capteurs de Poids':
        return TextFormField(
          initialValue: _configuration['target_weight_grams']?.toString() ?? '1000',
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppTheme.white),
          decoration: const InputDecoration(
            labelText: 'Poids cible correct (Grammes)',
            labelStyle: TextStyle(color: AppTheme.grayText),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.grayBorder)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryRed)),
          ),
          onChanged: (val) => _configuration['target_weight_grams'] = int.tryParse(val) ?? 0,
        );
      case 'Plante Eau':
        return TextFormField(
          initialValue: _configuration['water_threshold']?.toString() ?? '50',
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppTheme.white),
          decoration: const InputDecoration(
            labelText: "Seuil minimum d'eau (%)",
            labelStyle: TextStyle(color: AppTheme.grayText),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.grayBorder)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryRed)),
          ),
          onChanged: (val) => _configuration['water_threshold'] = int.tryParse(val) ?? 0,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
