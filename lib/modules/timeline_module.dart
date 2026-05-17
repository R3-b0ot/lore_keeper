import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lore_keeper/models/calendar_node.dart';
import 'package:lore_keeper/models/timeline_event.dart';
import 'package:lore_keeper/providers/calendar_tree_provider.dart';
import 'package:lore_keeper/providers/timeline_event_provider.dart';
import 'package:lore_keeper/theme/app_colors.dart';
import 'package:lore_keeper/widgets/responsive_layout.dart';

enum _ZoomTier { era, year, month, date }

class TimelineModule extends StatefulWidget {
  final CalendarTreeProvider calendarProvider;
  final TimelineEventProvider eventProvider;

  const TimelineModule({
    super.key,
    required this.calendarProvider,
    required this.eventProvider,
  });

  @override
  State<TimelineModule> createState() => _TimelineModuleState();
}

class _TimelineModuleState extends State<TimelineModule> {
  static const List<String> _iconOptions = <String>[
    'festival',
    'holiday',
    'ritual',
    'star',
    'flame',
    'moon',
    'calendar',
    'history',
  ];
  static const List<int> _colorOptions = <int>[
    0xFFF59E0B,
    0xFF06B6D4,
    0xFF6366F1,
    0xFF8B5CF6,
    0xFFF43F5E,
    0xFF10B981,
    0xFFFB923C,
    0xFF94A3B8,
  ];

  final ScrollController _scroll = ScrollController();

  int? _activeSystemKey;
  String? _selectedEventId;
  String _search = '';
  double _zoom = 1.2;

  _ZoomTier get _tier {
    if (_zoom < 0.9) return _ZoomTier.era;
    if (_zoom < 1.5) return _ZoomTier.year;
    if (_zoom < 2.2) return _ZoomTier.month;
    return _ZoomTier.date;
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  int _readInt(
    List<CalendarAttribute> attrs,
    List<String> labels,
    int fallback,
  ) {
    for (final attr in attrs) {
      final l = attr.label.toLowerCase();
      for (final key in labels) {
        if (l.contains(key.toLowerCase())) {
          final m = RegExp(r'-?\d+').firstMatch(attr.value);
          final parsed = m == null ? null : int.tryParse(m.group(0)!);
          if (parsed != null && parsed != 0) return parsed;
        }
      }
    }
    return fallback;
  }

  _AxisData _axis(int systemKey) {
    final provider = widget.calendarProvider;
    final system = provider.getSystemByKey(systemKey);
    final root = provider.getRootNodeForSystem(systemKey);
    final top = provider.getTopCalendarNodeForSystem(systemKey);
    if (system == null || root == null || top == null) return _AxisData.empty();

    final rootChildren = provider.getChildrenOf(root.id);
    CalendarNode? erasHeader;
    for (final node in rootChildren) {
      if (node.title.toLowerCase().contains('eras')) erasHeader = node;
    }
    final eras = erasHeader == null
        ? <String>[]
        : provider.getChildrenOf(erasHeader.id).map((e) => e.title).toList();

    final topChildren = provider.getChildrenOf(top.id);
    CalendarNode? monthHeader;
    for (final node in topChildren) {
      if (node.title.toLowerCase().contains('month')) monthHeader = node;
    }
    final monthNodes = monthHeader == null
        ? <CalendarNode>[]
        : provider.getChildrenOf(monthHeader.id);

    final months = <_Month>[];
    var cursor = 1;
    for (final node in monthNodes) {
      final days = _readInt(node.attributes, ['days', 'number of days'], 30);
      final safe = days <= 0 ? 30 : days;
      months.add(_Month(node.title, safe, cursor));
      cursor += safe;
    }
    if (months.isEmpty) {
      const names = [
        'Primus',
        'Secundus',
        'Tertius',
        'Quartus',
        'Quintus',
        'Sextus',
        'Septimus',
        'Octavus',
        'Nonus',
        'Decimus',
        'Undecim',
        'Duodecim',
      ];
      cursor = 1;
      for (final name in names) {
        months.add(_Month(name, 30, cursor));
        cursor += 30;
      }
    }

    var total = _readInt(top.attributes, [
      'total cycle',
      'total days',
      'days/year',
    ], 0);
    if (total <= 0) total = months.fold(0, (sum, m) => sum + m.days);
    if (total <= 0) total = 360;
    return _AxisData(system.name, top.title, eras, months, total);
  }

  _RelDate _dateFor(
    TimelineEvent event,
    _AxisData axis,
    List<TimelineEvent> events,
  ) {
    final total = math.max(1, axis.totalDays);
    final day = ((((event.absoluteDayOfYear - 1) % total) + total) % total) + 1;

    var rem = day;
    var monthIdx = 0;
    for (int i = 0; i < axis.months.length; i++) {
      if (rem <= axis.months[i].days) {
        monthIdx = i;
        break;
      }
      rem -= axis.months[i].days;
    }

    final eraIdx = _eraIndex(event.absoluteYear, axis.eras, events);
    final eraName = axis.eras.isEmpty ? 'Era' : axis.eras[eraIdx];
    return _RelDate(event.absoluteYear, day, monthIdx, rem, eraIdx, eraName);
  }

  int _eraIndex(int year, List<String> eras, List<TimelineEvent> events) {
    if (eras.length <= 1) return 0;
    final years = events.map((e) => e.absoluteYear).toList()
      ..add(year)
      ..sort();
    final span = math.max(
      1,
      ((years.last - years.first + 1) / eras.length).ceil(),
    );
    return (((year - years.first) / span).floor()).clamp(0, eras.length - 1);
  }

  IconData _icon(String key) {
    switch (key) {
      case 'festival':
        return LucideIcons.partyPopper;
      case 'holiday':
        return LucideIcons.wine;
      case 'ritual':
        return LucideIcons.tent;
      case 'flame':
        return LucideIcons.sun;
      case 'moon':
        return LucideIcons.moon;
      case 'calendar':
        return LucideIcons.calendar;
      case 'history':
        return LucideIcons.history;
      default:
        return LucideIcons.sparkles;
    }
  }

  List<TimelineEvent> _events() {
    final q = _search.trim().toLowerCase();
    final all = widget.eventProvider.events;
    if (q.isEmpty) return all;
    return all
        .where(
          (e) =>
              e.name.toLowerCase().contains(q) ||
              e.lore.toLowerCase().contains(q),
        )
        .toList();
  }

  String _label(_RelDate d, _AxisData axis) {
    final monthName = axis.months.isEmpty
        ? 'Month'
        : axis.months[d.monthIdx].name;
    return '${d.eraName}  Year ${d.year}  $monthName ${d.dayInMonth}';
  }

  double _dayPx() => 3.0 * _zoom;

  double _monthPx() => 180.0 * _zoom.clamp(0.8, 2.0);

  double _trackWidth(_AxisData axis, List<TimelineEvent> events) {
    if (events.isEmpty) return 1200;
    switch (_tier) {
      case _ZoomTier.era:
        return (math.max(1, axis.eras.length) * 260.0) + 240.0;
      case _ZoomTier.year:
        final years = events.map((e) => e.absoluteYear).toList()..sort();
        return ((years.last - years.first + 1) *
                (180.0 * _zoom.clamp(0.8, 1.8))) +
            240.0;
      case _ZoomTier.month:
        return (axis.months.length * _monthPx()) + 240.0;
      case _ZoomTier.date:
        return (axis.totalDays * _dayPx()) + 240.0;
    }
  }

  double _x(
    TimelineEvent event,
    _AxisData axis,
    List<TimelineEvent> events,
    Map<String, _RelDate> dates,
  ) {
    const left = 120.0;
    final d = dates[event.id]!;
    switch (_tier) {
      case _ZoomTier.era:
        return left + (d.eraIdx * 260.0) + 130.0;
      case _ZoomTier.year:
        final years = events.map((e) => e.absoluteYear).toList()..sort();
        final minYear = years.first;
        final yearW = 180.0 * _zoom.clamp(0.8, 1.8);
        return left + ((event.absoluteYear - minYear) * yearW) + (yearW / 2);
      case _ZoomTier.month:
        final monthDays = math.max(1, axis.months[d.monthIdx].days);
        final ratio = (d.dayInMonth - 1) / monthDays;
        return left + (d.monthIdx * _monthPx()) + (ratio * _monthPx());
      case _ZoomTier.date:
        return left + ((d.dayOfYear - 1) * _dayPx());
    }
  }

  Future<void> _createEvent(_AxisData axis) async {
    final id = await widget.eventProvider.createEvent(
      name: 'New Event',
      absoluteYear: 1,
      absoluteDayOfYear: (axis.totalDays / 2).round().clamp(1, axis.totalDays),
      iconKey: 'star',
      colorValue: 0xFF6366F1,
    );
    if (!mounted) return;
    setState(() => _selectedEventId = id);
  }

  Widget _listPane(
    ThemeData theme,
    _AxisData axis,
    List<TimelineEvent> events,
    Map<String, _RelDate> dates,
    List<dynamic> systems,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.7),
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _activeSystemKey,
                  decoration: const InputDecoration(
                    labelText: 'Calendar System',
                    isDense: true,
                  ),
                  items: systems
                      .map(
                        (s) => DropdownMenuItem<int>(
                          value: s.key as int,
                          child: Text(s.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _activeSystemKey = value);
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (value) => setState(() => _search = value),
                        decoration: const InputDecoration(
                          hintText: 'Search events...',
                          prefixIcon: Icon(LucideIcons.search, size: 16),
                          isDense: true,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _createEvent(axis),
                      icon: const Icon(LucideIcons.plus),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: events.isEmpty
                ? Center(
                    child: Text(
                      'No events yet.',
                      style: theme.textTheme.bodySmall,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                    itemCount: events.length,
                    itemBuilder: (context, i) {
                      final e = events[i];
                      final d = dates[e.id]!;
                      final selected = e.id == _selectedEventId;
                      final color = Color(e.colorValue);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: InkWell(
                          onTap: () => setState(() => _selectedEventId = e.id),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: selected
                                  ? theme.colorScheme.primaryContainer
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _icon(e.iconKey),
                                    size: 14,
                                    color: color,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        e.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        _label(d, axis),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.labelSmall,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    LucideIcons.trash2,
                                    size: 16,
                                  ),
                                  onPressed: () async {
                                    final wasSelected =
                                        _selectedEventId == e.id;
                                    await widget.eventProvider.deleteEvent(
                                      e.id,
                                    );
                                    if (!mounted) return;
                                    if (wasSelected) {
                                      setState(() => _selectedEventId = null);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _panel(
    ThemeData theme,
    _AxisData axis,
    List<TimelineEvent> events,
    Map<String, _RelDate> dates,
    TimelineEvent? selected,
  ) {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: selected == null
                ? Center(
                    child: Text(
                      'Select an event to edit.',
                      style: theme.textTheme.bodySmall,
                    ),
                  )
                : _editor(theme, axis, selected, dates[selected.id]!),
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.3,
                  ),
                ),
              ),
              color: theme.colorScheme.surface.withValues(alpha: 0.25),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('Mode: ${_tier.name.toUpperCase()}'),
                      const Icon(LucideIcons.zoomOut, size: 14),
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 120,
                          maxWidth: 180,
                        ),
                        child: Slider(
                          value: _zoom,
                          min: 0.5,
                          max: 3.0,
                          divisions: 25,
                          onChanged: (value) => setState(() => _zoom = value),
                        ),
                      ),
                      const Icon(LucideIcons.zoomIn, size: 14),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scroll,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: _trackWidth(axis, events),
                      child: _track(theme, axis, events, dates),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _editor(ThemeData theme, _AxisData axis, TimelineEvent e, _RelDate d) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          e.name,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${axis.systemName}  ${axis.calendarName}',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(_label(d, axis), style: theme.textTheme.bodySmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: math.min(240, MediaQuery.sizeOf(context).width - 48),
              child: TextFormField(
                key: ValueKey('ev-name-${e.id}-${e.updatedAt}'),
                initialValue: e.name,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  isDense: true,
                ),
                onChanged: (value) =>
                    widget.eventProvider.updateEvent(e.id, name: value),
              ),
            ),
            SizedBox(
              width: math.min(120, MediaQuery.sizeOf(context).width - 48),
              child: TextFormField(
                key: ValueKey('ev-year-${e.id}-${e.updatedAt}'),
                initialValue: '${e.absoluteYear}',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Year',
                  isDense: true,
                ),
                onChanged: (value) {
                  final n = int.tryParse(value);
                  if (n != null) {
                    widget.eventProvider.updateEvent(e.id, absoluteYear: n);
                  }
                },
              ),
            ),
            SizedBox(
              width: math.min(140, MediaQuery.sizeOf(context).width - 48),
              child: TextFormField(
                key: ValueKey('ev-day-${e.id}-${e.updatedAt}'),
                initialValue: '${e.absoluteDayOfYear}',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Day Of Year',
                  isDense: true,
                ),
                onChanged: (value) {
                  final n = int.tryParse(value);
                  if (n != null) {
                    widget.eventProvider.updateEvent(
                      e.id,
                      absoluteDayOfYear: n,
                    );
                  }
                },
              ),
            ),
            SizedBox(
              width: math.min(170, MediaQuery.sizeOf(context).width - 48),
              child: DropdownButtonFormField<String>(
                initialValue: _iconOptions.contains(e.iconKey)
                    ? e.iconKey
                    : _iconOptions.first,
                decoration: const InputDecoration(
                  labelText: 'Icon',
                  isDense: true,
                ),
                items: _iconOptions
                    .map(
                      (iconKey) => DropdownMenuItem<String>(
                        value: iconKey,
                        child: Row(
                          children: [
                            Icon(_icon(iconKey), size: 16),
                            const SizedBox(width: 8),
                            Text(iconKey),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  widget.eventProvider.updateEvent(e.id, iconKey: value);
                },
              ),
            ),
            SizedBox(
              width: math.min(180, MediaQuery.sizeOf(context).width - 48),
              child: DropdownButtonFormField<int>(
                initialValue: _colorOptions.contains(e.colorValue)
                    ? e.colorValue
                    : _colorOptions.first,
                decoration: const InputDecoration(
                  labelText: 'Color',
                  isDense: true,
                ),
                items: _colorOptions
                    .map(
                      (value) => DropdownMenuItem<int>(
                        value: value,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Color(value),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('#${value.toRadixString(16).toUpperCase()}'),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  widget.eventProvider.updateEvent(e.id, colorValue: value);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: TextFormField(
            key: ValueKey('ev-lore-${e.id}-${e.updatedAt}'),
            initialValue: e.lore,
            expands: true,
            minLines: null,
            maxLines: null,
            decoration: const InputDecoration(
              hintText: 'Write event lore here...',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) =>
                widget.eventProvider.updateEvent(e.id, lore: value),
          ),
        ),
      ],
    );
  }

  Widget _track(
    ThemeData theme,
    _AxisData axis,
    List<TimelineEvent> events,
    Map<String, _RelDate> dates,
  ) {
    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 110,
          child: Container(
            height: 2,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
          ),
        ),
        if (_tier == _ZoomTier.era)
          Row(
            children: [
              const SizedBox(width: 120),
              ...(axis.eras.isEmpty ? ['Era'] : axis.eras).map(
                (era) => Container(
                  width: 260,
                  padding: const EdgeInsets.only(left: 10, bottom: 18),
                  alignment: Alignment.bottomLeft,
                  child: Text(era, style: theme.textTheme.labelLarge),
                ),
              ),
            ],
          ),
        if (_tier == _ZoomTier.month || _tier == _ZoomTier.date)
          Row(
            children: [
              const SizedBox(width: 120),
              ...axis.months.map(
                (m) => Container(
                  width: _tier == _ZoomTier.month
                      ? _monthPx()
                      : (m.days * _dayPx()),
                  padding: const EdgeInsets.only(left: 10, bottom: 18),
                  alignment: Alignment.bottomLeft,
                  child: Text(m.name, style: theme.textTheme.labelLarge),
                ),
              ),
            ],
          ),
        ...events.map((e) {
          final x = _x(e, axis, events, dates);
          final active = _selectedEventId == e.id;
          final color = Color(e.colorValue);
          return Positioned(
            left: x - 18,
            top: 76,
            child: GestureDetector(
              onTap: () => setState(() => _selectedEventId = e.id),
              child: Column(
                children: [
                  Container(
                    width: active ? 42 : 36,
                    height: active ? 42 : 36,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: active
                            ? color
                            : theme.colorScheme.outlineVariant,
                        width: active ? 2 : 1,
                      ),
                    ),
                    child: Icon(_icon(e.iconKey), color: color),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 120),
                    child: Text(
                      e.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.calendarProvider,
        widget.eventProvider,
      ]),
      builder: (context, _) {
        if (!widget.calendarProvider.isInitialized ||
            !widget.eventProvider.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        final systems = widget.calendarProvider.systems
            .where((s) => s.isConfigured)
            .toList();
        if (systems.isEmpty) {
          return const Center(child: Text('No configured calendar systems.'));
        }
        final keys = systems.map((s) => s.key as int).toSet();
        _activeSystemKey =
            (_activeSystemKey != null && keys.contains(_activeSystemKey))
            ? _activeSystemKey
            : systems.first.key as int;

        final axis = _axis(_activeSystemKey!);
        final events = _events();
        if (events.isNotEmpty && !events.any((e) => e.id == _selectedEventId)) {
          _selectedEventId = events.first.id;
        }
        TimelineEvent? selected;
        for (final event in events) {
          if (event.id == _selectedEventId) {
            selected = event;
            break;
          }
        }

        final dates = <String, _RelDate>{
          for (final e in events) e.id: _dateFor(e, axis, events),
        };

        return Container(
          color: theme.brightness == Brightness.dark
              ? AppColors.bgMain
              : AppColors.bgMainLight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < AppBreakpoints.medium) {
                return Column(
                  children: [
                    SizedBox(
                      height: 260,
                      child: _listPane(theme, axis, events, dates, systems),
                    ),
                    Expanded(
                      child: _panel(theme, axis, events, dates, selected),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  SizedBox(
                    width: constraints.maxWidth < AppBreakpoints.wide
                        ? 280
                        : 340,
                    child: _listPane(theme, axis, events, dates, systems),
                  ),
                  Expanded(child: _panel(theme, axis, events, dates, selected)),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _AxisData {
  final String systemName;
  final String calendarName;
  final List<String> eras;
  final List<_Month> months;
  final int totalDays;
  const _AxisData(
    this.systemName,
    this.calendarName,
    this.eras,
    this.months,
    this.totalDays,
  );
  factory _AxisData.empty() => const _AxisData('', '', [], [], 360);
}

class _Month {
  final String name;
  final int days;
  final int start;
  const _Month(this.name, this.days, this.start);
}

class _RelDate {
  final int year;
  final int dayOfYear;
  final int monthIdx;
  final int dayInMonth;
  final int eraIdx;
  final String eraName;
  const _RelDate(
    this.year,
    this.dayOfYear,
    this.monthIdx,
    this.dayInMonth,
    this.eraIdx,
    this.eraName,
  );
}
