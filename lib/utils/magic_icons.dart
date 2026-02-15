import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MagicIconCategory {
  final String label;
  final List<String> icons;

  const MagicIconCategory({required this.label, required this.icons});
}

const Map<String, IconData> magicIconMap = {
  'magic_system': LucideIcons.sparkles,
  'fuel_category': LucideIcons.flame,
  'trigger_category': LucideIcons.slidersHorizontal,
  'discipline_category': LucideIcons.school,
  'discipline': LucideIcons.school,
  'spells_category': LucideIcons.wand,
  'enchantments_category': LucideIcons.wand,
  'spell': LucideIcons.wand,
  'enchantment': LucideIcons.wand,
  'fuel': LucideIcons.flame,
  'trigger': LucideIcons.wrench,
  'wand': LucideIcons.sparkles,
  'sparkle': LucideIcons.sparkles,
  'book': LucideIcons.book,
  'scroll': LucideIcons.fileText,
  'flame': LucideIcons.flame,
  'drop': LucideIcons.droplet,
  'wind': LucideIcons.wind,
  'mountain': LucideIcons.mountain,
  'zap': LucideIcons.bolt,
  'skull': LucideIcons.skull,
  'flask': LucideIcons.flaskConical,
  'gem': LucideIcons.gem,
  'shield': LucideIcons.shield,
  'eye': LucideIcons.eye,
  'brain': LucideIcons.brain,
  'ghost': LucideIcons.eyeOff,
  'beaker': LucideIcons.flaskConical,
  'battery': LucideIcons.batteryCharging,
  'hand': LucideIcons.hand,
  'heart': LucideIcons.heart,
  'shapes': LucideIcons.tag,
  'moon': LucideIcons.moon,
  'sun': LucideIcons.sun,
  'star': LucideIcons.star,
  'cloud': LucideIcons.cloud,
  'compass': LucideIcons.compass,
  'anchor': LucideIcons.anchor,
  'key': LucideIcons.key,
  'lock': LucideIcons.lock,
  'target': LucideIcons.target,
  'sword': LucideIcons.gavel,
  'axe': LucideIcons.axe,
  'hammer': LucideIcons.hammer,
  'infinity': LucideIcons.infinity,
  'flaskround': LucideIcons.flaskConical,
  'dna': LucideIcons.dna,
  'atom': LucideIcons.atom,
  'magnet': LucideIcons.magnet,
  'telescope': LucideIcons.telescope,
  'lightbulb': LucideIcons.lightbulb,
};

const List<MagicIconCategory> magicIconCategories = [
  MagicIconCategory(
    label: 'Arcane',
    icons: [
      'wand',
      'sparkle',
      'book',
      'scroll',
      'gem',
      'key',
      'lock',
      'infinity',
      'star',
      'moon',
      'sun',
    ],
  ),
  MagicIconCategory(
    label: 'Elemental',
    icons: ['flame', 'drop', 'wind', 'mountain', 'zap', 'cloud', 'atom'],
  ),
  MagicIconCategory(
    label: 'Life & Death',
    icons: ['heart', 'skull', 'ghost', 'brain', 'eye', 'dna'],
  ),
  MagicIconCategory(
    label: 'Combat & Tools',
    icons: ['sword', 'axe', 'hammer', 'shield', 'target', 'compass', 'anchor'],
  ),
  MagicIconCategory(
    label: 'Alchemy',
    icons: [
      'flask',
      'flaskround',
      'beaker',
      'battery',
      'magnet',
      'telescope',
      'lightbulb',
    ],
  ),
];
