import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lore_keeper/models/project.dart';
import 'package:lore_keeper/providers/chapter_list_provider.dart';
import 'package:lore_keeper/providers/character_list_provider.dart';
import 'package:lore_keeper/providers/magic_tree_provider.dart';
import 'package:lore_keeper/providers/calendar_tree_provider.dart';
import 'package:lore_keeper/providers/timeline_event_provider.dart';
import 'package:lore_keeper/widgets/project_editor/project_editor_module_item.dart';

/// Overview module — default landing after book-open transition.
/// Shows project title, genre/author, last edited, basic stats, recent
/// manuscripts, and quick links to other top-level sections.
class OverviewModule extends StatelessWidget {
  final Project project;
  final ChapterListProvider chapterProvider;
  final CharacterListProvider characterProvider;
  final MagicTreeProvider magicProvider;
  final CalendarTreeProvider calendarProvider;
  final TimelineEventProvider timelineProvider;
  final ValueChanged<ProjectEditorModuleItem> onNavigate;

  const OverviewModule({
    super.key,
    required this.project,
    required this.chapterProvider,
    required this.characterProvider,
    required this.magicProvider,
    required this.calendarProvider,
    required this.timelineProvider,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final wordCount = _estimateWordCount();
    final characterCount = characterProvider.characters.length;
    final locationCount = _estimateLocationCount();
    final eventCount = timelineProvider.events.length;
    final magicSystemCount = magicProvider.systems.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProjectHeader(
            project: project,
            lastEdited: _formatDate(project.lastModified ?? project.createdAt),
          ),
          const SizedBox(height: 32),
          _StatsGrid(
            wordCount: wordCount,
            characterCount: characterCount,
            locationCount: locationCount,
            eventCount: eventCount,
            magicSystemCount: magicSystemCount,
          ),
          const SizedBox(height: 32),
          _QuickNavGrid(onNavigate: onNavigate),
          const SizedBox(height: 32),
          _RecentManuscripts(
            chapters: chapterProvider.chapters,
            selectedKey: '',
          ),
        ],
      ),
    );
  }

  int _estimateWordCount() => chapterProvider.chapters.length * 500;

  int _estimateLocationCount() => 0;

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${date.month}/${date.day}/${date.year}';
  }
}

// ─── Project header ───────────────────────────────────────────────────────────

class _ProjectHeader extends StatelessWidget {
  final Project project;
  final String lastEdited;

  const _ProjectHeader({required this.project, required this.lastEdited});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          project.title,
          style: textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        if (project.genre != null || project.authors != null)
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              if (project.genre != null)
                _InfoChip(icon: LucideIcons.tag, label: project.genre!),
              if (project.authors != null)
                _InfoChip(icon: LucideIcons.user, label: project.authors!),
            ],
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(
              LucideIcons.clock,
              size: 14,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              'Last edited $lastEdited',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Info chip ────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stats grid ───────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final int wordCount;
  final int characterCount;
  final int locationCount;
  final int eventCount;
  final int magicSystemCount;

  const _StatsGrid({
    required this.wordCount,
    required this.characterCount,
    required this.locationCount,
    required this.eventCount,
    required this.magicSystemCount,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatItem(
        icon: LucideIcons.fileText,
        label: 'Words',
        value: _formatNumber(wordCount),
      ),
      _StatItem(
        icon: LucideIcons.users,
        label: 'Characters',
        value: characterCount.toString(),
      ),
      _StatItem(
        icon: LucideIcons.mapPin,
        label: 'Locations',
        value: locationCount.toString(),
      ),
      _StatItem(
        icon: LucideIcons.calendarClock,
        label: 'Timeline Events',
        value: eventCount.toString(),
      ),
      _StatItem(
        icon: LucideIcons.sparkles,
        label: 'Magic Systems',
        value: magicSystemCount.toString(),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 900
            ? 5
            : constraints.maxWidth > 600
            ? 3
            : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: 2.4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) => _StatCard(stat: stats[index]),
        );
      },
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _StatItem {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _StatCard extends StatelessWidget {
  final _StatItem stat;

  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(stat.icon, size: 22, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  stat.label,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            stat.value,
            textAlign: TextAlign.center,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick navigation ─────────────────────────────────────────────────────────

class _QuickNavGrid extends StatelessWidget {
  final ValueChanged<ProjectEditorModuleItem> onNavigate;

  const _QuickNavGrid({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final destinations = [
      (
        label: 'Manuscripts',
        sub: 'Write & organize chapters',
        icon: LucideIcons.bookOpen,
      ),
      (
        label: 'Characters',
        sub: 'Manage character profiles',
        icon: LucideIcons.users,
      ),
      (
        label: 'World Building',
        sub: 'Magic, Timeline, Calendar & more',
        icon: LucideIcons.globe,
      ),
      (
        label: 'Lore Map',
        sub: 'Connectivity graph (coming soon)',
        icon: LucideIcons.map,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Navigation',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 350 ? 4 : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                childAspectRatio: 2.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: destinations.length,
              itemBuilder: (context, index) {
                final dest = destinations[index];
                return _NavCard(
                  label: dest.label,
                  subtitle: dest.sub,
                  icon: dest.icon,
                  onTap: () => onNavigate(
                    ProjectEditorModuleItem(label: dest.label, icon: dest.icon),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _NavCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _NavCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Recent manuscripts ───────────────────────────────────────────────────────

class _RecentManuscripts extends StatelessWidget {
  final List<dynamic> chapters;
  final String selectedKey;

  const _RecentManuscripts({required this.chapters, required this.selectedKey});

  @override
  Widget build(BuildContext context) {
    if (chapters.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final recent = chapters.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Manuscripts',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recent.length,
          separatorBuilder: (_, _) => Divider(
            height: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          ),
          itemBuilder: (context, index) {
            final chapter = recent[index];
            final isSelected = chapter.key.toString() == selectedKey;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                isSelected ? LucideIcons.bookOpen : LucideIcons.book,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              title: Text(
                chapter.title ?? 'Untitled',
                style: textTheme.bodyLarge?.copyWith(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              trailing: isSelected
                  ? Icon(LucideIcons.chevronRight, color: colorScheme.primary)
                  : null,
              onTap: () {
                // Wire to manuscript navigation in ProjectEditorScreen if needed.
              },
            );
          },
        ),
      ],
    );
  }
}
