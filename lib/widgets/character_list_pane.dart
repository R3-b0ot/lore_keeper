import 'package:flutter/material.dart';
import 'package:lore_keeper/models/character.dart';
import 'package:lore_keeper/providers/character_list_provider.dart';

class CharacterListPane extends StatefulWidget {
  final CharacterListProvider characterProvider;
  final String? selectedCharacterKey;
  final ValueChanged<String> onCharacterSelected; // This is correct
  final VoidCallback onCharacterCreated;
  final ValueChanged<String>? onCharacterEdit;
  final bool isMobile;

  const CharacterListPane({
    super.key,
    required this.characterProvider,
    required this.selectedCharacterKey,
    required this.onCharacterSelected,
    required this.onCharacterCreated,
    this.onCharacterEdit,
    required this.isMobile,
  });

  @override
  State<CharacterListPane> createState() => _CharacterListPaneState();
}

class _CharacterListPaneState extends State<CharacterListPane> {
  late TextEditingController _filterController;
  bool _showFilter = false;

  @override
  void initState() {
    super.initState();
    _filterController = TextEditingController();
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      padding: const EdgeInsets.all(12.0),
      child: ListenableBuilder(
        listenable: widget.characterProvider,
        builder: (context, child) {
          final characters = widget.characterProvider.filteredCharacters;
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
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showFilter = !_showFilter;
                        if (!_showFilter) {
                          _filterController.clear();
                          widget.characterProvider.setFilterText('');
                        }
                      });
                    },
                    icon: Icon(
                      _showFilter ? Icons.filter_list_off : Icons.filter_list,
                      size: 18,
                    ),
                    label: Text(_showFilter ? 'Hide Filter' : 'Filter'),
                  ),
                ],
              ),
              if (_showFilter) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _filterController,
                  decoration: const InputDecoration(
                    hintText: 'Filter characters...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (value) {
                    widget.characterProvider.setFilterText(value);
                  },
                ),
              ],
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed:
                    widget.onCharacterCreated, // Directly call the VoidCallback
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
                        character.key.toString() == widget.selectedCharacterKey;
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
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () =>
                  widget.onCharacterSelected(character.key.toString()),
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
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: () =>
                widget.onCharacterEdit?.call(character.key.toString()),
            tooltip: 'Edit Character',
          ),
        ],
      ),
    );
  }
}
