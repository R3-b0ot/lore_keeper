import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lore_keeper/models/project.dart';
import 'package:lore_keeper/models/chapter.dart';
import 'package:lore_keeper/models/character.dart';
import 'package:lore_keeper/theme/app_colors.dart';

class ProjectListTable extends StatelessWidget {
  const ProjectListTable({super.key});

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

  int _getProjectCharacterCount(Project project) {
    if (!Hive.isBoxOpen('characters')) return 0;
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgPanel : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [isDark ? AppColors.shadow : AppColors.shadowLight],
      ),
      clipBehavior: Clip.antiAlias,
      child: ValueListenableBuilder(
        valueListenable: Hive.box<Project>('projects').listenable(),
        builder: (context, Box<Project> box, _) {
          final projects = box.values.toList();
          projects.sort((a, b) {
            final aDate = a.lastModified ?? a.createdAt;
            final bDate = b.lastModified ?? b.createdAt;
            return bDate.compareTo(aDate);
          });

          if (projects.isEmpty) {
            return const SizedBox.shrink();
          }

          return Table(
            columnWidths: const {
              0: FlexColumnWidth(40),
              1: FlexColumnWidth(20),
              2: FlexColumnWidth(20),
              3: FlexColumnWidth(20),
            },
            children: [
              // Header
              TableRow(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.2)
                      : Theme.of(context).colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                children: [
                  _buildHeaderCell(context, 'Title'),
                  _buildHeaderCell(context, 'Words'),
                  _buildHeaderCell(context, 'Characters'),
                  _buildHeaderCell(context, 'Modified'),
                ],
              ),
              // Rows
              ...projects.map(
                (project) => _buildRow(
                  context,
                  project.title,
                  '${_getProjectWordCount(project)}',
                  '${_getProjectCharacterCount(project)}',
                  _formatDate(project.lastModified ?? project.createdAt),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderCell(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  TableRow _buildRow(
    BuildContext context,
    String title,
    String words,
    String chars,
    String date,
  ) {
    return TableRow(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outline.withValues(alpha: 0.05),
          ),
        ),
      ),
      children: [
        _buildCell(context, title, isPrimary: true),
        _buildCell(context, words),
        _buildCell(context, chars),
        _buildCell(context, date),
      ],
    );
  }

  Widget _buildCell(
    BuildContext context,
    String text, {
    bool isPrimary = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: Text(
        text,
        style: TextStyle(
          color: isPrimary
              ? Theme.of(context).colorScheme.onSurface
              : Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: isPrimary ? FontWeight.w700 : FontWeight.normal,
          fontSize: 14,
        ),
      ),
    );
  }
}
