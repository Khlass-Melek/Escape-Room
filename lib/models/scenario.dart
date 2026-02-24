import 'room.dart';

class Scenario {
  final String id;
  final String name;
  final String description;
  final bool isActive;
  final int difficulty;
  final int estimatedTime;
  final String players; // UI specific mapping
  final String image; // UI specific mapping
  final List<String> cameras;
  final String musicFolderPath;
  final List<Room> rooms;

  const Scenario({
    required this.id,
    required this.name,
    this.description = '',
    this.isActive = true,
    this.difficulty = 3,
    this.estimatedTime = 60,
    this.players = '2-6',
    this.image = 'assets/images/saw1.jpg',
    this.cameras = const [],
    this.musicFolderPath = '',
    this.rooms = const [],
  });

  factory Scenario.fromJson(Map<String, dynamic> json) {
    return Scenario(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? 'Sans Nom',
      description: json['description']?.toString() ?? '',
      isActive: json['is_active'] ?? true,
      difficulty: json['difficulty'] as int? ?? 3,
      estimatedTime: json['estimated_time'] as int? ?? 60,
      players: '2-6', // Default for now
      image: json['image']?.toString() ?? 'assets/images/saw1.jpg',
      cameras: (json['cameras'] as List?)?.map((e) => e.toString()).toList() ?? [],
      musicFolderPath: json['music_folder_path']?.toString() ?? '',
    );
  }
}