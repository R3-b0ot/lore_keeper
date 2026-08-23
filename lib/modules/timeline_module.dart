import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lore_keeper/models/timeline_event.dart';
import 'package:lore_keeper/providers/calendar_tree_provider.dart';
import 'package:lore_keeper/providers/timeline_event_provider.dart';
import 'package:lore_keeper/providers/character_list_provider.dart';

import 'package:lore_keeper/theme/app_colors.dart';
import 'package:lore_keeper/utils/calendar_chronology.dart';
import 'package:lore_keeper/widgets/calendar_picker.dart';

enum _ZoomTier { era, year, month, day }

class TimelineModule extends StatefulWidget {
  final CalendarTreeProvider calendarProvider;
  final TimelineEventProvider eventProvider;
  final CharacterListProvider characterProvider;

  const TimelineModule({
    super.key,
    required this.calendarProvider,
    required this.eventProvider,
    required this.characterProvider,
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

  double _zoom = 1.0;

  _ZoomTier get _tier {
    if (_zoom < 0.7) return _ZoomTier.era;
    if (_zoom < 1.3) return _ZoomTier.year;
    if (_zoom < 2.2) return _ZoomTier.month;
    return _ZoomTier.day;
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Builds the active chronology from the calendar tree.
  CalendarChronology _chronology(int systemKey) =>
      CalendarChronology.fromProvider(widget.calendarProvider, systemKey);

  _EventPosition _positionFor(TimelineEvent event, CalendarChronology chronology) {
    final totalDays = math.max(1, chronology.daysInYear);
    final startDay = math.max(1, math.min(totalDays, event.absoluteDayOfYear));
    final endDay = event.endYear == 0 || event.endDayOfYear == 0
        ? startDay
        : math.max(1, math.min(totalDays, event.endDayOfYear));
    final startYear = event.absoluteYear;
    final endYear = event.endYear == 0 ? startYear : event.endYear;

    final startMonthIdx = chronology.monthAtDayOfYear(startDay);
    final startDayInMonth = chronology.dayOfMonthAtDayOfYear(startDay);
    final startEraIdx = chronology.eraAtYear(startYear);

    final endMonthIdx = chronology.monthAtDayOfYear(endDay);
    final endDayInMonth = chronology.dayOfMonthAtDayOfYear(endDay);
    final endEraIdx = chronology.eraAtYear(endYear);

    return _EventPosition(
      startYear: startYear,
      startDayOfYear: startDay,
      startMonthIdx: startMonthIdx < 0 ? 0 : startMonthIdx,
      startDayInMonth: startDayInMonth < 1 ? startDay : startDayInMonth,
      startEraIdx: startEraIdx < 0 ? 0 : startEraIdx,
      endYear: endYear,
      endDayOfYear: endDay,
      endMonthIdx: endMonthIdx < 0 ? 0 : endMonthIdx,
      endDayInMonth: endDayInMonth < 1 ? endDay : endDayInMonth,
      endEraIdx: endEraIdx < 0 ? 0 : endEraIdx,
    );
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

  double _dayPx() => 3.0 * _zoom;
  double _monthPx() => 180.0 * _zoom.clamp(0.8, 2.0);
  double _yearPx() => 180.0 * _zoom.clamp(0.8, 1.8);
  double _eraPx() => 260.0 * _zoom.clamp(0.5, 1.5);

  /// Computes the full track width for the current tier and chronology.
  double _trackWidth(CalendarChronology chronology, List<TimelineEvent> events) {
    switch (_tier) {
      case _ZoomTier.era:
        return math.max(1, chronology.eras.length) * _eraPx() + 240.0;
      case _ZoomTier.year:
        if (events.isEmpty) return 1200;
        final years = events
            .map((e) => e.absoluteYear)
            .followedBy(events.map((e) => e.endYear == 0 ? e.absoluteYear : e.endYear))
            .toList()
          ..sort();
        return ((years.last - years.first + 1) * _yearPx()) + 240.0;
      case _ZoomTier.month:
        return chronology.months.length * _monthPx() + 240.0;
      case _ZoomTier.day:
        return chronology.daysInYear * _dayPx() + 240.0;
    }
  }

  /// X position for a specific day-of-year within the current tier.
  double _xForDay(
    int dayOfYear,
    int year,
    CalendarChronology chronology,
    List<TimelineEvent> events,
  ) {
    const left = 120.0;
    switch (_tier) {
      case _ZoomTier.era:
        final eraIdx = chronology.eraAtYear(year);
        return left + (eraIdx * _eraPx()) + (_eraPx() / 2);
      case _ZoomTier.year:
        final years = events
            .map((e) => e.absoluteYear)
            .followedBy(events.map((e) => e.endYear == 0 ? e.absoluteYear : e.endYear))
            .toList()
          ..sort();
        final minYear = years.first;
        return left + ((year - minYear) * _yearPx()) + ((dayOfYear - 1) / math.max(1, chronology.daysInYear) * _yearPx());
      case _ZoomTier.month:
        final monthIdx = chronology.monthAtDayOfYear(dayOfYear);
        final monthDays = math.max(1, chronology.months[monthIdx].days);
        final dayInMonth = chronology.dayOfMonthAtDayOfYear(dayOfYear);
        final ratio = (dayInMonth - 1) / monthDays;
        return left + (monthIdx * _monthPx()) + (ratio * _monthPx());
      case _ZoomTier.day:
        return left + ((dayOfYear - 1) * _dayPx());
    }
  }

  /// X position for an event's start (or center for instant events).
  double _eventStartX(_EventPosition pos, CalendarChronology chronology, List<TimelineEvent> events) {
    return _xForDay(pos.startDayOfYear, pos.startYear, chronology, events);
  }

  /// X position for an event's end.
  double _eventEndX(_EventPosition pos, CalendarChronology chronology, List<TimelineEvent> events) {
    if (pos.endYear == pos.startYear && pos.endDayOfYear == pos.startDayOfYear) {
      return _eventStartX(pos, chronology, events);
    }
    return _xForDay(pos.endDayOfYear, pos.endYear, chronology, events);
  }

  Widget _panel(
    ThemeData theme,
    CalendarChronology chronology,
    List<TimelineEvent> events,
    Map<String, _EventPosition> positions,
    TimelineEvent? selected,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = _trackWidth(chronology, events);
        final fullWidth = constraints.maxWidth;
        final viewportWidth = math.max(trackWidth, fullWidth);

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
                    : _editor(theme, chronology, selected, positions[selected.id]!),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  color: theme.colorScheme.surface.withValues(alpha: 0.25),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('Mode: ${_tier.name.toUpperCase()}'),
                          const Icon(LucideIcons.zoomOut, size: 14),
                          ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 120, maxWidth: 180),
                            child: Slider(
                              value: _zoom,
                              min: 0.3,
                              max: 3.5,
                              divisions: 32,
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
                          width: viewportWidth,
                          child: _track(theme, chronology, events, positions, viewportWidth),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _editor(ThemeData theme, CalendarChronology chronology, TimelineEvent e, _EventPosition pos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          e.name,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          '${chronology.systemName}  ${chronology.calendarName}',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(_formatRange(pos, chronology), style: theme.textTheme.bodySmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: math.min(240, MediaQuery.sizeOf(context).width - 48),
              child: TextFormField(
                key: ValueKey('ev-name-${e.id}'),
                initialValue: e.name,
                decoration: const InputDecoration(labelText: 'Name', isDense: true),
                onChanged: (value) => widget.eventProvider.updateEvent(e.id, name: value),
              ),
            ),
            DateRangePickerButton(
              chronology: chronology,
              startYear: e.absoluteYear,
              startDayOfYear: e.absoluteDayOfYear,
              endYear: e.endYear == 0 ? e.absoluteYear : e.endYear,
              endDayOfYear: e.endDayOfYear == 0 ? e.absoluteDayOfYear : e.endDayOfYear,
              label: 'Date Range',
              onChanged: (date) {
                widget.eventProvider.updateEvent(
                  e.id,
                  absoluteYear: date.startYear,
                  absoluteDayOfYear: date.startDayOfYear,
                  endYear: date.endYear,
                  endDayOfYear: date.endDayOfYear,
                );
              },
            ),
            SizedBox(
              width: math.min(170, MediaQuery.sizeOf(context).width - 48),
              child: DropdownButtonFormField<String>(
                initialValue: _iconOptions.contains(e.iconKey) ? e.iconKey : _iconOptions.first,
                decoration: const InputDecoration(labelText: 'Icon', isDense: true),
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
                initialValue: _colorOptions.contains(e.colorValue) ? e.colorValue : _colorOptions.first,
                decoration: const InputDecoration(labelText: 'Color', isDense: true),
                items: _colorOptions
                    .map(
                      (value) => DropdownMenuItem<int>(
                        value: value,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(color: Color(value), shape: BoxShape.circle),
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
            key: ValueKey('ev-lore-${e.id}'),
            initialValue: e.lore,
            expands: true,
            minLines: null,
            maxLines: null,
            decoration: const InputDecoration(
              hintText: 'Write event lore here...',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => widget.eventProvider.updateEvent(e.id, lore: value),
          ),
        ),
      ],
    );
  }

  String _formatRange(_EventPosition pos, CalendarChronology chronology) {
    final startLabel = chronology.formatDisplay(pos.startYear, pos.startDayOfYear);
    if (pos.endYear == pos.startYear && pos.endDayOfYear == pos.startDayOfYear) {
      return startLabel;
    }
    final endLabel = chronology.formatDisplay(pos.endYear, pos.endDayOfYear);
    return '$startLabel — $endLabel';
  }

  Widget _track(
    ThemeData theme,
    CalendarChronology chronology,
    List<TimelineEvent> events,
    Map<String, _EventPosition> positions,
    double viewportWidth,
  ) {
    const left = 120.0;

    return Stack(
      children: [
        // Base timeline line
        Positioned(
          left: 0,
          right: 0,
          top: 110,
          child: Container(height: 2, color: theme.colorScheme.onSurface.withValues(alpha: 0.12)),
        ),
        // Era labels
        if (_tier == _ZoomTier.era)
          Row(
            children: [
              const SizedBox(width: left),
              ...chronology.eras.map(
                (era) => Container(
                  width: _eraPx(),
                  padding: const EdgeInsets.only(left: 10, bottom: 18),
                  alignment: Alignment.bottomLeft,
                  child: Text(era, style: theme.textTheme.labelLarge),
                ),
              ),
            ],
          ),
        // Year labels
        if (_tier == _ZoomTier.year)
          Row(
            children: [
              const SizedBox(width: left),
              ..._visibleYears(chronology, events).map(
                (year) => Container(
                  width: _yearPx(),
                  padding: const EdgeInsets.only(left: 10, bottom: 18),
                  alignment: Alignment.bottomLeft,
                  child: Text('$year', style: theme.textTheme.labelLarge),
                ),
              ),
            ],
          ),
        // Month labels
        if (_tier == _ZoomTier.month || _tier == _ZoomTier.day)
          Row(
            children: [
              const SizedBox(width: left),
              ...chronology.months.map(
                (m) => Container(
                  width: _tier == _ZoomTier.month ? _monthPx() : (m.days * _dayPx()),
                  padding: const EdgeInsets.only(left: 10, bottom: 18),
                  alignment: Alignment.bottomLeft,
                  child: Text(m.name, style: theme.textTheme.labelLarge),
                ),
              ),
            ],
          ),
        // Day labels (only in day tier)
        if (_tier == _ZoomTier.day)
          Row(
            children: [
              const SizedBox(width: left),
              ...List.generate(chronology.daysInYear, (i) {
                final day = i + 1;
                return Container(
                  width: _dayPx(),
                  padding: const EdgeInsets.only(left: 2, bottom: 18),
                  alignment: Alignment.bottomCenter,
                  child: Text('$day', style: theme.textTheme.labelSmall?.copyWith(fontSize: 8)),
                );
              }),
            ],
          ),
        // Events as horizontal bars
        ...events.map((e) {
          final pos = positions[e.id]!;
          final startX = _eventStartX(pos, chronology, events);
          final endX = _eventEndX(pos, chronology, events);
          final barWidth = math.max(24.0, endX - startX);
          final active = widget.eventProvider.selectedEventId == e.id;
          final color = Color(e.colorValue);
          final barLeft = math.max(left, startX);

          return Positioned(
            left: barLeft,
            top: 76,
            width: barWidth,
            child: GestureDetector(
              onTap: () => widget.eventProvider.selectEvent(e.id),
              child: Column(
                children: [
                  Container(
                    height: active ? 42 : 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: active ? 0.25 : 0.15),
                      borderRadius: BorderRadius.circular(active ? 12 : 8),
                      border: Border.all(
                        color: active ? color : theme.colorScheme.outlineVariant,
                        width: active ? 2 : 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_icon(e.iconKey), size: active ? 20 : 16, color: color),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            e.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: active ? color : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (active) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatRange(pos, chronology),
                      style: theme.textTheme.labelSmall?.copyWith(color: color),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  List<int> _visibleYears(CalendarChronology chronology, List<TimelineEvent> events) {
    final years = events
        .map((e) => e.absoluteYear)
        .followedBy(events.map((e) => e.endYear == 0 ? e.absoluteYear : e.endYear))
        .toSet()
        .toList()
      ..sort();
    if (years.isEmpty) return [1];
    return years;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([widget.calendarProvider, widget.eventProvider]),
      builder: (context, _) {
        if (!widget.calendarProvider.isInitialized || !widget.eventProvider.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        final systems = widget.calendarProvider.systems.where((s) => s.isConfigured).toList();
        if (systems.isEmpty) {
          return const Center(child: Text('No configured calendar systems.'));
        }

        final keys = systems.map((s) => s.key as int).toSet();
        var systemKey = widget.eventProvider.selectedSystemKey;
        if (systemKey == null || !keys.contains(systemKey)) {
          systemKey = widget.calendarProvider.selectedSystem?.key as int?;
        }
        if (systemKey == null || !keys.contains(systemKey)) {
          systemKey = systems.first.key as int;
        }

        final chronology = _chronology(systemKey);
        final events = widget.eventProvider.filteredEvents;

        final selectedId = widget.eventProvider.selectedEventId;
        TimelineEvent? selected;
        for (final event in events) {
          if (event.id == selectedId) {
            selected = event;
            break;
          }
        }
        selected ??= events.isEmpty ? null : events.first;

        final positions = <String, _EventPosition>{
          for (final e in events) e.id: _positionFor(e, chronology),
        };

        return Container(
          color: theme.brightness == Brightness.dark ? AppColors.bgMain : AppColors.bgMainLight,
          child: _panel(theme, chronology, events, positions, selected),
        );
      },
    );
  }
}

class _EventPosition {
  final int startYear;
  final int startDayOfYear;
  final int startMonthIdx;
  final int startDayInMonth;
  final int startEraIdx;
  final int endYear;
  final int endDayOfYear;
  final int endMonthIdx;
  final int endDayInMonth;
  final int endEraIdx;

  const _EventPosition({
    required this.startYear,
    required this.startDayOfYear,
    required this.startMonthIdx,
    required this.startDayInMonth,
    required this.startEraIdx,
    required this.endYear,
    required this.endDayOfYear,
    required this.endMonthIdx,
    required this.endDayInMonth,
    required this.endEraIdx,
  });
}