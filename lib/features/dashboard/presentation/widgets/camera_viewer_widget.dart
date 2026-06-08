import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:escape_room_admin/core/theme/app_theme.dart';
import 'package:gap/gap.dart';
import 'dart:ui_web' as ui;
import 'dart:html' as html;

class CameraViewerWidget extends StatefulWidget {
  const CameraViewerWidget({super.key});

  @override
  State<CameraViewerWidget> createState() => _CameraViewerWidgetState();
}

class _CameraViewerWidgetState extends State<CameraViewerWidget> {
  // ⬇️ Changez cette IP par l'IP affichée dans le Serial Monitor de votre ESP32-CAM
  final String _streamUrl = 'http://192.168.1.42/stream';

  bool _isVisible = false;
  final String _viewId = 'esp32cam-stream-${DateTime.now().millisecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
        final img = html.ImageElement()
          ..src = _streamUrl
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'cover';
        return img;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isVisible ? Colors.teal : AppTheme.grayBorder,
          width: _isVisible ? 1.5 : 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── En-tête
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.videocam_rounded, color: Colors.teal, size: 20),
              ),
              const Gap(12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Caméra Salle',
                      style: TextStyle(
                        color: AppTheme.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.2,
                      )),
                  Text('ESP32-CAM · OV2640',
                      style: TextStyle(color: AppTheme.grayText, fontSize: 10)),
                ],
              ),
              const Spacer(),
              // Indicateur live
              if (_isVisible)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red.withOpacity(0.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: Colors.red, size: 8),
                      Gap(6),
                      Text('LIVE',
                          style: TextStyle(
                              color: Colors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1)),
                    ],
                  ),
                ),
            ],
          ),

          const Gap(16),

          // ── Zone Video
          if (_isVisible) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: HtmlElementView(viewType: _viewId),
            ),
            const Gap(12),
            // URL du flux
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link_rounded, color: AppTheme.grayText, size: 14),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      _streamUrl,
                      style: const TextStyle(
                          color: AppTheme.grayText, fontSize: 10, fontFamily: 'monospace'),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Placeholder quand éteint
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.grayBorder.withOpacity(0.3)),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.videocam_off_rounded, color: AppTheme.grayText, size: 40),
                  Gap(12),
                  Text('Flux vidéo inactif',
                      style: TextStyle(color: AppTheme.grayText, fontSize: 12)),
                  Gap(4),
                  Text('Cliquez sur "Activer" pour voir le stream',
                      style: TextStyle(color: AppTheme.grayText, fontSize: 10)),
                ],
              ),
            ),
          ],

          const Gap(16),

          // ── Bouton Activer / Désactiver
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _isVisible ? Colors.red.withOpacity(0.1) : Colors.teal.withOpacity(0.1),
              foregroundColor: _isVisible ? Colors.red : Colors.teal,
              side: BorderSide(
                color: _isVisible
                    ? Colors.red.withOpacity(0.5)
                    : Colors.teal.withOpacity(0.5),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            onPressed: () => setState(() => _isVisible = !_isVisible),
            icon: Icon(_isVisible ? Icons.stop_circle_outlined : Icons.play_circle_outlined,
                size: 20),
            label: Text(
              _isVisible ? 'DÉSACTIVER LE STREAM' : 'ACTIVER LE STREAM',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
  }
}
