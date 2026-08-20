# Script to refactor timeline_module.dart
from pathlib import Path

p = Path(r'e:\lore_keeper\lib\modules\timeline_module.dart')
s = p.read_text()

# Remove calendar_node import (no longer needed)
s = s.replace("import 'package:lore_keeper/models/calendar_node.dart';\n", "")

# Add calendar_chronology import after app_colors
s = s.replace("import 'package:lore_keeper/theme/app_colors.dart';\n", "import 'package:lore_keeper/theme/app_colors.dart';\nimport 'package:lore_keeper/utils/calendar_chronology.dart';\n")

# Replace the _readInt, _axis, _dateFor, _eraIndex methods with new chronology-based methods
start = s.index('  int _readInt(')
end = s.index('  IconData _icon')

new = '''  /// Builds the active chronology from the calendar tree.
  CalendarChronology _chronology(int systemKey) =>
      CalendarChronology.fromProvider(widget.calendarProvider, systemKey);

  _RelDate _dateFor(TimelineEvent event, CalendarChronology chronology) {
    final total = math.max(1, chronology.daysInYear);
    final day = ((((event.absoluteDayOfYear - 1) % total) + total) % total) + 1;
    final monthIdx = chronology.monthAtDayOfYear(day);
    final dayInMonth = chronology.dayOfMonthAtDayOfYear(day);
    final eraIdx = chronology.eraAtYear(event.absoluteYear);
    final eraName = eraIdx >= 0 and eraIdx < chronology.eras.length
        ? chronology.eras[eraIdx]
        : 'Era';

    return _RelDate(
      event.absoluteYear,
      day,
      monthIdx < 0 ? 0 : monthIdx,
      dayInMonth < 1 ? day : dayInMonth,
      eraIdx < 0 ? 0 : eraIdx,
      eraName,
    );
  }

'''

s = s[:start] + new + s[end:]

# Replace _AxisData with CalendarChronology everywhere
s = s.replace('_AxisData axis', 'CalendarChronology chronology')
s = s.replace('_AxisData axis,', 'CalendarChronology chronology,')
s = s.replace('axis.totalDays', 'chronology.daysInYear')
s = s.replace('axis.eras', 'chronology.eras')
s = s.replace('axis.months', 'chronology.months')
s = s.replace('axis.systemName', 'chronology.systemName')
s = s.replace('axis.calendarName', 'chronology.calendarName')
s = s.replace('_axis(_activeSystemKey!)', '_chronology(_activeSystemKey!)')
s = s.replace('_dateFor(e, axis, events)', '_dateFor(e, chronology)')
s = s.replace('_dateFor(e, axis, events)', '_dateFor(e, chronology)')
s = s.replace('_label(d, axis)', '_label(d, chronology)')
s = s.replace('_createEvent(axis)', '_createEvent(chronology)')
s = s.replace('_listPane(theme, axis, events, dates, systems)', '_listPane(theme, chronology, events, dates, systems)')
s = s.replace('_panel(theme, axis, events, dates, selected)', '_panel(theme, chronology, events, dates, selected)')
s = s.replace('_trackWidth(axis, events)', '_trackWidth(chronology, events)')
s = s.replace('_track(theme, axis, events, dates)', '_track(theme, chronology, events, dates)')
s = s.replace('_editor(theme, axis, selected, dates[selected.id]!)', '_editor(theme, chronology, selected, dates[selected.id]!)')
s = s.replace('final axis = _chronology(_activeSystemKey!);', 'final chronology = _chronology(_activeSystemKey!);')

# Fix the createEvent to pass calendarSystemKey
s = s.replace("      colorValue: 0xFF6366F1,\n    );", "      colorValue: 0xFF6366F1,\n      calendarSystemKey: chronology.systemKey,\n    );", 1)

# Remove dead _AxisData and _Month classes at bottom (keep _RelDate)
idx = s.find('\nclass _AxisData')
if idx != -1:
    idx2 = s.find('\nclass _RelDate', idx)
    if idx2 != -1:
        s = s[:idx] + s[idx2:]

p.write_text(s)
print("Done!")