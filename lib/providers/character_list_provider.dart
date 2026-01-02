import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:lore_keeper/models/link.dart';
import 'package:lore_keeper/models/character.dart';

class CharacterListProvider with ChangeNotifier {
  final int _projectId;
  final Box<Character> _characterBox;
  List<Character> _characters = [];
  bool _isInitialized = false;
  String _filterText = '';

  CharacterListProvider(this._projectId)
    : _characterBox = Hive.box<Character>('characters') {
    _loadCharacters();
  }

  List<Character> get characters => _characters;
  bool get isInitialized => _isInitialized;
  String get filterText => _filterText;

  List<Character> get filteredCharacters {
    if (_filterText.isEmpty) return _characters;
    final queryWords = _filterText
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    bool matchesQuery(String? text) {
      if (text == null || text.isEmpty) return false;
      final lowerText = text.toLowerCase();
      final textWords = lowerText.split(RegExp(r'\s+'));
      return queryWords.any(
        (queryWord) =>
            textWords.any((textWord) => textWord.startsWith(queryWord)),
      );
    }

    return _characters.where((c) {
      // Search in main character fields
      if (matchesQuery(c.name)) return true;
      if (matchesQuery(c.bio)) return true;
      if (c.aliases?.any(matchesQuery) ?? false) return true;
      if (matchesQuery(c.occupation)) return true;
      if (matchesQuery(c.gender)) return true;
      if (matchesQuery(c.customGender)) return true;
      if (matchesQuery(c.residence)) return true;
      if (matchesQuery(c.religion)) return true;
      if (matchesQuery(c.affiliation)) return true;
      if (matchesQuery(c.species)) return true;

      // Search in current iteration fields
      if (c.iterations.isNotEmpty) {
        final currentIteration = c.iterations.last;
        if (matchesQuery(currentIteration.name)) return true;
        if (matchesQuery(currentIteration.bio)) return true;
        if (currentIteration.aliases?.any(matchesQuery) ?? false) return true;
        if (matchesQuery(currentIteration.occupation)) return true;
        if (matchesQuery(currentIteration.gender)) return true;
        if (matchesQuery(currentIteration.customGender)) return true;
        if (matchesQuery(currentIteration.originCountry)) return true;
        if (currentIteration.traits?.any(matchesQuery) ?? false) return true;
        if (currentIteration.congenitalTraits.any(matchesQuery)) return true;
        if (currentIteration.leveledTraits.keys.any(matchesQuery)) return true;
        if (currentIteration.personalityTraits.keys.any(matchesQuery)) {
          return true;
        }

        // Search in custom field values
        if (currentIteration.customFieldValues.values.any(matchesQuery)) {
          return true;
        }

        // Search in custom panels
        for (final panel in currentIteration.customPanels) {
          if (matchesQuery(panel.name)) return true;
          if (matchesQuery(panel.content)) return true;
          if (panel.items.any(matchesQuery)) return true;
        }
      }

      return false;
    }).toList();
  }

  void setFilterText(String text) {
    _filterText = text;
    notifyListeners();
  }

  void _loadCharacters() {
    _characters = _characterBox.values
        .where((char) => char.parentProjectId == _projectId)
        .toList();

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
    debugPrint(
      '[PROVIDER] 1. Starting deletion for character key: $characterKey',
    );

    // Parse the key to handle both string and int types
    dynamic parsedKey = characterKey;
    if (characterKey is String) {
      final intKey = int.tryParse(characterKey);
      if (intKey != null) {
        parsedKey = intKey;
      }
    }

    // --- 1. Delete all associated links ---
    final linkBox = Hive.box<Link>('links');
    final linksToDelete = linkBox.values.where(
      (link) => link.entity1Key == parsedKey || link.entity2Key == parsedKey,
    );

    if (linksToDelete.isNotEmpty) {
      debugPrint('[DB] 1a. Deleting ${linksToDelete.length} associated links.');
      await linkBox.deleteAll(linksToDelete.map((l) => l.key));
      debugPrint('[DB] 1b. Associated links deleted.');
    }

    // --- 3. Delete the character itself from the database ---
    await _characterBox.delete(parsedKey);
    debugPrint('[DB] 3. Delete command issued for character key: $parsedKey');

    // --- 4. Reload the in-memory list from the database and notify the UI ---
    debugPrint('[PROVIDER] 4. Reloading all characters from DB to update UI.');
    _loadCharacters();
  }

  Future<void> updateCharacterName(dynamic characterKey, String newName) async {
    final character = _characterBox.get(characterKey);

    if (character != null) {
      debugPrint(
        '[PROVIDER] 1. Starting name update for character key: $characterKey',
      );
      debugPrint(
        '[DB] 2. Updating character "${character.name}" to "$newName" and saving.',
      );
      character.name = newName;
      await character.save();
      debugPrint('[DB] 3. Save complete.');

      // --- 4. Reload the in-memory list from the database and notify the UI ---
      debugPrint(
        '[PROVIDER] 4. Reloading all characters from DB to update UI.',
      );
      _loadCharacters();
    }
  }
}
