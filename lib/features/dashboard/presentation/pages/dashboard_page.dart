import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:escape_room_admin/models/room.dart';
import 'package:escape_room_admin/models/screen.dart';
import 'package:escape_room_admin/models/message.dart';
import 'package:escape_room_admin/features/dashboard/presentation/pages/room_details_page.dart';
import 'package:escape_room_admin/features/messages/data/models/gm_message.dart'; // or gm_messages.dart

class DashboardPage extends StatefulWidget {
  final String scenarioId;

  const DashboardPage({
    super.key,
    required this.scenarioId,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late List<Room> rooms;

  @override
  void initState() {
    super.initState();
    rooms = _getMockRoomsForScenario(widget.scenarioId);
  }

  List<Room> _getMockRoomsForScenario(String scenarioId) {
    return List.generate(5, (i) {
      return Room(
        id: '${widget.scenarioId}-room-$i',
        name: ['Cell Block A', 'Attic', 'Basement', 'Hallway', 'Courtyard'][i],
        videoStreamUrls: [
'http://localhost:8080/stream.m3u8',    
    ],
        screens: [
          Screen(
            id: 'tv-main',
            location: 'Main Wall',
            messages: [], // ← we don't use static messages anymore
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Monitoring: ${widget.scenarioId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'global-hint',
        backgroundColor: const Color.fromARGB(255, 255, 149, 1),
        icon: const Icon(Icons.send),
        label: const Text('Send Hint'),
        onPressed: () => _showSendHintToRoomDialog(context),
      ),
      body: rooms.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = 1;
                if (constraints.maxWidth > 1200) crossAxisCount = 3;
                else if (constraints.maxWidth > 800) crossAxisCount = 2;

                return MasonryGridView.count(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  padding: const EdgeInsets.all(12),
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    return RoomPreviewCard(
                      room: rooms[index],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RoomDetailPage(room: rooms[index]),
                            fullscreenDialog: true,
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  // ── Global send hint dialog ──────────────────────────────────────────────
  void _showSendHintToRoomDialog(BuildContext context) {
    String? selectedRoomId;
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Send Hint'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedRoomId,
              hint: const Text('Select room'),
              isExpanded: true,
              items: rooms.map((r) => DropdownMenuItem(
                    value: r.id,
                    child: Text(r.name),
                  )).toList(),
              onChanged: (val) => selectedRoomId = val,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                labelText: 'Hint message',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = textController.text.trim();
              if (text.isEmpty || selectedRoomId == null) return;

              GmMessages().addMessage(selectedRoomId!, text);
              Navigator.pop(dialogContext);
              setState(() {}); // refresh counts
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Hint sent')),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  // ── Quick send for specific room ─────────────────────────────────────────
  void _showQuickSendForThisRoom(BuildContext context, String roomId, String roomName) {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Hint to $roomName'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: 'Message',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = textController.text.trim();
              if (text.isEmpty) return;

              GmMessages().addMessage(roomId, text);
              Navigator.pop(dialogContext);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Sent to $roomName')),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}

// ── RoomPreviewCard with targeted hint button ────────────────────────────────
class RoomPreviewCard extends StatefulWidget {
  final Room room;
  final VoidCallback onTap;

  const RoomPreviewCard({
    super.key,
    required this.room,
    required this.onTap,
  });

  @override
  State<RoomPreviewCard> createState() => _RoomPreviewCardState();
}

class _RoomPreviewCardState extends State<RoomPreviewCard> {
  VideoPlayerController? _controller;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    if (widget.room.videoStreamUrls.isNotEmpty) {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.room.videoStreamUrls.first),
      )..initialize().then((_) {
          if (mounted) {
            setState(() {});
            _controller?.setLooping(true);
            _controller?.setVolume(0.0);
            _controller?.play();
          }
        });

      _chewieController = ChewieController(
        videoPlayerController: _controller!,
        autoPlay: false,
        looping: true,
        showControls: false,
        aspectRatio: 16 / 9,
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasVideo = _controller?.value.isInitialized ?? false;

    return GestureDetector(
      onTap: widget.onTap,
      child: Card(
        elevation: 3,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: hasVideo
                  ? Chewie(controller: _chewieController!)
                  : Container(
                      color: Colors.grey[900],
                      child: const Icon(Icons.videocam_off, size: 48, color: Colors.white54),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.room.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.room.videoStreamUrls.length} camera(s) • '
                    '${GmMessages().getCount(widget.room.id)} hints',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          final state = context.findAncestorStateOfType<_DashboardPageState>();
                          state?._showQuickSendForThisRoom(context, widget.room.id, widget.room.name);
                        },
                        icon: const Icon(Icons.send, size: 16),
                        label: const Text('Hint', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          side: BorderSide(color: Colors.yellowAccent.withOpacity(0.7)),
                          foregroundColor: Colors.yellowAccent,
                          minimumSize: const Size(0, 32),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}