import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lore_keeper/models/calendar_node.dart';
import 'package:lore_keeper/providers/calendar_tree_provider.dart';
import 'package:lore_keeper/utils/calendar_icons.dart';

class CalendarListPane extends StatefulWidget {
  final CalendarTreeProvider calendarProvider;
  final bool isMobile;

  const CalendarListPane({
    super.key,
    required this.calendarProvider,
    required this.isMobile,
  });

  @override
  State<CalendarListPane> createState() => _CalendarListPaneState();
}

class _CalendarListPaneState extends State<CalendarListPane> {
  late TextEditingController _filterController;
  bool _showFilter = false;

  @override
  void initState() {
    super.initState();
    _filterController = TextEditingController();
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  Future<void> _showCreateSystemDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Calendar System'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'System name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      await widget.calendarProvider.createSystem(result);
    }
  }

  Future<void> _confirmDeleteSystem(int systemKey) async {
    if (!widget.calendarProvider.canDeleteSelectedSystem) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          title: const Text('Delete Calendar System'),
          content: const Text('This will remove the entire chronology tree.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      await widget.calendarProvider.deleteSystem(systemKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: colorScheme.surface,
      child: ListenableBuilder(
        listenable: widget.calendarProvider,
        builder: (context, child) {
          if (!widget.calendarProvider.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          final systems = widget.calendarProvider.systems;
          final selectedSystem = widget.calendarProvider.selectedSystem;
          final filterText = _filterController.text;
          final nodes = widget.calendarProvider.getVisibleNodes(
            filter: filterText,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                child: Row(
                  children: [
                    Text(
                      'CALENDAR',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        _showFilter ? LucideIcons.searchX : LucideIcons.search,
                        size: 20,
                      ),
                      onPressed: () => setState(() {
                        _showFilter = !_showFilter;
                        if (!_showFilter) {
                          _filterController.clear();
                        }
                      }),
                      tooltip: 'Search Nodes',
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.circlePlus, size: 20),
                      onPressed: _showCreateSystemDialog,
                      tooltip: 'Create Calendar System',
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'System',
                          isDense: true,
                          filled: true,
                          fillColor: isDark
                              ? colorScheme.surfaceContainerHighest.withValues(
                                  alpha: 0.4,
                                )
                              : colorScheme.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: selectedSystem?.key as int?,
                            isDense: true,
                            items: systems
                                .map(
                                  (system) => DropdownMenuItem<int>(
                                    value: system.key as int?,
                                    child: Text(system.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                widget.calendarProvider.selectSystem(value);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: selectedSystem == null
                          ? null
                          : () =>
                                _confirmDeleteSystem(selectedSystem.key as int),
                      icon: const Icon(LucideIcons.trash2, size: 20),
                      tooltip: 'Delete System',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (_showFilter)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: TextField(
                    controller: _filterController,
                    autofocus: true,
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Filter by name...',
                      prefixIcon: const Icon(LucideIcons.listFilter, size: 18),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      fillColor: isDark
                          ? colorScheme.surfaceContainerHighest.withValues(
                              alpha: 0.5,
                            )
                          : colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: nodes.isEmpty
                    ? Center(
                        child: Text(
                          'No nodes found',
                          style: theme.textTheme.bodySmall,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: nodes.length,
                        itemBuilder: (context, index) {
                          final entry = nodes[index];
                          final node = entry.node;
                          final canSelect = widget.calendarProvider
                              .canSelectNode(node.id);
                          final canAddChild = widget.calendarProvider
                              .canAddChildToNode(node.id);
                          final canDelete = widget.calendarProvider
                              .canDeleteNode(node.id);
                          final isSelected =
                              widget.calendarProvider.selectedNode?.id ==
                              node.id;
                          return _CalendarTreeTile(
                            node: node,
                            level: entry.level,
                            isSelected: canSelect && isSelected,
                            isExpanded: widget.calendarProvider.isExpanded(
                              node.id,
                            ),
                            hasChildren: widget.calendarProvider.hasChildren(
                              node.id,
                            ),
                            onTap: () {
                              if (canSelect) {
                                widget.calendarProvider.selectNode(node.id);
                              } else if (widget.calendarProvider.hasChildren(
                                node.id,
                              )) {
                                widget.calendarProvider.toggleExpanded(node.id);
                              }
                            },
                            onToggle: () =>
                                widget.calendarProvider.toggleExpanded(node.id),
                            onAddChild: canAddChild
                                ? () {
                                    final type = widget.calendarProvider
                                        .inferChildType(node);
                                    widget.calendarProvider
                                        .addChildNodeToParent(node.id, type);
                                  }
                                : null,
                            onDelete: canDelete
                                ? () => widget.calendarProvider.deleteNode(
                                    node.id,
                                  )
                                : null,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CalendarTreeTile extends StatelessWidget {
  final CalendarNode node;
  final int level;
  final bool isSelected;
  final bool isExpanded;
  final bool hasChildren;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback? onAddChild;
  final VoidCallback? onDelete;

  const _CalendarTreeTile({
    required this.node,
    required this.level,
    required this.isSelected,
    required this.isExpanded,
    required this.hasChildren,
    required this.onTap,
    required this.onToggle,
    required this.onAddChild,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final iconData = calendarIconMap[node.iconKey] ?? LucideIcons.calendar;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              SizedBox(width: 8 + (level * 12)),
              if (hasChildren)
                IconButton(
                  onPressed: onToggle,
                  icon: Icon(
                    isExpanded
                        ? LucideIcons.chevronDown
                        : LucideIcons.chevronRight,
                    size: 18,
                  ),
                  tooltip: isExpanded ? 'Collapse' : 'Expand',
                )
              else
                const SizedBox(width: 40),
              Icon(
                iconData,
                size: 18,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  node.title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onAddChild != null)
                IconButton(
                  onPressed: onAddChild,
                  icon: const Icon(LucideIcons.plus, size: 18),
                  tooltip: 'Add Child',
                ),
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(LucideIcons.trash2, size: 18),
                  tooltip: 'Delete Node',
                ),
            ],
          ),
        ),
      ),
    );
  }
}
