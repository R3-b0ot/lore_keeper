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
  void _showMapCreatorDialog() {
    showDialog(
      context: context,
      builder: (context) => MapCreatorDialog(mapProvider: widget.mapProvider),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: ListenableBuilder(
        listenable: widget.mapProvider,
        builder: (context, child) {
          final maps = widget.mapProvider.maps;

          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Maps',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    TextButton(
                      onPressed: _showMapCreatorDialog,
                      child: const Text('Create'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: maps.isEmpty
                      ? const Center(child: Text('No maps created yet.'))
                      : ListView.builder(
                          itemCount: maps.length,
                          itemBuilder: (context, index) {
                            final map = maps[index];
                            final isSelected =
                                map.key.toString() == widget.selectedMapKey;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: _buildMapItem(context, map, isSelected),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMapItem(BuildContext context, MapModel map, bool isSelected) {
    return OutlinedButton.icon(
      onPressed: () => widget.onMapSelected(map.key.toString()),
      icon: Icon(
        _getFileTypeIcon(map.fileType),
        size: 16,
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface,
      ),
      label: Text(map.name, softWrap: true, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.centerLeft,
        backgroundColor: isSelected
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surface,
        foregroundColor: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface,
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  IconData _getFileTypeIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'jpeg':
      case 'jpg':
        return Icons.image;
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
