import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lore_keeper/models/project.dart';
import 'package:lore_keeper/models/chapter.dart';
import 'package:lore_keeper/screens/project_editor_screen.dart';
import 'package:lore_keeper/screens/dashboard/widgets/project_recent_grid.dart'; // Reuse ProjectCard
import 'package:lore_keeper/widgets/project_details_dialog.dart';
import 'package:lore_keeper/theme/app_colors.dart';

enum ProjectSort { nameAZ, nameZA, newest, oldest, lastModified }

class ProjectBrowserScreen extends StatefulWidget {
  const ProjectBrowserScreen({super.key});

  @override
  State<ProjectBrowserScreen> createState() => _ProjectBrowserScreenState();
}

class _ProjectBrowserScreenState extends State<ProjectBrowserScreen> {
  final TextEditingController _searchController = TextEditingController();
  ProjectSort _sortBy = ProjectSort.lastModified;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Project Browser'),
        backgroundColor: isDark
            ? AppColors.bgMain
            : Theme.of(context).colorScheme.surfaceContainer,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        shape: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildFilterBar(isDark),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: Hive.box<Project>('projects').listenable(),
              builder: (context, Box<Project> box, _) {
                final query = _searchController.text.toLowerCase();
                var projects = box.values.where((p) {
                  final title = p.title.toLowerCase();
                  final desc = (p.description ?? '').toLowerCase();
                  return title.contains(query) || desc.contains(query);
                }).toList();

                // Apply Sorting
                projects.sort((a, b) {
                  switch (_sortBy) {
                    case ProjectSort.nameAZ:
                      return a.title.toLowerCase().compareTo(
                        b.title.toLowerCase(),
                      );
                    case ProjectSort.nameZA:
                      return b.title.toLowerCase().compareTo(
                        a.title.toLowerCase(),
                      );
                    case ProjectSort.newest:
                      return b.createdAt.compareTo(a.createdAt);
                    case ProjectSort.oldest:
                      return a.createdAt.compareTo(b.createdAt);
                    case ProjectSort.lastModified:
                      final aDate = a.lastModified ?? a.createdAt;
                      final bDate = b.lastModified ?? b.createdAt;
                      return bDate.compareTo(aDate);
                  }
                });

                if (projects.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open_outlined,
                          size: 64,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          query.isEmpty
                              ? 'Your library is empty.'
                              : 'No projects match your search.',
                          style: TextStyle(
                            fontSize: 18,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final double width = constraints.maxWidth;
                    int crossAxisCount = (width / 260).floor();
                    if (crossAxisCount < 1) crossAxisCount = 1;

                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 24,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 32,
                        crossAxisSpacing: 32,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: projects.length,
                      itemBuilder: (context, index) {
                        final project = projects[index];
                        final genre = project.genre ?? 'General';

                        return ProjectCard(
                          title: project.title,
                          tag: genre,
                          wordCount: '${_getProjectWordCount(project)} words',
                          time: _formatDate(
                            project.lastModified ?? project.createdAt,
                          ),
                          gradientColors: _getGenreColor(genre),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProjectEditorScreen(project: project),
                              ),
                            );
                          },
                          onEditTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProjectEditorScreen(project: project),
                              ),
                            );
                          },
                          onSettingsTap: () {
                            showDialog(
                              context: context,
                              builder: (context) =>
                                  ProjectDetailsDialog(project: project),
                            );
                          },
                          onDeleteTap: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Project?'),
                                content: Text(
                                  'Are you sure you want to delete "${project.title}"? This cannot be undone.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                      foregroundColor: Theme.of(
                                        context,
                                      ).colorScheme.onError,
                                    ),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed == true) {
                              await project.delete();
                            }
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.2)
            : Colors.grey.withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          // Search Box
          Expanded(
            flex: 2,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search projects...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.1),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          const SizedBox(width: 24),
          // Sort Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ProjectSort>(
                value: _sortBy,
                icon: const Icon(Icons.sort, size: 20),
                onChanged: (ProjectSort? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _sortBy = newValue;
                    });
                  }
                },
                items: [
                  const DropdownMenuItem(
                    value: ProjectSort.lastModified,
                    child: Text('Recently Modified'),
                  ),
                  const DropdownMenuItem(
                    value: ProjectSort.newest,
                    child: Text('Newest First'),
                  ),
                  const DropdownMenuItem(
                    value: ProjectSort.oldest,
                    child: Text('Oldest First'),
                  ),
                  const DropdownMenuItem(
                    value: ProjectSort.nameAZ,
                    child: Text('Name (A-Z)'),
                  ),
                  const DropdownMenuItem(
                    value: ProjectSort.nameZA,
                    child: Text('Name (Z-A)'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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
}
