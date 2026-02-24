
import 'package:escape_room_admin/core/theme/app_theme.dart';
import 'package:escape_room_admin/shared/widgets/app_drawer.dart';
import 'package:escape_room_admin/shared/widgets/primary_button.dart';
import 'package:escape_room_admin/shared/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:escape_room_admin/features/dashboard/data/scenario_provider.dart';
import 'package:escape_room_admin/features/admin/data/enigma_provider.dart';
import 'package:escape_room_admin/features/dashboard/data/clue_provider.dart';
import 'package:escape_room_admin/features/dashboard/data/audio_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

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

  String? _editingScenarioId;
  String _selectedImage = 'assets/images/saw1.jpg';
  List<String> _cameras = [];
  List<String> _rooms = [];
  Map<String, String?> _enigmaCameraMappings = {}; // enigmaId -> cameraIp
  final _musicFolderController = TextEditingController();


  final List<String> _availableImages = [
    'assets/images/saw1.jpg',
    'assets/images/saw2.jpg',
    'assets/images/pirate.png',
    'assets/images/cannibal.png',
    'assets/images/Guantanamo.png',
    'assets/images/mafia.png',
  ];

  final TextEditingController _clueController = TextEditingController();
  final TextEditingController _audioTitleController = TextEditingController();
  final TextEditingController _audioFileController = TextEditingController();

  void _enterFormView([Map<String, dynamic>? scenario, List<String> mappedEnigmas = const []]) {
    setState(() {
      if (scenario != null) {
        _editingScenarioId = scenario['id'];
        _nameController.text = scenario['name'];
        _descriptionController.text = scenario['description'] ?? '';
        _selectedImage = scenario['image'] ?? 'assets/images/saw1.jpg';
        _musicFolderController.text = scenario['music_folder_path'] ?? '';
        _cameras = List<String>.from(scenario['cameras'] ?? []);
        _rooms = [];
        _enigmaCameraMappings = {}; // Will be set by _fetchMappedEnigmasAndEnterForm for edits



        // Load clues and audio for this scenario
        ref.read(clueProvider.notifier).loadClues(_editingScenarioId!);
        ref.read(audioProvider.notifier).loadTracks(_editingScenarioId!);
      } else {
        _editingScenarioId = null;
        _nameController.clear();
        _descriptionController.clear();
        _selectedImage = 'assets/images/saw1.jpg';
        _musicFolderController.clear();
        _cameras = [];
        _rooms = [];
        _enigmaCameraMappings = {};

      }
      _currentView = _SettingsView.form;
    });
  }

  Future<void> _fetchMappedEnigmasAndEnterForm(Map<String, dynamic> scenario) async {
    final client = supa.Supabase.instance.client;
    final res = await client.from('scenario_puzzles').select('puzzle_id, camera_ip').eq('scenario_id', scenario['id']);
    
    final Map<String, String?> mappings = {};
    for (var row in res) {
      mappings[row['puzzle_id'].toString()] = row['camera_ip']?.toString();
    }
    
    _enterFormView(scenario);
    setState(() {
      _enigmaCameraMappings = mappings;
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
    final scenariosAsync = ref.watch(scenarioProvider);
    
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
              child: scenariosAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed)),
                error: (e, s) => Center(child: Text('Erreur: $e', style: const TextStyle(color: AppTheme.primaryRed))),
                data: (scenarios) {
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isMobile ? 1 : (Responsive.isTablet(context) ? 2 : 3),
                      mainAxisSpacing: isMobile ? 20 : 24,
                      crossAxisSpacing: isMobile ? 20 : 24,
                      childAspectRatio: isMobile ? 1.5 : 1.4,
                    ),
                    itemCount: scenarios.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildAddButton();
                      }
                      final scenario = scenarios[index - 1];
                      return _buildScenarioItem({
                        'id': scenario.id,
                        'name': scenario.name,
                        'description': scenario.description,
                        'image': scenario.image,
                        'cameras': scenario.cameras,
                        'music_folder_path': scenario.musicFolderPath,
                      });
                    },
                  );
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
      onTap: () => _fetchMappedEnigmasAndEnterForm(scenario),
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
                  const Gap(24),
                  CustomTextField(
                    controller: _musicFolderController,
                    label: 'CHEMIN DU DOSSIER MUSIQUE',
                    hint: 'EX: C:/Users/Admin/Music/EscapeRoom',
                  ),
                  const Gap(24),
                  const Text('IMAGE DU SCÉNARIO', style: TextStyle(color: AppTheme.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  const Gap(16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: _availableImages.length,
                    itemBuilder: (context, index) {
                      final img = _availableImages[index];
                      final isSelected = _selectedImage == img;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedImage = img),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppTheme.primaryRed : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: Image.asset(img, fit: BoxFit.cover),
                          ),
                        ),
                      );
                    },
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
                    child: Consumer(
                      builder: (context, ref, child) {
                        final enigmaAsync = ref.watch(enigmaProvider);
                        return enigmaAsync.when(
                          loading: () => const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()),
                          error: (e, s) => Padding(padding: const EdgeInsets.all(20), child: Text('Erreur: $e', style: const TextStyle(color: AppTheme.primaryRed))),
                          data: (enigmaState) {
                            final enigmas = enigmaState.enigmas;
                            if (enigmas.isEmpty) {
                              return const Padding(padding: EdgeInsets.all(20), child: Text('Aucune énigme disponible. Veuillez en créer une dans la gestion des énigmes.'));
                            }
                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: enigmas.length,
                              separatorBuilder: (_, __) => Divider(color: AppTheme.grayBorder.withOpacity(0.1), height: 1),
                              itemBuilder: (context, index) {
                                final enigma = enigmas[index];
                                final isSelected = _enigmaCameraMappings.containsKey(enigma.id);
                                final selectedIp = _enigmaCameraMappings[enigma.id];
                                
                                return Column(
                                  children: [
                                    SwitchListTile(
                                      title: Text(enigma.name.toUpperCase(), style: const TextStyle(color: AppTheme.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                      subtitle: Text('MODULE : ${enigma.type.toUpperCase()}', style: const TextStyle(color: AppTheme.grayText, fontSize: 9)),
                                      value: isSelected,
                                      activeColor: AppTheme.primaryRed,
                                      onChanged: (val) {
                                        setState(() {
                                          if (val) {
                                            _enigmaCameraMappings[enigma.id] = _cameras.isNotEmpty ? _cameras.first : null;
                                          } else {
                                            _enigmaCameraMappings.remove(enigma.id);
                                          }
                                        });
                                      },
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                                    ),
                                    if (isSelected && _cameras.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
                                        child: Row(
                                          children: [
                                            const Text('LIER À LA CAMÉRA :', style: TextStyle(color: AppTheme.grayText, fontSize: 10, fontWeight: FontWeight.bold)),
                                            const Gap(12),
                                            Expanded(
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primaryBlack,
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: AppTheme.primaryRed.withOpacity(0.3)),
                                                ),
                                                child: DropdownButton<String>(
                                                  value: _cameras.contains(selectedIp) ? selectedIp : _cameras.first,
                                                  dropdownColor: AppTheme.secondaryBlack,
                                                  underline: const SizedBox(),
                                                  isExpanded: true,
                                                  style: const TextStyle(color: AppTheme.white, fontSize: 12),
                                                  items: _cameras.map((ip) => DropdownMenuItem(
                                                    value: ip,
                                                    child: Text('CAMÉRA IP: $ip'),
                                                  )).toList(),
                                                  onChanged: (newIp) {
                                                    setState(() => _enigmaCameraMappings[enigma.id] = newIp);
                                                  },
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (isSelected && _cameras.isEmpty)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 20, right: 20, bottom: 12),
                                        child: Text(
                                          'VEUILLEZ AJOUTER UNE CAMÉRA CI-DESSUS POUR LIER CETTE ÉNIGME',
                                          style: TextStyle(color: AppTheme.warningOrange, fontSize: 9, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),

              const Gap(32),

              if (_editingScenarioId != null) ...[
                _buildFormSection(
                  title: 'MESSAGES PRÉDÉFINIS (CLUES)',
                  subtitle: 'GÉREZ LES INDICES POUR CE SCÉNARIO',
                  icon: Icons.chat_bubble_outline_rounded,
                  children: [
                    Consumer(builder: (context, ref, _) {
                      final cluesAsync = ref.watch(clueProvider);
                      return cluesAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, s) => Text('Erreur: $e'),
                        data: (clues) => Column(
                          children: [
                            ...clues.map((clue) => _buildListItem(
                              label: clue.content,
                              icon: Icons.message,
                              onDelete: () => ref.read(clueProvider.notifier).deleteClue(clue.id),
                            )),
                            const Gap(16),
                            Row(
                              children: [
                                Expanded(child: CustomTextField(controller: _clueController, label: 'NOUVEAU MESSAGE', hint: 'Tapez ici...')),
                                const Gap(12),
                                _CircleAddButton(onPressed: () {
                                  if (_clueController.text.isNotEmpty) {
                                    ref.read(clueProvider.notifier).addClue(_clueController.text);
                                    _clueController.clear();
                                  }
                                }),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
                const Gap(32),
                _buildFormSection(
                  title: 'MUSIQUE D\'AMBIANCE',
                  subtitle: 'GÉREZ LES PISTES AUDIO',
                  icon: Icons.music_note_rounded,
                  children: [
                    Consumer(builder: (context, ref, _) {
                      final audioAsync = ref.watch(audioProvider);
                      return audioAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, s) => Text('Erreur: $e'),
                        data: (audioState) => Column(
                          children: [
                            ...audioState.tracks.map((track) => _buildListItem(
                              label: '${track.title} (${track.filename})',
                              icon: Icons.audiotrack,
                              onDelete: () => ref.read(audioProvider.notifier).deleteTrack(track.id),
                            )),
                            const Gap(16),
                            Row(
                              children: [
                                Expanded(child: CustomTextField(controller: _audioTitleController, label: 'TITRE', hint: 'Ambiance horreur')),
                                const Gap(12),
                                Expanded(child: CustomTextField(controller: _audioFileController, label: 'FICHIER', hint: 'saw_theme.mp3')),
                                const Gap(12),
                                _CircleAddButton(onPressed: () {
                                  if (_audioTitleController.text.isNotEmpty && _audioFileController.text.isNotEmpty) {
                                    ref.read(audioProvider.notifier).addTrack(_audioTitleController.text, _audioFileController.text);
                                    _audioTitleController.clear();
                                    _audioFileController.clear();
                                  }
                                }),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
                const Gap(32),
              ],

              const Gap(64),
              PrimaryButton(
                label: _editingScenarioId == null ? 'ACTIVER LE SCÉNARIO' : 'METTRE À JOUR LE SYSTÈME',
                icon: Icons.power_settings_new_rounded,
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final data = {
                      'name': _nameController.text,
                      'description': _descriptionController.text,
                      'image': _selectedImage,
                      'music_folder_path': _musicFolderController.text,
                      'cameras': _cameras, // Store the list of IPs as JSONB
                    };

                    if (_editingScenarioId == null) {
                      await ref.read(scenarioProvider.notifier).addScenario(data, _enigmaCameraMappings);
                    } else {
                      await ref.read(scenarioProvider.notifier).updateScenario(_editingScenarioId!, data, _enigmaCameraMappings);
                    }

                    if (!context.mounted) return;

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
