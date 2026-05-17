import 'package:flutter/material.dart';
import 'package:lore_keeper/models/calendar_node.dart';
import 'package:lore_keeper/theme/app_colors.dart';

class CalendarTypeSpec {
  final String key;
  final String label;
  final String iconKey;
  final Color color;
  final List<CalendarAttribute> Function() defaultAttributes;

  const CalendarTypeSpec({
    required this.key,
    required this.label,
    required this.iconKey,
    required this.color,
    required this.defaultAttributes,
  });
}

List<CalendarAttribute> _none() => <CalendarAttribute>[];

List<CalendarAttribute> _systemDefaults() => [
  CalendarAttribute(label: 'Total Days/Year', value: '365'),
  CalendarAttribute(label: 'Hours/Day', value: '24'),
  CalendarAttribute(label: 'Day/Night Split', value: '12/12'),
];

List<CalendarAttribute> _calendarDefaults() => [
  CalendarAttribute(label: 'Era Prefix', value: 'A.D.'),
  CalendarAttribute(label: 'Numbering System', value: 'Sequential'),
  CalendarAttribute(label: 'Regex Pattern', value: '^[0-9]+ [A-Z]{2}\$'),
];

List<CalendarAttribute> _monthDefaults() => [
  CalendarAttribute(label: 'Number of Days', value: '30'),
  CalendarAttribute(label: 'Associated Season', value: 'Spring'),
  CalendarAttribute(label: 'Mana Alignment', value: 'Neutral'),
];

List<CalendarAttribute> _dayDefaults() => [
  CalendarAttribute(label: 'Ruling Planet', value: 'Unknown'),
  CalendarAttribute(label: 'Daily Ritual', value: 'None'),
  CalendarAttribute(label: 'Auspicious For', value: 'New Beginnings'),
];

List<CalendarAttribute> _holidayDefaults() => [
  CalendarAttribute(label: 'Occurrence', value: 'Annual'),
  CalendarAttribute(label: 'Celebration Type', value: 'Feast'),
  CalendarAttribute(label: 'Tradition', value: 'Gift Exchange'),
];

List<CalendarAttribute> _celestialDefaults() => [
  CalendarAttribute(label: 'Orbit Type', value: 'Geocentric'),
  CalendarAttribute(label: 'Orbital Period', value: '28 Days'),
];

List<CalendarAttribute> _eraDefaults() => [
  CalendarAttribute(label: 'Start Condition', value: 'Ascension'),
  CalendarAttribute(label: 'Numerical Format', value: 'Roman Numerals'),
];

final List<CalendarTypeSpec> calendarTypeSpecs = [
  CalendarTypeSpec(
    key: 'chronos_system',
    label: 'SYSTEM',
    iconKey: 'clock',
    color: AppColors.warning,
    defaultAttributes: _systemDefaults,
  ),
  CalendarTypeSpec(
    key: 'category',
    label: 'CATEGORY',
    iconKey: 'calendar',
    color: AppColors.primary,
    defaultAttributes: _none,
  ),
  CalendarTypeSpec(
    key: 'calendar',
    label: 'CALENDAR',
    iconKey: 'calendar',
    color: AppColors.primary,
    defaultAttributes: _calendarDefaults,
  ),
  CalendarTypeSpec(
    key: 'month',
    label: 'MONTH',
    iconKey: 'moon',
    color: AppColors.primaryLight,
    defaultAttributes: _monthDefaults,
  ),
  CalendarTypeSpec(
    key: 'day',
    label: 'DAY',
    iconKey: 'day',
    color: AppColors.success,
    defaultAttributes: _dayDefaults,
  ),
  CalendarTypeSpec(
    key: 'celestial',
    label: 'CELESTIAL',
    iconKey: 'orbit',
    color: AppColors.primaryDark,
    defaultAttributes: _celestialDefaults,
  ),
  CalendarTypeSpec(
    key: 'era',
    label: 'ERA',
    iconKey: 'milestone',
    color: AppColors.warning,
    defaultAttributes: _eraDefaults,
  ),
  CalendarTypeSpec(
    key: 'holiday',
    label: 'HOLIDAY',
    iconKey: 'holiday',
    color: AppColors.error,
    defaultAttributes: _holidayDefaults,
  ),
];

CalendarTypeSpec calendarSpecForType(String key) {
  return calendarTypeSpecs.firstWhere(
    (spec) => spec.key == key,
    orElse: () => calendarTypeSpecs.first,
  );
}

List<String> calendarTypeKeysForDropdown() =>
    calendarTypeSpecs.map((spec) => spec.key).toList();
