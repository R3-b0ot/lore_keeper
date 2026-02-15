import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lore_keeper/models/project.dart';
import 'package:lore_keeper/models/chapter.dart';
import 'package:lore_keeper/models/character.dart';
import 'package:lore_keeper/models/map_model.dart';
import 'package:lore_keeper/screens/project_editor_screen.dart';
import 'package:lore_keeper/theme/app_colors.dart';

class GlobalSearchDelegate extends SearchDelegate {
  @override
  String get searchFieldLabel => 'Search everything...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: theme.brightness == Brightness.dark
            ? AppColors.bgMain
            : theme.colorScheme.surface,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(LucideIcons.arrowLeft),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.search,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'Looking for something?',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final projects = Hive.box<Project>('projects').values
        .where((p) => p.title.toLowerCase().contains(query.toLowerCase()))
        .toList();

    final chapters = Hive.box<Chapter>('chapters').values
        .where((c) => c.title.toLowerCase().contains(query.toLowerCase()))
        .toList();

    final characters = Hive.box<Character>('characters').values
        .where((c) => c.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    final maps = Hive.box<MapModel>('maps').values
        .where((m) => m.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    if (projects.isEmpty &&
        chapters.isEmpty &&
        characters.isEmpty &&
        maps.isEmpty) {
      return Center(child: Text('No results found for "$query"'));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (projects.isNotEmpty) ...[
          _buildSectionHeader(context, 'Projects'),
          ...projects.map((p) => _buildProjectTile(context, p)),
        ],
        if (chapters.isNotEmpty) ...[
          _buildSectionHeader(context, 'Chapters'),
          ...chapters.map((c) => _buildChapterTile(context, c)),
        ],
        if (characters.isNotEmpty) ...[
          _buildSectionHeader(context, 'Characters'),
          ...characters.map((c) => _buildCharacterTile(context, c)),
        ],
        if (maps.isNotEmpty) ...[
          _buildSectionHeader(context, 'Maps'),
          ...maps.map((m) => _buildMapTile(context, m)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildProjectTile(BuildContext context, Project project) {
    return ListTile(
      leading: const Icon(LucideIcons.package),
      title: Text(project.title),
      subtitle: Text(
        'Project • Created ${project.createdAt.day}/${project.createdAt.month}/${project.createdAt.year}',
      ),
      onTap: () {
        close(context, null);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProjectEditorScreen(project: project),
          ),
        );
      },
    );
  }

  Widget _buildChapterTile(BuildContext context, Chapter chapter) {
    final project = Hive.box<Project>('projects').get(chapter.parentProjectId);
    return ListTile(
      leading: const Icon(LucideIcons.fileText),
      title: Text(chapter.title),
      subtitle: Text('Chapter • In ${project?.title ?? 'Unknown Project'}'),
      onTap: () {
        if (project == null) return;
        close(context, null);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProjectEditorScreen(
              project: project,
              initialModuleIndex: 0,
              initialChapterKey: chapter.key.toString(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCharacterTile(BuildContext context, Character character) {
    final project = Hive.box<Project>(
      'projects',
    ).get(character.parentProjectId);
    return ListTile(
      leading: const Icon(LucideIcons.user),
      title: Text(character.name),
      subtitle: Text('Character • In ${project?.title ?? 'Unknown Project'}'),
      onTap: () {
        if (project == null) return;
        close(context, null);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProjectEditorScreen(
              project: project,
              initialModuleIndex: 1,
              initialCharacterKey: character.key.toString(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapTile(BuildContext context, MapModel map) {
    final project = Hive.box<Project>('projects').get(map.parentProjectId);
    return ListTile(
      leading: const Icon(LucideIcons.map),
      title: Text(map.name),
      subtitle: Text('Map • In ${project?.title ?? 'Unknown Project'}'),
      onTap: () {
        if (project == null) return;
        close(context, null);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProjectEditorScreen(
              project: project,
              initialModuleIndex: 2,
              initialMapKey: map.key.toString(),
            ),
          ),
        );
      },
    );
  }
}
