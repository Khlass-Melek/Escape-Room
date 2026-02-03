import 'room.dart';
class Scenario {
  final String id;
  final String name;
  final List<Room> rooms;             // avg ~5

  const Scenario({
    required this.id,
    required this.name,
    this.rooms = const [],
  });
}