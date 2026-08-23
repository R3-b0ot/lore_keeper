import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lore_keeper/models/classification_node.dart';
import 'package:uuid/uuid.dart';

class SpeciesNodeEntry {
  final ClassificationNode node;
  final int level;
  const SpeciesNodeEntry(this.node, this.level);
}

class SpeciesProvider extends ChangeNotifier {
  static const _root = '__root__';
  final int _projectId;
  final _uuid = const Uuid();
  late Box<ClassificationNode> _box;
  bool _ready = false;
  String? _selectedId;
  final _expanded = <String>{};
  final _byId = <String, ClassificationNode>{};
  final _keys = <String, int>{};
  final _children = <String, List<ClassificationNode>>{};
  String? _faunaRootId;
  String? _floraRootId;

  SpeciesProvider(this._projectId) {
    _initialize();
  }

  bool get isInitialized => _ready;
  ClassificationNode? get selectedNode =>
      _selectedId == null ? null : _byId[_selectedId!];
  ClassificationNode? get faunaRoot =>
      _faunaRootId == null ? null : _byId[_faunaRootId!];
  ClassificationNode? get floraRoot =>
      _floraRootId == null ? null : _byId[_floraRootId!];
  bool get hasSelection => _selectedId != null;
  ClassificationNode? getNodeById(String id) => _byId[id];
  List<ClassificationNode> getChildrenOf(String id) =>
      List.unmodifiable(_children[id] ?? const <ClassificationNode>[]);
  bool isExpanded(String id) => _expanded.contains(id);
  bool hasChildren(String id) => (_children[id]?.isNotEmpty ?? false);

  ClassificationNode? findRootCategory(String normalizedName) {
    for (final n in _byId.values) {
      if (n.parentId == null &&
          n.rank == ClassificationRank.category.name &&
          n.normalizedName == normalizedName) {
        return n;
      }
    }
    return null;
  }

  List<ClassificationNode> getRootNodes() {
    return _children[_root] ?? const <ClassificationNode>[];
  }

  Future<void> _initialize() async {
    _box = Hive.box<ClassificationNode>('classification_nodes');
    _ready = true;
    await _ensureRootCategories();
    _rebuild();
    notifyListeners();
  }

  Future<void> _ensureRootCategories() async {
    _rebuild();

    // Clean up any extra root categories (keep only Fauna and Flora)
    final validRoots = {'fauna', 'flora'};
    final existingRoots = _byId.values
        .where(
          (n) =>
              n.parentId == null && n.rank == ClassificationRank.category.name,
        )
        .toList();

    for (final root in existingRoots) {
      if (!validRoots.contains(root.normalizedName)) {
        // Delete any root that isn't Fauna or Flora
        await deleteNode(root.id);
      }
    }

    // Ensure Fauna exists
    if (findRootCategory('fauna') == null) {
      await _addNode(
        name: 'Fauna',
        rank: ClassificationRank.category,
        parentId: null,
        colorValue: 0xFF22C55E,
        iconKey: 'paw',
      );
    }

    // Ensure Flora exists
    if (findRootCategory('flora') == null) {
      await _addNode(
        name: 'Flora',
        rank: ClassificationRank.category,
        parentId: null,
        colorValue: 0xFF84CC16,
        iconKey: 'leaf',
      );
    }
  }

  void _rebuild() {
    _byId.clear();
    _keys.clear();
    _children.clear();
    _faunaRootId = null;
    _floraRootId = null;
    for (final key in _box.keys) {
      final n = _box.get(key);
      if (n == null || n.projectId != _projectId) continue;
      _byId[n.id] = n;
      if (key is int) _keys[n.id] = key;
      (_children[n.parentId ?? _root] ??= <ClassificationNode>[]).add(n);
      if (n.parentId == null && n.rank == ClassificationRank.category.name) {
        if (n.normalizedName == 'fauna') _faunaRootId = n.id;
        if (n.normalizedName == 'flora') _floraRootId = n.id;
      }
    }
    for (final list in _children.values) {
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
  }

  Future<ClassificationNode> createRootCategory(String name) async {
    final existing = findRootCategory(ClassificationNode.normalizeName(name));
    if (existing != null) return existing;
    final node = await _addNode(
      name: name,
      rank: ClassificationRank.category,
      parentId: null,
    );
    _selectedId = node.id;
    notifyListeners();
    return node;
  }

  Future<ClassificationNode> createChildNode({
    required String parentId,
    required String name,
  }) async {
    final parent = _byId[parentId];
    if (parent == null) throw StateError('Parent node not found: $parentId');
    final rank = parent.rankEnum.nextRank ?? parent.rankEnum;
    final existing = _findChild(parentId, name, rank);
    if (existing != null) return existing;
    final node = await _addNode(name: name, rank: rank, parentId: parentId);
    _selectedId = node.id;
    _expanded.add(parentId);
    notifyListeners();
    return node;
  }

  Future<ClassificationNode> createClassificationPath(
    List<
      ({
        String rank,
        String name,
        String? iconKey,
        int? colorValue,
        String content,
      })
    >
    path,
  ) async {
    ClassificationNode? parent;
    for (final step in path) {
      final rank = ClassificationRank.fromString(step.rank);
      final name = step.name.trim();
      if (name.isEmpty) continue;

      final existing = (parent == null)
          ? findRootCategory(ClassificationNode.normalizeName(name))
          : _findChild(parent.id, name, rank);

      if (existing != null) {
        parent = existing;
      } else {
        parent = await _addNode(
          name: name,
          rank: rank,
          parentId: parent?.id,
          colorValue: step.colorValue ?? 0xFF6366F1,
          iconKey: step.iconKey ?? 'folder',
        );
      }

      if (parent.parentId != null) {
        _expanded.add(parent.parentId!);
      }
    }

    if (parent == null) {
      throw ArgumentError('No classification names provided');
    }

    _selectedId = parent.id;
    _rebuild();
    notifyListeners();
    return parent;
  }

  Future<ClassificationNode> createNode({
    required String? parentId,
    required String rank,
    required String name,
    int colorValue = 0xFF6366F1,
    String iconKey = 'folder',
  }) async {
    final rankEnum = ClassificationRank.fromString(rank);
    final node = await _addNode(
      name: name,
      rank: rankEnum,
      parentId: parentId,
      colorValue: colorValue,
      iconKey: iconKey,
    );
    _selectedId = node.id;
    if (parentId != null) {
      _expanded.add(parentId);
    }
    notifyListeners();
    return node;
  }

  Future<void> deleteNode(String id) async {
    final node = _byId[id];
    if (node == null) return;

    final toDelete = <String>[id];
    _getDescendants(id, toDelete);

    for (final deleteId in toDelete) {
      final key = _keys[deleteId];
      if (key != null) {
        await _box.delete(key);
      }
      _expanded.remove(deleteId);
      if (_selectedId == deleteId) {
        _selectedId = null;
      }
    }

    _rebuild();
    notifyListeners();
  }

  void _getDescendants(String id, List<String> result) {
    final children = _children[id] ?? const <ClassificationNode>[];
    for (final child in children) {
      result.add(child.id);
      _getDescendants(child.id, result);
    }
  }

  String? getValidChildRank(String rank) {
    try {
      final current = ClassificationRank.fromString(rank);
      return current.nextRank?.name;
    } catch (_) {
      return null;
    }
  }

  List<ClassificationNode> getClassificationPath(String nodeId) {
    final path = <ClassificationNode>[];
    String? currentId = nodeId;
    while (currentId != null) {
      final node = _byId[currentId];
      if (node == null) break;
      path.insert(0, node);
      currentId = node.parentId;
    }
    return path;
  }

  ClassificationNode? tryFindExistingChild(
    String parentId,
    String rank,
    String normalizedName,
  ) {
    try {
      final rankEnum = ClassificationRank.fromString(rank);
      for (final child in _children[parentId] ?? const <ClassificationNode>[]) {
        if (child.rank == rankEnum.name &&
            child.normalizedName == normalizedName) {
          return child;
        }
      }
    } catch (_) {}
    return null;
  }

  List<ClassificationNode> getChildrenOfRank(String parentId, String rank) {
    return (_children[parentId] ?? const <ClassificationNode>[])
        .where((child) => child.rank == rank)
        .toList();
  }

  List<SpeciesNodeEntry> getVisibleNodes({String? filter}) {
    final query = filter?.trim().toLowerCase();
    if (query != null && query.isNotEmpty) {
      final results = <SpeciesNodeEntry>[];
      for (final node in _byId.values) {
        if (node.name.toLowerCase().contains(query)) {
          int level = 0;
          var curr = node;
          while (curr.parentId != null) {
            final parent = _byId[curr.parentId!];
            if (parent == null) break;
            level++;
            curr = parent;
          }
          results.add(SpeciesNodeEntry(node, level));
        }
      }
      return results;
    }

    final list = <SpeciesNodeEntry>[];
    final roots = _children[_root] ?? const <ClassificationNode>[];
    for (final root in roots) {
      _traverseVisible(root, 0, list);
    }
    return list;
  }

  void _traverseVisible(
    ClassificationNode node,
    int level,
    List<SpeciesNodeEntry> list,
  ) {
    list.add(SpeciesNodeEntry(node, level));
    if (_expanded.contains(node.id)) {
      final children = _children[node.id] ?? const <ClassificationNode>[];
      for (final child in children) {
        _traverseVisible(child, level + 1, list);
      }
    }
  }

  ClassificationNode? _findChild(
    String parentId,
    String name,
    ClassificationRank rank,
  ) {
    final normalized = ClassificationNode.normalizeName(name);
    for (final child in _children[parentId] ?? const <ClassificationNode>[]) {
      if (child.rank == rank.name && child.normalizedName == normalized) {
        return child;
      }
    }
    return null;
  }

  Future<ClassificationNode> _addNode({
    required String name,
    required ClassificationRank rank,
    required String? parentId,
    int colorValue = 0xFF6366F1,
    String iconKey = 'folder',
  }) async {
    final node = ClassificationNode(
      id: _uuid.v4(),
      projectId: _projectId,
      parentId: parentId,
      rank: rank.name,
      name: name.trim(),
      normalizedName: ClassificationNode.normalizeName(name),
      colorValue: colorValue,
      iconKey: iconKey,
    );
    final key = await _box.add(node);
    _keys[node.id] = key;
    _rebuild();
    return node;
  }

  void selectNode(String id) {
    if (_byId.containsKey(id)) {
      _selectedId = id;
      notifyListeners();
    }
  }

  void toggleExpanded(String id) {
    if (!_expanded.add(id)) _expanded.remove(id);
    notifyListeners();
  }

  Future<void> updateNodeContent(String id, String content) async {
    final node = _byId[id];
    final key = _keys[id];
    if (node == null || key == null) return;
    node.content = content;
    node.updateTimestamp();
    await _box.put(key, node);
    _rebuild();
    notifyListeners();
  }

  /// Persists the full species article details edited via the edit dialog.
  ///
  /// Updates every field displayed in the wiki article so the UI and the
  /// Hive box stay in sync after a single save operation.
  Future<void> updateNodeDetails(
    String id, {
    String? name,
    String? scientificName,
    String? status,
    String? origin,
    String? description,
    String? physiology,
    String? averageLifespan,
    String? averageHeight,
    String? reproduction,
    String? diet,
    String? sentience,
    String? population,
  }) async {
    final node = _byId[id];
    final key = _keys[id];
    if (node == null || key == null) return;

    if (name != null && name.trim().isNotEmpty) {
      node.name = name.trim();
      node.normalizedName = ClassificationNode.normalizeName(name);
    }
    node.scientificName = scientificName?.trim().isEmpty ?? true
        ? null
        : scientificName!.trim();
    node.status = (status?.trim().isEmpty ?? true) ? 'Extant' : status!.trim();
    node.origin = origin?.trim().isEmpty ?? true ? null : origin!.trim();
    if (description != null) node.content = description.trim();
    if (physiology != null) node.physiology = physiology.trim();
    node.averageLifespan = averageLifespan?.trim() ?? '';
    node.averageHeight = averageHeight?.trim() ?? '';
    node.reproduction = reproduction?.trim() ?? '';
    node.diet = diet?.trim() ?? '';
    node.sentience = sentience?.trim() ?? '';
    node.population = population?.trim().isEmpty ?? true
        ? null
        : population!.trim();

    node.updateTimestamp();
    await _box.put(key, node);
    _rebuild();
    notifyListeners();
  }

  @override
  void dispose() {
    _byId.clear();
    _keys.clear();
    _children.clear();
    _expanded.clear();
    super.dispose();
  }
}
