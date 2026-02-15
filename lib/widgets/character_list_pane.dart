import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: colorScheme.surface,
      child: ListenableBuilder(
        listenable: widget.characterProvider,
        builder: (context, child) {
          final characters = widget.characterProvider.filteredCharacters;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pane Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                child: Row(
                  children: [
                    Text(
                      'CHARACTERS',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        _showFilter ? LucideIcons.searchX : LucideIcons.search,
                        size: 20,
                      ),
                      onPressed: () => setState(() {
                        _showFilter = !_showFilter;
                        if (!_showFilter) {
                          _filterController.clear();
                          widget.characterProvider.setFilterText('');
                        }
                      }),
                      tooltip: 'Search Characters',
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.userPlus, size: 20),
                      onPressed: widget.onCharacterCreated,
                      tooltip: 'New Character',
                    ),
                  ],
                ),
              ),

              // Integrated Search Bar
              if (_showFilter)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: TextField(
                    controller: _filterController,
                    autofocus: true,
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Filter by name...',
                      prefixIcon: const Icon(LucideIcons.listFilter, size: 18),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      fillColor: isDark
                          ? colorScheme.surfaceContainerHighest.withValues(
                              alpha: 0.5,
                            )
                          : colorScheme.surfaceContainerLowest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) =>
                        widget.characterProvider.setFilterText(val),
                  ),
                ),

              const SizedBox(height: 8),

              // Scrollable List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: characters.length,
                  itemBuilder: (context, index) {
                    final character = characters[index];
                    final isSelected =
                        character.key.toString() == widget.selectedCharacterKey;
                    return _buildCharacterTile(character, isSelected);
                  },
                ),
              ),
              if (characters.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'No characters found',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCharacterTile(Character character, bool isSelected) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: InkWell(
        onTap: () => widget.onCharacterSelected(character.key.toString()),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Active Indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 80),
                width: 4,
                height: isSelected ? 24 : 0,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(2),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Icon
              Icon(
                LucideIcons.user,
                size: 18,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),

              // Title
              Expanded(
                child: Text(
                  character.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Actions
              IconButton(
                icon: Icon(
                  LucideIcons.pencil,
                  size: 16,
                  color: isSelected
                      ? colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                onPressed: () =>
                    widget.onCharacterEdit?.call(character.key.toString()),
                tooltip: 'Edit',
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}
