import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lore_keeper/providers/magic_tree_provider.dart';
import 'package:lore_keeper/theme/app_colors.dart';
import 'package:lore_keeper/utils/magic_icons.dart';

class MagicSchoolDraft {
  String name;
  String iconKey;
  int colorValue;
  bool selected;

  MagicSchoolDraft({
    required this.name,
    required this.iconKey,
    required this.colorValue,
    this.selected = true,
  });
}

class MagicInitWizard extends StatefulWidget {
  final MagicTreeProvider provider;
  final int systemKey;
  final String initialName;

  const MagicInitWizard({
    super.key,
    required this.provider,
    required this.systemKey,
    required this.initialName,
  });

  @override
  State<MagicInitWizard> createState() => _MagicInitWizardState();
}

class _MagicInitWizardState extends State<MagicInitWizard> {
  static const List<(String title, String subtitle, IconData icon)> _stepsMeta =
      [
        ('Welcome', 'Foundation', LucideIcons.sparkles),
        ('System Name', 'Identity', LucideIcons.bookText),
        ('Fuels', 'Source', LucideIcons.flame),
        ('Triggers', 'Execution', LucideIcons.wand),
        ('Schools', 'Disciplines', LucideIcons.school),
      ];

  int _step = 0;
  bool _isSubmitting = false;
  late TextEditingController _nameController;

  final List<String> _fuels = ['Essence Shards'];
  final List<String> _methods = ['Somatic Tracing'];
  final List<MagicSchoolDraft> _schools = [
    MagicSchoolDraft(
      name: 'Illusion',
      iconKey: 'eye',
      colorValue: AppColors.primary.toARGB32(),
    ),
    MagicSchoolDraft(
      name: 'Conjuration',
      iconKey: 'ghost',
      colorValue: AppColors.primaryDark.toARGB32(),
    ),
    MagicSchoolDraft(
      name: 'Destruction',
      iconKey: 'flame',
      colorValue: AppColors.error.toARGB32(),
    ),
    MagicSchoolDraft(
      name: 'Restoration',
      iconKey: 'heart',
      colorValue: AppColors.success.toARGB32(),
    ),
    MagicSchoolDraft(
      name: 'Alteration',
      iconKey: 'shapes',
      colorValue: AppColors.warning.toARGB32(),
    ),
  ];

  static const List<Color> _palette = [
    AppColors.primary,
    AppColors.primaryDark,
    AppColors.primaryLight,
    AppColors.success,
    AppColors.warning,
    AppColors.error,
    AppColors.borderDark,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addFuel() => setState(() => _fuels.add(''));

  void _addMethod() => setState(() => _methods.add(''));

  void _addSchool() => setState(
    () => _schools.add(
      MagicSchoolDraft(
        name: 'New Focus',
        iconKey: 'sparkle',
        colorValue: AppColors.primary.toARGB32(),
      ),
    ),
  );

  Future<void> _finish() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final seed = MagicSystemSeed(
      name: _nameController.text.trim().isEmpty
          ? 'Magic System'
          : _nameController.text.trim(),
      fuels: _fuels.where((f) => f.trim().isNotEmpty).toList(),
      methods: _methods.where((m) => m.trim().isNotEmpty).toList(),
      schools: _schools
          .where((s) => s.selected && s.name.trim().isNotEmpty)
          .map(
            (s) => MagicSchoolSeed(
              name: s.name.trim(),
              iconKey: s.iconKey,
              colorValue: s.colorValue,
            ),
          )
          .toList(),
    );

    try {
      await widget.provider.configureSystem(widget.systemKey, seed);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _next() {
    if (_step < _stepsMeta.length - 1) {
      setState(() => _step += 1);
      return;
    }
    _finish();
  }

  void _previous() {
    if (_step > 0) {
      setState(() => _step -= 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final panelColor = isDark ? AppColors.bgPanel : AppColors.bgPanelLight;
    final panelLighter = isDark
        ? AppColors.bgPanelLighter
        : AppColors.bgPanelLighterLight;

    final progress = (_step + 1) / _stepsMeta.length;
    final currentMeta = _stepsMeta[_step];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
        boxShadow: [isDark ? AppColors.shadow : AppColors.shadowLight],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryCardGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(LucideIcons.sparkles, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Arcane Initialization',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    Text(
                      'Step ${_step + 1} of ${_stepsMeta.length}: ${currentMeta.$1}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress,
              backgroundColor: panelLighter,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _stepsMeta.asMap().entries.map((entry) {
              final index = entry.key;
              final (title, _, icon) = entry.value;
              final isActive = index == _step;
              final isDone = index < _step;
              return InkWell(
                onTap: () => setState(() => _step = index),
                borderRadius: BorderRadius.circular(999),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? colorScheme.primaryContainer
                        : panelLighter,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isActive
                          ? colorScheme.primary
                          : colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDone ? LucideIcons.check : icon,
                        size: 14,
                        color: isActive
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        title,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isActive
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: panelLighter,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.45),
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: SingleChildScrollView(
                  key: ValueKey<int>(_step),
                  child: _buildStepContent(_step),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (_step > 0)
                OutlinedButton.icon(
                  onPressed: _isSubmitting ? null : _previous,
                  icon: const Icon(LucideIcons.arrowLeft, size: 16),
                  label: const Text('Back'),
                )
              else
                const SizedBox(width: 1),
              const Spacer(),
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _next,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _step == _stepsMeta.length - 1
                            ? LucideIcons.wandSparkles
                            : LucideIcons.arrowRight,
                        size: 16,
                      ),
                label: Text(
                  _step == _stepsMeta.length - 1
                      ? 'Bind to Grimoire'
                      : 'Continue',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(int step) {
    switch (step) {
      case 0:
        return _buildWelcomeStep();
      case 1:
        return _buildSystemNameStep();
      case 2:
        return _EditableList(
          label: 'Fuel source',
          values: _fuels,
          addLabel: 'Add Fuel Source',
          onAdd: _addFuel,
          onRemove: (index) => setState(() => _fuels.removeAt(index)),
          onChanged: (index, value) => _fuels[index] = value,
        );
      case 3:
        return _EditableList(
          label: 'Trigger',
          values: _methods,
          addLabel: 'Add Trigger',
          onAdd: _addMethod,
          onRemove: (index) => setState(() => _methods.removeAt(index)),
          onChanged: (index, value) => _methods[index] = value,
        );
      case 4:
        return _buildSchoolsStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildWelcomeStep() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shape the rules of your arcane world.',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Define fuels, triggers, and disciplines. Everything remains editable after setup.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: const [
            _InfoPill(icon: LucideIcons.flame, label: 'Fuel economy'),
            _InfoPill(icon: LucideIcons.wand, label: 'Casting methods'),
            _InfoPill(icon: LucideIcons.school, label: 'Schools'),
          ],
        ),
      ],
    );
  }

  Widget _buildSystemNameStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Name the system',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Magic system name',
            prefixIcon: Icon(LucideIcons.bookText),
          ),
        ),
      ],
    );
  }

  Widget _buildSchoolsStep() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._schools.asMap().entries.map((entry) {
          final index = entry.key;
          final school = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Switch(
                      value: school.selected,
                      onChanged: (value) =>
                          setState(() => school.selected = value),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        key: ValueKey('school-$index-${school.name}'),
                        decoration: const InputDecoration(
                          labelText: 'School name',
                          isDense: true,
                        ),
                        initialValue: school.name,
                        onChanged: (value) => school.name = value,
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _schools.removeAt(index)),
                      icon: const Icon(LucideIcons.trash2),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _IconPicker(
                      selectedIconKey: school.iconKey,
                      onSelected: (iconKey) =>
                          setState(() => school.iconKey = iconKey),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _palette.map((color) {
                          final selected =
                              school.colorValue == color.toARGB32();
                          return InkWell(
                            onTap: () => setState(
                              () => school.colorValue = color.toARGB32(),
                            ),
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected
                                      ? colorScheme.onSurface
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _addSchool,
            icon: const Icon(LucideIcons.plus),
            label: const Text('Add School'),
          ),
        ),
      ],
    );
  }
}

class _EditableList extends StatelessWidget {
  final String label;
  final String addLabel;
  final List<String> values;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final void Function(int index, String value) onChanged;

  const _EditableList({
    required this.label,
    required this.addLabel,
    required this.values,
    required this.onAdd,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        ...values.asMap().entries.map((entry) {
          final index = entry.key;
          final value = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: ValueKey('$label-$index-$value'),
                    initialValue: value,
                    decoration: InputDecoration(
                      labelText: label,
                      border: InputBorder.none,
                    ),
                    onChanged: (text) => onChanged(index, text),
                  ),
                ),
                IconButton(
                  onPressed: () => onRemove(index),
                  icon: const Icon(LucideIcons.x),
                ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(LucideIcons.plus),
          label: Text(addLabel),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.primary),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}

class _IconPicker extends StatelessWidget {
  final String selectedIconKey;
  final ValueChanged<String> onSelected;

  const _IconPicker({required this.selectedIconKey, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final iconData = magicIconMap[selectedIconKey] ?? LucideIcons.bookOpen;
    return PopupMenuButton<String>(
      tooltip: 'Change icon',
      onSelected: onSelected,
      itemBuilder: (context) => magicIconCategories
          .map(
            (category) => PopupMenuItem<String>(
              enabled: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.label,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: category.icons
                        .map(
                          (iconKey) => IconButton(
                            onPressed: () => Navigator.of(context).pop(iconKey),
                            icon: Icon(
                              magicIconMap[iconKey] ?? LucideIcons.bookOpen,
                              size: 18,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Icon(iconData, size: 20),
      ),
    );
  }
}
