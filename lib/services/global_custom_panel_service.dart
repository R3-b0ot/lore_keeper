import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lore_keeper/models/character.dart';

class GlobalCustomPanelService {
  static const String _boxName = 'customPanel';
  static const String _key = 'data';

  late Box<String> _box;

  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
  }

  List<CustomPanel> getCustomPanels() {
    final jsonString = _box.get(_key);
    if (jsonString == null) return [];
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => CustomPanel.fromJson(json)).toList();
  }

  Future<void> saveCustomPanels(List<CustomPanel> panels) async {
    final jsonList = panels.map((p) => p.toJson()).toList();
    await _box.put(_key, jsonEncode(jsonList));
  }

  Future<void> addCustomPanel(CustomPanel panel) async {
    final panels = getCustomPanels();
    panels.add(panel);
    await saveCustomPanels(panels);
  }

  Future<void> updateCustomPanel(String id, CustomPanel updatedPanel) async {
    final panels = getCustomPanels();
    final index = panels.indexWhere((p) => p.id == id);
    if (index != -1) {
      panels[index] = updatedPanel;
      await saveCustomPanels(panels);
    }
  }

  Future<void> removeCustomPanel(String id) async {
    final panels = getCustomPanels();
    panels.removeWhere((p) => p.id == id);
    await saveCustomPanels(panels);
  }
}
