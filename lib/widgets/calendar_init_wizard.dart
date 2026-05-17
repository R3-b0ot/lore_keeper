import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lore_keeper/providers/calendar_tree_provider.dart';
import 'package:lore_keeper/theme/app_colors.dart';
import 'package:lore_keeper/utils/calendar_icons.dart';

class CalendarMonthDraft {
  String name;
  int days;

  CalendarMonthDraft({required this.name, required this.days});
}

class CalendarSeasonDraft {
  String name;
  String iconKey;
  int colorValue;
  int duration;

  CalendarSeasonDraft({
    required this.name,
    required this.iconKey,
    required this.colorValue,
    required this.duration,
  });
}

class _RegexPreset {
  final String label;
  final String value;

  const _RegexPreset({required this.label, required this.value});
}

const List<_RegexPreset> _regexPresets = [
  _RegexPreset(label: 'Standard (1234 AD)', value: '^[0-9]+ [A-Z]{2}\$'),
  _RegexPreset(label: 'Era First (AD 1234)', value: '^[A-Z]{2} [0-9]+\$'),
  _RegexPreset(
    label: 'Dot Separated (1.2.34)',
    value: r'^[0-9]+\.[0-9]+\.[0-9]+$',
  ),
  _RegexPreset(label: 'Celestial (Y:1 C:2)', value: r'^Y:[0-9]+ C:[0-9]+$'),
];

const List<String> _seasonIconOptions = [
  'wind',
  'zap',
  'flame',
  'drop',
  'sun',
  'moon',
  'star',
  'sparkles',
];

class CalendarInitWizard extends StatefulWidget {
  final CalendarTreeProvider provider;
  final int systemKey;
  final String initialName;

  const CalendarInitWizard({
    super.key,
    required this.provider,
    required this.systemKey,
    required this.initialName,
  });

  @override
  State<CalendarInitWizard> createState() => _CalendarInitWizardState();
}

class _CalendarInitWizardState extends State<CalendarInitWizard> {
  static const List<(String title, String subtitle, IconData icon)> _stepsMeta =
      [
        ('Genesis', 'Identity', LucideIcons.orbit),
        ('The Measure', 'Rhythm', LucideIcons.clock3),
        ('Components', 'Months & Days', LucideIcons.calendarDays),
        ('Weekly Cycle', 'Week Rules', LucideIcons.repeat),
        ('Seasonal Flow', 'Climate Arc', LucideIcons.wind),
      ];

  int _step = 0;
  bool _isSubmitting = false;
  late TextEditingController _worldNameController;
  late TextEditingController _calendarNameController;
  late TextEditingController _totalDaysController;
  late TextEditingController _dayNightRatioController;

  final List<String> _eras = ['The Age of Dawn', 'The Silver Epoch'];
  List<CalendarMonthDraft> _months = [];
  List<String> _weekDays = [];
  String _firstDayOfWeek = '';
  final Set<String> _weekends = <String>{};
  String _yearRegex = _regexPresets.first.value;

  final List<CalendarSeasonDraft> _seasons = [
    CalendarSeasonDraft(
      name: 'Great Thaw',
      iconKey: 'drop',
      colorValue: const Color(0xFF2DD4BF).toARGB32(),
      duration: 90,
    ),
    CalendarSeasonDraft(
      name: 'Solar Peak',
      iconKey: 'sun',
      colorValue: const Color(0xFFFBBF24).toARGB32(),
      duration: 90,
    ),
    CalendarSeasonDraft(
      name: 'Deep Frost',
      iconKey: 'wind',
      colorValue: const Color(0xFF3B82F6).toARGB32(),
      duration: 180,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _worldNameController = TextEditingController(text: 'Aethelgard');
    _calendarNameController = TextEditingController(
      text: 'The High Solar Reach',
    );
    _totalDaysController = TextEditingController(text: '360');
    _dayNightRatioController = TextEditingController(text: '14/10');
    _autoBalance(notify: false);
  }

  @override
  void dispose() {
    _worldNameController.dispose();
    _calendarNameController.dispose();
    _totalDaysController.dispose();
    _dayNightRatioController.dispose();
    super.dispose();
  }

  void _autoBalance({bool notify = true}) {
    final days = int.tryParse(_totalDaysController.text);
    if (days == null || days <= 0) return;

    int monthCount = 12;
    if (days % 12 != 0) {
      if (days % 10 == 0) {
        monthCount = 10;
      } else if (days % 8 == 0) {
        monthCount = 8;
      } else if (days % 13 == 0) {
        monthCount = 13;
      }
    }

    final daysPerMonth = days ~/ monthCount;
    const monthNames = [
      'Primus',
      'Secundus',
      'Tertius',
      'Quartus',
      'Quintus',
      'Sextus',
      'Septimus',
      'Octavus',
      'Nonus',
      'Decimus',
      'Undecim',
      'Duodecim',
      'Tertiusdecimus',
    ];

    final months = List<CalendarMonthDraft>.generate(
      monthCount,
      (index) => CalendarMonthDraft(
        name: monthNames.length > index
            ? monthNames[index]
            : 'Month ${index + 1}',
        days: daysPerMonth,
      ),
    );

    final remainder = days % monthCount;
    if (remainder > 0) {
      months[months.length - 1].days += remainder;
    }

    int weekLength = 7;
    if (daysPerMonth % 6 == 0) {
      weekLength = 6;
    } else if (daysPerMonth % 8 == 0) {
      weekLength = 8;
    }

    const weekDayNames = [
      'Sunsday',
      'Moonday',
      'Ironsday',
      'Windsday',
      'Stone-day',
      'Starday',
      'Highday',
      'Void-day',
    ];

    final weekdays = weekDayNames.take(weekLength).toList();

    void apply() {
      _months = months;
      _weekDays = weekdays;
      _firstDayOfWeek = weekdays.first;
      _weekends
        ..clear()
        ..add(weekdays.last);
    }

    if (notify) {
      setState(apply);
    } else {
      apply();
    }
  }

  void _toggleWeekend(String day) {
    setState(() {
      if (_weekends.contains(day)) {
        _weekends.remove(day);
      } else {
        _weekends.add(day);
      }
    });
  }

  Future<void> _finish() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final worldName = _worldNameController.text.trim().isEmpty
        ? 'World'
        : _worldNameController.text.trim();
    final configuredSystemName = widget.initialName.trim().isEmpty
        ? '$worldName Chronology'
        : widget.initialName.trim();
    final calendarName = _calendarNameController.text.trim().isEmpty
        ? 'Main Calendar'
        : _calendarNameController.text.trim();

    final months = _months
        .where((month) => month.name.trim().isNotEmpty)
        .map(
          (month) => CalendarMonthSeed(
            name: month.name.trim(),
            days: month.days <= 0 ? 1 : month.days,
          ),
        )
        .toList();

    final weekDays = _weekDays
        .map((d) => d.trim())
        .where((d) => d.isNotEmpty)
        .toList();

    if (weekDays.isEmpty) {
      weekDays.addAll(const ['Sunsday', 'Moonday', 'Starday']);
    }

    if (!weekDays.contains(_firstDayOfWeek)) {
      _firstDayOfWeek = weekDays.first;
    }

    if (_weekends.isEmpty) {
      _weekends.add(weekDays.last);
    }

    final seasons = _seasons
        .where((s) => s.name.trim().isNotEmpty)
        .map(
          (s) => CalendarSeasonSeed(
            name: s.name.trim(),
            iconKey: s.iconKey,
            colorValue: s.colorValue,
            duration: s.duration <= 0 ? 1 : s.duration,
          ),
        )
        .toList();

    final totalDays =
        int.tryParse(_totalDaysController.text) ??
        months.fold<int>(0, (sum, month) => sum + month.days);

    final seed = CalendarSystemSeed(
      systemName: configuredSystemName,
      worldName: worldName,
      calendarName: calendarName,
      eras: _eras.map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      yearRegex: _yearRegex,
      totalDays: totalDays <= 0 ? 360 : totalDays,
      dayNightRatio: _dayNightRatioController.text.trim().isEmpty
          ? '12/12'
          : _dayNightRatioController.text.trim(),
      months: months,
      weekDays: weekDays,
      firstDayOfWeek: _firstDayOfWeek,
      weekends: _weekends.where(weekDays.contains).toList(),
      seasons: seasons,
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
                child: const Icon(LucideIcons.calendar, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chronos Initialization',
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
                            ? LucideIcons.check
                            : LucideIcons.arrowRight,
                        size: 16,
                      ),
                label: Text(
                  _step == _stepsMeta.length - 1
                      ? 'Construct Universe'
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _worldNameController,
              decoration: const InputDecoration(
                labelText: 'World Name',
                prefixIcon: Icon(LucideIcons.globe),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _calendarNameController,
              decoration: const InputDecoration(
                labelText: 'Calendar Name',
                prefixIcon: Icon(LucideIcons.calendar),
              ),
            ),
            const SizedBox(height: 14),
            _EditableStringList(
              title: 'Historical Eras',
              values: _eras,
              addLabel: 'Add Era',
              onAdd: () => setState(() => _eras.add('New Age')),
              onRemove: (index) => setState(() => _eras.removeAt(index)),
              onChanged: (index, value) => _eras[index] = value,
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _totalDaysController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Days per Year',
                      prefixIcon: Icon(LucideIcons.hash),
                    ),
                    onChanged: (_) => _autoBalance(),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _autoBalance,
                  icon: const Icon(LucideIcons.wandSparkles, size: 16),
                  label: const Text('Auto-balance'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dayNightRatioController,
              decoration: const InputDecoration(
                labelText: 'Day/Night Ratio',
                prefixIcon: Icon(LucideIcons.sunMoon),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Year Label Format',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _regexPresets
                  .map(
                    (preset) => ChoiceChip(
                      label: Text(preset.label),
                      selected: _yearRegex == preset.value,
                      onSelected: (_) =>
                          setState(() => _yearRegex = preset.value),
                    ),
                  )
                  .toList(),
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Months',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ..._months.asMap().entries.map((entry) {
              final index = entry.key;
              final month = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: ValueKey('month-name-$index-${month.name}'),
                        initialValue: month.name,
                        decoration: const InputDecoration(
                          isDense: true,
                          labelText: 'Name',
                          border: InputBorder.none,
                        ),
                        onChanged: (value) => month.name = value,
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      child: TextFormField(
                        key: ValueKey('month-days-$index-${month.days}'),
                        initialValue: '${month.days}',
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          isDense: true,
                          labelText: 'Days',
                          border: InputBorder.none,
                        ),
                        onChanged: (value) =>
                            month.days = int.tryParse(value) ?? 0,
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _months.removeAt(index)),
                      icon: const Icon(LucideIcons.x),
                    ),
                  ],
                ),
              );
            }),
            TextButton.icon(
              onPressed: () => setState(
                () => _months.add(
                  CalendarMonthDraft(name: 'New Month', days: 30),
                ),
              ),
              icon: const Icon(LucideIcons.plus),
              label: const Text('Add Month'),
            ),
            const Divider(height: 24),
            _EditableStringList(
              title: 'Days of the Week',
              values: _weekDays,
              addLabel: 'Add Day',
              onAdd: () => setState(() => _weekDays.add('Newday')),
              onRemove: (index) => setState(() => _weekDays.removeAt(index)),
              onChanged: (index, value) => _weekDays[index] = value,
            ),
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'First Day of Week',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _weekDays
                  .map(
                    (day) => ChoiceChip(
                      label: Text(day),
                      selected: _firstDayOfWeek == day,
                      onSelected: (_) => setState(() => _firstDayOfWeek = day),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            Text(
              'Weekend Days',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _weekDays
                  .map(
                    (day) => FilterChip(
                      label: Text(day),
                      selected: _weekends.contains(day),
                      onSelected: (_) => _toggleWeekend(day),
                    ),
                  )
                  .toList(),
            ),
          ],
        );
      case 4:
        return _buildSeasonsStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSeasonsStep() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final coverage = _seasons.fold<int>(
      0,
      (sum, season) => sum + season.duration,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Coverage: $coverage days',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        ..._seasons.asMap().entries.map((entry) {
          final index = entry.key;
          final season = entry.value;
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
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: ValueKey('season-name-$index-${season.name}'),
                        initialValue: season.name,
                        decoration: const InputDecoration(
                          isDense: true,
                          labelText: 'Season Name',
                        ),
                        onChanged: (value) => season.name = value,
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _seasons.removeAt(index)),
                      icon: const Icon(LucideIcons.trash2),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: season.iconKey,
                        decoration: const InputDecoration(
                          isDense: true,
                          labelText: 'Icon',
                        ),
                        items: _seasonIconOptions
                            .map(
                              (iconKey) => DropdownMenuItem(
                                value: iconKey,
                                child: Row(
                                  children: [
                                    Icon(
                                      calendarIconMap[iconKey] ??
                                          LucideIcons.wind,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(iconKey),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => season.iconKey = value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 100,
                      child: TextFormField(
                        key: ValueKey(
                          'season-duration-$index-${season.duration}',
                        ),
                        initialValue: '${season.duration}',
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          isDense: true,
                          labelText: 'Days',
                        ),
                        onChanged: (value) =>
                            season.duration = int.tryParse(value) ?? 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: calendarSeasonalColors.map((color) {
                    final selected = season.colorValue == color.toARGB32();
                    return InkWell(
                      onTap: () =>
                          setState(() => season.colorValue = color.toARGB32()),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        width: 22,
                        height: 22,
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
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: () => setState(
            () => _seasons.add(
              CalendarSeasonDraft(
                name: 'New Season',
                iconKey: 'wind',
                colorValue: const Color(0xFF64748B).toARGB32(),
                duration: 30,
              ),
            ),
          ),
          icon: const Icon(LucideIcons.plus),
          label: const Text('Add Season'),
        ),
      ],
    );
  }
}

class _EditableStringList extends StatelessWidget {
  final String title;
  final List<String> values;
  final String addLabel;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final void Function(int index, String value) onChanged;

  const _EditableStringList({
    required this.title,
    required this.values,
    required this.addLabel,
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
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ...values.asMap().entries.map((entry) {
          final index = entry.key;
          final value = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
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
                    key: ValueKey('$title-$index-$value'),
                    initialValue: value,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: title,
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
