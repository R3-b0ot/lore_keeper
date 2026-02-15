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
  int _step = 0;
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
    await widget.provider.configureSystem(widget.systemKey, seed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final panelColor = isDark ? AppColors.bgPanel : AppColors.bgPanelLight;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: SingleChildScrollView(
        child: Stepper(
          currentStep: _step,
          onStepContinue: () {
            if (_step < 4) {
              setState(() => _step += 1);
            } else {
              _finish();
            }
          },
          onStepCancel: () {
            if (_step > 0) {
              setState(() => _step -= 1);
            }
          },
          controlsBuilder: (context, details) {
            return Row(
              children: [
                FilledButton(
                  onPressed: details.onStepContinue,
                  child: Text(_step == 4 ? 'Bind to Grimoire' : 'Next'),
                ),
                const SizedBox(width: 8),
                if (_step > 0)
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Back'),
                  ),
              ],
            );
          },
          steps: [
            Step(
              title: const Text('Welcome'),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create your magic system foundation.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You can edit everything later from the main panel.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              isActive: _step >= 0,
            ),
            Step(
              title: const Text('System Name'),
              content: TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Magic system name',
                ),
              ),
              isActive: _step >= 1,
            ),
            Step(
              title: const Text('Fuels'),
              content: _EditableList(
                label: 'Fuel source',
                values: _fuels,
                onAdd: _addFuel,
                onRemove: (index) => setState(() => _fuels.removeAt(index)),
                onChanged: (index, value) => _fuels[index] = value,
              ),
              isActive: _step >= 2,
            ),
            Step(
              title: const Text('Triggers'),
              content: _EditableList(
                label: 'Trigger',
                values: _methods,
                onAdd: _addMethod,
                onRemove: (index) => setState(() => _methods.removeAt(index)),
                onChanged: (index, value) => _methods[index] = value,
              ),
              isActive: _step >= 3,
            ),
            Step(
              title: const Text('Schools'),
              content: Column(
                children: [
                  ..._schools.asMap().entries.map((entry) {
                    final index = entry.key;
                    final school = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
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
                                    key: ValueKey(
                                      'school-$index-${school.name}',
                                    ),
                                    decoration: const InputDecoration(
                                      labelText: 'School name',
                                    ),
                                    initialValue: school.name,
                                    onChanged: (value) => school.name = value,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      setState(() => _schools.removeAt(index)),
                                  icon: const Icon(LucideIcons.x),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                _IconPicker(
                                  selectedIconKey: school.iconKey,
                                  onSelected: (iconKey) =>
                                      setState(() => school.iconKey = iconKey),
                                ),
                                const SizedBox(width: 12),
                                Wrap(
                                  spacing: 8,
                                  children: _palette
                                      .map(
                                        (color) => GestureDetector(
                                          onTap: () => setState(
                                            () => school.colorValue = color
                                                .toARGB32(),
                                          ),
                                          child: Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              color: color,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color:
                                                    school.colorValue ==
                                                        color.toARGB32()
                                                    ? colorScheme.onSurface
                                                    : Colors.transparent,
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                            ),
                          ],
                        ),
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
              ),
              isActive: _step >= 4,
            ),
          ],
        ),
      ),
    );
  }
}

class _EditableList extends StatelessWidget {
  final String label;
  final List<String> values;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final void Function(int index, String value) onChanged;

  const _EditableList({
    required this.label,
    required this.values,
    required this.onAdd,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...values.asMap().entries.map((entry) {
          final index = entry.key;
          final value = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: ValueKey('$label-$index-$value'),
                    initialValue: value,
                    decoration: InputDecoration(labelText: label),
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
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(LucideIcons.plus),
            label: const Text('Add'),
          ),
        ),
      ],
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
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Icon(iconData, size: 20),
      ),
    );
  }
}
