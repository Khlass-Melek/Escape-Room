
import 'package:escape_room_admin/core/theme/app_theme.dart';
import 'package:escape_room_admin/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class HintControlWidget extends StatefulWidget {
  const HintControlWidget({super.key});

  @override
  State<HintControlWidget> createState() => _HintControlWidgetState();
}

class _HintControlWidgetState extends State<HintControlWidget> {
  String? currentHint;
  final TextEditingController _customHintController = TextEditingController();

  final List<String> predefinedHints = [
    "Regardez sous le tapis.",
    "Le code est lié au nombre de livres.",
    "Vérifiez le tableau sur le mur.",
    "Rappelez-vous la séquence de couleurs.",
    "La clé est dans le tiroir du bas.",
  ];

  @override
  void dispose() {
    _customHintController.dispose();
    super.dispose();
  }

  void _sendHint(String hint) {
    setState(() {
      currentHint = hint;
    });
    // In a real app, this would send a WebSocket message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Indice envoyé: "$hint"'),
        backgroundColor: AppTheme.successGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showHintDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryBlack,
        title: const Text('Envoyer un Indice', style: TextStyle(color: AppTheme.white)),
        content: SizedBox(
          width: 400,
          child: DefaultTabController(
            length: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const TabBar(
                  labelColor: AppTheme.primaryRed,
                  unselectedLabelColor: AppTheme.grayText,
                  indicatorColor: AppTheme.primaryRed,
                  tabs: [
                    Tab(text: 'Prédéfinis'),
                    Tab(text: 'Personnalisé'),
                  ],
                ),
                SizedBox(
                  height: 300,
                  child: TabBarView(
                    children: [
                      // Predefined Hints
                      ListView.separated(
                        itemCount: predefinedHints.length,
                        separatorBuilder: (context, index) => const Divider(color: AppTheme.grayBorder),
                        itemBuilder: (context, index) {
                          final hint = predefinedHints[index];
                          return ListTile(
                            title: Text(hint, style: const TextStyle(color: AppTheme.white)),
                            trailing: IconButton(
                              icon: const Icon(Icons.send, color: AppTheme.primaryRed),
                              onPressed: () {
                                _sendHint(hint);
                                Navigator.pop(context);
                              },
                            ),
                          );
                        },
                      ),
                      // Custom Hint
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            TextField(
                              controller: _customHintController,
                              style: const TextStyle(color: AppTheme.white),
                              maxLines: 4,
                              decoration: const InputDecoration(
                                hintText: 'Tapez votre indice ici...',
                                filled: true,
                                fillColor: AppTheme.primaryBlack,
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const Gap(16),
                            PrimaryButton(
                              label: 'ENVOYER INDICE',
                              onPressed: () {
                                if (_customHintController.text.isNotEmpty) {
                                  _sendHint(_customHintController.text);
                                  Navigator.pop(context);
                                  _customHintController.clear();
                                }
                              },
                            ),
                          ],
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.grayBorder, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.warningOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.lightbulb_rounded, color: AppTheme.warningOrange, size: 20),
              ),
              const Gap(12),
              const Text(
                'SYSTÈME D\'INDICES',
                style: TextStyle(
                  color: AppTheme.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const Gap(24),
          
          // Current Hint Digital Display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlack,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: currentHint != null ? AppTheme.warningOrange.withOpacity(0.3) : AppTheme.grayBorder,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'STATUS: ${currentHint != null ? 'ACTIF' : 'ATTENTE'}',
                      style: TextStyle(
                        color: currentHint != null ? AppTheme.warningOrange : AppTheme.grayText,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    if (currentHint != null)
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppTheme.warningOrange,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const Gap(12),
                Text(
                  currentHint ?? '> EN ATTENTE D\'INSTRUCTIONS...',
                  style: TextStyle(
                    color: currentHint != null ? AppTheme.white : AppTheme.grayDisabled,
                    fontFamily: 'monospace',
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          
          const Gap(24),
          
          PrimaryButton(
            label: 'ENVOYER UN INDICE',
            icon: Icons.send_rounded,
            onPressed: _showHintDialog,
            backgroundColor: AppTheme.primaryRed,
          ),
          
          if (currentHint != null) ...[
            const Gap(12),
            OutlinedButton(
              onPressed: () => setState(() => currentHint = null),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.grayText,
                side: const BorderSide(color: AppTheme.grayBorder),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('EFFACER L\'ÉCRAN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }
}
