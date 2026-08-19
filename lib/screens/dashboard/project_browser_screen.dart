import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lore_keeper/models/project.dart';
import 'package:lore_keeper/widgets/project_details_dialog.dart';
import 'package:lore_keeper/widgets/project_book/project_book.dart';
import 'package:lore_keeper/theme/app_colors.dart';

enum ProjectSort { nameAZ, nameZA, newest, oldest, lastModified }

class ProjectBrowserScreen extends StatefulWidget {
  const ProjectBrowserScreen({super.key});

  @override
  State<ProjectBrowserScreen> createState() => _ProjectBrowserScreenState();
}

class _ProjectBrowserScreenState extends State<ProjectBrowserScreen> {
  final TextEditingController _searchController = TextEditingController();

  /// Tracks the genre glow colour of whichever book is currently hovered,
  /// or null when nothing is hovered. Drives the screen-level ambient glow.
  final ValueNotifier<Color?> _hoveredGlowColor = ValueNotifier(null);

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
    _hoveredGlowColor.dispose();
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
      body: Stack(
        children: [
          // ── Screen-level ambient glow ────────────────────────────────────
          // Rendered at Scaffold level so it isn't clipped by GridView.
          // ImageFiltered blurs the circle itself (CSS `filter: blur()` equiv).
          Positioned.fill(
            child: IgnorePointer(
              child: ValueListenableBuilder<Color?>(
                valueListenable: _hoveredGlowColor,
                builder: (context, color, _) {
                  return AnimatedOpacity(
                    opacity: color != null ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 400),
                    child: Center(
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(
                          sigmaX: 120,
                          sigmaY: 120,
                          tileMode: TileMode.decal,
                        ),
                        child: Container(
                          width: 600,
                          height: 600,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (color ?? Colors.transparent).withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Main content ─────────────────────────────────────────────────
          Column(
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
                              LucideIcons.folderOpen,
                              size: 64,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withValues(alpha: 0.5),
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
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: 32,
                                crossAxisSpacing: 32,
                                childAspectRatio: 0.82,
                              ),
                          itemCount: projects.length,
                          itemBuilder: (context, index) {
                            final project = projects[index];

                            return ProjectBook(
                              project: project,
                              onHoverGlowChanged: (color) {
                                _hoveredGlowColor.value = color;
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
                prefixIcon: const Icon(LucideIcons.search, size: 20),
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
                icon: const Icon(LucideIcons.arrowUpDown, size: 20),
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
}
