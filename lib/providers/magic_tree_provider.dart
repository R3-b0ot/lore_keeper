import 'package:flutter/material.dart';
import 'package:lore_keeper/theme/app_colors.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lore_keeper/models/magic_node.dart';
import 'package:lore_keeper/models/magic_system.dart';
import 'package:lore_keeper/utils/magic_type_specs.dart';
import 'package:uuid/uuid.dart';

class MagicSystemSeed {
  final String name;
  final List<String> fuels;
  final List<String> methods;
  final List<MagicSchoolSeed> schools;

  const MagicSystemSeed({
    required this.name,
    required this.fuels,
    required this.methods,
    required this.schools,
  });
}

class MagicSchoolSeed {
  final String name;
  final String iconKey;
  final int colorValue;

  const MagicSchoolSeed({
    required this.name,
    required this.iconKey,
    required this.colorValue,
  });
}

class MagicNodeEntry {
  final MagicNode node;
  final int level;

  const MagicNodeEntry(this.node, this.level);
}

class MagicTreeProvider extends ChangeNotifier {
  static const String _rootParentKey = '__root__';
  static const Set<String> _nonEditableTypes = {
    'magic_system',
    'fuel_category',
    'trigger_category',
    'discipline_category',
  };

  final int _projectId;
  final Uuid _uuid = const Uuid();
  late Box<MagicSystem> _systemBox;
  late Box<MagicNode> _nodeBox;

  bool _isInitialized = false;
  int? _selectedSystemKey;
  String? _selectedNodeId;
  final Set<String> _expandedNodeIds = <String>{};

  final Map<String, MagicNode> _nodesById = <String, MagicNode>{};
  final Map<String, int> _nodeHiveKeyById = <String, int>{};
  final Map<String, List<MagicNode>> _childrenByParent =
      <String, List<MagicNode>>{};

  MagicTreeProvider(this._projectId) {
    _initialize();
  }

  bool get isInitialized => _isInitialized;

  List<MagicSystem> get systems {
    if (!_isInitialized) return [];
    final systems = _systemBox.values
        .where((system) => system.projectId == _projectId)
        .toList();
    systems.sort((a, b) => a.name.compareTo(b.name));
    return systems;
  }

  MagicSystem? get selectedSystem {
    if (_selectedSystemKey == null) return null;
    return _systemBox.get(_selectedSystemKey);
  }

  MagicNode? get selectedNode {
    if (_selectedNodeId == null) return null;
    return _nodesById[_selectedNodeId!];
  }

  bool get canDeleteSelectedSystem => systems.length > 1;

  bool get hasSelection => selectedSystem != null;

  bool isExpanded(String nodeId) => _expandedNodeIds.contains(nodeId);

  bool hasChildren(String nodeId) =>
      (_childrenByParent[nodeId]?.isNotEmpty ?? false);

  List<MagicNodeEntry> getVisibleNodes({String filter = ''}) {
    final system = selectedSystem;
    if (system == null) return [];
    final rootId = system.rootNodeId;
    final normalizedFilter = filter.trim().toLowerCase();

    if (normalizedFilter.isNotEmpty) {
      final matches =
          _nodesById.values
              .where(
                (node) =>
                    node.systemKey == system.key &&
                    node.title.toLowerCase().contains(normalizedFilter),
              )
              .where((node) => node.type != 'magic_system')
              .toList()
            ..sort((a, b) => a.title.compareTo(b.title));
      return matches.map((node) => MagicNodeEntry(node, 0)).toList();
    }

    final List<MagicNodeEntry> result = [];

    void visit(String nodeId, int level) {
      final node = _nodesById[nodeId];
      if (node == null) return;
      final isRoot = node.id == rootId && node.type == 'magic_system';
      if (!isRoot) {
        result.add(MagicNodeEntry(node, level));
      }
      if (isRoot || _expandedNodeIds.contains(nodeId)) {
        for (final child in _getChildren(nodeId)) {
          visit(child.id, isRoot ? level : level + 1);
        }
      }
    }

    visit(rootId, 0);
    return result;
  }

  Future<void> _initialize() async {
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(MagicSystemAdapter());
    }
    if (!Hive.isAdapterRegistered(8)) {
      Hive.registerAdapter(MagicNodeAdapter());
    }
    if (!Hive.isAdapterRegistered(9)) {
      Hive.registerAdapter(MagicAttributeAdapter());
    }
    if (!Hive.isAdapterRegistered(22)) {
      Hive.registerAdapter(MagicImageAdapter());
    }
    _systemBox = await Hive.openBox<MagicSystem>('magic_systems');
    _nodeBox = await Hive.openBox<MagicNode>('magic_nodes');
    _isInitialized = true;
    await _migrateLegacyTypes();
    await _ensureAtLeastOneSystem();
    _rebuildCaches();
    notifyListeners();
  }

  Future<void> _ensureAtLeastOneSystem() async {
    if (systems.isNotEmpty) {
      _selectedSystemKey ??= systems.first.key as int?;
      final system = selectedSystem;
      _selectedNodeId ??= system?.lastSelectedNodeId ?? system?.rootNodeId;
      if (system != null) {
        _expandedNodeIds.add(system.rootNodeId);
      }
      return;
    }

    await createSystem('New Magic System');
  }

  void _rebuildCaches() {
    _nodesById.clear();
    _nodeHiveKeyById.clear();
    _childrenByParent.clear();

    final projectSystemKeys = systems.map((s) => s.key as int).toSet();

    for (final entry in _nodeBox.toMap().entries) {
      final hiveKey = entry.key;
      final node = entry.value;
      if (!projectSystemKeys.contains(node.systemKey)) continue;
      _nodesById[node.id] = node;
      _nodeHiveKeyById[node.id] = hiveKey;
      final parentKey = node.parentId ?? _rootParentKey;
      _childrenByParent.putIfAbsent(parentKey, () => <MagicNode>[]).add(node);
    }

    for (final entry in _childrenByParent.entries) {
      entry.value.sort((a, b) => a.title.compareTo(b.title));
    }

    final system = selectedSystem;
    if (system != null) {
      _selectedNodeId = _resolveContentSelection(
        _selectedNodeId ?? system.rootNodeId,
        system.rootNodeId,
      );
    }
  }

  List<MagicNode> _getChildren(String parentId) {
    final children = _childrenByParent[parentId] ?? <MagicNode>[];
    final parent = _nodesById[parentId];
    if (parent == null || parent.childrenOrder.isEmpty) {
      return children;
    }

    final orderIndex = <String, int>{};
    for (int i = 0; i < parent.childrenOrder.length; i++) {
      orderIndex[parent.childrenOrder[i]] = i;
    }

    final sorted = List<MagicNode>.from(children);
    sorted.sort((a, b) {
      final aIndex = orderIndex[a.id] ?? 9999;
      final bIndex = orderIndex[b.id] ?? 9999;
      return aIndex.compareTo(bIndex);
    });
    return sorted;
  }

  String? _resolveContentSelection(String? nodeId, String? rootId) {
    if (nodeId == null) return null;
    final node = _nodesById[nodeId];
    if (node == null) return nodeId;
    if (!_nonEditableTypes.contains(node.type)) return nodeId;
    final fallbackRoot = rootId ?? node.id;
    return _findFirstContentDescendant(node.id) ??
        _findFirstContentDescendant(fallbackRoot) ??
        nodeId;
  }

  String? _findFirstContentDescendant(String nodeId) {
    for (final child in _getChildren(nodeId)) {
      if (!_nonEditableTypes.contains(child.type)) return child.id;
      final nested = _findFirstContentDescendant(child.id);
      if (nested != null) return nested;
    }
    return null;
  }

  void selectSystem(int key) {
    if (_selectedSystemKey == key) return;
    _selectedSystemKey = key;
    final system = _systemBox.get(key);
    _selectedNodeId = system?.lastSelectedNodeId ?? system?.rootNodeId;
    _selectedNodeId = _resolveContentSelection(
      _selectedNodeId,
      system?.rootNodeId,
    );
    if (system != null) {
      _expandedNodeIds.add(system.rootNodeId);
    }
    notifyListeners();
  }

  void selectNode(String nodeId) {
    final system = selectedSystem;
    final resolved = _resolveContentSelection(nodeId, system?.rootNodeId);
    _selectedNodeId = resolved ?? nodeId;
    if (system != null) {
      system.lastSelectedNodeId = _selectedNodeId!;
      system.updateTimestamp();
      system.save();
    }
    notifyListeners();
  }

  void toggleExpanded(String nodeId) {
    if (_expandedNodeIds.contains(nodeId)) {
      _expandedNodeIds.remove(nodeId);
    } else {
      _expandedNodeIds.add(nodeId);
    }
    notifyListeners();
  }

  Future<int> createSystem(String name) async {
    final rootId = _uuid.v4();
    final system = MagicSystem(
      name: name.trim().isEmpty ? 'New Magic System' : name.trim(),
      projectId: _projectId,
      rootNodeId: rootId,
      lastSelectedNodeId: rootId,
      isConfigured: false,
    );

    final systemKey = await _systemBox.add(system);
    final rootNode = MagicNode(
      id: rootId,
      systemKey: systemKey,
      parentId: null,
      type: 'magic_system',
      title: system.name,
      iconKey: 'magic_system',
      colorValue: AppColors.primary.toARGB32(),
      content: '',
      attributes: <MagicAttribute>[],
      childrenOrder: <String>[],
    );
    await _nodeBox.add(rootNode);

    _selectedSystemKey = systemKey;
    _selectedNodeId = rootId;
    _expandedNodeIds.add(rootId);
    _rebuildCaches();
    notifyListeners();
    return systemKey;
  }

  Future<void> deleteSystem(int key) async {
    if (!canDeleteSelectedSystem) return;
    final system = _systemBox.get(key);
    if (system == null) return;
    await _deleteNodesForSystem(key);
    await _systemBox.delete(key);

    final remaining = systems;
    if (remaining.isNotEmpty) {
      selectSystem(remaining.first.key as int);
    }
    _rebuildCaches();
    notifyListeners();
  }

  Future<void> updateSystemName(int key, String newName) async {
    final system = _systemBox.get(key);
    if (system == null) return;
    system.name = newName.trim().isEmpty ? system.name : newName.trim();
    system.updateTimestamp();
    await system.save();

    final rootNode = _nodesById[system.rootNodeId];
    if (rootNode != null) {
      rootNode.title = system.name;
      rootNode.updateTimestamp();
      await rootNode.save();
    }
    _rebuildCaches();
    notifyListeners();
  }

  Future<void> configureSystem(int systemKey, MagicSystemSeed seed) async {
    final system = _systemBox.get(systemKey);
    if (system == null) return;
    await _deleteNodesForSystem(systemKey, keepRootId: system.rootNodeId);

    final rootNode =
        _nodesById[system.rootNodeId] ??
        MagicNode(
          id: system.rootNodeId,
          systemKey: systemKey,
          parentId: null,
          type: 'magic_system',
          title: seed.name,
          iconKey: 'magic_system',
          colorValue: AppColors.primary.toARGB32(),
          content: '',
          attributes: <MagicAttribute>[],
          childrenOrder: <String>[],
        );

    rootNode.title = seed.name;
    rootNode.iconKey = 'magic_system';
    rootNode.type = 'magic_system';
    rootNode.updateTimestamp();
    await _upsertNode(rootNode);

    final fuelsCategory = await _createChildNode(
      parentId: rootNode.id,
      systemKey: systemKey,
      type: 'fuel_category',
      title: 'Catalysts & Fuel',
      iconKey: specForType('fuel_category').iconKey,
      colorValue: specForType('fuel_category').color.toARGB32(),
    );
    for (final fuel in seed.fuels) {
      await _createChildNode(
        parentId: fuelsCategory.id,
        systemKey: systemKey,
        type: 'fuel',
        title: fuel,
        iconKey: 'fuel',
        colorValue: AppColors.success.toARGB32(),
      );
    }

    final methodsCategory = await _createChildNode(
      parentId: rootNode.id,
      systemKey: systemKey,
      type: 'trigger_category',
      title: 'Triggers',
      iconKey: specForType('trigger_category').iconKey,
      colorValue: specForType('trigger_category').color.toARGB32(),
    );
    for (final method in seed.methods) {
      await _createChildNode(
        parentId: methodsCategory.id,
        systemKey: systemKey,
        type: 'trigger',
        title: method,
        iconKey: specForType('trigger').iconKey,
        colorValue: specForType('trigger').color.toARGB32(),
      );
    }

    final disciplinesCategory = await _createChildNode(
      parentId: rootNode.id,
      systemKey: systemKey,
      type: 'discipline_category',
      title: 'Disciplines',
      iconKey: specForType('discipline_category').iconKey,
      colorValue: specForType('discipline_category').color.toARGB32(),
    );

    for (final school in seed.schools) {
      final schoolNode = await _createChildNode(
        parentId: disciplinesCategory.id,
        systemKey: systemKey,
        type: 'discipline',
        title: school.name,
        iconKey: school.iconKey,
        colorValue: school.colorValue,
      );
      await _createChildNode(
        parentId: schoolNode.id,
        systemKey: systemKey,
        type: 'spells_category',
        title: 'Spells',
        iconKey: specForType('spells_category').iconKey,
        colorValue: school.colorValue,
      );
      await _createChildNode(
        parentId: schoolNode.id,
        systemKey: systemKey,
        type: 'enchantments_category',
        title: 'Enchantments',
        iconKey: specForType('enchantments_category').iconKey,
        colorValue: school.colorValue,
      );
    }

    system.name = seed.name;
    system.isConfigured = true;
    system.lastSelectedNodeId = rootNode.id;
    system.updateTimestamp();
    await system.save();

    _selectedSystemKey = systemKey;
    _selectedNodeId = rootNode.id;
    _expandedNodeIds.add(rootNode.id);
    _rebuildCaches();
    notifyListeners();
  }

  Future<MagicNode> _createChildNode({
    required String parentId,
    required int systemKey,
    required String type,
    required String title,
    required String iconKey,
    required int colorValue,
  }) async {
    final node = MagicNode(
      id: _uuid.v4(),
      systemKey: systemKey,
      parentId: parentId,
      type: type,
      title: title,
      iconKey: iconKey,
      colorValue: colorValue,
      content: '',
      attributes: specForType(type).defaultAttributes(),
      childrenOrder: <String>[],
    );

    await _nodeBox.add(node);
    final parent = _nodesById[parentId];
    if (parent != null) {
      parent.childrenOrder = [...parent.childrenOrder, node.id];
      parent.updateTimestamp();
      await parent.save();
    }

    return node;
  }

  Future<void> addChildNode(String type) async {
    final system = selectedSystem;
    final parentId = _selectedNodeId ?? system?.rootNodeId;
    if (system == null || parentId == null) return;

    await _createChildNode(
      parentId: parentId,
      systemKey: system.key as int,
      type: type,
      title: 'New ${specForType(type).label}',
      iconKey: specForType(type).iconKey,
      colorValue: specForType(type).color.toARGB32(),
    );
    _rebuildCaches();
    notifyListeners();
  }

  Future<void> addChildNodeToParent(String parentId, String type) async {
    final system = selectedSystem;
    if (system == null) return;
    final spec = specForType(type);
    await _createChildNode(
      parentId: parentId,
      systemKey: system.key as int,
      type: type,
      title: 'New ${spec.label}',
      iconKey: spec.iconKey,
      colorValue: spec.color.toARGB32(),
    );
    _rebuildCaches();
    notifyListeners();
  }

  Future<void> addSiblingNode(String nodeId) async {
    final node = _nodesById[nodeId];
    if (node == null) return;
    final parentId = node.parentId;
    if (parentId == null) return;
    await addChildNodeToParent(parentId, node.type);
  }

  Future<void> deleteNode(String nodeId) async {
    final node = _nodesById[nodeId];
    if (node == null) return;
    final system = selectedSystem;
    if (system != null && node.id == system.rootNodeId) return;

    final idsToDelete = _collectDescendants(nodeId);
    idsToDelete.add(nodeId);
    for (final id in idsToDelete) {
      final hiveKey = _nodeHiveKeyById[id];
      if (hiveKey != null) {
        await _nodeBox.delete(hiveKey);
      }
    }

    final parent = node.parentId != null ? _nodesById[node.parentId!] : null;
    if (parent != null) {
      parent.childrenOrder = parent.childrenOrder
          .where((id) => id != nodeId)
          .toList();
      parent.updateTimestamp();
      await parent.save();
    }

    if (_selectedNodeId == nodeId) {
      _selectedNodeId = parent?.id ?? system?.rootNodeId;
    }

    _rebuildCaches();
    notifyListeners();
  }

  Future<void> _migrateLegacyTypes() async {
    final entries = _nodeBox.toMap().entries.toList();
    for (final entry in entries) {
      final node = entry.value;
      String? newType;
      if (node.type == 'magic_system') {
        if (node.iconKey != specForType('magic_system').iconKey) {
          node.iconKey = specForType('magic_system').iconKey;
          node.updateTimestamp();
          await node.save();
        }
        continue;
      } else if (node.type == 'system') {
        newType = 'magic_system';
      } else if (node.type == 'system_category') {
        final title = node.title.trim().toLowerCase();
        if (title == 'catalysts & fuel') {
          newType = 'fuel_category';
        } else if (title == 'incantations' || title == 'usage') {
          newType = 'trigger_category';
        } else {
          newType = 'discipline_category';
        }
      } else if (node.type == 'spell_category') {
        newType = 'spells_category';
      } else if (node.type == 'enchantment_category') {
        newType = 'enchantments_category';
      } else if (node.type == 'category') {
        final title = node.title.trim().toLowerCase();
        if (title == 'catalysts & fuel') {
          newType = 'fuel_category';
        } else if (title == 'incantations' || title == 'usage') {
          newType = 'trigger_category';
        } else if (title == 'magical disciplines' ||
            title == 'schools' ||
            title == 'disciplines') {
          newType = 'discipline_category';
        } else if (title == 'spells') {
          newType = 'spells_category';
        } else if (title == 'enchantments') {
          newType = 'enchantments_category';
        } else {
          newType = 'discipline_category';
        }
      } else if (node.type == 'method') {
        newType = 'trigger';
      } else if (node.type == 'usage_cat') {
        newType = 'trigger_category';
      } else if (node.type == 'indi_use') {
        newType = 'trigger';
      } else if (node.type == 'fuel_cat') {
        newType = 'fuel_category';
      } else if (node.type == 'schools_cat') {
        newType = 'discipline_category';
      } else if (node.type == 'school') {
        newType = 'discipline';
      } else if (node.type == 'spells_cat') {
        newType = 'spells_category';
      } else if (node.type == 'enchantments_cat') {
        newType = 'enchantments_category';
      }

      if (newType != null && node.type != newType) {
        node.type = newType;
        node.iconKey = specForType(newType).iconKey;
        node.updateTimestamp();
        await node.save();
      }
    }
  }

  Future<void> updateNodeTitle(String nodeId, String title) async {
    final node = _nodesById[nodeId];
    if (node == null) return;
    node.title = title;
    node.updateTimestamp();
    await node.save();
    final system = _systemBox.get(node.systemKey);
    if (system != null && system.rootNodeId == node.id) {
      system.name = title.trim().isEmpty ? system.name : title.trim();
      system.updateTimestamp();
      await system.save();
    }
    notifyListeners();
  }

  Future<void> updateNodeContent(String nodeId, String content) async {
    final node = _nodesById[nodeId];
    if (node == null) return;
    node.content = content;
    node.updateTimestamp();
    await node.save();
    notifyListeners();
  }

  Future<void> updateNodeType(String nodeId, String type) async {
    final node = _nodesById[nodeId];
    if (node == null) return;
    node.type = type;
    node.iconKey = specForType(type).iconKey;
    node.attributes = _mergeAttributes(node.attributes, type);
    node.updateTimestamp();
    await node.save();
    notifyListeners();
  }

  Future<void> updateNodeIcon(String nodeId, String iconKey) async {
    final node = _nodesById[nodeId];
    if (node == null) return;
    node.iconKey = iconKey;
    node.updateTimestamp();
    await node.save();
    notifyListeners();
  }

  Future<void> updateNodeColor(String nodeId, Color color) async {
    final node = _nodesById[nodeId];
    if (node == null) return;
    node.colorValue = color.toARGB32();
    node.updateTimestamp();
    await node.save();
    notifyListeners();
  }

  Future<void> addAttribute(String nodeId) async {
    final node = _nodesById[nodeId];
    if (node == null) return;
    node.attributes = [
      ...node.attributes,
      MagicAttribute(label: 'Property', value: ''),
    ];
    node.updateTimestamp();
    await node.save();
    notifyListeners();
  }

  Future<void> updateAttribute(
    String nodeId,
    int index, {
    String? label,
    String? value,
  }) async {
    final node = _nodesById[nodeId];
    if (node == null) return;
    if (index < 0 || index >= node.attributes.length) return;
    final attribute = node.attributes[index];
    node.attributes[index] = MagicAttribute(
      label: label ?? attribute.label,
      value: value ?? attribute.value,
    );
    node.updateTimestamp();
    await node.save();
    notifyListeners();
  }

  Future<void> deleteAttribute(String nodeId, int index) async {
    final node = _nodesById[nodeId];
    if (node == null) return;
    if (index < 0 || index >= node.attributes.length) return;
    final updated = [...node.attributes]..removeAt(index);
    node.attributes = updated;
    node.updateTimestamp();
    await node.save();
    notifyListeners();
  }

  Future<void> addImage(String nodeId, MagicImage image) async {
    final node = _nodesById[nodeId];
    if (node == null) return;
    node.images = [...node.images, image];
    node.updateTimestamp();
    await node.save();
    notifyListeners();
  }

  Future<void> updateImage(
    String nodeId,
    int index, {
    String? caption,
    String? state,
  }) async {
    final node = _nodesById[nodeId];
    if (node == null) return;
    if (index < 0 || index >= node.images.length) return;
    final current = node.images[index];
    node.images = [
      ...node.images.take(index),
      MagicImage(
        imageData: current.imageData,
        caption: caption ?? current.caption,
        state: state ?? current.state,
        aspectRatio: current.aspectRatio,
      ),
      ...node.images.skip(index + 1),
    ];
    node.updateTimestamp();
    await node.save();
    notifyListeners();
  }

  Future<void> deleteImage(String nodeId, int index) async {
    final node = _nodesById[nodeId];
    if (node == null) return;
    if (index < 0 || index >= node.images.length) return;
    node.images = [...node.images]..removeAt(index);
    node.updateTimestamp();
    await node.save();
    notifyListeners();
  }

  List<String> _collectDescendants(String nodeId) {
    final result = <String>[];
    void visit(String id) {
      for (final child in _getChildren(id)) {
        result.add(child.id);
        visit(child.id);
      }
    }

    visit(nodeId);
    return result;
  }

  Future<void> _deleteNodesForSystem(
    int systemKey, {
    String? keepRootId,
  }) async {
    final entries = _nodeBox.toMap().entries.toList();
    for (final entry in entries) {
      final node = entry.value;
      if (node.systemKey != systemKey) continue;
      if (keepRootId != null && node.id == keepRootId) continue;
      await _nodeBox.delete(entry.key);
    }
    _rebuildCaches();
  }

  Future<void> _upsertNode(MagicNode node) async {
    final hiveKey = _nodeHiveKeyById[node.id];
    if (hiveKey != null) {
      await node.save();
    } else {
      await _nodeBox.add(node);
    }
  }

  List<MagicAttribute> _mergeAttributes(
    List<MagicAttribute> existing,
    String type,
  ) {
    final defaults = specForType(type).defaultAttributes();
    final existingKeys = existing.map((attr) => attr.label).toSet();
    final additions = defaults
        .where((attr) => !existingKeys.contains(attr.label))
        .toList();
    return [...existing, ...additions];
  }

  @override
  void dispose() {
    _systemBox.close();
    _nodeBox.close();
    super.dispose();
  }
}
