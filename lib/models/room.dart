import 'screen.dart';
class Room {
  final String id;                    // unique within scenario or global
  final String name;                  // e.g. "Cell Block A", "Attic", "Treasure Cave"
  final List<String> videoStreamUrls; // RTSP, HLS, WebRTC URLs or asset paths
  final List<Screen> screens;         // TVs / monitors in this room

  const Room({
    required this.id,
    required this.name,
    this.videoStreamUrls = const [],
    this.screens = const [],
  });
}