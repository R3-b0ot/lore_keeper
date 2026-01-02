import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lore_keeper/models/character.dart';

class GlobalCustomFieldService {
  static const String _boxName = 'customField';
  static const String _key = 'data';

  late Box<String> _box;

  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
  }

  List<CustomField> getCustomFields() {
    final jsonString = _box.get(_key);
    if (jsonString == null) return [];
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => CustomField.fromJson(json)).toList();
  }

  Future<void> saveCustomFields(List<CustomField> fields) async {
    final jsonList = fields.map((f) => f.toJson()).toList();
    await _box.put(_key, jsonEncode(jsonList));
  }

  Future<void> addCustomField(CustomField field) async {
    final fields = getCustomFields();
    fields.add(field);
    await saveCustomFields(fields);
  }

  Future<void> updateCustomField(String name, CustomField updatedField) async {
    final fields = getCustomFields();
    final index = fields.indexWhere((f) => f.name == name);
    if (index != -1) {
      fields[index] = updatedField;
      await saveCustomFields(fields);
    }
  }

  Future<void> toggleVisibility(String name) async {
    final fields = getCustomFields();
    final index = fields.indexWhere((f) => f.name == name);
    if (index != -1) {
      fields[index].visible = !fields[index].visible;
      await saveCustomFields(fields);
    }
  }

  Future<void> removeCustomField(String name) async {
    final fields = getCustomFields();
    fields.removeWhere((f) => f.name == name);
    await saveCustomFields(fields);
  }
}
