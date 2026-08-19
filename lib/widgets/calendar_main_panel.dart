import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lore_keeper/models/calendar_node.dart';
import 'package:lore_keeper/providers/calendar_tree_provider.dart';
import 'package:lore_keeper/theme/app_colors.dart';
import 'package:lore_keeper/utils/calendar_icons.dart';
import 'package:lore_keeper/utils/calendar_type_specs.dart';
import 'package:lore_keeper/widgets/responsive_layout.dart';

class CalendarMainPanel extends StatelessWidget {
  final CalendarTreeProvider provider;

  const CalendarMainPanel({super.key, required this.provider});

  static List<String> _typeOptions() => calendarTypeKeysForDropdown();
  static const Set<String> _nonEditableTypes = {'chronos_system'};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final panelColor = isDark ? AppColors.bgPanel : AppColors.bgPanelLight;
    final panelLighter = isDark
        ? AppColors.bgPanelLighter
        : AppColors.bgPanelLighterLight;
    final node = provider.selectedNode;

    if (node == null) {
      return Center(
        child: Text(
          'Select an entry from the list',
          style: theme.textTheme.bodySmall,
        ),
      );
    }

    if (_nonEditableTypes.contains(node.type)) {
      return Container(
        color: isDark ? AppColors.bgMain : AppColors.bgMainLight,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Select an editable node to continue.',
            style: theme.textTheme.bodySmall,
          ),
        ),
      );
    }

    return Container(
      color: isDark ? AppColors.bgMain : AppColors.bgMainLight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < AppBreakpoints.medium;
          final content = Column(
            children: [
              _CalendarPanelCard(
                title: 'Visual Evidence',
                panelColor: panelColor,
                panelLighter: panelLighter,
                child: AspectRatio(
                  aspectRatio: compact ? 16 / 9 : 21 / 9,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: panelLighter,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      'Image generation can be plugged in here',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _ContentCard(
                node: node,
                provider: provider,
                panelColor: panelColor,
                panelLighter: panelLighter,
              ),
            ],
          );

          Widget inner;
          if (compact) {
            inner = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                content,
                const SizedBox(height: 16),
                _AttributesCard(
                  node: node,
                  provider: provider,
                  panelColor: panelColor,
                  panelLighter: panelLighter,
                ),
              ],
            );
          } else {
            inner = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: content),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: _AttributesCard(
                    node: node,
                    provider: provider,
                    panelColor: panelColor,
                    panelLighter: panelLighter,
                  ),
                ),
              ],
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HeaderRow(
                  node: node,
                  provider: provider,
                  panelLighter: panelLighter,
                ),
                const SizedBox(height: 16),
                inner,
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final CalendarNode node;
  final CalendarTreeProvider provider;
  final Color panelLighter;

  const _HeaderRow({
    required this.node,
    required this.provider,
    required this.panelLighter,
  });

  static const List<Color> _palette = [
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFFF43F5E),
    Color(0xFFFB923C),
    Color(0xFF64748B),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final iconData = calendarIconMap[node.iconKey] ?? LucideIcons.calendar;
    final isRoot = provider.selectedSystem?.rootNodeId == node.id;

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        PopupMenuButton<String>(
          tooltip: 'Change Icon',
          position: PopupMenuPosition.under,
          offset: const Offset(0, 8),
          onSelected: (selected) => provider.updateNodeIcon(node.id, selected),
          itemBuilder: (context) => calendarIconCategories
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
                                onPressed: () =>
                                    Navigator.of(context).pop(iconKey),
                                icon: Icon(
                                  calendarIconMap[iconKey] ??
                                      LucideIcons.calendar,
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
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: panelLighter,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            child: Icon(iconData, color: Color(node.colorValue), size: 28),
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 220, maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DropdownButton<String>(
                    value: node.type,
                    items: CalendarMainPanel._typeOptions()
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(calendarSpecForType(type).label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        provider.updateNodeType(node.id, value);
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  PopupMenuButton<Color>(
                    tooltip: 'Change Color',
                    position: PopupMenuPosition.under,
                    offset: const Offset(0, 8),
                    onSelected: (color) =>
                        provider.updateNodeColor(node.id, color),
                    itemBuilder: (context) => _palette
                        .map(
                          (color) => PopupMenuItem<Color>(
                            value: color,
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outlineVariant,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '#${color.toARGB32().toRadixString(16).toUpperCase()}',
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Color(node.colorValue),
                        shape: BoxShape.circle,
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                    ),
                  ),
                ],
              ),
              TextFormField(
                key: ValueKey('calendar-title-${node.id}'),
                initialValue: node.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                ),
                onChanged: (value) => provider.updateNodeTitle(node.id, value),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        if (!isRoot && provider.canDeleteNode(node.id))
          IconButton(
            onPressed: () => provider.deleteNode(node.id),
            icon: const Icon(LucideIcons.trash2),
            tooltip: 'Delete',
          ),
      ],
    );
  }
}

class _ContentCard extends StatelessWidget {
  final CalendarNode node;
  final CalendarTreeProvider provider;
  final Color panelColor;
  final Color panelLighter;

  const _ContentCard({
    required this.node,
    required this.provider,
    required this.panelColor,
    required this.panelLighter,
  });

  @override
  Widget build(BuildContext context) {
    return _CalendarPanelCard(
      title: 'Mythic Description',
      panelColor: panelColor,
      panelLighter: panelLighter,
      child: TextFormField(
        key: ValueKey('calendar-content-${node.id}'),
        initialValue: node.content,
        minLines: 14,
        maxLines: null,
        decoration: const InputDecoration(
          hintText:
              'Detail the cultural significance, myths, and observances here...',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) => provider.updateNodeContent(node.id, value),
      ),
    );
  }
}

class _AttributesCard extends StatelessWidget {
  final CalendarNode node;
  final CalendarTreeProvider provider;
  final Color panelColor;
  final Color panelLighter;

  const _AttributesCard({
    required this.node,
    required this.provider,
    required this.panelColor,
    required this.panelLighter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _CalendarPanelCard(
      title: 'Properties',
      panelColor: panelColor,
      panelLighter: panelLighter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...node.attributes.asMap().entries.map((entry) {
            final index = entry.key;
            final attr = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          key: ValueKey(
                            'calendar-attr-label-${node.id}-$index',
                          ),
                          initialValue: attr.label,
                          decoration: const InputDecoration(
                            isDense: true,
                            labelText: 'Name',
                          ),
                          onChanged: (value) => provider.updateAttribute(
                            node.id,
                            index,
                            label: value,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          key: ValueKey(
                            'calendar-attr-value-${node.id}-$index',
                          ),
                          initialValue: attr.value,
                          decoration: const InputDecoration(
                            isDense: true,
                            labelText: 'Value',
                          ),
                          onChanged: (value) => provider.updateAttribute(
                            node.id,
                            index,
                            value: value,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: () => provider.deleteAttribute(node.id, index),
                    icon: const Icon(LucideIcons.trash2, size: 16),
                    tooltip: 'Delete Property',
                  ),
                ],
              ),
            );
          }),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => provider.addAttribute(node.id),
              icon: const Icon(LucideIcons.plus),
              label: Text('Add Property', style: theme.textTheme.labelLarge),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarPanelCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Color panelColor;
  final Color panelLighter;

  const _CalendarPanelCard({
    required this.title,
    required this.child,
    required this.panelColor,
    required this.panelLighter,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
