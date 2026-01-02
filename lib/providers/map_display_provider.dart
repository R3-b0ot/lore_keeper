import 'package:flutter/foundation.dart';
import 'package:lore_keeper/models/map_model.dart';

class MapDisplayProvider extends ChangeNotifier {
  MapModel? _currentMap;

  MapModel? get currentMap => _currentMap;

  void setCurrentMap(MapModel? map) {
    _currentMap = map;
    notifyListeners();
  }

  void clearCurrentMap() {
    _currentMap = null;
    notifyListeners();
  }
}
