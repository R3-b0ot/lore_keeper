import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lore_keeper/models/timeline_event.dart';
import 'package:lore_keeper/providers/calendar_tree_provider.dart';
import 'package:lore_keeper/providers/timeline_event_provider.dart';
import 'package:lore_keeper/utils/calendar_chronology.dart';

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

  void _selectSystem(int key) {
    widget.calendarProvider.selectSystem(key);
    widget.eventProvider.setSelectedSystemKey(key);
  }

  /// Creates a new event through the standard provider, anchored mid-year of
  /// the selected calendar system, then selects it so the canvas editor opens.
  Future<void> _createEvent(int systemKey) async {
    final chronology = CalendarChronology.fromProvider(
      widget.calendarProvider,
      systemKey,
    );
    final id = await widget.eventProvider.createEvent(
      name: 'New Event',
      absoluteYear: 1,
      absoluteDayOfYear: (chronology.daysInYear / 2).round().clamp(
        1,
        chronology.daysInYear,
      ),
      iconKey: 'star',
      colorValue: 0xFF6366F1,
      calendarSystemKey: systemKey,
    );
    widget.eventProvider.selectEvent(id);
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
    final isDark = theme.brightness == Brightness.dark;

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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                child: Row(
                  children: [
                    Text(
                      'TIMELINE',
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
                      tooltip: 'Search Events',
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.circlePlus, size: 20),
                      onPressed: selectedSystem == null
                          ? null
                          : () => _createEvent(selectedSystem.key as int),
                      tooltip: 'New Event',
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
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: selectedSystem == null
                          ? null
                          : () => _selectSystem(selectedSystem.key as int),
                      icon: const Icon(LucideIcons.refreshCw, size: 20),
                      tooltip: 'Refresh',
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
                      hintText: 'Filter by name or lore...',
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
                  .where(
                    (e) =>
                        e.name.toLowerCase().contains(filter) ||
                        e.lore.toLowerCase().contains(filter),
                  )
                  .toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.calendarDays,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  filter.isEmpty
                      ? 'No events for selected calendar'
                      : 'No matching events',
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
              isSelected: eventProvider.selectedEventId == event.id,
              onSelect: () => eventProvider.selectEvent(event.id),
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
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onDelete;
  final ThemeData theme;

  const _EventTile({
    required this.event,
    required this.isSelected,
    required this.onSelect,
    required this.onDelete,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    final color = Color(event.colorValue);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.surface
                      : color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(LucideIcons.calendar, size: 16, color: color),
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
                        color: isSelected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Year ${event.absoluteYear}, Day ${event.absoluteDayOfYear}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isSelected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                      ),
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
      ),
    );
  }
}
