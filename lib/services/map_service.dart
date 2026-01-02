import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:lore_keeper/models/map_model.dart';
import 'package:uuid/uuid.dart';

class MapService {
  static const String _boxName = 'maps';
  static final _uuid = Uuid();

  Future<Box<String>> _getBox() async {
    return await Hive.openBox<String>(_boxName);
  }

  static Future<List<MapModel>> getAllMaps(int projectId) async {
    final service = MapService();
    final box = await service._getBox();
    final maps = <MapModel>[];

    for (final key in box.keys) {
      final value = box.get(key);
      if (value != null) {
        try {
          final mapData = jsonDecode(value) as Map<String, dynamic>;
          if (mapData['projectId'] == projectId) {
            maps.add(MapModel.fromJson(mapData));
          }
        } catch (e) {
          // Skip invalid entries
          continue;
        }
      }
    }

    return maps;
  }

  static Map<String, dynamic> getMapDataFromModel(MapModel model) {
    return {
      'id': model.id,
      'name': model.name,
      'style': model.style,
      'resolution': model.resolution,
      'aspectRatio': model.aspectRatio,
      'created': model.created?.toIso8601String(),
      'lastModified': model.lastModified?.toIso8601String(),
    };
  }

  static MapModel createMapModelFromData(
    Map<String, dynamic> mapData,
    int projectId,
  ) {
    return MapModel(
      id: mapData['id'] ?? _uuid.v4(),
      name: mapData['name'] ?? 'Unnamed Map',
      projectId: projectId,
      style: mapData['style'],
      resolution: mapData['resolution'],
      aspectRatio: mapData['aspectRatio'],
    );
  }

  static Future<String> saveMap(MapModel map) async {
    final service = MapService();
    final box = await service._getBox();
    final key = '${map.projectId}_${map.id}';
    final jsonData = jsonEncode(map.toJson());
    await box.put(key, jsonData);
    return map.id;
  }

  Future<void> deleteMap(int projectId, String mapId) async {
    final box = await _getBox();
    final key = '${projectId}_$mapId';
    await box.delete(key);
  }

  Future<MapModel?> getMap(int projectId, String mapId) async {
    final box = await _getBox();
    final key = '${projectId}_$mapId';
    final value = box.get(key);

    if (value != null) {
      try {
        final mapData = jsonDecode(value) as Map<String, dynamic>;
        return MapModel.fromJson(mapData);
      } catch (e) {
        return null;
      }
    }

    return null;
  }
}
