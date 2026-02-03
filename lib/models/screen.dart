import 'message.dart';
class Screen {
  final String id;
  final String location;              // e.g. "Wall", "Corner", "Ceiling"
  final List<Message> messages;       // hints displayed on this screen (one-way)

  const Screen({
    required this.id,
    required this.location,
    this.messages = const [],
  });
}