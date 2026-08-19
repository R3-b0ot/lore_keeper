import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lore_keeper/models/project.dart';
import 'package:lore_keeper/widgets/project_details_dialog.dart';
import 'package:lore_keeper/widgets/project_book/project_book.dart';

class ProjectRecentGrid extends StatelessWidget {
  const ProjectRecentGrid({super.key});

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
                return ProjectBook(
                  project: project,
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
