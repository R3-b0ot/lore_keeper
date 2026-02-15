import 'package:flutter/material.dart';
import 'package:lore_keeper/providers/character_list_provider.dart';

/// Presents the character list for quick selection.
class CharacterSelectionDialog extends StatelessWidget {
  final CharacterListProvider characterProvider;
  final String selectedCharacterKey;
  final ValueChanged<String> onCharacterSelected;

  const CharacterSelectionDialog({
    super.key,
    required this.characterProvider,
    required this.selectedCharacterKey,
    required this.onCharacterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Character'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListenableBuilder(
          listenable: characterProvider,
          builder: (context, child) {
            final characters = characterProvider.characters;
            return ListView.builder(
              shrinkWrap: true,
              itemCount: characters.length,
              itemBuilder: (context, index) {
                final character = characters[index];
                final isSelected =
                    character.key.toString() == selectedCharacterKey;
                return ListTile(
                  title: Text(character.name),
                  selected: isSelected,
                  onTap: () {
                    onCharacterSelected(character.key.toString());
                    Navigator.of(context).pop();
                  },
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
