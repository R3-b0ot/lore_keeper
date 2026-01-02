import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lore_keeper/providers/map_display_provider.dart';
import 'package:lore_keeper/widgets/map_creator_dialog.dart';

class MapViewScreen extends ConsumerStatefulWidget {
  final String? mapKey;

  const MapViewScreen({super.key, this.mapKey});

  @override
  ConsumerState<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends ConsumerState<MapViewScreen> {
  Map<String, dynamic>? _currentMap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentMap != null ? 'Map View' : 'Map Generator'),
        actions: [
          if (_currentMap != null) ...[
            IconButton(
              icon: const Icon(Icons.layers),
              onPressed: _showLayerPanel,
              tooltip: 'Toggle Layers',
            ),
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveMap,
              tooltip: 'Save Map',
            ),
          ],
        ],
      ),
      body: _currentMap != null
          ? const Center(child: Text('Map Display Coming Soon'))
          : _buildWelcomeScreen(),
      floatingActionButton: _currentMap == null
          ? FloatingActionButton.extended(
              onPressed: _showGenerationWizard,
              icon: const Icon(Icons.map),
              label: const Text('Forge New Map'),
            )
          : FloatingActionButton(
              onPressed: _showGenerationWizard,
              tooltip: 'Create New Map',
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.map_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No Map Loaded',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create a new procedural fantasy world map',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _showGenerationWizard,
            icon: const Icon(Icons.auto_fix_high),
            label: const Text('Forge New Map'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showGenerationWizard() async {
    final result = await showDialog<MapCreationResult>(
      context: context,
      builder: (context) => const MapCreatorDialog(),
    );

    if (result != null) {
      // Convert MapCreationResult to Map<String, dynamic>
      setState(() {
        _currentMap = {
          'name': result.name,
          'style': result.style,
          'resolution': result.resolution,
          'aspectRatio': result.aspectRatio,
          'created': DateTime.now(),
          'layers': [
            {
              'id': 'base_texture',
              'name': 'Base Texture',
              'type': 'texture',
              'visible': true,
              'opacity': 1.0,
            },
            {
              'id': 'grid',
              'name': 'Grid',
              'type': 'grid',
              'visible': true,
              'opacity': 0.5,
              'gridType': 'square',
              'columns': 20,
              'rows': 20,
              'lineWidth': 1.0,
              'color': Colors.grey,
            },
            {
              'id': 'objects',
              'name': 'Objects',
              'type': 'objects',
              'visible': true,
              'opacity': 1.0,
            },
          ],
        };
      });
    }
  }

  void _showLayerPanel() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _LayerControlPanel(),
    );
  }

  void _saveMap() {
    // TODO: Implement map saving
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Map saving not yet implemented')),
    );
  }
}

class _LayerControlPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayState = ref.watch(mapDisplayProvider);
    final notifier = ref.read(mapDisplayProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Map Layers',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Show Biomes'),
            subtitle: const Text('Display biome colors'),
            value: displayState.showBiomes,
            onChanged: (value) => notifier.toggleBiomes(),
          ),
          SwitchListTile(
            title: const Text('Show Elevation'),
            subtitle: const Text('Display height-based colors'),
            value: displayState.showElevation,
            onChanged: (value) => notifier.toggleElevation(),
          ),
          SwitchListTile(
            title: const Text('Show Temperature'),
            subtitle: const Text('Display temperature-based colors'),
            value: displayState.showTemperature,
            onChanged: (value) => notifier.toggleTemperature(),
          ),
          SwitchListTile(
            title: const Text('Show Precipitation'),
            subtitle: const Text('Display rainfall-based colors'),
            value: displayState.showPrecipitation,
            onChanged: (value) => notifier.togglePrecipitation(),
          ),
          SwitchListTile(
            title: const Text('Show Rivers'),
            subtitle: const Text('Display river networks'),
            value: displayState.showRivers,
            onChanged: (value) => notifier.toggleRivers(),
          ),
          SwitchListTile(
            title: const Text('Show Borders'),
            subtitle: const Text('Display political borders'),
            value: displayState.showBorders,
            onChanged: (value) => notifier.toggleBorders(),
          ),
          SwitchListTile(
            title: const Text('Show Cultures'),
            subtitle: const Text('Display culture zones'),
            value: displayState.showCultures,
            onChanged: (value) => notifier.toggleCultures(),
          ),
          SwitchListTile(
            title: const Text('Show Names'),
            subtitle: const Text('Display location names'),
            value: displayState.showNames,
            onChanged: (value) => notifier.toggleNames(),
          ),
          SwitchListTile(
            title: const Text('Show Water'),
            subtitle: const Text('Highlight water features'),
            value: displayState.showWater,
            onChanged: (value) => notifier.toggleWater(),
          ),
        ],
      ),
    );
  }
}
