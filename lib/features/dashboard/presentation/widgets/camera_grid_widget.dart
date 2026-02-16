
import 'package:escape_room_admin/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:escape_room_admin/shared/utils/responsive.dart';

// - [x] Design and Plan Room Focus View <!-- id: 0 -->
// - [/] Update `CameraGridWidget` to support camera selection <!-- id: 1 -->
class CameraGridWidget extends StatelessWidget {
  final Function(String)? onCameraSelected;
  
  const CameraGridWidget({super.key, this.onCameraSelected});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = Responsive.isMobile(context);
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isMobile ? 1 : 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _CameraFeed(
          id: 'CAM_01',
          label: 'CAM 01 - ENTRÉE', 
          isLive: true,
          onTap: () => onCameraSelected?.call('CAM_01'),
        ),
        _CameraFeed(
          id: 'CAM_02',
          label: 'CAM 02 - ZONE ÉNIGME', 
          isLive: true,
          onTap: () => onCameraSelected?.call('CAM_02'),
        ),
        _CameraFeed(
          id: 'CAM_03',
          label: 'CAM 03 - CHAMBRE SECRÈTE', 
          isLive: true,
          onTap: () => onCameraSelected?.call('CAM_03'),
        ),
        _CameraFeed(
          id: 'CAM_04',
          label: 'CAM 04 - PORTE FINALE', 
          isLive: false,
          onTap: () => onCameraSelected?.call('CAM_04'),
        ),
      ],
    );
  }
}

class _CameraFeed extends StatefulWidget {
  final String id;
  final String label;
  final bool isLive;
  final VoidCallback? onTap;

  const _CameraFeed({
    required this.id,
    required this.label, 
    required this.isLive,
    this.onTap,
  });

  @override
  State<_CameraFeed> createState() => _CameraFeedState();
}

class _CameraFeedState extends State<_CameraFeed> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isLive 
                ? (_isHovered ? AppTheme.primaryRed : AppTheme.primaryRed.withOpacity(0.3)) 
                : AppTheme.grayBorder,
              width: _isHovered ? 2 : 1,
            ),
            boxShadow: [
              if (widget.isLive && _isHovered)
                BoxShadow(
                  color: AppTheme.primaryRed.withOpacity(0.2),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Mock Static/Noise Background
                Opacity(
                  opacity: 0.1,
                  child: Image.network(
                    'https://media.giphy.com/media/oEI9uWUqW8K6A/giphy.gif',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                ),
                
                // Central Content
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.isLive ? Icons.videocam : Icons.videocam_off,
                        size: 40,
                        color: widget.isLive ? AppTheme.white.withOpacity(0.5) : AppTheme.grayDisabled,
                      ),
                      const Gap(8),
                      if (!widget.isLive)
                        Text(
                          'FLUX INTERROMPU',
                          style: TextStyle(
                            color: AppTheme.grayDisabled,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Scanline Overlay Effect
                const _ScanlineOverlay(),
    
                // Label Overlay (Bottom Left)
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      color: Colors.black.withOpacity(0.7),
                      child: Text(
                        widget.label,
                        style: const TextStyle(
                          color: AppTheme.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
    
                // Status Indicator (Top Right)
                Positioned(
                  top: 12,
                  right: 12,
                  child: _CameraStatus(isLive: widget.isLive),
                ),
    
                // Corner Accents
                const _CameraCorners(),

                // Hover Action Indicator
                if (_isHovered && widget.isLive)
                  Positioned.fill(
                    child: Container(
                      color: AppTheme.primaryRed.withOpacity(0.05),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryRed.withOpacity(0.8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 32),
                        ),
                      ),
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

class _CameraStatus extends StatefulWidget {
  final bool isLive;
  const _CameraStatus({required this.isLive});

  @override
  State<_CameraStatus> createState() => _CameraStatusState();
}

class _CameraStatusState extends State<_CameraStatus> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'HORS LIGNE',
          style: TextStyle(color: AppTheme.grayText, fontSize: 8, fontWeight: FontWeight.bold),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: _controller,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppTheme.primaryRed,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const Gap(6),
        const Text(
          'EN DIRECT',
          style: TextStyle(
            color: AppTheme.primaryRed,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _ScanlineOverlay extends StatelessWidget {
  const _ScanlineOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: List.generate(
            100,
            (index) => index % 2 == 0 ? Colors.transparent : Colors.black.withOpacity(0.05),
          ),
        ),
      ),
    );
  }
}

class _CameraCorners extends StatelessWidget {
  const _CameraCorners();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          child: _CornerAccent(isTop: true, isLeft: true),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: _CornerAccent(isTop: true, isLeft: false),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          child: _CornerAccent(isTop: false, isLeft: true),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: _CornerAccent(isTop: false, isLeft: false),
        ),
      ],
    );
  }
}

class _CornerAccent extends StatelessWidget {
  final bool isTop;
  final bool isLeft;

  const _CornerAccent({required this.isTop, required this.isLeft});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 15,
      height: 15,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? BorderSide(color: AppTheme.white.withOpacity(0.2), width: 1.5) : BorderSide.none,
          bottom: !isTop ? BorderSide(color: AppTheme.white.withOpacity(0.2), width: 1.5) : BorderSide.none,
          left: isLeft ? BorderSide(color: AppTheme.white.withOpacity(0.2), width: 1.5) : BorderSide.none,
          right: !isLeft ? BorderSide(color: AppTheme.white.withOpacity(0.2), width: 1.5) : BorderSide.none,
        ),
      ),
    );
  }
}

