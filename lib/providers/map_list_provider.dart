import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lore_keeper/models/map_model.dart';
import 'package:lore_keeper/shared/svg_style_inliner.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MapListProvider extends ChangeNotifier {
  final int _projectId;
  late Box<MapModel> _mapBox;
  bool _isInitialized = false;

  MapListProvider(this._projectId) {
    _initialize();
  }

  bool get isInitialized => _isInitialized;

  List<MapModel> get maps {
    if (!_isInitialized) return [];
    return _mapBox.values
        .where((map) => map.parentProjectId == _projectId)
        .toList();
  }

  Future<void> _initialize() async {
    _mapBox = await Hive.openBox<MapModel>('maps');
    _isInitialized = true;
    await _runSvgInlineMigrationOnce();
    notifyListeners();
  }

  Future<int> createNewMap(
    String name,
    String filePath,
    String fileType,
  ) async {
    if (!_isInitialized) return -1;

    var resolvedPath = filePath;
    if (fileType.toLowerCase() == 'svg') {
      resolvedPath = await SvgStyleInliner.inlineFile(filePath);
    }

    final newMap = MapModel(
      name: name,
      filePath: resolvedPath,
      fileType: fileType,
      parentProjectId: _projectId,
    );

    final key = await _mapBox.add(newMap);
    notifyListeners();
    return key;
  }

  Future<void> deleteMap(int key) async {
    if (!_isInitialized) return;

    await _mapBox.delete(key);
    notifyListeners();
  }

  Future<void> updateMapName(int key, String newName) async {
    if (!_isInitialized) return;

    final map = _mapBox.get(key);
    if (map != null) {
      map.name = newName;
      map.updateTimestamp();
      await map.save();
      notifyListeners();
    }
  }

  MapModel? getMap(int key) {
    if (!_isInitialized) return null;
    return _mapBox.get(key);
  }

  @override
  void dispose() {
    _mapBox.close();
    super.dispose();
  }

  Future<void> _runSvgInlineMigrationOnce() async {
    const migrationKey = 'svg_inline_migration_v1_done';
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(migrationKey) ?? false) return;

    var updated = false;
    final maps = _mapBox.values
        .where((map) => map.fileType.toLowerCase() == 'svg')
        .toList();

    for (final map in maps) {
      final currentPath = map.filePath;
      if (currentPath.toLowerCase().endsWith('_inline.svg')) {
        continue;
      }
      final newPath = await SvgStyleInliner.inlineFile(currentPath);
      if (newPath != currentPath) {
        map.filePath = newPath;
        map.updateTimestamp();
        await map.save();
        updated = true;
      }
    }

    await prefs.setBool(migrationKey, true);

    if (updated) {
      notifyListeners();
    }
  }
}
