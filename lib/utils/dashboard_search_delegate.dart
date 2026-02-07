import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lore_keeper/models/project.dart';
import 'package:lore_keeper/models/character.dart';
import 'package:lore_keeper/models/chapter.dart';
import 'package:lore_keeper/models/map_model.dart';
import 'package:lore_keeper/screens/project_editor_screen.dart';

class DashboardSearchDelegate extends SearchDelegate {
  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        titleTextStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 18,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          fontSize: 12,
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        ),
        border: InputBorder.none,
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 18,
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    if (query.isEmpty) {
      return Container(color: Theme.of(context).colorScheme.surface);
    }

    final projects = Hive.box<Project>('projects').values
        .where((p) => p.title.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: ListView(
        children: [
          if (projects.isNotEmpty)
            ...projects.map(
              (p) => ListTile(
                leading: Icon(
                  Icons.book,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  p.title,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  'Project',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                onTap: () {
                  close(context, null);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProjectEditorScreen(project: p),
                    ),
                  );
                },
              ),
            ),

          ..._searchBox<Chapter>(context, 'chapters', (c) => c.title, (c) {
            // Navigate lookup needed for chapters
          }, icon: Icons.description),

          ..._searchBox<MapModel>(context, 'maps', (m) => m.name, (m) {
            // Navigate lookup needed for maps
          }, icon: Icons.map),

          ..._searchCharacters(context),
        ],
      ),
    );
  }

  List<Widget> _searchBox<T>(
    BuildContext context,
    String boxName,
    String Function(T) getName,
    Function(T) onTap, {
    required IconData icon,
  }) {
    if (!Hive.isBoxOpen(boxName)) return [];

    final box = Hive.box<T>(boxName);
    final results = box.values
        .where(
          (item) => getName(item).toLowerCase().contains(query.toLowerCase()),
        )
        .take(5); // Limit results

    return results
        .map(
          (item) => ListTile(
            leading: Icon(
              icon,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            title: Text(
              getName(item),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            subtitle: Text(
              T.toString(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            onTap: () {
              // Placeholder for future navigation logic
            },
          ),
        )
        .toList();
  }

  List<Widget> _searchCharacters(BuildContext context) {
    if (!Hive.isBoxOpen('characters')) return [];
    final box = Hive.box<Character>('characters');

    final results = box.values
        .where((c) {
          if (c.iterations.isEmpty) return false;
          return c.iterations.any(
            (it) => (it.name ?? '').toLowerCase().contains(query.toLowerCase()),
          );
        })
        .take(5);

    return results
        .map(
          (c) => ListTile(
            leading: Icon(
              Icons.person,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            title: Text(
              c.iterations.isNotEmpty
                  ? c.iterations.first.name ?? 'Unknown'
                  : 'Unknown',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            subtitle: Text(
              'Character',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            onTap: () {
              // Find parent project to open editor
              final projectBox = Hive.box<Project>('projects');
              final project = projectBox.get(c.parentProjectId);
              if (project != null) {
                close(context, null);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProjectEditorScreen(project: project),
                  ),
                );
              }
            },
          ),
        )
        .toList();
  }
}
