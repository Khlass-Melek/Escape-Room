import 'package:escape_room_admin/core/theme/app_theme.dart';
import 'package:escape_room_admin/features/dashboard/data/game_report_provider.dart';
import 'package:escape_room_admin/features/dashboard/data/scenario_provider.dart';
import 'package:escape_room_admin/models/game_report.dart';
import 'package:escape_room_admin/shared/widgets/custom_text_field.dart';
import 'package:escape_room_admin/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class GameReportForm extends ConsumerStatefulWidget {
  final String? scenarioId;
  final String? sessionId;
  final GameReport? initialReport;

  const GameReportForm({
    super.key,
    this.scenarioId,
    this.sessionId,
    this.initialReport,
  });

  @override
  ConsumerState<GameReportForm> createState() => _GameReportFormState();
}

class _GameReportFormState extends ConsumerState<GameReportForm> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedScenarioId;
  int _percentage = 100;
  bool _isSuccess = true;
  late TextEditingController _timeController;
  late TextEditingController _playersController;
  late TextEditingController _cluesController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _selectedScenarioId = widget.scenarioId ?? widget.initialReport?.scenarioId;
    _percentage = widget.initialReport?.percentageCompleted ?? 100;
    _isSuccess = widget.initialReport?.isSuccess ?? true;
    _timeController = TextEditingController(text: (widget.initialReport?.timePlayedMinutes ?? 60).toString());
    _playersController = TextEditingController(text: (widget.initialReport?.playerCount ?? 4).toString());
    _cluesController = TextEditingController(text: (widget.initialReport?.cluesUsed ?? 0).toString());
    _notesController = TextEditingController(text: widget.initialReport?.gamemasterNotes ?? '');
  }

  @override
  void dispose() {
    _timeController.dispose();
    _playersController.dispose();
    _cluesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedScenarioId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez sélectionner un scénario')),
        );
        return;
      }

      final report = GameReport(
        id: widget.initialReport?.id, // Preserve ID for upsert
        scenarioId: _selectedScenarioId!,
        sessionId: widget.sessionId ?? widget.initialReport?.sessionId,
        percentageCompleted: _percentage,
        timePlayedMinutes: int.parse(_timeController.text),
        isSuccess: _isSuccess,
        playerCount: int.parse(_playersController.text),
        cluesUsed: int.parse(_cluesController.text),
        gamemasterNotes: _notesController.text,
        status: 'completed',
      );

      await ref.read(gameReportProvider.notifier).submitReport(report);
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.secondaryBlack,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'RAPPORT DE MISSION',
                      style: TextStyle(
                        color: AppTheme.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.grayText),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(color: AppTheme.grayBorder, height: 32),

                // Scenario Selection (if not fixed)
                if (widget.scenarioId == null && widget.initialReport == null) ...[
                  const Text('SÉLECTIONNER LE SCÉNARIO',
                      style: TextStyle(color: AppTheme.primaryRed, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const Gap(8),
                  ref.watch(scenarioProvider).when(
                    data: (scenarios) => DropdownButtonFormField<String>(
                      initialValue: _selectedScenarioId,
                      dropdownColor: AppTheme.secondaryBlack,
                      style: const TextStyle(color: AppTheme.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppTheme.primaryBlack,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.grayBorder),
                        ),
                      ),
                      items: scenarios.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                      onChanged: (val) => setState(() => _selectedScenarioId = val),
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, _) => const Text('Erreur de chargement', style: TextStyle(color: AppTheme.secondaryRed)),
                  ),
                  const Gap(24),
                ],

                // Progression Section
                const Text('PROGRESSION DES JOUEURS',
                    style: TextStyle(color: AppTheme.primaryRed, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const Gap(8),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _percentage.toDouble(),
                        min: 0,
                        max: 100,
                        divisions: 20,
                        activeColor: AppTheme.primaryRed,
                        inactiveColor: AppTheme.grayBorder,
                        label: '$_percentage%',
                        onChanged: (v) => setState(() => _percentage = v.toInt()),
                      ),
                    ),
                    Text('$_percentage%', style: const TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'monospace')),
                  ],
                ),
                const Gap(16),

                // Success Switch
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlack,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.grayBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('MISSION RÉUSSIE ?', style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.bold)),
                      Switch(
                        value: _isSuccess,
                        activeThumbColor: AppTheme.successGreen,
                        onChanged: (v) => setState(() => _isSuccess = v),
                      ),
                    ],
                  ),
                ),
                const Gap(24),

                // Numeric Fields
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'TEMPS (MIN)',
                        controller: _timeController,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const Gap(16),
                    Expanded(
                      child: CustomTextField(
                        label: 'JOUEURS',
                        controller: _playersController,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const Gap(16),
                CustomTextField(
                  label: 'INDICES UTILISÉS',
                  controller: _cluesController,
                  keyboardType: TextInputType.number,
                ),
                const Gap(24),

                // Notes
                const Text('NOTES DU GAME MASTER', style: TextStyle(color: AppTheme.grayText, fontSize: 10, fontWeight: FontWeight.bold)),
                const Gap(8),
                TextFormField(
                  controller: _notesController,
                  maxLines: 4,
                  style: const TextStyle(color: AppTheme.white),
                  decoration: InputDecoration(
                    hintText: 'Comment s\'est passée la partie ?',
                    hintStyle: const TextStyle(color: AppTheme.grayText, fontSize: 12),
                    filled: true,
                    fillColor: AppTheme.primaryBlack,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.grayBorder)),
                  ),
                ),
                const Gap(32),

                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          if (_selectedScenarioId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Veuillez sélectionner un scénario')),
                            );
                            return;
                          }
                          final report = GameReport(
                            scenarioId: _selectedScenarioId!,
                            sessionId: widget.sessionId ?? widget.initialReport?.sessionId,
                            percentageCompleted: _percentage,
                            timePlayedMinutes: int.parse(_timeController.text),
                            isSuccess: _isSuccess,
                            status: 'pending',
                          );
                          await ref.read(gameReportProvider.notifier).submitReport(report);
                          if (context.mounted) Navigator.of(context).pop();
                        },
                        child: const Text('PLUS TARD', style: TextStyle(color: AppTheme.grayText)),
                      ),
                    ),
                    const Gap(16),
                    Expanded(
                      flex: 2,
                      child: PrimaryButton(
                        label: 'ENREGISTRER',
                        onPressed: _submit,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
