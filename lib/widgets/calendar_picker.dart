import 'package:flutter/material.dart';
import 'package:lore_keeper/utils/calendar_chronology.dart';

/// A comprehensive date range picker dialog with dual-month calendar view,
/// relative time presets, and full chronology awareness.
class DateRangePickerDialog extends StatefulWidget {
  final CalendarChronology chronology;
  final int startYear;
  final int startDayOfYear;
  final int endYear;
  final int endDayOfYear;
  final ValueChanged<({int startYear, int startDayOfYear, int endYear, int endDayOfYear})> onRangeSelected;
  final String title;

  const DateRangePickerDialog({
    super.key,
    required this.chronology,
    required this.startYear,
    required this.startDayOfYear,
    required this.endYear,
    required this.endDayOfYear,
    required this.onRangeSelected,
    required this.title,
  });

  @override
  State<DateRangePickerDialog> createState() => _DateRangePickerDialogState();
}

class _DateRangePickerDialogState extends State<DateRangePickerDialog> {
  late int _startYear;
  late int _startDayOfYear;
  late int _endYear;
  late int _endDayOfYear;
  late int _viewStartMonth;
  late int _viewStartYear;
  late int _viewEndMonth;
  late int _viewEndYear;
  DateSelectionMode _selectionMode = DateSelectionMode.start;

  @override
  void initState() {
    super.initState();
    _startYear = widget.startYear;
    _startDayOfYear = widget.startDayOfYear;
    _endYear = widget.endYear;
    _endDayOfYear = widget.endDayOfYear;

    _viewStartMonth = widget.chronology.monthAtDayOfYear(_startDayOfYear).clamp(0, widget.chronology.months.length - 1);
    _viewStartYear = _startYear;
    _viewEndMonth = widget.chronology.monthAtDayOfYear(_endDayOfYear).clamp(0, widget.chronology.months.length - 1);
    _viewEndYear = _endYear;
  }

  void _applyPreset(int daysOffset, {bool isFuture = false}) {
    final baseYear = _selectionMode == DateSelectionMode.start ? _startYear : _endYear;
    final baseDayOfYear = _selectionMode == DateSelectionMode.start ? _startDayOfYear : _endDayOfYear;
    final baseDate = _dayOfYearToDate(baseYear, baseDayOfYear);
    final newDate = baseDate.add(Duration(days: isFuture ? daysOffset : -daysOffset));
    final newYear = newDate.year;
    final newDayOfYear = _dateToDayOfYear(newDate, newYear);

    setState(() {
      if (_selectionMode == DateSelectionMode.start) {
        _startYear = newYear;
        _startDayOfYear = newDayOfYear;
        // Ensure start doesn't exceed end
        if (_compareDates(_startYear, _startDayOfYear, _endYear, _endDayOfYear) > 0) {
          _endYear = _startYear;
          _endDayOfYear = _startDayOfYear;
        }
        _viewStartMonth = widget.chronology.monthAtDayOfYear(_startDayOfYear).clamp(0, widget.chronology.months.length - 1);
        _viewStartYear = _startYear;
      } else {
        _endYear = newYear;
        _endDayOfYear = newDayOfYear;
        // Ensure end doesn't precede start
        if (_compareDates(_startYear, _startDayOfYear, _endYear, _endDayOfYear) > 0) {
          _startYear = _endYear;
          _startDayOfYear = _endDayOfYear;
        }
        _viewEndMonth = widget.chronology.monthAtDayOfYear(_endDayOfYear).clamp(0, widget.chronology.months.length - 1);
        _viewEndYear = _endYear;
      }
    });
  }

  int _compareDates(int year1, int day1, int year2, int day2) {
    if (year1 != year2) return year1.compareTo(year2);
    return day1.compareTo(day2);
  }

  DateTime _dayOfYearToDate(int year, int dayOfYear) {
    return DateTime(year).add(Duration(days: dayOfYear - 1));
  }

  int _dateToDayOfYear(DateTime date, int year) {
    return date.difference(DateTime(year)).inDays + 1;
  }

  void _goToStartMonth(int monthIdx, int year) {
    setState(() {
      _viewStartMonth = monthIdx.clamp(0, widget.chronology.months.length - 1);
      _viewStartYear = year;
    });
  }

  void _goToEndMonth(int monthIdx, int year) {
    setState(() {
      _viewEndMonth = monthIdx.clamp(0, widget.chronology.months.length - 1);
      _viewEndYear = year;
    });
  }

  void _prevStartMonth() {
    if (_viewStartMonth > 0) {
      _goToStartMonth(_viewStartMonth - 1, _viewStartYear);
    } else if (_viewStartYear > 1) {
      _goToStartMonth(widget.chronology.months.length - 1, _viewStartYear - 1);
    }
  }

  void _nextStartMonth() {
    if (_viewStartMonth < widget.chronology.months.length - 1) {
      _goToStartMonth(_viewStartMonth + 1, _viewStartYear);
    } else {
      _goToStartMonth(0, _viewStartYear + 1);
    }
  }

  void _prevEndMonth() {
    if (_viewEndMonth > 0) {
      _goToEndMonth(_viewEndMonth - 1, _viewEndYear);
    } else if (_viewEndYear > 1) {
      _goToEndMonth(widget.chronology.months.length - 1, _viewEndYear - 1);
    }
  }

  void _nextEndMonth() {
    if (_viewEndMonth < widget.chronology.months.length - 1) {
      _goToEndMonth(_viewEndMonth + 1, _viewEndYear);
    } else {
      _goToEndMonth(0, _viewEndYear + 1);
    }
  }

  void _selectStartDay(int dayOfMonth) {
    final month = widget.chronology.months[_viewStartMonth];
    final dayOfYear = month.startDayOfYear + dayOfMonth - 1;
    setState(() {
      _startYear = _viewStartYear;
      _startDayOfYear = dayOfYear;
      _selectionMode = DateSelectionMode.end;
      // Ensure start doesn't exceed end
      if (_compareDates(_startYear, _startDayOfYear, _endYear, _endDayOfYear) > 0) {
        _endYear = _startYear;
        _endDayOfYear = _startDayOfYear;
        _viewEndMonth = _viewStartMonth;
        _viewEndYear = _viewStartYear;
      }
    });
  }

  void _selectEndDay(int dayOfMonth) {
    final month = widget.chronology.months[_viewEndMonth];
    final dayOfYear = month.startDayOfYear + dayOfMonth - 1;
    setState(() {
      _endYear = _viewEndYear;
      _endDayOfYear = dayOfYear;
      _selectionMode = DateSelectionMode.start;
      // Ensure end doesn't precede start
      if (_compareDates(_startYear, _startDayOfYear, _endYear, _endDayOfYear) > 0) {
        _startYear = _endYear;
        _startDayOfYear = _endDayOfYear;
        _viewStartMonth = _viewEndMonth;
        _viewStartYear = _viewEndYear;
      }
    });
  }

  bool _isStartSelected(int year, int dayOfYear) =>
      _selectionMode == DateSelectionMode.start && year == _startYear && dayOfYear == _startDayOfYear;

  bool _isEndSelected(int year, int dayOfYear) =>
      _selectionMode == DateSelectionMode.end && year == _endYear && dayOfYear == _endDayOfYear;

  bool _isInRange(int year, int dayOfYear) {
    if (_startYear == _endYear) {
      return year == _startYear && dayOfYear >= _startDayOfYear && dayOfYear <= _endDayOfYear;
    }
    if (year == _startYear) return dayOfYear >= _startDayOfYear;
    if (year == _endYear) return dayOfYear <= _endDayOfYear;
    return year > _startYear && year < _endYear;
  }

  void _confirmSelection() {
    widget.onRangeSelected((
      startYear: _startYear,
      startDayOfYear: _startDayOfYear,
      endYear: _endYear,
      endDayOfYear: _endDayOfYear,
    ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Text(widget.title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Body
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left sidebar - Relative time presets
                    _PresetSidebar(
                      chronology: widget.chronology,
                      selectionMode: _selectionMode,
                      onModeChanged: (mode) => setState(() => _selectionMode = mode),
                      onPresetSelected: _applyPreset,
                    ),
                    const VerticalDivider(width: 1, thickness: 1),
                    // Dual month calendar view
                    Expanded(
                      child: _DualMonthCalendar(
                        chronology: widget.chronology,
                        selectionMode: _selectionMode,
                        startYear: _startYear,
                        startDayOfYear: _startDayOfYear,
                        endYear: _endYear,
                        endDayOfYear: _endDayOfYear,
                        viewStartMonth: _viewStartMonth,
                        viewStartYear: _viewStartYear,
                        viewEndMonth: _viewEndMonth,
                        viewEndYear: _viewEndYear,
                        onStartMonthChanged: _goToStartMonth,
                        onEndMonthChanged: _goToEndMonth,
                        onPrevStartMonth: _prevStartMonth,
                        onNextStartMonth: _nextStartMonth,
                        onPrevEndMonth: _prevEndMonth,
                        onNextEndMonth: _nextEndMonth,
                        onSelectStartDay: _selectStartDay,
                        onSelectEndDay: _selectEndDay,
                        isStartSelected: _isStartSelected,
                        isEndSelected: _isEndSelected,
                        isInRange: _isInRange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Footer actions
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Apply'),
                    onPressed: _confirmSelection,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum DateSelectionMode { start, end }

/// Left sidebar with relative time presets
class _PresetSidebar extends StatelessWidget {
  final CalendarChronology chronology;
  final DateSelectionMode selectionMode;
  final ValueChanged<DateSelectionMode> onModeChanged;
  final void Function(int daysOffset, {bool isFuture}) onPresetSelected;

  const _PresetSidebar({
    required this.chronology,
    required this.selectionMode,
    required this.onModeChanged,
    required this.onPresetSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selection mode toggle
          _ModeToggle(
            selectionMode: selectionMode,
            onModeChanged: onModeChanged,
          ),
          const SizedBox(height: 16),
          // Past presets
          Text('Past', style: theme.textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          _PresetButton(
            label: 'Last 7 Days',
            onPressed: () => onPresetSelected(7),
            isSelected: false,
          ),
          _PresetButton(
            label: 'Last 30 Days',
            onPressed: () => onPresetSelected(30),
            isSelected: false,
          ),
          _PresetButton(
            label: 'Last 90 Days',
            onPressed: () => onPresetSelected(90),
            isSelected: false,
          ),
          const SizedBox(height: 16),
          // Future presets
          Text('Future', style: theme.textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          _PresetButton(
            label: 'Next 7 Days',
            onPressed: () => onPresetSelected(7, isFuture: true),
            isSelected: false,
          ),
          _PresetButton(
            label: 'Next 30 Days',
            onPressed: () => onPresetSelected(30, isFuture: true),
            isSelected: false,
          ),
          _PresetButton(
            label: 'Next 90 Days',
            onPressed: () => onPresetSelected(90, isFuture: true),
            isSelected: false,
          ),
        ],
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final DateSelectionMode selectionMode;
  final ValueChanged<DateSelectionMode> onModeChanged;

  const _ModeToggle({
    required this.selectionMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select', style: theme.textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ModeButton(
                label: 'Start',
                isSelected: selectionMode == DateSelectionMode.start,
                onTap: () => onModeChanged(DateSelectionMode.start),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ModeButton(
                label: 'End',
                isSelected: selectionMode == DateSelectionMode.end,
                onTap: () => onModeChanged(DateSelectionMode.end),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? cs.primary : cs.outlineVariant),
        ),
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isSelected;

  const _PresetButton({
    required this.label,
    required this.onPressed,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? cs.primaryContainer : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? cs.primary : cs.outlineVariant),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isSelected ? cs.onPrimaryContainer : cs.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

/// Dual month calendar view
class _DualMonthCalendar extends StatelessWidget {
  final CalendarChronology chronology;
  final DateSelectionMode selectionMode;
  final int startYear;
  final int startDayOfYear;
  final int endYear;
  final int endDayOfYear;
  final int viewStartMonth;
  final int viewStartYear;
  final int viewEndMonth;
  final int viewEndYear;
  final void Function(int monthIdx, int year) onStartMonthChanged;
  final void Function(int monthIdx, int year) onEndMonthChanged;
  final VoidCallback onPrevStartMonth;
  final VoidCallback onNextStartMonth;
  final VoidCallback onPrevEndMonth;
  final VoidCallback onNextEndMonth;
  final void Function(int dayOfMonth) onSelectStartDay;
  final void Function(int dayOfMonth) onSelectEndDay;
  final bool Function(int year, int dayOfYear) isStartSelected;
  final bool Function(int year, int dayOfYear) isEndSelected;
  final bool Function(int year, int dayOfYear) isInRange;

  const _DualMonthCalendar({
    required this.chronology,
    required this.selectionMode,
    required this.startYear,
    required this.startDayOfYear,
    required this.endYear,
    required this.endDayOfYear,
    required this.viewStartMonth,
    required this.viewStartYear,
    required this.viewEndMonth,
    required this.viewEndYear,
    required this.onStartMonthChanged,
    required this.onEndMonthChanged,
    required this.onPrevStartMonth,
    required this.onNextStartMonth,
    required this.onPrevEndMonth,
    required this.onNextEndMonth,
    required this.onSelectStartDay,
    required this.onSelectEndDay,
    required this.isStartSelected,
    required this.isEndSelected,
    required this.isInRange,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Start month calendar
        Expanded(
          child: _MonthCalendar(
            chronology: chronology,
            label: 'Start Date',
            isActive: selectionMode == DateSelectionMode.start,
            viewMonth: viewStartMonth,
            viewYear: viewStartYear,
            selectedYear: startYear,
            selectedDayOfYear: startDayOfYear,
            otherYear: endYear,
            otherDayOfYear: endDayOfYear,
            onMonthChanged: onStartMonthChanged,
            onPrevMonth: onPrevStartMonth,
            onNextMonth: onNextStartMonth,
            onSelectDay: onSelectStartDay,
            isSelected: isStartSelected,
            isInRange: isInRange,
          ),
        ),
        const VerticalDivider(width: 1, thickness: 1),
        // End month calendar
        Expanded(
          child: _MonthCalendar(
            chronology: chronology,
            label: 'End Date',
            isActive: selectionMode == DateSelectionMode.end,
            viewMonth: viewEndMonth,
            viewYear: viewEndYear,
            selectedYear: endYear,
            selectedDayOfYear: endDayOfYear,
            otherYear: startYear,
            otherDayOfYear: startDayOfYear,
            onMonthChanged: onEndMonthChanged,
            onPrevMonth: onPrevEndMonth,
            onNextMonth: onNextEndMonth,
            onSelectDay: onSelectEndDay,
            isSelected: isEndSelected,
            isInRange: isInRange,
          ),
        ),
      ],
    );
  }
}

/// Single month calendar widget
class _MonthCalendar extends StatelessWidget {
  final CalendarChronology chronology;
  final String label;
  final bool isActive;
  final int viewMonth;
  final int viewYear;
  final int selectedYear;
  final int selectedDayOfYear;
  final int otherYear;
  final int otherDayOfYear;
  final void Function(int monthIdx, int year) onMonthChanged;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final void Function(int dayOfMonth) onSelectDay;
  final bool Function(int year, int dayOfYear) isSelected;
  final bool Function(int year, int dayOfYear) isInRange;

  const _MonthCalendar({
    required this.chronology,
    required this.label,
    required this.isActive,
    required this.viewMonth,
    required this.viewYear,
    required this.selectedYear,
    required this.selectedDayOfYear,
    required this.otherYear,
    required this.otherDayOfYear,
    required this.onMonthChanged,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onSelectDay,
    required this.isSelected,
    required this.isInRange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final safeViewMonth = viewMonth.clamp(0, chronology.months.length - 1);
    final month = chronology.months[safeViewMonth];
    final firstWeekday = chronology.weekdayAt(viewYear, month.startDayOfYear);
    final daysInMonth = month.days;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: isActive ? cs.primary : cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          // Month/Year header with navigation
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                onPressed: onPrevMonth,
                tooltip: 'Previous month',
              ),
              Expanded(
                child: _MonthYearSelector(
                  chronology: chronology,
                  viewMonth: safeViewMonth,
                  viewYear: viewYear,
                  onMonthChanged: onMonthChanged,
                  onYearChanged: (year) => onMonthChanged(safeViewMonth, year),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                onPressed: onNextMonth,
                tooltip: 'Next month',
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Weekday headers
          Row(
            children: chronology.weekdays
                .asMap()
                .entries
                .map((e) => Expanded(
                      child: Center(
                        child: Text(
                          e.value,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 4),
          // Day grid
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
              ),
              itemCount: firstWeekday + daysInMonth,
              itemBuilder: (context, index) {
                if (index < firstWeekday) {
                  return const SizedBox.shrink();
                }
                final day = index - firstWeekday + 1;
                final dayOfYear = month.startDayOfYear + day - 1;
                final selected = isSelected(viewYear, dayOfYear);
                final inRange = isInRange(viewYear, dayOfYear);
                final isOtherMonth = viewYear != selectedYear;

                Color? bgColor;
                Color? textColor;
                if (selected) {
                  bgColor = cs.primary;
                  textColor = cs.onPrimary;
                } else if (inRange) {
                  bgColor = cs.primaryContainer;
                  textColor = cs.onPrimaryContainer;
                } else {
                  bgColor = Colors.transparent;
                  textColor = isOtherMonth
                      ? cs.onSurfaceVariant.withValues(alpha: 0.4)
                      : cs.onSurface;
                }

                return InkWell(
                  onTap: () => onSelectDay(day),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: textColor,
                          fontWeight: selected || inRange ? FontWeight.w600 : FontWeight.w400,
                        ),
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

  int get firstWeekday => chronology.weekdayAt(viewYear, month.startDayOfYear);
  int get daysInMonth => month.days;
  ChronologyMonth get month => chronology.months[viewMonth.clamp(0, chronology.months.length - 1)];
}

/// Month/Year selector with dropdowns
class _MonthYearSelector extends StatelessWidget {
  final CalendarChronology chronology;
  final int viewMonth;
  final int viewYear;
  final void Function(int monthIdx, int year) onMonthChanged;
  final void Function(int year) onYearChanged;

  const _MonthYearSelector({
    required this.chronology,
    required this.viewMonth,
    required this.viewYear,
    required this.onMonthChanged,
    required this.onYearChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Month dropdown
        DropdownButton<int>(
          value: viewMonth,
          underline: const SizedBox(),
          isDense: true,
          items: List.generate(chronology.months.length, (i) {
            return DropdownMenuItem<int>(
              value: i,
              child: Text(chronology.months[i].name, style: theme.textTheme.bodyMedium),
            );
          }),
          onChanged: (v) => v != null ? onMonthChanged(v, viewYear) : null,
        ),
        const SizedBox(width: 12),
        // Year field
        SizedBox(
          width: 80,
          child: TextFormField(
            initialValue: viewYear.toString(),
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            onFieldSubmitted: (v) {
              final y = int.tryParse(v);
              if (y != null && y > 0) onYearChanged(y);
            },
          ),
        ),
      ],
    );
  }
}

/// Main entry point - a single button that opens the date range picker
class DateRangePickerButton extends StatelessWidget {
  final CalendarChronology chronology;
  final int startYear;
  final int startDayOfYear;
  final int endYear;
  final int endDayOfYear;
  final String label;
  final ValueChanged<({int startYear, int startDayOfYear, int endYear, int endDayOfYear})> onChanged;

  const DateRangePickerButton({
    super.key,
    required this.chronology,
    required this.startYear,
    required this.startDayOfYear,
    required this.endYear,
    required this.endDayOfYear,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final startMonthIdx = chronology.monthAtDayOfYear(startDayOfYear);
    final startDayOfMonth = startMonthIdx >= 0 ? chronology.dayOfMonthAtDayOfYear(startDayOfYear) : 1;
    final startMonthName = startMonthIdx >= 0 ? chronology.months[startMonthIdx].name : 'Unknown';
    final startWeekday = chronology.weekdayNameAt(startYear, startDayOfYear);

    final endMonthIdx = chronology.monthAtDayOfYear(endDayOfYear);
    final endDayOfMonth = endMonthIdx >= 0 ? chronology.dayOfMonthAtDayOfYear(endDayOfYear) : 1;
    final endMonthName = endMonthIdx >= 0 ? chronology.months[endMonthIdx].name : 'Unknown';
    final endWeekday = chronology.weekdayNameAt(endYear, endDayOfYear);

    final isSameDay = startYear == endYear && startDayOfYear == endDayOfYear;

    return OutlinedButton.icon(
      icon: const Icon(Icons.date_range, size: 18),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: theme.textTheme.labelSmall),
          if (isSameDay)
            Text(
              '$startDayOfMonth $startMonthName, Year $startYear ($startWeekday)',
              style: theme.textTheme.bodySmall,
            )
          else ...[
            Text(
              'From: $startDayOfMonth $startMonthName, Year $startYear ($startWeekday)',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              'To: $endDayOfMonth $endMonthName, Year $endYear ($endWeekday)',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => DateRangePickerDialog(
            chronology: chronology,
            startYear: startYear,
            startDayOfYear: startDayOfYear,
            endYear: endYear,
            endDayOfYear: endDayOfYear,
            title: 'Select Date Range',
            onRangeSelected: onChanged,
          ),
        );
      },
    );
  }
}