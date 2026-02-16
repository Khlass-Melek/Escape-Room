
import 'package:escape_room_admin/core/theme/app_theme.dart';
import 'package:escape_room_admin/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class LightingControlWidget extends StatefulWidget {
  const LightingControlWidget({super.key});

  @override
  State<LightingControlWidget> createState() => _LightingControlWidgetState();
}

class _LightingControlWidgetState extends State<LightingControlWidget> {
  // Mock State
  final List<Map<String, dynamic>> rooms = [
    {'name': 'Chambre 1', 'isOn': true},
    {'name': 'Chambre 2', 'isOn': true},
    {'name': 'Chambre 3', 'isOn': false},
    {'name': 'Chambre 4', 'isOn': false},
  ];

  int _blinkDuration = 5; // Seconds

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
                  color: AppTheme.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.lightbulb_outline_rounded, color: AppTheme.white, size: 20),
              ),
              const Gap(12),
              const Text(
                'ÉCLAIRAGE',
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
          
          // Global Controls
          Row(
            children: [
              Expanded(
                child: _LightActionButton(
                  label: 'TOUT ALLUMER',
                  icon: Icons.light_mode_rounded,
                  color: AppTheme.successGreen,
                  onPressed: () => _setAll(true),
                ),
              ),
              const Gap(12),
              Expanded(
                child: _LightActionButton(
                  label: 'TOUT ÉTEINDRE',
                  icon: Icons.dark_mode_rounded,
                  color: AppTheme.grayText,
                  onPressed: () => _setAll(false),
                ),
              ),
            ],
          ),
          
          const Gap(20),

          // Effects Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlack,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.grayBorder, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'EFFETS SPÉCIAUX',
                  style: TextStyle(color: AppTheme.grayDisabled, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                const Gap(12),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: AppTheme.grayText, size: 16),
                    const Gap(8),
                    DropdownButton<int>(
                      value: _blinkDuration,
                      dropdownColor: AppTheme.secondaryBlack,
                      style: const TextStyle(color: AppTheme.white, fontSize: 13),
                      underline: const SizedBox(),
                      items: [5, 10, 30, 60].map((int value) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text('$value s'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _blinkDuration = val);
                      },
                    ),
                    const Spacer(),
                    PrimaryButton(
                      label: 'CLIGNOTER',
                      icon: Icons.flash_on_rounded,
                      backgroundColor: AppTheme.warningOrange,
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const Gap(20),

          // Room List (Scrollable if needed)
          Column(
            children: rooms.asMap().entries.map((entry) {
              final room = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppTheme.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SwitchListTile(
                  title: Text(
                    room['name'], 
                    style: const TextStyle(color: AppTheme.white, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  value: room['isOn'],
                  activeColor: AppTheme.primaryRed,
                  activeTrackColor: AppTheme.primaryRed.withOpacity(0.2),
                  inactiveThumbColor: AppTheme.grayText,
                  inactiveTrackColor: AppTheme.grayBorder.withOpacity(0.2),
                  onChanged: (val) => setState(() => room['isOn'] = val),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _setAll(bool value) {
    setState(() {
      for (var room in rooms) {
        room['isOn'] = value;
      }
    });
  }
}

class _LightActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _LightActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const Gap(4),
          Text(
            label,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
