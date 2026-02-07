import 'package:flutter/material.dart';
import 'package:lore_keeper/providers/map_list_provider.dart';
import 'package:lore_keeper/providers/map_display_provider.dart';
import 'package:lore_keeper/widgets/map_display.dart';

class MapModule extends StatefulWidget {
  final int projectId;
  final MapListProvider mapProvider;
  final String selectedMapKey;
  final VoidCallback onReload;

  const MapModule({
    super.key,
    required this.projectId,
    required this.mapProvider,
    required this.selectedMapKey,
    required this.onReload,
  });

  @override
  State<MapModule> createState() => MapModuleState();
}

class MapModuleState extends State<MapModule> {
  late MapDisplayProvider _displayProvider;

  @override
  void initState() {
    super.initState();
    _displayProvider = MapDisplayProvider();
    _syncMapSelection();
  }

  @override
  void didUpdateWidget(MapModule oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedMapKey != widget.selectedMapKey) {
      _syncMapSelection();
    }
  }

  void _syncMapSelection() {
    if (widget.selectedMapKey.isNotEmpty) {
      final map = widget.mapProvider.getMap(
        int.tryParse(widget.selectedMapKey) ?? -1,
      );
      if (map != null) {
        _displayProvider.setCurrentMap(map);
      }
    }
  }

  @override
  void dispose() {
    _displayProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Expanded(
            child: widget.selectedMapKey.isEmpty
                ? const Center(
                    child: Text('Select a map from the sidebar to view'),
                  )
                : ListenableBuilder(
                    listenable: _displayProvider,
                    builder: (context, child) {
                      final map = _displayProvider.currentMap;
                      return map != null
                          ? MapDisplay(map: map)
                          : const Center(child: Text('Map not found'));
                    },
                  ),
          ),
          _buildBottomStatusBar(),
        ],
      ),
    );
  }

  Widget _buildBottomStatusBar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      height: 35,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600, size: 14),
              const SizedBox(width: 4),
              Text(
                'Ready',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
