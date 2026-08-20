import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lore_keeper/models/timeline_event.dart';
import 'package:lore_keeper/providers/calendar_tree_provider.dart';
import 'package:lore_keeper/providers/timeline_event_provider.dart';

/// Event list pane for the Timelines tab second column.
/// Mirrors the CalendarListPane/MagicListPane pattern.
class TimelineListPane extends StatefulWidget {
  final CalendarTreeProvider calendarProvider;
  final TimelineEventProvider eventProvider;
  final bool isMobile;

  const TimelineListPane({
    super.key,
    required this.calendarProvider,
    required this.eventProvider,
    required this.isMobile,
  });

  @override
  State<TimelineListPane> createState() => _TimelineListPaneState();
}

class _TimelineListPaneState extends State<TimelineListPane> {
  late TextEditingController _filterController;

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

  void _selectSystem(int key) {
    widget.calendarProvider.selectSystem(key);
    widget.eventProvider.setSelectedSystemKey(key);
  }

  Future<void> _deleteEvent(String eventId) async {
    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Remove this event from the timeline?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await widget.eventProvider.deleteEvent(eventId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surface,
      child: ListenableBuilder(
        listenable: widget.calendarProvider,
        builder: (context, child) {
          if (!widget.calendarProvider.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          final systems = widget.calendarProvider.systems
              .where((s) => s.isConfigured)
              .toList();
          final selectedSystem = widget.calendarProvider.selectedSystem;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: systems.isEmpty
                          ? Text(
                              'No calendars configured',
                              style: theme.textTheme.bodySmall,
                            )
                          : DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: selectedSystem?.key as int?,
                                isDense: true,
                                isExpanded: true,
                                hint: const Text('Select calendar'),
                                items: systems
                                    .map(
                                      (s) => DropdownMenuItem<int>(
                                        value: s.key as int?,
                                        child: Text(s.name),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    _selectSystem(value);
                                  }
                                },
                              ),
                            ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: selectedSystem == null
                          ? null
                          : () => _selectSystem(selectedSystem.key as int),
                      icon: const Icon(LucideIcons.refreshCw, size: 18),
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _EventList(
                  eventProvider: widget.eventProvider,
                  filter: _filterController.text.trim().toLowerCase(),
                  onDeleteEvent: _deleteEvent,
                  theme: theme,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EventList extends StatelessWidget {
  final TimelineEventProvider eventProvider;
  final String filter;
  final Future<void> Function(String) onDeleteEvent;
  final ThemeData theme;

  const _EventList({
    required this.eventProvider,
    required this.filter,
    required this.onDeleteEvent,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: eventProvider,
      builder: (context, child) {
        final events = eventProvider.filteredEvents;
        final filtered = filter.isEmpty
            ? events
            : events
                .where((e) =>
                    e.name.toLowerCase().contains(filter) ||
                    e.lore.toLowerCase().contains(filter))
                .toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.calendarDays,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 12),
                Text(
                  filter.isEmpty ? 'No events for selected calendar' : 'No matching events',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final event = filtered[index];
            return _EventTile(
              event: event,
              onDelete: () => onDeleteEvent(event.id),
              theme: theme,
            );
          },
        );
      },
    );
  }
}

class _EventTile extends StatelessWidget {
  final TimelineEvent event;
  final VoidCallback onDelete;
  final ThemeData theme;

  const _EventTile({
    required this.event,
    required this.onDelete,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(event.colorValue);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                LucideIcons.calendar,
                size: 16,
                color: color,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Year ${event.absoluteYear}, Day ${event.absoluteDayOfYear}',
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(LucideIcons.trash2, size: 16),
              tooltip: 'Delete event',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}