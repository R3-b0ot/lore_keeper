import 'package:flutter/material.dart';
import 'package:lore_keeper/providers/map_list_provider.dart';
import 'package:lore_keeper/models/map_model.dart';
import 'package:lore_keeper/widgets/map_creator_dialog.dart';

class MapListPane extends StatefulWidget {
  final MapListProvider mapProvider;
  final String selectedMapKey;
  final Function(String key) onMapSelected;
  final bool isMobile;

  const MapListPane({
    super.key,
    required this.mapProvider,
    required this.selectedMapKey,
    required this.onMapSelected,
    required this.isMobile,
  });

  @override
  State<MapListPane> createState() => _MapListPaneState();
}

class _MapListPaneState extends State<MapListPane> {
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

  void _showMapCreatorDialog() {
    showDialog(
      context: context,
      builder: (context) => MapCreatorDialog(mapProvider: widget.mapProvider),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: colorScheme.surface,
      child: ListenableBuilder(
        listenable: widget.mapProvider,
        builder: (context, child) {
          final maps = widget.mapProvider.maps;
          final filterText = _filterController.text.toLowerCase();
          final filteredMaps = maps
              .where((map) => map.name.toLowerCase().contains(filterText))
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pane Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                child: Row(
                  children: [
                    Text(
                      'MAPS',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        _showFilter ? Icons.search_off : Icons.search,
                        size: 20,
                      ),
                      onPressed: () => setState(() {
                        _showFilter = !_showFilter;
                        if (!_showFilter) _filterController.clear();
                      }),
                      tooltip: 'Search Maps',
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add_location_alt_outlined,
                        size: 20,
                      ),
                      onPressed: _showMapCreatorDialog,
                      tooltip: 'Create Map',
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
                      prefixIcon: const Icon(Icons.filter_list, size: 18),
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
                    onChanged: (_) => setState(() {}),
                  ),
                ),

              const SizedBox(height: 8),

              // Scrollable List
              Expanded(
                child: filteredMaps.isEmpty
                    ? Center(
                        child: Text(
                          _filterController.text.isEmpty
                              ? 'No maps created yet.'
                              : 'No maps found',
                          style: theme.textTheme.bodySmall,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: filteredMaps.length,
                        itemBuilder: (context, index) {
                          final map = filteredMaps[index];
                          final isSelected =
                              map.key.toString() == widget.selectedMapKey;
                          return _buildMapTile(map, isSelected);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMapTile(MapModel map, bool isSelected) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: InkWell(
        onTap: () => widget.onMapSelected(map.key.toString()),
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
                _getFileTypeIcon(map.fileType),
                size: 18,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),

              // Title
              Expanded(
                child: Text(
                  map.name,
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
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFileTypeIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'jpeg':
      case 'jpg':
      case 'png':
        return Icons.image;
      case 'svg':
        return Icons.code;
      case 'eps':
        return Icons.picture_as_pdf;
      default:
        return Icons.insert_drive_file;
    }
  }
}
