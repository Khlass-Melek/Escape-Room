
import 'package:escape_room_admin/models/message.dart'; // adjust import if your Message model is elsewhere

/// In-memory repository for Game Master (admin) messages/hints.
/// Messages are grouped by room ID for easy filtering.
class GmMessages {
  // Singleton pattern (easy access from anywhere)
  static final GmMessages _instance = GmMessages._internal();
  factory GmMessages() => _instance;
  GmMessages._internal();

  // roomId → List<Message> (newest first or oldest first — your choice)
  final Map<String, List<Message>> _messagesByRoom = {};

  /// Get all messages for a specific room
  List<Message> getMessages(String roomId) {
    final list = _messagesByRoom[roomId] ?? [];
    // Optional: sort by timestamp descending (newest first)
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  /// Add a new hint/message for a room
  void addMessage(String roomId, String text, {String? sender = 'GM'}) {
    final message = Message(
      text: text,
      timestamp: DateTime.now(),
    );

    _messagesByRoom.putIfAbsent(roomId, () => []).add(message);
  }

  /// Get number of messages for a room (used in dashboard previews)
  int getCount(String roomId) {
    return _messagesByRoom[roomId]?.length ?? 0;
  }

  /// Clear all messages for a room (useful for reset/new game)
  void clearRoom(String roomId) {
    _messagesByRoom.remove(roomId);
  }

  /// Clear everything (for app reset / testing)
  void clearAll() {
    _messagesByRoom.clear();
  }

  // Future extension points:
  // - Stream<List<Message>> watchMessages(String roomId) { ... }  // for real-time
  // - Future<void> syncWithBackend() { ... }                     // MQTT/Firebase/etc.
}