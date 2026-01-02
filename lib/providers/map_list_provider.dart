import 'package:flutter/foundation.dart';
import 'package:lore_keeper/models/map_model.dart';
import 'package:lore_keeper/services/map_service.dart';

class MapListProvider with ChangeNotifier {
  final int projectId;
  List<MapModel> _maps = [];
  bool _isInitialized = false;

  List<MapModel> get maps => _maps;
  bool get isInitialized => _isInitialized;

  MapListProvider({required this.projectId}) {
    _loadMaps();
  }

  Future<void> _loadMaps() async {
    try {
      _maps = await MapService.getAllMaps(projectId);
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading maps: $e');
      _isInitialized = true; // Even on error, mark as initialized
      notifyListeners();
    }
  }

  Future<String> createNewMap(
    String name, {
    String? style,
    String? resolution,
    String? aspectRatio,
    String? gridType,
  }) async {
    final newMap = MapModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      projectId: projectId,
      style: style,
      resolution: resolution,
      aspectRatio: aspectRatio,
      gridType: gridType,
    );
    _maps.add(newMap);
    notifyListeners();
    // Save to storage
    try {
      await MapService.saveMap(newMap);
    } catch (e) {
      debugPrint('Error saving map: $e');
    }
    return newMap.id;
  }

  Future<void> deleteMap(String mapId) async {
    _maps.removeWhere((map) => map.id == mapId);
    notifyListeners();
    // Remove from storage
    try {
      await MapService().deleteMap(projectId, mapId);
    } catch (e) {
      debugPrint('Error deleting map: $e');
    }
  }

  Future<void> updateMapName(String mapId, String newName) async {
    final mapIndex = _maps.indexWhere((map) => map.id == mapId);
    if (mapIndex != -1) {
      _maps[mapIndex].name = newName;
      _maps[mapIndex].lastModified = DateTime.now();
      notifyListeners();
      // Save to storage
      try {
        await MapService.saveMap(_maps[mapIndex]);
      } catch (e) {
        debugPrint('Error updating map: $e');
      }
    }
  }
}
