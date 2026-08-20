/// CalendarChronology — Pure Dart chronology engine.
library;

import 'package:lore_keeper/models/calendar_node.dart';
import 'package:lore_keeper/providers/calendar_tree_provider.dart';

class CalendarChronology {
  final int systemKey;
  final int daysInYear;
  final List<ChronologyMonth> months;
  final List<String> eras;
  final List<int> eraStartYears;
  final String calendarName;
  final String systemName;

  const CalendarChronology({
    required this.systemKey,
    required this.daysInYear,
    required this.months,
    required this.eras,
    required this.eraStartYears,
    required this.calendarName,
    required this.systemName,
  });

  int monthAtDayOfYear(int dayOfYear) {
    if (dayOfYear < 1 || dayOfYear > daysInYear) return -1;
    for (int i = 0; i < months.length; i++) {
      final m = months[i];
      final end = m.startDayOfYear + m.days - 1;
      if (dayOfYear >= m.startDayOfYear && dayOfYear <= end) return i;
    }
    return -1;
  }

  int dayOfMonthAtDayOfYear(int dayOfYear) {
    final monthIdx = monthAtDayOfYear(dayOfYear);
    if (monthIdx < 0) return -1;
    final month = months[monthIdx];
    return dayOfYear - month.startDayOfYear + 1;
  }

  int eraAtYear(int year) {
    if (eras.isEmpty) return -1;
    if (eraStartYears.isEmpty) return 0;
    for (int i = eraStartYears.length - 1; i >= 0; i--) {
      if (year >= eraStartYears[i]) return i;
    }
    return 0;
  }

  String formatDisplay(int absoluteYear, int absoluteDayOfYear) {
    final monthIdx = monthAtDayOfYear(absoluteDayOfYear);
    final dayOfMonth = dayOfMonthAtDayOfYear(absoluteDayOfYear);
    final eraIdx = eraAtYear(absoluteYear);

    final monthName = monthIdx >= 0 ? months[monthIdx].name : 'Unknown Month';
    final dayStr = dayOfMonth >= 1 ? '$dayOfMonth' : '?';
    final eraStr = eraIdx >= 0 && eraIdx < eras.length ? eras[eraIdx] : '';
    final yearStr = eraStartYears.isNotEmpty && eraIdx >= 0
        ? '${absoluteYear - eraStartYears[eraIdx] + 1}'
        : '$absoluteYear';

    final parts = <String>[];
    parts.add('$dayStr $monthName');
    if (eraStr.isNotEmpty) parts.add(eraStr);
    parts.add('Year $yearStr');
    return parts.join(', ');
  }

  int dayOfYearFromParts({
    required int year,
    required int monthIndex,
    required int dayOfMonth,
  }) {
    if (monthIndex < 0 || monthIndex >= months.length) return -1;
    final month = months[monthIndex];
    if (dayOfMonth < 1 || dayOfMonth > month.days) return -1;
    return month.startDayOfYear + dayOfMonth - 1;
  }

  static CalendarChronology fromProvider(
    CalendarTreeProvider provider,
    int systemKey,
  ) {
    final system = provider.getSystemByKey(systemKey);
    final root = provider.getRootNodeForSystem(systemKey);
    final top = provider.getTopCalendarNodeForSystem(systemKey);

    if (system == null || root == null || top == null) {
      return CalendarChronology._empty(systemKey, system?.name ?? 'Unknown');
    }

    final totalDays = _readPositiveInt(
      root.attributes,
      const {'total_days_year', 'total_days', 'days_year'},
      365,
    );

    String calName = 'Calendar';
    final topChildren = provider.getChildrenOf(top.id);
    for (final node in topChildren) {
      if (node.type == 'calendar') {
        calName = node.title;
        break;
      }
    }

    final List<String> eraNames = [];
    final List<int> eraStarts = [];
    final rootChildren = provider.getChildrenOf(root.id);
    CalendarNode? erasHeader;
    for (final node in rootChildren) {
      if (node.title.toLowerCase().contains('era')) {
        erasHeader = node;
        break;
      }
    }
    if (erasHeader != null) {
      final eraNodes = provider.getChildrenOf(erasHeader.id);
      for (final eraNode in eraNodes) {
        eraNames.add(eraNode.title);
        final startYear = _readPositiveInt(
          eraNode.attributes,
          const {'start_year', 'start_year_era', 'era_start'},
          1,
        );
        eraStarts.add(startYear);
      }
    }

    final List<ChronologyMonth> monthList = [];
    CalendarNode? monthHeader;
    for (final node in topChildren) {
      if (node.title.toLowerCase().contains('month')) {
        monthHeader = node;
        break;
      }
    }
    if (monthHeader != null) {
      final monthNodes = provider.getChildrenOf(monthHeader.id);
      var cursor = 1;
      for (final node in monthNodes) {
        final days = _readPositiveInt(
          node.attributes,
          const {'number_of_days', 'days_month', 'month_days'},
          30,
        );
        monthList.add(ChronologyMonth(
          name: node.title,
          days: days,
          startDayOfYear: cursor,
        ));
        cursor += days;
      }
    }

    if (monthList.isEmpty) {
      final perMonth = (totalDays / 12).floor();
      var cursor = 1;
      for (int i = 1; i <= 12; i++) {
        final days = (i == 12) ? totalDays - cursor + 1 : perMonth;
        monthList.add(ChronologyMonth(
          name: 'Month $i',
          days: days,
          startDayOfYear: cursor,
        ));
        cursor += days;
      }
    }

    return CalendarChronology(
      systemKey: systemKey,
      daysInYear: totalDays,
      months: monthList,
      eras: eraNames,
      eraStartYears: eraStarts,
      calendarName: calName,
      systemName: system.name,
    );
  }

  static CalendarChronology _empty(int systemKey, String systemName) {
    return CalendarChronology(
      systemKey: systemKey,
      daysInYear: 365,
      months: List.generate(12, (i) => ChronologyMonth(
        name: 'Month ${i + 1}',
        days: 30 + (i == 11 ? 5 : 0),
        startDayOfYear: i * 30 + 1,
      )),
      eras: [],
      eraStartYears: [],
      calendarName: 'Default',
      systemName: systemName,
    );
  }

  static int? _parseInt(String s) {
    final m = RegExp(r'-?\d+').firstMatch(s);
    return m == null ? null : int.tryParse(m.group(0)!);
  }

  /// Reads an attribute by trying a set of normalized keys (underscore-lowercase).
  /// Falls back to substring matching if no exact key matches.
  static int _readPositiveInt(
    List<CalendarAttribute> attrs,
    Set<String> keys,
    int fallback,
  ) {
    // Build a normalized map: key (underscore-lower) -> value
    final normalized = <String, String>{};
    for (final attr in attrs) {
      final norm = attr.label
          .toLowerCase()
          .replaceAll(' ', '_')
          .replaceAll('/', '_')
          .replaceAll('-', '_');
      normalized[norm] = attr.value;
    }

    // Try exact normalized key match first
    for (final key in keys) {
      final val = normalized[key];
      if (val != null) {
        final parsed = _parseInt(val);
        if (parsed != null && parsed > 0) return parsed;
      }
    }

    // Fallback: substring match on original labels
    for (final attr in attrs) {
      final l = attr.label.toLowerCase();
      for (final key in keys) {
        final search = key.replaceAll('_', ' ');
        if (l.contains(search)) {
          final parsed = _parseInt(attr.value);
          if (parsed != null && parsed > 0) return parsed;
        }
      }
    }

    return fallback;
  }
}

class ChronologyMonth {
  final String name;
  final int days;
  final int startDayOfYear;

  const ChronologyMonth({
    required this.name,
    required this.days,
    required this.startDayOfYear,
  });

  int get endDayOfYear => startDayOfYear + days - 1;
}
