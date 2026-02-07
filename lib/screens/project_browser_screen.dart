import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lore_keeper/models/project.dart';
import 'package:lore_keeper/models/chapter.dart';
import 'package:lore_keeper/models/character.dart';
import 'package:lore_keeper/theme/app_colors.dart';
import 'package:lore_keeper/screens/project_editor_screen.dart';

class ProjectBrowserScreen extends StatelessWidget {
  const ProjectBrowserScreen({super.key});

  int _getProjectWordCount(Project project) {
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
        totalWords += text.split(' ').where((word) => word.isNotEmpty).length;
      }
    }
    return totalWords;
  }

  int _getProjectCharacterCount(Project project) {
    return Hive.box<Character>('characters').values
        .where((character) => character.parentProjectId == project.key)
        .length;
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

  void _openProject(BuildContext context, Project project) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProjectEditorScreen(project: project),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgMain,
      appBar: AppBar(
        backgroundColor: AppColors.bgMain,
        elevation: 0,
        title: Text(
          'Project Browser',
          style: TextStyle(
            fontFamily: 'Inter',
            color: AppColors.textMain,
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textMain),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Project>('projects').listenable(),
        builder: (context, Box<Project> box, _) {
          final projects = box.values.toList();
          if (projects.isEmpty) {
            return const Center(
              child: Text(
                'No projects found',
                style: TextStyle(color: AppColors.textMuted),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double width = constraints.maxWidth;
                int crossAxisCount = (width / 300).floor();
                if (crossAxisCount < 1) crossAxisCount = 1;
                if (crossAxisCount > 4) crossAxisCount = 4;

                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 24,
                    crossAxisSpacing: 24,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    final genre = project.genre ?? 'Unknown';
                    final wordCount = _getProjectWordCount(project);
                    final characterCount = _getProjectCharacterCount(project);
                    final time = _formatDate(
                      project.lastModified ?? project.createdAt,
                    );
                    final gradientColors = _getGenreColor(genre);

                    return ProjectBrowserCard(
                      title: project.title,
                      description: project.description ?? '',
                      tag: genre,
                      wordCount: '$wordCount words',
                      characterCount: '$characterCount characters',
                      time: time,
                      gradientColors: gradientColors,
                      onTap: () => _openProject(context, project),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class ProjectBrowserCard extends StatefulWidget {
  final String title;
  final String description;
  final String tag;
  final String wordCount;
  final String characterCount;
  final String time;
  final List<Color> gradientColors;
  final VoidCallback? onTap;

  const ProjectBrowserCard({
    super.key,
    required this.title,
    required this.description,
    required this.tag,
    required this.wordCount,
    required this.characterCount,
    required this.time,
    required this.gradientColors,
    this.onTap,
  });

  @override
  State<ProjectBrowserCard> createState() => _ProjectBrowserCardState();
}

class _ProjectBrowserCardState extends State<ProjectBrowserCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
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
              ? (Matrix4.identity()..translateByDouble(0.0, -8.0, 0.0, 1.0))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: AppColors.bgPanel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered ? AppColors.primary : AppColors.border,
            ),
            boxShadow: _isHovered ? [AppColors.shadow] : [],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cover Image
              Expanded(
                flex: 3,
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
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.tag.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Card Details
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          color: AppColors.textMain,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      if (widget.description.isNotEmpty)
                        Text(
                          widget.description,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 14,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.wordCount,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                widget.characterCount,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            widget.time,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
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
}
