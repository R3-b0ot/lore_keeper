import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lore_keeper/models/map_model.dart';
import 'package:lore_keeper/providers/map_list_provider.dart';
import 'package:lore_keeper/providers/map_display_provider.dart';
import 'package:lore_keeper/widgets/map_list_pane.dart';
import 'package:lore_keeper/widgets/map_display.dart';

class MapModule extends StatefulWidget {
  final int projectId;
  final VoidCallback onReload;

  const MapModule({super.key, required this.projectId, required this.onReload});

  @override
  State<MapModule> createState() => MapModuleState();
}

class MapModuleState extends State<MapModule> {
  late MapListProvider _mapProvider;
  late MapDisplayProvider _displayProvider;
  String _selectedMapKey = '';
  bool _isMobile = false;

  @override
  void initState() {
    super.initState();
    _mapProvider = MapListProvider(widget.projectId);
    _displayProvider = MapDisplayProvider();
  }

  @override
  void dispose() {
    _mapProvider.dispose();
    _displayProvider.dispose();
    super.dispose();
  }

  void _onMapSelected(String key) {
    setState(() {
      _selectedMapKey = key;
    });
    final map = _mapProvider.getMap(int.tryParse(key) ?? -1);
    _displayProvider.setCurrentMap(map);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                _isMobile = constraints.maxWidth < 800;
                return _isMobile ? _buildMobileLayout() : _buildDesktopLayout();
              },
            ),
          ),
          _buildBottomStatusBar(),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Top bar with map selection
        SizedBox(
          height: kToolbarHeight,
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: DropdownButton<String>(
                    value: _selectedMapKey.isEmpty ? null : _selectedMapKey,
                    hint: const Text('Select a map'),
                    isExpanded: true,
                    items: _mapProvider.maps.map((map) {
                      return DropdownMenuItem<String>(
                        value: map.key.toString(),
                        child: Text(map.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        _onMapSelected(value);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        // Map viewer
        Expanded(
          child: _selectedMapKey.isEmpty
              ? const Center(child: Text('Select a map to view'))
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
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left sidebar with map list
        SizedBox(
          width: 250,
          child: MapListPane(
            mapProvider: _mapProvider,
            selectedMapKey: _selectedMapKey,
            onMapSelected: _onMapSelected,
            isMobile: false,
          ),
        ),
        // Vertical divider
        const VerticalDivider(width: 1),
        // Main content area
        Expanded(
          child: _selectedMapKey.isEmpty
              ? const Center(child: Text('Select a map to view'))
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
      ],
    );
  }

  Widget _buildBottomStatusBar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      height: 35,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      color: colorScheme.surfaceContainer,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Status indicator (placeholder for future saving status)
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
