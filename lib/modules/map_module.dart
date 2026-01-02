import 'package:flutter/material.dart';
import 'package:lore_keeper/providers/map_list_provider.dart';
import 'package:lore_keeper/widgets/map_editor.dart';

class MapModule extends StatefulWidget {
  final int projectId;
  final String? selectedMapKey;
  final MapListProvider? mapListProvider;

  const MapModule({
    super.key,
    required this.projectId,
    this.selectedMapKey,
    this.mapListProvider,
  });

  @override
  State<MapModule> createState() => _MapModuleState();
}

class _MapModuleState extends State<MapModule> {
  late MapListProvider _mapListProvider;
  String? _selectedMapKey;
  Map<String, dynamic>? _currentMapData;
  bool _ownsProvider = false;

  @override
  void initState() {
    super.initState();
    // Use provided provider or create a new one
    if (widget.mapListProvider != null) {
      _mapListProvider = widget.mapListProvider!;
      _ownsProvider = false;
    } else {
      _mapListProvider = MapListProvider(projectId: widget.projectId);
      _ownsProvider = true;
    }
    _selectedMapKey = widget.selectedMapKey;
    _loadMapData();
  }

  @override
  void dispose() {
    // Only dispose if we own the provider
    if (_ownsProvider) {
      _mapListProvider.dispose();
    }
    super.dispose();
  }

  Future<void> _loadMapData() async {
    if (_selectedMapKey != null && _selectedMapKey!.isNotEmpty) {
      // Wait for provider to initialize if needed
      if (!_mapListProvider.isInitialized) {
        // Wait a bit for initialization
        await Future.delayed(const Duration(milliseconds: 100));
      }

      try {
        // Find the map in the provider
        final map = _mapListProvider.maps.firstWhere(
          (m) => m.id.toString() == _selectedMapKey,
        );
        _currentMapData = _mapToMapData(map);
        if (mounted) setState(() {});
      } catch (e) {
        // Map not found - clear current map data
        if (mounted) {
          setState(() {
            _currentMapData = null;
          });
        }
        debugPrint('Error loading map: $e');
      }
    } else {
      // No map selected - clear current map data
      if (mounted) {
        setState(() {
          _currentMapData = null;
        });
      }
    }
  }

  Map<String, dynamic> _mapToMapData(dynamic map) {
    return {
      'id': map.id.toString(),
      'name': map.name,
      'style': map.style,
      'resolution': map.resolution,
      'aspectRatio': map.aspectRatio,
      'gridType': map.gridType,
      'created': map.created,
      'lastModified': map.lastModified,
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
          'gridType': map.gridType ?? 'square',
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
  }

  List<Map<String, dynamic>> _getMapsList() {
    return _mapListProvider.maps.map((map) => _mapToMapData(map)).toList();
  }

  @override
  void didUpdateWidget(MapModule oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update selected map key if it changed from parent
    if (widget.selectedMapKey != oldWidget.selectedMapKey) {
      _selectedMapKey = widget.selectedMapKey;
      _loadMapData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _mapListProvider,
      builder: (context, child) {
        // Update selected map key from widget prop
        final newSelectedKey = widget.selectedMapKey;
        if (newSelectedKey != _selectedMapKey) {
          _selectedMapKey = newSelectedKey;
          // Load map data immediately
          _loadMapData();
        }

        // Try to load map if we have a selected key but no current data
        if (_selectedMapKey != null &&
            _selectedMapKey!.isNotEmpty &&
            _currentMapData == null &&
            _mapListProvider.isInitialized) {
          // Try to find and load the map
          try {
            final map = _mapListProvider.maps.firstWhere(
              (m) => m.id.toString() == _selectedMapKey,
            );
            _currentMapData = _mapToMapData(map);
          } catch (e) {
            // Map not found yet, will be loaded by _loadMapData
            debugPrint('Map not found in build: $e');
          }
        }

        final maps = _getMapsList();
        final currentMap = _currentMapData;

        if (currentMap == null) {
          return const Center(
            child: Text(
              'No map selected. Select a map from the list to edit.',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        }

        return MapEditor(
          mapData: currentMap,
          maps: maps,
          onMapSelected: _onMapSelected,
          onMapCreated: _onMapCreated,
        );
      },
    );
  }

  void _onMapSelected(Map<String, dynamic> map) {
    setState(() {
      _selectedMapKey = map['id']?.toString();
      _currentMapData = map;
    });
  }

  void _onMapCreated(Map<String, dynamic> map) {
    // The map is already added to the provider via MapListPane
    // Just select it
    setState(() {
      _selectedMapKey = map['id']?.toString();
      _currentMapData = map;
    });
  }
}
