import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lore_keeper/models/timeline_event.dart';
import 'package:uuid/uuid.dart';

class TimelineEventProvider extends ChangeNotifier {
  final int _projectId;
  final Uuid _uuid = const Uuid();

  late Box<TimelineEvent> _eventBox;
  bool _isInitialized = false;
  List<TimelineEvent> _events = <TimelineEvent>[];

  TimelineEventProvider(this._projectId) {
    _initialize();
  }

  bool get isInitialized => _isInitialized;

  List<TimelineEvent> get events => List<TimelineEvent>.unmodifiable(_events);

  TimelineEvent? getEventById(String id) {
    for (final event in _events) {
      if (event.id == id) {
        return event;
      }
    }
    return null;
  }

  Future<void> _initialize() async {
    if (!Hive.isAdapterRegistered(29)) {
      Hive.registerAdapter(TimelineEventAdapter());
    }

    _eventBox = await Hive.openBox<TimelineEvent>('timeline_events');
    _isInitialized = true;
    _reload();
    notifyListeners();
  }

  void _reload() {
    _events = _eventBox.values
        .where((event) => event.projectId == _projectId)
        .toList();
    _events.sort((a, b) {
      final yearCmp = a.absoluteYear.compareTo(b.absoluteYear);
      if (yearCmp != 0) return yearCmp;
      return a.absoluteDayOfYear.compareTo(b.absoluteDayOfYear);
    });
  }

  Future<String> createEvent({
    String? name,
    int absoluteYear = 1,
    int absoluteDayOfYear = 1,
    String iconKey = 'star',
    int colorValue = 0xFF6366F1,
    String lore = '',
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
    String? iconKey,
    int? colorValue,
    String? lore,
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
    if (iconKey != null) {
      event.iconKey = iconKey;
    }
    if (colorValue != null) {
      event.colorValue = colorValue;
    }
    if (lore != null) {
      event.lore = lore;
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
    _reload();
    notifyListeners();
  }

  @override
  void dispose() {
    _eventBox.close();
    super.dispose();
  }
}
