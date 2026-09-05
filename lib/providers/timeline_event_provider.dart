import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lore_keeper/database/reference_engine/reference_engine.dart';
import 'package:lore_keeper/models/timeline_event.dart';
import 'package:lore_keeper/services/reference_name_resolver.dart';
import 'package:uuid/uuid.dart';

class TimelineEventProvider extends ChangeNotifier {
  final int _projectId;
  final ReferenceEngine? _referenceEngine;
  final Uuid _uuid = const Uuid();

  late Box<TimelineEvent> _eventBox;
  bool _isInitialized = false;
  List<TimelineEvent> _events = <TimelineEvent>[];

  /// Currently selected calendar system for filtering events in the UI.
  int? _selectedSystemKey;

  /// Currently selected event id shared by the list pane and the canvas so
  /// both surfaces always reflect a single Timeline selection.
  String? _selectedEventId;

  TimelineEventProvider(
    this._projectId, {
    ReferenceEngine? referenceEngine,
  }) : _referenceEngine = referenceEngine {
    _initialize();
  }

  bool get isInitialized => _isInitialized;

  int? get selectedSystemKey => _selectedSystemKey;

  void setSelectedSystemKey(int? systemKey) {
    _selectedSystemKey = systemKey;
    notifyListeners();
  }

  /// The event currently selected in the Timeline UI, or null when nothing
  /// is selected.
  String? get selectedEventId => _selectedEventId;

  /// Selects an event (or clears selection with null) across all Timeline
  /// surfaces listening to this provider.
  void selectEvent(String? eventId) {
    if (_selectedEventId == eventId) return;
    _selectedEventId = eventId;
    notifyListeners();
  }

  List<TimelineEvent> get events => List<TimelineEvent>.unmodifiable(_events);

  /// Returns events filtered by the selected calendar system (if set).
  List<TimelineEvent> get filteredEvents {
    if (_selectedSystemKey == null) return events;
    return _events
        .where((e) => e.calendarSystemKey == _selectedSystemKey)
        .toList();
  }

  TimelineEvent? getEventById(String id) {
    for (final event in _events) {
      if (event.id == id) {
        return event;
      }
    }
    return null;
  }

  Future<void> _initialize() async {
    _eventBox = Hive.box<TimelineEvent>('timeline_events');
    _isInitialized = true;
    _reload();
    notifyListeners();
  }

  void _reload() {
    _events = _eventBox.values
        .where((event) => event.projectId == _projectId)
        .toList();
    _events.sort((a, b) {
      // Sort by calendar system first, then year, then day of year
      final sysCmp = a.calendarSystemKey.compareTo(b.calendarSystemKey);
      if (sysCmp != 0) return sysCmp;
      final yearCmp = a.absoluteYear.compareTo(b.absoluteYear);
      if (yearCmp != 0) return yearCmp;
      return a.absoluteDayOfYear.compareTo(b.absoluteDayOfYear);
    });
  }

  Future<String> createEvent({
    String? name,
    int absoluteYear = 1,
    int absoluteDayOfYear = 1,
    int? endYear,
    int? endDayOfYear,
    String iconKey = 'star',
    int colorValue = 0xFF6366F1,
    String lore = '',
    int? calendarSystemKey,
    int durationDays = 0,
    List<String>? linkedCharacterIds,
    List<String>? linkedLocationIds,
  }) async {
    final event = TimelineEvent(
      id: _uuid.v4(),
      projectId: _projectId,
      name: (name == null || name.trim().isEmpty) ? 'New Event' : name.trim(),
      tier: 'date',
      absoluteYear: absoluteYear,
      absoluteDayOfYear: absoluteDayOfYear,
      iconKey: iconKey,
      colorValue: colorValue,
      lore: lore,
      calendarSystemKey: calendarSystemKey ?? _selectedSystemKey ?? 0,
      durationDays: durationDays,
      endYear: endYear ?? absoluteYear,
      endDayOfYear: endDayOfYear ?? absoluteDayOfYear,
      linkedCharacterIds: linkedCharacterIds,
      linkedLocationIds: linkedLocationIds,
    );
    await _eventBox.add(event);
    _reload();
    notifyListeners();
    return event.id;
  }

  Future<void> updateEvent(
    String eventId, {
    String? name,
    int? absoluteYear,
    int? absoluteDayOfYear,
    int? endYear,
    int? endDayOfYear,
    String? iconKey,
    int? colorValue,
    String? lore,
    int? calendarSystemKey,
    int? durationDays,
    List<String>? linkedCharacterIds,
    List<String>? linkedLocationIds,
  }) async {
    final event = getEventById(eventId);
    if (event == null) return;

    if (name != null) {
      event.name = name;
    }
    if (absoluteYear != null) {
      event.absoluteYear = absoluteYear;
    }
    if (absoluteDayOfYear != null) {
      event.absoluteDayOfYear = absoluteDayOfYear;
    }
    if (endYear != null) {
      event.endYear = endYear;
    }
    if (endDayOfYear != null) {
      event.endDayOfYear = endDayOfYear;
    }
    if (iconKey != null) {
      event.iconKey = iconKey;
    }
    if (colorValue != null) {
      event.colorValue = colorValue;
    }
    if (lore != null) {
      event.lore = lore;
    }
    if (calendarSystemKey != null) {
      event.calendarSystemKey = calendarSystemKey;
    }
    if (durationDays != null) {
      event.durationDays = durationDays;
    }
    if (linkedCharacterIds != null) {
      event.linkedCharacterIds = linkedCharacterIds;
    }
    if (linkedLocationIds != null) {
      event.linkedLocationIds = linkedLocationIds;
    }
    event.updateTimestamp();
    await event.save();
    _reload();
    notifyListeners();
  }

  Future<void> deleteEvent(String eventId) async {
    final event = getEventById(eventId);
    if (event == null) return;
    await event.delete();
    if (_selectedEventId == eventId) {
      _selectedEventId = null;
    }
    _reload();
    // Purge stale manuscript backlinks to the deleted timeline event now that
    // it is gone from the box (see ReferenceNameResolver.purgeStaleFromDatabase).
    final engine = _referenceEngine;
    if (engine != null) {
      ReferenceNameResolver.purgeStaleFromDatabase(engine);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    // The box is opened asynchronously in [_initialize]; only close it when it
    // was actually opened (unconditionally touching a `late` box that never
    // got assigned would throw LateInitializationError if the editor is torn
    // down before the async open completes).
    if (_isInitialized) {
      _eventBox.close();
    }
    super.dispose();
  }
}
