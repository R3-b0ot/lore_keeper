import 'package:flutter/material.dart';
import 'package:lore_keeper/models/map_model.dart';
import 'package:lore_keeper/providers/map_list_provider.dart';
import 'package:lore_keeper/services/map_service.dart';
import 'package:lore_keeper/widgets/map_creator_dialog.dart';

class MapListPane extends StatefulWidget {
  final MapListProvider mapProvider;
  final String? selectedMapKey;
  final ValueChanged<String> onMapSelected;

  const MapListPane({
    super.key,
    required this.mapProvider,
    required this.selectedMapKey,
    required this.onMapSelected,
  });

  @override
  State<MapListPane> createState() => _MapListPaneState();
}

class _MapListPaneState extends State<MapListPane> {
  late TextEditingController _searchController;
  bool _showFilter = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showCreateMapDialog() async {
    final result = await showDialog<MapCreationResult>(
      context: context,
      builder: (context) => const MapCreatorDialog(),
    );

    if (result != null && result.name.isNotEmpty) {
      // Create the map via the provider
      final mapId = await widget.mapProvider.createNewMap(
        result.name,
        style: result.style,
        resolution: result.resolution,
        aspectRatio: result.aspectRatio,
        gridType: result.gridType,
      );

      // Select the newly created map
      widget.onMapSelected(mapId.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      padding: const EdgeInsets.all(12.0),
      child: ListenableBuilder(
        listenable: widget.mapProvider,
        builder: (context, child) {
          final maps = widget.mapProvider.maps.where((map) {
            final query = _searchController.text.toLowerCase();
            return map.name.toLowerCase().contains(query);
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'World Maps',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showFilter = !_showFilter;
                        if (!_showFilter) {
                          _searchController.clear();
                        }
                      });
                    },
                    icon: Icon(
                      _showFilter ? Icons.search_off : Icons.search,
                      size: 18,
                    ),
                    tooltip: _showFilter ? 'Hide Search Box' : 'Search Maps',
                  ),
                ],
              ),
              if (_showFilter) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search maps...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
              ],
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _showCreateMapDialog,
                icon: Icon(
                  Icons.add,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                label: Text(
                  'New Map',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const Divider(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: maps.length,
                  itemBuilder: (context, index) {
                    final map = maps[index];
                    final isSelected =
                        map.id.toString() == widget.selectedMapKey;
                    return _buildMapItem(context, map, isSelected);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMapItem(BuildContext context, MapModel map, bool isSelected) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => widget.onMapSelected(map.id.toString()),
              icon: Icon(
                Icons.map_outlined,
                size: 16,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              ),
              label: Text(map.name),
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
            icon: const Icon(Icons.delete_outline, size: 18),
            color: Colors.red,
            onPressed: () {
              // TODO: Add confirmation dialog
              widget.mapProvider.deleteMap(map.id.toString());
            },
            tooltip: 'Delete Map',
          ),
        ],
      ),
    );
  }
}
