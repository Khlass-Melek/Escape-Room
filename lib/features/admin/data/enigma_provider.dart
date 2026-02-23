import 'package:escape_room_admin/features/admin/domain/models/enigma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class EnigmaState {
  final List<Enigma> enigmas;

  const EnigmaState({
    this.enigmas = const [],
  });

  EnigmaState copyWith({
    List<Enigma>? enigmas,
  }) {
    return EnigmaState(
      enigmas: enigmas ?? this.enigmas,
    );
  }
}

class EnigmaNotifier extends Notifier<EnigmaState> {
  final Uuid _uuid = const Uuid();

  @override
  EnigmaState build() {
    return EnigmaState(
      enigmas: [
        const Enigma(
          id: '1',
          name: "Porte d'entrée",
          type: 'Logique',
          description: 'Le code numérique caché dans le tableau des horaires.',
          difficulty: 'Facile',
        ),
        const Enigma(
          id: '2',
          name: 'Panneau Électrique',
          type: 'Câblage',
          description: 'Reconnecter les fils selon le code de couleurs pour rétablir le courant.',
          difficulty: 'Moyen',
        ),
        const Enigma(
          id: '3',
          name: 'Coffre-fort du Directeur',
          type: 'Tic Tac Toe',
          description: "Gagner une partie de morpion contre l'IA pour déverrouiller le coffre.",
          difficulty: 'Difficile',
        ),
      ],
    );
  }

  void addEnigma(String name, String type, String description, String difficulty, bool isActive, Map<String, dynamic> configuration) {
    final newEnigma = Enigma(
      id: _uuid.v4(),
      name: name,
      type: type,
      description: description,
      difficulty: difficulty,
      isActive: isActive,
      configuration: configuration,
    );

    state = state.copyWith(
      enigmas: [...state.enigmas, newEnigma],
    );
  }

  void updateEnigma(String id, String name, String type, String description, String difficulty, bool isActive, Map<String, dynamic> configuration) {
    final updatedEnigmas = state.enigmas.map((enigma) {
      if (enigma.id == id) {
        return enigma.copyWith(
          name: name,
          type: type,
          description: description,
          difficulty: difficulty,
          isActive: isActive,
          configuration: configuration,
        );
      }
      return enigma;
    }).toList();

    state = state.copyWith(enigmas: updatedEnigmas);
  }

  void toggleEnigmaStatus(String id) {
    final updatedEnigmas = state.enigmas.map((enigma) {
      if (enigma.id == id) {
        return enigma.copyWith(isActive: !enigma.isActive);
      }
      return enigma;
    }).toList();

    state = state.copyWith(enigmas: updatedEnigmas);
  }

  void deleteEnigma(String id) {
    final updatedEnigmas = state.enigmas.where((enigma) => enigma.id != id).toList();
    state = state.copyWith(enigmas: updatedEnigmas);
  }
}

final enigmaProvider = NotifierProvider<EnigmaNotifier, EnigmaState>(() {
  return EnigmaNotifier();
});
