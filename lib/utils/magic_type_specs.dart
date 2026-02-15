import 'package:flutter/material.dart';
import 'package:lore_keeper/theme/app_colors.dart';
import 'package:lore_keeper/models/magic_node.dart';

class MagicTypeSpec {
  final String key;
  final String label;
  final String iconKey;
  final Color color;
  final List<MagicAttribute> Function() defaultAttributes;

  const MagicTypeSpec({
    required this.key,
    required this.label,
    required this.iconKey,
    required this.color,
    required this.defaultAttributes,
  });
}

List<MagicAttribute> _none() => <MagicAttribute>[];

List<MagicAttribute> _spellDefaults() => [
  MagicAttribute(label: 'Level', value: '1'),
  MagicAttribute(label: 'Range', value: '60ft'),
  MagicAttribute(label: 'Duration', value: 'Instant'),
];

List<MagicAttribute> _enchantmentDefaults() => [
  MagicAttribute(label: 'Vessel', value: 'Steel'),
  MagicAttribute(label: 'Longevity', value: 'Permanent'),
  MagicAttribute(label: 'Strain', value: 'Low'),
];

List<MagicAttribute> _fuelDefaults() => [
  MagicAttribute(label: 'Potency', value: 'High'),
  MagicAttribute(label: 'Stability', value: 'Stable'),
  MagicAttribute(label: 'Burn Rate', value: '1oz/min'),
];

List<MagicAttribute> _triggerDefaults() => [
  MagicAttribute(label: 'Complexity', value: 'Medium'),
  MagicAttribute(label: 'Physicality', value: 'High'),
  MagicAttribute(label: 'Focus', value: 'Verbal/Somatic'),
];

List<MagicAttribute> _systemDefaults() => [
  MagicAttribute(label: 'Type', value: 'Hard Magic'),
];

final List<MagicTypeSpec> magicTypeSpecs = [
  MagicTypeSpec(
    key: 'magic_system',
    label: 'MAGIC SYSTEM',
    iconKey: 'magic_system',
    color: AppColors.primary,
    defaultAttributes: _systemDefaults,
  ),
  MagicTypeSpec(
    key: 'fuel_category',
    label: 'FUEL CATEGORY',
    iconKey: 'fuel',
    color: AppColors.success,
    defaultAttributes: _none,
  ),
  MagicTypeSpec(
    key: 'trigger_category',
    label: 'TRIGGER CATEGORY',
    iconKey: 'trigger_category',
    color: AppColors.primaryDark,
    defaultAttributes: _none,
  ),
  MagicTypeSpec(
    key: 'discipline_category',
    label: 'DISCIPLINE CATEGORY',
    iconKey: 'discipline_category',
    color: AppColors.warning,
    defaultAttributes: _none,
  ),
  MagicTypeSpec(
    key: 'discipline',
    label: 'DISCIPLINE',
    iconKey: 'discipline',
    color: AppColors.warning,
    defaultAttributes: _none,
  ),
  MagicTypeSpec(
    key: 'spells_category',
    label: 'SPELLS CATEGORY',
    iconKey: 'spells_category',
    color: AppColors.primary,
    defaultAttributes: _none,
  ),
  MagicTypeSpec(
    key: 'enchantments_category',
    label: 'ENCHANTMENTS CATEGORY',
    iconKey: 'enchantments_category',
    color: AppColors.primaryDark,
    defaultAttributes: _none,
  ),
  MagicTypeSpec(
    key: 'spell',
    label: 'SPELL',
    iconKey: 'sparkle',
    color: AppColors.primary,
    defaultAttributes: _spellDefaults,
  ),
  MagicTypeSpec(
    key: 'enchantment',
    label: 'ENCHANTMENT',
    iconKey: 'gem',
    color: AppColors.primaryDark,
    defaultAttributes: _enchantmentDefaults,
  ),
  MagicTypeSpec(
    key: 'fuel',
    label: 'FUEL',
    iconKey: 'fuel',
    color: AppColors.success,
    defaultAttributes: _fuelDefaults,
  ),
  MagicTypeSpec(
    key: 'trigger',
    label: 'TRIGGER',
    iconKey: 'trigger',
    color: AppColors.borderDark,
    defaultAttributes: _triggerDefaults,
  ),
];

MagicTypeSpec specForType(String key) {
  return magicTypeSpecs.firstWhere(
    (spec) => spec.key == key,
    orElse: () => magicTypeSpecs.first,
  );
}

List<String> magicTypeKeysForDropdown() =>
    magicTypeSpecs.map((spec) => spec.key).toList();
