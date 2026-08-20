import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lore_keeper/modules/calendar_module.dart';
import 'package:lore_keeper/modules/magic_module.dart';
import 'package:lore_keeper/modules/timeline_module.dart';
import 'package:lore_keeper/providers/calendar_tree_provider.dart';
import 'package:lore_keeper/providers/character_list_provider.dart';
import 'package:lore_keeper/providers/magic_tree_provider.dart';
import 'package:lore_keeper/providers/timeline_event_provider.dart';

/// World Building module — consolidates lore domains as internal tabs.
class WorldBuildingTabs extends StatefulWidget {
  final CalendarTreeProvider calendarProvider;
  final MagicTreeProvider magicProvider;
  final TimelineEventProvider timelineProvider;
  final CharacterListProvider characterProvider;

  /// Current tab index (controlled mode). If provided, the widget uses this index.
  final int? initialTabIndex;
  /// Callback when the user switches tabs.
  final ValueChanged<int>? onTabChanged;

  const WorldBuildingTabs({
    super.key,
    required this.calendarProvider,
    required this.magicProvider,
    required this.timelineProvider,
    required this.characterProvider,
    this.initialTabIndex,
    this.onTabChanged,
  });

  @override
  State<WorldBuildingTabs> createState() => _WorldBuildingTabsState();
}

class _WorldBuildingTabsState extends State<WorldBuildingTabs>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    _WorldTab(label: 'Magic', icon: LucideIcons.sparkles, index: 0),
    _WorldTab(label: 'Timelines', icon: LucideIcons.chartLine, index: 1),
    _WorldTab(label: 'Calendars', icon: LucideIcons.calendar, index: 2),
    _WorldTab(label: 'Species', icon: LucideIcons.pawPrint, index: 3),
    _WorldTab(label: 'Locations', icon: LucideIcons.mapPin, index: 4),
    _WorldTab(label: 'Languages', icon: LucideIcons.languages, index: 5),
    _WorldTab(label: 'Items', icon: LucideIcons.tag, index: 6),
    _WorldTab(label: 'Cultures', icon: LucideIcons.usersRound, index: 7),
    _WorldTab(label: 'Philosophies', icon: LucideIcons.brain, index: 8),
    _WorldTab(label: 'Religions', icon: LucideIcons.church, index: 9),
    _WorldTab(label: 'Systems', icon: LucideIcons.chartNetwork, index: 10),
    _WorldTab(label: 'Research', icon: LucideIcons.flaskConical, index: 11),
    _WorldTab(label: 'Arcs', icon: LucideIcons.chartLine, index: 12),
    _WorldTab(label: 'Relationships', icon: LucideIcons.link, index: 13),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: widget.initialTabIndex ?? 0,
    );
    _tabController.addListener(_onTabControllerChanged);
  }

  void _onTabControllerChanged() {
    if (!_tabController.indexIsChanging) {
      widget.onTabChanged?.call(_tabController.index);
    }
  }

  @override
  void didUpdateWidget(covariant WorldBuildingTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTabIndex != null &&
        widget.initialTabIndex != oldWidget.initialTabIndex &&
        widget.initialTabIndex != _tabController.index) {
      _tabController.animateTo(widget.initialTabIndex!);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabControllerChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          color: colorScheme.surfaceContainer,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            dividerColor: Colors.transparent,
            indicatorColor: colorScheme.primary,
            indicatorWeight: 3,
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            tabs: _tabs
                .map(
                  (tab) => Tab(icon: Icon(tab.icon, size: 18), text: tab.label),
                )
                .toList(),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: _tabs.map((tab) => _buildTabContent(tab.index)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent(int index) {
    switch (index) {
      case 0:
        return MagicModule(magicProvider: widget.magicProvider);
      case 1:
        return TimelineModule(
          calendarProvider: widget.calendarProvider,
          eventProvider: widget.timelineProvider,
          characterProvider: widget.characterProvider,
        );
      case 2:
        return CalendarModule(calendarProvider: widget.calendarProvider);
      default:
        return _PlaceholderTab(
          label: _tabs[index].label,
          icon: _tabs[index].icon,
        );
    }
  }
}

class _WorldTab {
  final String label;
  final IconData icon;
  final int index;

  const _WorldTab({
    required this.label,
    required this.icon,
    required this.index,
  });
}

class _PlaceholderTab extends StatelessWidget {
  final String label;
  final IconData icon;

  const _PlaceholderTab({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming soon — will be implemented in Phase 4',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
