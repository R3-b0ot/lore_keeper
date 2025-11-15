import 'package:flutter/material.dart';
import 'package:lore_keeper/models/character.dart';
import 'package:lore_keeper/providers/character_list_provider.dart';

class CharacterListPane extends StatelessWidget {
  final CharacterListProvider characterProvider;
  final String? selectedCharacterKey;
  final ValueChanged<String> onCharacterSelected;
  final ValueChanged<String> onCharacterCreated;

  const CharacterListPane({
    super.key,
    required this.characterProvider,
    required this.selectedCharacterKey,
    required this.onCharacterSelected,
    required this.onCharacterCreated,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      padding: const EdgeInsets.all(12.0),
      child: ListenableBuilder(
        listenable: characterProvider,
        builder: (context, child) {
          final characters = characterProvider.characters;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Characters',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  // Placeholder Filter Button
                  TextButton.icon(
                    onPressed: () {
                      // TODO: Implement filter functionality
                    },
                    icon: const Icon(Icons.filter_list, size: 18),
                    label: const Text('Filter'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () async {
                  // For simplicity, we'll just create a new character directly
                  final newKey = await characterProvider.createNewCharacter(
                    'New Character',
                  );
                  onCharacterCreated(newKey.toString());
                },
                icon: Icon(
                  Icons.add,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                label: Text(
                  'New Character',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const Divider(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: characters.length,
                  itemBuilder: (context, index) {
                    final character = characters[index];
                    final isSelected =
                        character.key.toString() == selectedCharacterKey;
                    return _buildCharacterItem(context, character, isSelected);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCharacterItem(
    BuildContext context,
    Character character,
    bool isSelected,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: OutlinedButton.icon(
        onPressed: () => onCharacterSelected(character.key.toString()),
        icon: Icon(
          Icons.person_outline,
          size: 16,
          color: isSelected ? colorScheme.primary : colorScheme.onSurface,
        ),
        label: Text(character.name),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.centerLeft,
          backgroundColor: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surface,
          foregroundColor: isSelected
              ? colorScheme.primary
              : colorScheme.onSurface,
          side: BorderSide(
            color: isSelected ? colorScheme.primary : colorScheme.outline,
          ),
        ),
      ),
    );
  }
}
