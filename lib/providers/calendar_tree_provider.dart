import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lore_keeper/models/calendar_node.dart';
import 'package:lore_keeper/models/calendar_system.dart';
import 'package:lore_keeper/theme/app_colors.dart';
import 'package:lore_keeper/utils/calendar_type_specs.dart';
import 'package:uuid/uuid.dart';

class CalendarMonthSeed {
  final String name;
  final int days;

  const CalendarMonthSeed({required this.name, required this.days});
}

class CalendarSeasonSeed {
  final String name;
  final String iconKey;
  final int colorValue;
  final int duration;

  const CalendarSeasonSeed({
    required this.name,
    required this.iconKey,
    required this.colorValue,
    required this.duration,
  });
}

class CalendarSystemSeed {
  final String systemName;
  final String worldName;
  final String calendarName;
  final List<String> eras;
  final String yearRegex;
  final int totalDays;
  final String dayNightRatio;
  final List<CalendarMonthSeed> months;
  final List<String> weekDays;
  final String firstDayOfWeek;
  final List<String> weekends;
  final List<CalendarSeasonSeed> seasons;

  const CalendarSystemSeed({
    required this.systemName,
    required this.worldName,
    required this.calendarName,
    required this.eras,
    required this.yearRegex,
    required this.totalDays,
    required this.dayNightRatio,
    required this.months,
    required this.weekDays,
    required this.firstDayOfWeek,
    required this.weekends,
    required this.seasons,
  });
}

class CalendarNodeEntry {
  final CalendarNode node;
  final int level;

  const CalendarNodeEntry(this.node, this.level);
}

class CalendarTreeProvider extends ChangeNotifier {
  static const String _rootParentKey = '__root__';
  static const Set<String> _nonEditableTypes = {'chronos_system'};
  static const Set<String> _terminalNodeTypes = {'era', 'celestial'};

  final int _projectId;
  final Uuid _uuid = const Uuid();
  late Box<CalendarSystem> _systemBox;
  late Box<CalendarNode> _nodeBox;

  bool _isInitialized = false;
  int? _selectedSystemKey;
  String? _selectedNodeId;
  final Set<String> _expandedNodeIds = <String>{};

  final Map<String, CalendarNode> _nodesById = <String, CalendarNode>{};
  final Map<String, int> _nodeHiveKeyById = <String, int>{};
  final Map<String, List<CalendarNode>> _childrenByParent =
      <String, List<CalendarNode>>{};

  CalendarTreeProvider(this._projectId) {
    _initialize();
  }

  bool get isInitialized => _isInitialized;

  List<CalendarSystem> get systems {
    if (!_isInitialized) return [];
    final available = _systemBox.values
        .where((system) => system.projectId == _projectId)
        .toList();
    available.sort((a, b) => a.name.compareTo(b.name));
    return available;
  }

  CalendarSystem? get selectedSystem {
    if (_selectedSystemKey == null) return null;
    return _systemBox.get(_selectedSystemKey);
  }

  CalendarSystem? getSystemByKey(int key) => _systemBox.get(key);

  CalendarNode? get selectedNode {
    if (_selectedNodeId == null) return null;
    return _nodesById[_selectedNodeId!];
  }

  CalendarNode? getNodeById(String nodeId) => _nodesById[nodeId];

  CalendarNode? getRootNodeForSystem(int systemKey) {
    final system = _systemBox.get(systemKey);
    if (system == null) return null;
    return _nodesById[system.rootNodeId];
  }

  List<CalendarNode> getChildrenOf(String parentId) =>
      List<CalendarNode>.unmodifiable(_getChildren(parentId));

  CalendarNode? getTopCalendarNodeForSystem(int systemKey) {
    final root = getRootNodeForSystem(systemKey);
    if (root == null) return null;
    final rootChildren = _getChildren(root.id);
    for (final child in rootChildren) {
      if (child.type == 'calendar') {
        return child;
      }
      if (_isActiveCalendarsWrapper(child)) {
        final nestedChildren = _getChildren(child.id);
        for (final nested in nestedChildren) {
          if (nested.type == 'calendar') {
            return nested;
          }
        }
      }
    }
    return null;
  }

  bool get canDeleteSelectedSystem => systems.length > 1;

  bool get hasSelection => selectedSystem != null;

  bool isExpanded(String nodeId) => _expandedNodeIds.contains(nodeId);

  bool hasChildren(String nodeId) =>
      (_childrenByParent[nodeId]?.isNotEmpty ?? false);

  bool _isActiveCalendarsWrapper(CalendarNode node) =>
      node.type == 'category' &&
      node.title.trim().toLowerCase() == 'active calendars';

  String? _topCalendarNodeId() {
    final system = selectedSystem;
    if (system == null) return null;
    final rootChildren = _getChildren(system.rootNodeId);
    for (final child in rootChildren) {
      if (child.type == 'calendar') {
        return child.id;
      }
      if (_isActiveCalendarsWrapper(child)) {
        for (final nested in _getChildren(child.id)) {
          if (nested.type == 'calendar') return nested.id;
        }
      }
    }
    return null;
  }

  bool _isTopCalendarNode(String nodeId) => _topCalendarNodeId() == nodeId;

  bool _isPrefabCalendarChild(String nodeId) {
    final node = _nodesById[nodeId];
    if (node == null) return false;
    final topCalendarId = _topCalendarNodeId();
    if (topCalendarId == null) return false;
    return node.parentId == topCalendarId;
  }

  bool isTopLevelEntityNode(String nodeId) {
    final node = _nodesById[nodeId];
    final system = selectedSystem;
    if (node == null || system == null) return false;
    return node.parentId == system.rootNodeId;
  }

  bool canSelectNode(String nodeId) {
    final node = _nodesById[nodeId];
    if (node == null) return false;
    if (_isActiveCalendarsWrapper(node)) return false;
    if (_nonEditableTypes.contains(node.type)) return false;
    if (_isPrefabCalendarChild(nodeId)) return false;
    return true;
  }

  bool canDeleteNode(String nodeId) {
    final node = _nodesById[nodeId];
    final system = selectedSystem;
    if (node == null || system == null) return false;
    if (node.id == system.rootNodeId) return false;
    if (_isActiveCalendarsWrapper(node)) return false;
    if (_isTopCalendarNode(nodeId)) return false;
    if (_isPrefabCalendarChild(nodeId)) return false;
    return true;
  }

  bool canAddChildToNode(String nodeId) {
    final node = _nodesById[nodeId];
    if (node == null) return false;
    final system = selectedSystem;
    if (system != null && node.id == system.rootNodeId) return false;
    if (_isActiveCalendarsWrapper(node)) return false;
    if (_isTopCalendarNode(nodeId)) return false;
    return !_terminalNodeTypes.contains(node.type);
  }

  List<CalendarNodeEntry> getVisibleNodes({String filter = ''}) {
    final system = selectedSystem;
    if (system == null) return [];

    final normalizedFilter = filter.trim().toLowerCase();
    if (normalizedFilter.isNotEmpty) {
      final matches =
          _nodesById.values
              .where(
                (node) =>
                    node.systemKey == system.key &&
                    node.type != 'chronos_system' &&
                    !_isActiveCalendarsWrapper(node) &&
                    node.title.toLowerCase().contains(normalizedFilter),
              )
              .toList()
            ..sort((a, b) => a.title.compareTo(b.title));
      return matches.map((node) => CalendarNodeEntry(node, 0)).toList();
    }

    final List<CalendarNodeEntry> result = [];

    void visit(String nodeId, int level) {
      final node = _nodesById[nodeId];
      if (node == null) return;
      final isRoot =
          node.id == system.rootNodeId && node.type == 'chronos_system';
      final isActiveCalendars = _isActiveCalendarsWrapper(node);

      if (!isRoot && !isActiveCalendars) {
        result.add(CalendarNodeEntry(node, level));
      }

      if (isRoot || isActiveCalendars || _expandedNodeIds.contains(nodeId)) {
        for (final child in _getChildren(nodeId)) {
          final keepLevel = isRoot || isActiveCalendars;
          visit(child.id, keepLevel ? level : level + 1);
        }
      }
    }

    visit(system.rootNodeId, 0);
    return result;
  }

  String inferChildType(CalendarNode parent) {
    final title = parent.title.toLowerCase();
    if (title.contains('calendar')) return 'calendar';
    if (title.contains('month')) return 'month';
    if (title.contains('week') || title.contains('cycle')) return 'day';
    if (title.contains('era')) return 'era';
    if (title.contains('holiday') || title.contains('festival')) {
      return 'holiday';
    }
    if (title.contains('cosmic') || title.contains('cosmos')) {
      return 'celestial';
    }

    if (parent.type == 'calendar') return 'category';
    if (parent.type == 'category') return 'category';
    return 'category';
  }

  Future<void> _initialize() async {
    _systemBox = Hive.box<CalendarSystem>('calendar_systems');
    _nodeBox = Hive.box<CalendarNode>('calendar_nodes');

    _isInitialized = true;
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

    await createSystem('New Chronology');
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
      _childrenByParent
          .putIfAbsent(parentKey, () => <CalendarNode>[])
          .add(node);
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

  List<CalendarNode> _getChildren(String parentId) {
    final children = _childrenByParent[parentId] ?? <CalendarNode>[];
    final parent = _nodesById[parentId];
    if (parent == null || parent.childrenOrder.isEmpty) {
      return children;
    }

    final orderIndex = <String, int>{};
    for (int i = 0; i < parent.childrenOrder.length; i++) {
      orderIndex[parent.childrenOrder[i]] = i;
    }

    final sorted = List<CalendarNode>.from(children);
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
    if (canSelectNode(node.id)) return nodeId;
    final fallbackRoot = rootId ?? node.id;
    return _findFirstSelectableDescendant(node.id) ??
        _findFirstSelectableDescendant(fallbackRoot) ??
        nodeId;
  }

  String? _findFirstSelectableDescendant(String nodeId) {
    for (final child in _getChildren(nodeId)) {
      if (canSelectNode(child.id)) return child.id;
      final nested = _findFirstSelectableDescendant(child.id);
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
    if (!canSelectNode(nodeId)) {
      return;
    }
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
    final safeName = name.trim().isEmpty ? 'New Chronology' : name.trim();
    final system = CalendarSystem(
      name: safeName,
      projectId: _projectId,
      rootNodeId: rootId,
      lastSelectedNodeId: rootId,
      isConfigured: false,
    );

    final systemKey = await _systemBox.add(system);
    final rootNode = CalendarNode(
      id: rootId,
      systemKey: systemKey,
      parentId: null,
      type: 'chronos_system',
      title: safeName,
      iconKey: 'clock',
      colorValue: AppColors.warning.toARGB32(),
      content: '',
      attributes: calendarSpecForType('chronos_system').defaultAttributes(),
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

  Future<void> configureSystem(int systemKey, CalendarSystemSeed seed) async {
    final system = _systemBox.get(systemKey);
    if (system == null) return;

    await _deleteNodesForSystem(systemKey, keepRootId: system.rootNodeId);

    CalendarNode rootNode =
        _nodesById[system.rootNodeId] ??
        CalendarNode(
          id: system.rootNodeId,
          systemKey: systemKey,
          parentId: null,
          type: 'chronos_system',
          title: seed.systemName,
          iconKey: 'clock',
          colorValue: AppColors.warning.toARGB32(),
          content: '',
          attributes: calendarSpecForType('chronos_system').defaultAttributes(),
          childrenOrder: <String>[],
        );

    rootNode
      ..title = seed.systemName
      ..type = 'chronos_system'
      ..iconKey = 'clock'
      ..content = 'The master temporal tapestry of ${seed.worldName}.'
      ..attributes = [
        CalendarAttribute(label: 'Total Days/Year', value: '${seed.totalDays}'),
        CalendarAttribute(label: 'Day/Night Split', value: seed.dayNightRatio),
      ]
      ..childrenOrder = <String>[];
    rootNode.updateTimestamp();
    await _upsertNode(rootNode);

    _rebuildCaches();
    rootNode = _nodesById[system.rootNodeId] ?? rootNode;

    final erasCategory = await _createChildNode(
      parentId: rootNode.id,
      systemKey: systemKey,
      type: 'category',
      title: 'Eras of Time',
      iconKey: 'history',
      colorValue: const Color(0xFFF59E0B).toARGB32(),
    );

    for (final era in seed.eras.where((e) => e.trim().isNotEmpty)) {
      await _createChildNode(
        parentId: erasCategory.id,
        systemKey: systemKey,
        type: 'era',
        title: era.trim(),
        iconKey: 'milestone',
        colorValue: const Color(0xFFF59E0B).toARGB32(),
      );
    }

    final mainCalendar = await _createChildNode(
      parentId: rootNode.id,
      systemKey: systemKey,
      type: 'calendar',
      title: seed.calendarName.trim().isEmpty
          ? 'Main Calendar'
          : seed.calendarName.trim(),
      iconKey: 'calendar',
      colorValue: const Color(0xFF8B5CF6).toARGB32(),
      attributes: [
        CalendarAttribute(label: 'Year Regex', value: seed.yearRegex),
        CalendarAttribute(
          label: 'Total Cycle',
          value: '${seed.totalDays} Days',
        ),
        CalendarAttribute(label: 'First Day', value: seed.firstDayOfWeek),
        CalendarAttribute(
          label: 'Weekend Days',
          value: seed.weekends.isEmpty ? 'None' : seed.weekends.join(', '),
        ),
      ],
    );

    final monthsCategory = await _createChildNode(
      parentId: mainCalendar.id,
      systemKey: systemKey,
      type: 'category',
      title: 'Months',
      iconKey: 'moon',
      colorValue: const Color(0xFFA78BFA).toARGB32(),
    );

    for (final month in seed.months) {
      await _createChildNode(
        parentId: monthsCategory.id,
        systemKey: systemKey,
        type: 'month',
        title: month.name.trim().isEmpty ? 'Month' : month.name.trim(),
        iconKey: 'moon',
        colorValue: const Color(0xFFC084FC).toARGB32(),
        attributes: [CalendarAttribute(label: 'Days', value: '${month.days}')],
      );
    }

    final weeksCategory = await _createChildNode(
      parentId: mainCalendar.id,
      systemKey: systemKey,
      type: 'category',
      title: 'Weekly Cycle',
      iconKey: 'scroll',
      colorValue: const Color(0xFFA78BFA).toARGB32(),
    );

    for (final weekDay in seed.weekDays) {
      final isWeekend = seed.weekends.contains(weekDay);
      await _createChildNode(
        parentId: weeksCategory.id,
        systemKey: systemKey,
        type: 'day',
        title: weekDay,
        iconKey: 'day',
        colorValue:
            (isWeekend ? const Color(0xFFF43F5E) : const Color(0xFF6366F1))
                .toARGB32(),
        attributes: [
          ...calendarSpecForType('day').defaultAttributes(),
          CalendarAttribute(
            label: 'Category',
            value: isWeekend ? 'Weekend' : 'Weekday',
          ),
        ],
      );
    }

    final seasonsCategory = await _createChildNode(
      parentId: mainCalendar.id,
      systemKey: systemKey,
      type: 'category',
      title: 'Seasonal Cycles',
      iconKey: 'wind',
      colorValue: const Color(0xFFA78BFA).toARGB32(),
    );

    for (final season in seed.seasons) {
      await _createChildNode(
        parentId: seasonsCategory.id,
        systemKey: systemKey,
        type: 'category',
        title: season.name.trim().isEmpty ? 'Season' : season.name.trim(),
        iconKey: season.iconKey,
        colorValue: season.colorValue,
        attributes: [
          CalendarAttribute(
            label: 'Duration',
            value: '${season.duration} Days',
          ),
        ],
      );
    }

    final holidaysCategory = await _createChildNode(
      parentId: mainCalendar.id,
      systemKey: systemKey,
      type: 'category',
      title: 'Holidays & Festivals',
      iconKey: 'holiday',
      colorValue: const Color(0xFFF59E0B).toARGB32(),
    );

    await _createChildNode(
      parentId: holidaysCategory.id,
      systemKey: systemKey,
      type: 'holiday',
      title: "New Year's Eve",
      iconKey: 'holiday',
      colorValue: const Color(0xFFFBBF24).toARGB32(),
    );

    for (final season in seed.seasons) {
      await _createChildNode(
        parentId: holidaysCategory.id,
        systemKey: systemKey,
        type: 'holiday',
        title: 'The Solstice of ${season.name}',
        iconKey: 'festival',
        colorValue: season.colorValue,
      );
    }

    await _createChildNode(
      parentId: holidaysCategory.id,
      systemKey: systemKey,
      type: 'holiday',
      title: 'Great Harvest Feast',
      iconKey: 'flame',
      colorValue: const Color(0xFFFB923C).toARGB32(),
    );

    final cosmosCategory = await _createChildNode(
      parentId: rootNode.id,
      systemKey: systemKey,
      type: 'category',
      title: 'Cosmic Clockwork',
      iconKey: 'orbit',
      colorValue: const Color(0xFF3B82F6).toARGB32(),
    );

    await _createChildNode(
      parentId: cosmosCategory.id,
      systemKey: systemKey,
      type: 'celestial',
      title: 'Primary Sun',
      iconKey: 'sun',
      colorValue: const Color(0xFFFCD34D).toARGB32(),
    );

    final initialSelection =
        _findFirstSelectableDescendant(mainCalendar.id) ?? mainCalendar.id;

    system
      ..name = seed.systemName
      ..isConfigured = true
      ..lastSelectedNodeId = initialSelection;
    system.updateTimestamp();
    await system.save();

    _selectedSystemKey = systemKey;
    _selectedNodeId = initialSelection;
    _expandedNodeIds
      ..add(rootNode.id)
      ..add(mainCalendar.id)
      ..add(holidaysCategory.id)
      ..add(erasCategory.id);

    _rebuildCaches();
    notifyListeners();
  }

  Future<CalendarNode> _createChildNode({
    required String parentId,
    required int systemKey,
    required String type,
    required String title,
    String? iconKey,
    int? colorValue,
    String content = '',
    List<CalendarAttribute>? attributes,
  }) async {
    final spec = calendarSpecForType(type);
    final node = CalendarNode(
      id: _uuid.v4(),
      systemKey: systemKey,
      parentId: parentId,
      type: type,
      title: title,
      iconKey: iconKey ?? spec.iconKey,
      colorValue: colorValue ?? spec.color.toARGB32(),
      content: content,
      attributes: attributes ?? spec.defaultAttributes(),
      childrenOrder: <String>[],
    );

    await _nodeBox.add(node);

    final parent = _nodesById[parentId] ?? _findNodeInBox(parentId);
    if (parent != null) {
      parent.childrenOrder = [...parent.childrenOrder, node.id];
      parent.updateTimestamp();
      await parent.save();
    }

    return node;
  }

  CalendarNode? _findNodeInBox(String nodeId) {
    for (final node in _nodeBox.values) {
      if (node.id == nodeId) return node;
    }
    return null;
  }

  Future<void> addChildNodeToParent(String parentId, String type) async {
    final system = selectedSystem;
    if (system == null) return;
    if (!canAddChildToNode(parentId)) return;

    final spec = calendarSpecForType(type);
    await _createChildNode(
      parentId: parentId,
      systemKey: system.key as int,
      type: type,
      title: 'New ${spec.label.toLowerCase()}',
      iconKey: spec.iconKey,
      colorValue: spec.color.toARGB32(),
    );

    _expandedNodeIds.add(parentId);
    _rebuildCaches();
    notifyListeners();
  }

  Future<void> deleteNode(String nodeId) async {
    final node = _nodesById[nodeId];
    if (node == null) return;

    if (!canDeleteNode(nodeId)) return;
    final system = selectedSystem;

    final idsToDelete = _collectDescendants(nodeId)..add(nodeId);
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

    _expandedNodeIds.remove(nodeId);
    _rebuildCaches();
    notifyListeners();
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
    node.iconKey = calendarSpecForType(type).iconKey;
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
      CalendarAttribute(label: 'Custom', value: '...'),
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
    node.attributes[index] = CalendarAttribute(
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

    node.attributes = [...node.attributes]..removeAt(index);
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

  Future<void> _upsertNode(CalendarNode node) async {
    final hiveKey = _nodeHiveKeyById[node.id];
    if (hiveKey != null) {
      await node.save();
    } else {
      await _nodeBox.add(node);
    }
  }

  List<CalendarAttribute> _mergeAttributes(
    List<CalendarAttribute> existing,
    String type,
  ) {
    final defaults = calendarSpecForType(type).defaultAttributes();
    final existingKeys = existing.map((attr) => attr.label).toSet();
    final additions = defaults
        .where((attr) => !existingKeys.contains(attr.label))
        .toList();
    return [...existing, ...additions];
  }

  @override
  void dispose() {
    // Boxes are opened asynchronously in [_initialize]; only close the ones
    // that were actually opened (unconditionally touching a `late` box that
    // never got assigned would throw LateInitializationError when the editor
    // is torn down before the async open completes).
    if (_isInitialized) {
      _systemBox.close();
      _nodeBox.close();
    }
    super.dispose();
  }
}
