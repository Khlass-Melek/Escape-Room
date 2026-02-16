
import 'package:escape_room_admin/core/theme/app_theme.dart';
import 'package:escape_room_admin/shared/widgets/app_drawer.dart';
import 'package:escape_room_admin/shared/widgets/primary_button.dart';
import 'package:escape_room_admin/shared/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:escape_room_admin/shared/utils/responsive.dart';

class ScenarioSettingsPage extends ConsumerStatefulWidget {
  const ScenarioSettingsPage({super.key});

  @override
  ConsumerState<ScenarioSettingsPage> createState() => _ScenarioSettingsPageState();
}

enum _SettingsView { selection, form }

class _ScenarioSettingsPageState extends ConsumerState<ScenarioSettingsPage> {
  _SettingsView _currentView = _SettingsView.selection;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final TextEditingController _cameraController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();

  // Mock list of existing scenarios for management
  final List<Map<String, dynamic>> _existingScenarios = [
    {'id': '1', 'name': 'SAW I', 'description': 'Scénario d\'horreur classique', 'image': 'assets/images/saw1.jpg'},
    {'id': '2', 'name': 'SAW II', 'description': 'La suite infernale', 'image': 'assets/images/saw2.jpg'},
    {'id': '3', 'name': 'Pirates des Caraïbes', 'description': 'Aventure en haute mer', 'image': 'assets/images/pirate.png'},
    {'id': '4', 'name': 'Le Cannibale', 'description': 'Survivez au dîner', 'image': 'assets/images/cannibal.png'},
    {'id': '5', 'name': 'Guantanamo', 'description': 'Évasion de haute sécurité', 'image': 'assets/images/Guantanamo.png'},
    {'id': '6', 'name': 'Mafia', 'description': 'Règlement de comptes', 'image': 'assets/images/mafia.png'},
  ];

  String? _editingScenarioId;
  List<String> _cameras = [];
  List<String> _rooms = [];
  Map<String, bool> _enigmas = {
    'Tic-Tac-Toe (IA)': false,
    'Reconnaissance Vocale': false,
    'Capteur Sonore (dB)': false,
    'Câblage': false,
    'Interrupteurs Binaires': false,
    'Capteurs de Poids': false,
    'Plante (Eau)': false,
  };

  void _enterFormView([Map<String, dynamic>? scenario]) {
    setState(() {
      if (scenario != null) {
        _editingScenarioId = scenario['id'];
        _nameController.text = scenario['name'];
        _descriptionController.text = scenario['description'] ?? '';
        // In a real app, load specific cameras/rooms/enigmas here
        _cameras = ['192.168.1.101'];
        _rooms = ['Chambre Alpha'];
        _enigmas.updateAll((key, value) => false);
        _enigmas['Tic-Tac-Toe (IA)'] = true;
      } else {
        _editingScenarioId = null;
        _nameController.clear();
        _descriptionController.clear();
        _cameras = [];
        _rooms = [];
        _enigmas.updateAll((key, value) => false);
      }
      _currentView = _SettingsView.form;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentView == _SettingsView.selection 
          ? 'Gestion des Scénarios' 
          : (_editingScenarioId == null ? 'Nouveau Scénario' : 'Modifier Scénario')),
        backgroundColor: AppTheme.secondaryBlack,
        leading: _currentView == _SettingsView.form 
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _currentView = _SettingsView.selection),
            )
          : null,
      ),
      drawer: _currentView == _SettingsView.selection ? const AppDrawer() : null,
      body: _currentView == _SettingsView.selection 
        ? _buildSelectionView() 
        : _buildFormView(),
    );
  }

  Widget _buildSelectionView() {
    final bool isMobile = Responsive.isMobile(context);
    
    return Container(
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
                Icon(Icons.settings_suggest_rounded, color: AppTheme.primaryRed, size: isMobile ? 24 : 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isMobile ? 'EXPÉRIENCES' : 'GESTION DES EXPÉRIENCES',
                        style: (isMobile ? Theme.of(context).textTheme.titleLarge : Theme.of(context).textTheme.headlineSmall)?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.white,
                              letterSpacing: 2,
                            ),
                      ),
                      Text(
                        isMobile ? 'CONFIGURATION' : 'MODIFIER LA CONFIGURATION OU CRÉER UN NOUVEAU SYSTÈME',
                        style: const TextStyle(color: AppTheme.grayText, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 32 : 40),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isMobile ? 1 : (Responsive.isTablet(context) ? 2 : 3),
                  mainAxisSpacing: isMobile ? 20 : 24,
                  crossAxisSpacing: isMobile ? 20 : 24,
                  childAspectRatio: isMobile ? 1.5 : 1.4,
                ),
                itemCount: _existingScenarios.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildAddButton();
                  }
                  final scenario = _existingScenarios[index - 1];
                  return _buildScenarioItem(scenario);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _enterFormView(),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.secondaryBlack,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.primaryRed.withOpacity(0.5), width: 1.5, style: BorderStyle.solid),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryRed.withOpacity(0.1),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_rounded, color: AppTheme.primaryRed, size: 48),
              ),
              const Gap(16),
              const Text(
                'NOUVEAU SYSTÈME',
                style: TextStyle(
                  color: AppTheme.primaryRed,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScenarioItem(Map<String, dynamic> scenario) {
    return _ScenarioEditCard(
      name: scenario['name'],
      description: scenario['description'] ?? '',
      image: scenario['image'] ?? 'assets/images/scenario_placeholder.jpg',
      onTap: () => _enterFormView(scenario),
    );
  }

  Widget _buildFormView() {
    final bool isMobile = Responsive.isMobile(context);
    
    return Container(
      decoration: const BoxDecoration(color: AppTheme.primaryBlack),
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16.0 : 40.0, vertical: 32.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFormSection(
                title: 'IDENTITÉ DE LA SALLE',
                subtitle: 'DÉFINISSEZ LE NOM ET L\'ATMOSPHÈRE DU SCÉNARIO',
                icon: Icons.badge_rounded,
                children: [
                  CustomTextField(
                    controller: _nameController,
                    label: 'NOM DU SCÉNARIO',
                    hint: 'EX: SAW I',
                  ),
                  const Gap(24),
                  CustomTextField(
                    controller: _descriptionController,
                    label: 'DESCRIPTION / SYNOPSIS',
                    hint: 'BRÈVE DESCRIPTION POUR L\'ADMINISTRATION...',
                  ),
                ],
              ),
              
              const Gap(32),

              _buildFormSection(
                title: 'INFRASTRUCTURE RÉSEAU',
                subtitle: 'CONFIGURATION DES CAMÉRAS DE SURVEILLANCE',
                icon: Icons.videocam_rounded,
                children: [
                  ..._cameras.asMap().entries.map((entry) => _buildListItem(
                    label: 'CAMÉRA IP : ${entry.value}',
                    icon: Icons.sensors_rounded,
                    onDelete: () => setState(() => _cameras.removeAt(entry.key)),
                  )),
                  const Gap(16),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _cameraController,
                          label: 'NOUVELLE IP',
                          hint: '192.168.1.X',
                        ),
                      ),
                      const Gap(16),
                      _CircleAddButton(onPressed: () {
                        if (_cameraController.text.isNotEmpty) {
                          setState(() {
                            _cameras.add(_cameraController.text);
                            _cameraController.clear();
                          });
                        }
                      }),
                    ],
                  ),
                ],
              ),

              const Gap(32),

              _buildFormSection(
                title: 'ARCHITECTURE PHYSIQUE',
                subtitle: 'DÉCOUPAGE DES ZONES ET CHAMBRES',
                icon: Icons.layers_rounded,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _rooms.map((room) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryRed.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(room, style: const TextStyle(color: AppTheme.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          const Gap(8),
                          GestureDetector(
                            onTap: () => setState(() => _rooms.remove(room)),
                            child: const Icon(Icons.close_rounded, size: 14, color: AppTheme.primaryRed),
                          ),
                        ],
                      ),
                    )).toList(),
                  ),
                  const Gap(24),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _roomController,
                          label: 'AJOUTER UNE ZONE',
                          hint: 'EX: BUREAU DU MAÎTRE',
                        ),
                      ),
                      const Gap(16),
                      _CircleAddButton(onPressed: () {
                        if (_roomController.text.isNotEmpty) {
                          setState(() {
                            _rooms.add(_roomController.text);
                            _roomController.clear();
                          });
                        }
                      }),
                    ],
                  ),
                ],
              ),

              const Gap(32),

              _buildFormSection(
                title: 'MODULES D\'ÉNIGMES ACTIVÉS',
                subtitle: 'SÉLECTIONNEZ LES SYSTÈMES À DÉPLOYER',
                icon: Icons.extension_rounded,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryBlack,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.grayBorder, width: 0.5),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _enigmas.length,
                      separatorBuilder: (_, __) => Divider(color: AppTheme.grayBorder.withOpacity(0.1), height: 1),
                      itemBuilder: (context, index) {
                        final key = _enigmas.keys.elementAt(index);
                        return SwitchListTile(
                          title: Text(key.toUpperCase(), style: const TextStyle(color: AppTheme.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          subtitle: Text('MODULE SYSTÈME RÉF: ${index + 101}', style: const TextStyle(color: AppTheme.grayText, fontSize: 9)),
                          value: _enigmas[key] ?? false,
                          activeColor: AppTheme.primaryRed,
                          onChanged: (val) => setState(() => _enigmas[key] = val),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const Gap(64),
              PrimaryButton(
                label: _editingScenarioId == null ? 'ACTIVER LE SCÉNARIO' : 'METTRE À JOUR LE SYSTÈME',
                icon: Icons.power_settings_new_rounded,
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_editingScenarioId == null 
                          ? 'DÉPLOIEMENT RÉUSSI !' 
                          : 'SYNCHRONISATION TERMINÉE !'),
                        backgroundColor: AppTheme.successGreen,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    setState(() => _currentView = _SettingsView.selection);
                  }
                },
              ),
              const Gap(48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.primaryRed, size: 20),
            ),
            const Gap(16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppTheme.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                Text(subtitle, style: const TextStyle(color: AppTheme.grayText, fontSize: 9, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        const Gap(24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.secondaryBlack.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.grayBorder.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildListItem({required String label, required IconData icon, required VoidCallback onDelete}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.grayBorder.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.grayText, size: 18),
          const Gap(16),
          Expanded(
            child: Text(label, style: const TextStyle(color: AppTheme.white, fontSize: 13, fontWeight: FontWeight.bold)),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.secondaryRed, size: 20),
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _ScenarioEditCard extends StatefulWidget {
  final String name;
  final String description;
  final String image;
  final VoidCallback onTap;

  const _ScenarioEditCard({
    required this.name,
    required this.description,
    required this.image,
    required this.onTap,
  });

  @override
  State<_ScenarioEditCard> createState() => _ScenarioEditCardState();
}

class _ScenarioEditCardState extends State<_ScenarioEditCard> {
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
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _isHovered ? AppTheme.primaryRed.withOpacity(0.1) : Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background Image
                AnimatedScale(
                  scale: _isHovered ? 1.05 : 1.0,
                  duration: const Duration(seconds: 2),
                  child: Image.asset(
                    widget.image,
                    fit: BoxFit.cover,
                  ),
                ),
                
                // Mask
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      const Gap(8),
                      Text(
                        widget.description,
                        style: TextStyle(
                          color: AppTheme.white.withOpacity(0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Gap(20),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _isHovered ? AppTheme.primaryRed : AppTheme.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isHovered ? Colors.transparent : AppTheme.white.withOpacity(0.2),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'MODIFIER LES RÉGLAGES',
                            style: TextStyle(
                              color: _isHovered ? Colors.white : AppTheme.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
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

class _CircleAddButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _CircleAddButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: AppTheme.successGreen,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}
