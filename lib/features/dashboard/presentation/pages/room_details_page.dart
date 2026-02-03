import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../models/room.dart';
import '../../../messages/data/models/gm_message.dart';


class RoomDetailPage extends StatefulWidget {
  final Room room;

  const RoomDetailPage({
    super.key,
    required this.room,
  });

  @override
  State<RoomDetailPage> createState() => _RoomDetailPageState();
}

class _RoomDetailPageState extends State<RoomDetailPage> {
  final Map<String, VideoPlayerController> _controllers = {};
  final Map<String, ChewieController> _chewieControllers = {};

  @override
  void initState() {
    super.initState();
    _initializeVideos();
  }

  void _initializeVideos() {
    for (final url in widget.room.videoStreamUrls) {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(url),
        formatHint: VideoFormat.hls, // most common for live camera streams
      );

      controller.initialize().then((_) {
        if (!mounted) return;
        setState(() {
          controller.setLooping(true);
          controller.play();
          // controller.setVolume(0.0); // uncomment if you want muted by default
        });
      }).catchError((error) {
        debugPrint('Video init error for $url: $error');
      });

      _controllers[url] = controller;

      final chewie = ChewieController(
        videoPlayerController: controller,
        autoPlay: true,
        looping: true,
        allowFullScreen: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: false, // usually not needed for live
        showControlsOnInitialize: true,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 12),
                Text('Stream error: $errorMessage'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => controller.initialize(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        },
      );

      _chewieControllers[url] = chewie;
    }
  }

  @override
  void dispose() {
    for (final ctrl in _controllers.values) {
      ctrl.pause();
      ctrl.dispose();
    }
    for (final chewie in _chewieControllers.values) {
      chewie.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.room.name),
        backgroundColor: Colors.black.withOpacity(0.6),
        elevation: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 900;

            return isWide
                ? Row(
                    children: [
                      Expanded(
                        flex: 7,
                        child: _buildVideoArea(),
                      ),
                      Expanded(
                        flex: 3,
                        child: _buildHintsPanel(),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Expanded(
                        flex: 7,
                        child: _buildVideoArea(),
                      ),
                      SizedBox(
                        height: 320,
                        child: _buildHintsPanel(),
                      ),
                    ],
                  );
          },
        ),
      ),
    );
  }

  Widget _buildVideoArea() {
    if (widget.room.videoStreamUrls.isEmpty) {
      return const Center(
        child: Text(
          'No cameras available',
          style: TextStyle(color: Colors.white70, fontSize: 20),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 16 / 9,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: widget.room.videoStreamUrls.length,
      itemBuilder: (context, index) {
        final url = widget.room.videoStreamUrls[index];
        final controller = _controllers[url];
        final chewie = _chewieControllers[url];

        if (controller == null || chewie == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!controller.value.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Chewie(controller: chewie),
        );
      },
    );
  }

  Widget _buildHintsPanel() {
  final hints = GmMessages().getMessages(widget.room.id);

  if (hints.isEmpty) {
    return const Center(
      child: Text(
        'No hints sent to this room yet',
        style: TextStyle(color: Colors.white70, fontSize: 18),
      ),
    );
  }

  return Container(
    color: Colors.grey[900],
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Optional header showing the single screen
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Screen in ${widget.room.name}',
            style: const TextStyle(
              color: Colors.yellowAccent,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: hints.length,
            itemBuilder: (context, index) {
              final msg = hints[index];
              return Card(
                color: Colors.grey[850],
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.tv, color: Colors.yellowAccent, size: 32),
                  title: Text(
                    msg.text,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  subtitle: Text(
                    msg.timestamp.toString().substring(0, 19), // YYYY-MM-DD HH:mm:ss
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  trailing: Text(
                    'GM',
                    style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}
}