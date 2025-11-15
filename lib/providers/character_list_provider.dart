import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:lore_keeper/models/character.dart';

class CharacterListProvider with ChangeNotifier {
  final int _projectId;
  final Box<Character> _characterBox;
  List<Character> _characters = [];
  bool _isInitialized = false;

  CharacterListProvider(this._projectId)
    : _characterBox = Hive.box<Character>('characters') {
    _loadCharacters();
  }

  List<Character> get characters => _characters;
  bool get isInitialized => _isInitialized;

  void _loadCharacters() {
    _characters = _characterBox.values
        .where((char) => char.parentProjectId == _projectId)
        .toList();

    if (_characters.isEmpty && !_isInitialized) {
      createNewCharacter('Hero');
      return; // createNewCharacter will call _loadCharacters again
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<dynamic> createNewCharacter(String name) async {
    final newCharacter = Character(
      name: name,
      parentProjectId: _projectId,
    ); // Use the simplified constructor
    final newKey = await _characterBox.add(newCharacter);
    _loadCharacters();
    return newKey;
  }

  Future<void> deleteCharacter(dynamic characterKey) async {
    await _characterBox.delete(characterKey);
    _loadCharacters();
  }

  Future<void> updateCharacterName(dynamic characterKey, String newName) async {
    final character = _characterBox.get(characterKey);
    if (character != null) {
      character.name = newName;
      await character.save();
      _loadCharacters();
    }
  }
}
