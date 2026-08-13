import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:lore_keeper/models/map_data.dart';
import 'package:uuid/uuid.dart';

enum MapTool { select, pan, brush, path, stamp, eraser }

class MapProvider extends ChangeNotifier {
  final int projectId;
  late Box<MapData> _mapBox;
  MapData? _activeMap;
  
  MapTool _currentTool = MapTool.pan;
  int _activeLayerIndex = 0;
  String? _selectedStampId;
  bool _isLayersPanelVisible = false;

  MapProvider(this.projectId) {
    _initialize();
  }

  MapData? get activeMap => _activeMap;
  MapTool get currentTool => _currentTool;
  int get activeLayerIndex => _activeLayerIndex;
  String? get selectedStampId => _selectedStampId;
  bool get isLayersPanelVisible => _isLayersPanelVisible;

  void toggleLayersPanel() {
    _isLayersPanelVisible = !_isLayersPanelVisible;
    notifyListeners();
  }

  void setTool(MapTool tool) {
    _currentTool = tool;
    notifyListeners();
  }

  void selectStamp(String? id) {
    _selectedStampId = id;
    notifyListeners();
  }

  Future<void> _initialize() async {
    _mapBox = Hive.box<MapData>('map_data');
    
    // Find a map for this project or create one
    try {
      _activeMap = _mapBox.values.firstWhere((map) => map.parentProjectId == projectId);
    } catch (e) {
      // Create new map
      final newMap = MapData(
        parentProjectId: projectId,
        title: 'Main Map',
        layers: [
          MapLayer(id: 'layer_1', name: 'Background'),
          MapLayer(id: 'layer_2', name: 'Details'),
        ],
      );
      await _mapBox.add(newMap);
      _activeMap = newMap;
    }
    notifyListeners();
  }

  // New fields for selected stamp transformation
  double _brushSize = 30.0;
  double _brushOpacity = 0.8;
  String _brushTexturePath = 'assets/brush_texture.png';

  double get brushSize => _brushSize;
  double get brushOpacity => _brushOpacity;
  String get brushTexturePath => _brushTexturePath;

  void setBrushSize(double size) {
    _brushSize = size.clamp(5.0, 200.0);
    notifyListeners();
  }

  void setBrushOpacity(double opacity) {
    _brushOpacity = opacity.clamp(0.0, 1.0);
    notifyListeners();
  }

  void setBrushTexturePath(String path) {
    _brushTexturePath = path;
    notifyListeners();
  }

  /// Update selected stamp's transform properties (position, scale, rotation)
  void updateSelectedStamp({Offset? position, double? scale, double? rotation}) {
    if (_selectedStampId == null) return;
    MapStamp? targetStamp;
    for (var layer in _activeMap!.layers) {
      try {
        targetStamp = layer.stamps.firstWhere((s) => s.id == _selectedStampId);
        break;
      } catch (_) {}
    }
    if (targetStamp == null) return;
    if (position != null) {
      targetStamp.x = position.dx;
      targetStamp.y = position.dy;
    }
    if (scale != null) targetStamp.scale = scale;
    if (rotation != null) targetStamp.rotation = rotation;
    _activeMap!.save();
    notifyListeners();
  }

  void setActiveLayer(int index) {
    if (_activeMap != null && index >= 0 && index < _activeMap!.layers.length) {
      _activeLayerIndex = index;
      notifyListeners();
    }
  }

  Future<void> addLayer(String name) async {
    if (_activeMap == null) return;
    _activeMap!.layers.insert(0, MapLayer(
      id: const Uuid().v4(),
      name: name,
    ));
    await _activeMap!.save();
    _activeLayerIndex = 0; // Select new layer
    notifyListeners();
  }

  Future<void> deleteLayer(int index) async {
    if (_activeMap == null || _activeMap!.layers.length <= 1) return; // Always keep one layer
    _activeMap!.layers.removeAt(index);
    if (_activeLayerIndex >= _activeMap!.layers.length) {
      _activeLayerIndex = _activeMap!.layers.length - 1;
    }
    await _activeMap!.save();
    notifyListeners();
  }

  Future<void> reorderLayers(int oldIndex, int newIndex) async {
    if (_activeMap == null) return;
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final layer = _activeMap!.layers.removeAt(oldIndex);
    _activeMap!.layers.insert(newIndex, layer);
    
    // Update active index to track the moved layer if it was active
    if (_activeLayerIndex == oldIndex) {
      _activeLayerIndex = newIndex;
    } else if (oldIndex < _activeLayerIndex && newIndex >= _activeLayerIndex) {
      _activeLayerIndex -= 1;
    } else if (oldIndex > _activeLayerIndex && newIndex <= _activeLayerIndex) {
      _activeLayerIndex += 1;
    }
    
    await _activeMap!.save();
    notifyListeners();
  }

  Future<void> toggleLayerVisibility(int index) async {
    if (_activeMap == null) return;
    _activeMap!.layers[index].isVisible = !_activeMap!.layers[index].isVisible;
    await _activeMap!.save();
    notifyListeners();
  }

  Future<void> toggleLayerLock(int index) async {
    if (_activeMap == null) return;
    _activeMap!.layers[index].isLocked = !_activeMap!.layers[index].isLocked;
    await _activeMap!.save();
    notifyListeners();
  }

  Future<void> updateStamp(MapStamp stamp) async {
    if (_activeMap == null) return;
    await _activeMap!.save();
    notifyListeners();
  }

  Future<void> addStamp(MapStamp stamp) async {
    if (_activeMap == null || _activeMap!.layers.isEmpty) return;
    
    _activeMap!.layers[_activeLayerIndex].stamps.add(stamp);
    await _activeMap!.save();
    notifyListeners();
  }

  Future<void> addPath(MapPath path) async {
    if (_activeMap == null || _activeMap!.layers.isEmpty) return;
    
    _activeMap!.layers[_activeLayerIndex].paths.add(path);
    await _activeMap!.save();
    notifyListeners();
  }
  
  Future<void> addPolygon(MapPolygon polygon) async {
    if (_activeMap == null || _activeMap!.layers.isEmpty) return;
    
    _activeMap!.layers[_activeLayerIndex].polygons.add(polygon);
    await _activeMap!.save();
    notifyListeners();
  }

  Future<void> removeAssetAt(Offset position) async {
    // Basic hit testing would go here
    // We'll iterate layers in reverse (top to bottom) to delete the top-most clicked asset
    if (_activeMap == null) return;
    
    for (int i = _activeMap!.layers.length - 1; i >= 0; i--) {
      var layer = _activeMap!.layers[i];
      if (layer.isLocked || !layer.isVisible) continue;
      
      // Checking stamps (very crude bounding box)
      for (int j = layer.stamps.length - 1; j >= 0; j--) {
        var stamp = layer.stamps[j];
        if ((position.dx - stamp.x).abs() < 50 && (position.dy - stamp.y).abs() < 50) {
          layer.stamps.removeAt(j);
          await _activeMap!.save();
          notifyListeners();
          return;
        }
      }
    }
  }
}
