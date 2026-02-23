class Enigma {
  final String id;
  final String name;
  final String type; // e.g., 'Tic Tac Toe', 'Câblage', 'Logique', 'Mécanique'
  final String description;
  final String difficulty; // e.g., 'Facile', 'Moyen', 'Difficile'
  final bool isActive;
  final Map<String, dynamic> configuration;

  const Enigma({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.difficulty,
    this.isActive = true,
    this.configuration = const {},
  });

  Enigma copyWith({
    String? id,
    String? name,
    String? type,
    String? description,
    String? difficulty,
    bool? isActive,
    Map<String, dynamic>? configuration,
  }) {
    return Enigma(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      isActive: isActive ?? this.isActive,
      configuration: configuration ?? this.configuration,
    );
  }

  factory Enigma.fromJson(Map<String, dynamic> json) {
    return Enigma(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      description: json['description'] as String,
      difficulty: json['difficulty'] as String,
      isActive: json['isActive'] as bool? ?? true,
      configuration: json['configuration'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'description': description,
      'difficulty': difficulty,
      'isActive': isActive,
      'configuration': configuration,
    };
  }
}
