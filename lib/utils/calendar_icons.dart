import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CalendarIconCategory {
  final String label;
  final List<String> icons;

  const CalendarIconCategory({required this.label, required this.icons});
}

const Map<String, IconData> calendarIconMap = {
  'chronos_system': LucideIcons.clock3,
  'system': LucideIcons.clock3,
  'category': LucideIcons.folder,
  'calendar': LucideIcons.calendar,
  'month': LucideIcons.moon,
  'day': LucideIcons.sun,
  'celestial': LucideIcons.orbit,
  'era': LucideIcons.milestone,
  'holiday': LucideIcons.partyPopper,
  'clock': LucideIcons.clock3,
  'orbit': LucideIcons.orbit,
  'milestone': LucideIcons.milestone,
  'moon': LucideIcons.moon,
  'sun': LucideIcons.sun,
  'star': LucideIcons.star,
  'telescope': LucideIcons.telescope,
  'history': LucideIcons.history,
  'infinity': LucideIcons.infinity,
  'compass': LucideIcons.compass,
  'scroll': LucideIcons.scrollText,
  'festival': LucideIcons.partyPopper,
  'cycle': LucideIcons.refreshCw,
  'wind': LucideIcons.wind,
  'zap': LucideIcons.bolt,
  'flame': LucideIcons.flame,
  'drop': LucideIcons.droplet,
  'ritual': LucideIcons.tent,
  'sparkles': LucideIcons.sparkles,
};

const List<CalendarIconCategory> calendarIconCategories = [
  CalendarIconCategory(
    label: 'Temporal',
    icons: ['calendar', 'clock', 'history', 'infinity', 'milestone', 'scroll'],
  ),
  CalendarIconCategory(
    label: 'Celestial',
    icons: ['sun', 'moon', 'star', 'orbit', 'telescope', 'compass'],
  ),
  CalendarIconCategory(
    label: 'Seasonal',
    icons: ['wind', 'zap', 'flame', 'drop', 'sparkles'],
  ),
  CalendarIconCategory(
    label: 'Culture',
    icons: ['holiday', 'festival', 'ritual'],
  ),
];

const List<Color> calendarSeasonalColors = [
  Color(0xFFF43F5E),
  Color(0xFFFB923C),
  Color(0xFFFBBF24),
  Color(0xFF4ADE80),
  Color(0xFF2DD4BF),
  Color(0xFF3B82F6),
  Color(0xFF8B5CF6),
  Color(0xFFD946EF),
  Color(0xFF64748B),
];
