import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lore_keeper/models/project.dart';
import 'package:lore_keeper/models/chapter.dart';
import 'package:lore_keeper/widgets/project_details_dialog.dart';
import 'package:lore_keeper/theme/app_colors.dart';

class ProjectRecentGrid extends StatelessWidget {
  final void Function(Project project) onProjectTap;

  const ProjectRecentGrid({super.key, required this.onProjectTap});

  int _getProjectWordCount(Project project) {
    if (!Hive.isBoxOpen('chapters')) return 0;
    final chapters = Hive.box<Chapter>('chapters').values
        .where((chapter) => chapter.parentProjectId == project.key)
        .toList();
    int totalWords = 0;
    for (final chapter in chapters) {
      if (chapter.richTextJson != null) {
        final text = chapter.richTextJson!
            .replaceAll(RegExp(r'<[^>]*>'), '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        if (text.isNotEmpty) {
          totalWords += text.split(' ').where((word) => word.isNotEmpty).length;
        }
      }
    }
    return totalWords;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${date.month}/${date.day}/${date.year}';
  }

  List<Color> _getGenreColor(String genre) {
    switch (genre.toLowerCase()) {
      case 'fantasy':
        return [const Color(0xFF1e1b4b), const Color(0xFF4338ca)];
      case 'horror':
        return [const Color(0xFF450a0a), const Color(0xFF991b1b)];
      case 'sci-fi':
        return [const Color(0xFF064e3b), const Color(0xFF059669)];
      case 'mystery':
        return [const Color(0xFF4c1d95), const Color(0xFF7c3aed)];
      default:
        return [const Color(0xFF1e293b), const Color(0xFF334155)];
    }
  }

  Future<void> _confirmDeleteProject(
    BuildContext context,
    Project project,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project?'),
        content: Text(
          'Are you sure you want to delete "${project.title}"? This cannot be undone.',
        ),
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

    if (confirmed == true) {
      await project.delete();
    }
  }

  void _showEditProjectDialog(BuildContext context, Project project) {
    showDialog(
      context: context,
      builder: (context) => ProjectDetailsDialog(project: project),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Project>('projects').listenable(),
      builder: (context, Box<Project> box, _) {
        final projects = box.values.toList();
        projects.sort((a, b) {
          final aDate = a.lastModified ?? a.createdAt;
          final bDate = b.lastModified ?? b.createdAt;
          return bDate.compareTo(aDate);
        });
        final recentProjects = projects.take(4).toList();
        if (recentProjects.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    LucideIcons.bookOpen,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No recent manuscripts found.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            int crossAxisCount = (width / 260).floor();
            if (crossAxisCount < 1) crossAxisCount = 1;
            if (crossAxisCount > 4) crossAxisCount = 4;

            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 24,
                crossAxisSpacing: 24,
                childAspectRatio: 0.85,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentProjects.length,
              itemBuilder: (context, index) {
                final project = recentProjects[index];
                final genre = project.genre ?? 'General';
                final wordCount = _getProjectWordCount(project);
                final time = _formatDate(
                  project.lastModified ?? project.createdAt,
                );
                final gradientColors = _getGenreColor(genre);

                return ProjectCard(
                  title: project.title,
                  tag: genre,
                  wordCount: '$wordCount words',
                  time: time,
                  gradientColors: gradientColors,
                  onTap: () => onProjectTap(project),
                  onEditTap: () => onProjectTap(project),
                  onSettingsTap: () => _showEditProjectDialog(context, project),
                  onDeleteTap: () => _confirmDeleteProject(context, project),
                );
              },
            );
          },
        );
      },
    );
  }
}

class ProjectCard extends StatefulWidget {
  final String title;
  final String tag;
  final String wordCount;
  final String time;
  final List<Color> gradientColors;
  final VoidCallback? onTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onEditTap;
  final VoidCallback? onDeleteTap;

  const ProjectCard({
    super.key,
    required this.title,
    required this.tag,
    required this.wordCount,
    required this.time,
    required this.gradientColors,
    this.onTap,
    this.onSettingsTap,
    this.onEditTap,
    this.onDeleteTap,
  });

  @override
  State<ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<ProjectCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          transform: _isHovered
              ? Matrix4.translationValues(0.0, -8.0, 0.0)
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgPanel : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                  : Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.1),
              width: _isHovered ? 2 : 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      offset: const Offset(0, 10),
                      blurRadius: 20,
                      spreadRadius: -5,
                    ),
                  ]
                : [],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cover Representation
              Expanded(
                flex: 12,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.gradientColors,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Tag
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            widget.tag.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      // Decorative Element
                      Center(
                        child: Icon(
                          LucideIcons.bookOpen,
                          color: Colors.white.withValues(alpha: 0.15),
                          size: 64,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Content
              Expanded(
                flex: 10,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.penLine,
                            size: 14,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.wordCount,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            widget.time,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildCardAction(
                            icon: LucideIcons.settings,
                            onTap: widget.onSettingsTap,
                            tooltip: 'Settings',
                          ),
                          const SizedBox(width: 8),
                          _buildCardAction(
                            icon: LucideIcons.externalLink,
                            onTap: widget.onTap,
                            tooltip: 'Open',
                            isPrimary: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardAction({
    required IconData icon,
    required VoidCallback? onTap,
    required String tooltip,
    bool isPrimary = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isPrimary
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isPrimary
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                  : Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isPrimary
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
