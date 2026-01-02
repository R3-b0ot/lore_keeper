import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:lore_keeper/models/project.dart';
import 'package:lore_keeper/models/chapter.dart';
import 'package:lore_keeper/models/character.dart';
import 'package:lore_keeper/models/map_model.dart';
import 'package:lore_keeper/models/section.dart'; // ⭐️ NEW IMPORT ⭐️
import 'package:lore_keeper/models/link.dart'; // 1. Import the new Link model
import 'package:lore_keeper/models/history_entry.dart';
import 'package:lore_keeper/services/trait_service.dart';
import 'package:lore_keeper/services/relationship_service.dart';
import 'package:lore_keeper/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:lore_keeper/screens/project_editor_screen.dart';
import 'package:lore_keeper/widgets/project_details_dialog.dart';
import 'package:lore_keeper/widgets/settings_dialog.dart';
import 'package:lore_keeper/widgets/create_project_dialog.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'screens/trait_editor_screen.dart';

// Global access point for the Project data store (Hive Box)
late Box<Project> projectBox;
late Box<Section> sectionBox;
late Box<Chapter> chapterBox;
late Box<Character> characterBox;
late Box<MapModel> mapBox;
// We will access chapter data through a service/local box later.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeHive();
  await RelationshipService()
      .initialize(); // Initialize the relationship service
  runApp(
    riverpod.ProviderScope(
      child: ChangeNotifierProvider(
        create: (_) => ThemeNotifier(),
        child: const LoreKeeperApp(),
      ),
    ),
  );
}

/// Initializes the Hive database, sets the directory, and registers Type Adapters.
Future<void> initializeHive() async {
  if (kIsWeb) {
    await Hive.initFlutter();
  } else {
    Directory dir = await getApplicationSupportDirectory();
    await Hive.initFlutter(dir.path);
  }

  Hive.registerAdapter(ProjectAdapter());
  Hive.registerAdapter(ChapterAdapter());
  Hive.registerAdapter(CharacterAdapter());
  Hive.registerAdapter(SectionAdapter()); // ⭐️ REGISTER NEW ADAPTER ⭐️
  Hive.registerAdapter(LinkAdapter()); // 2. Register the LinkAdapter
  Hive.registerAdapter(CharacterIterationAdapter()); // Add this line
  Hive.registerAdapter(CustomFieldAdapter());
  Hive.registerAdapter(CustomPanelAdapter());
  Hive.registerAdapter(CustomTraitAdapter());
  Hive.registerAdapter(MapModelAdapter());
  Hive.registerAdapter(HistoryEntryAdapter()); // Register the History adapter

  try {
    projectBox = await Hive.openBox<Project>('projects');
    sectionBox = await Hive.openBox<Section>('sections');
    chapterBox = await Hive.openBox<Chapter>('chapters');
    characterBox = await Hive.openBox<Character>('characters');
    mapBox = await Hive.openBox<MapModel>('maps');
    await Hive.openBox<Link>('links'); // 3. Open the 'links' box
    await Hive.openBox<HistoryEntry>('history');
    await Hive.openBox<SimpleTrait>('custom_traits');
  } catch (e) {
    // If there's an adapter mismatch (e.g., old data with unknown typeId),
    // clear all boxes and reopen them
    if (e.toString().contains('unknown typeId')) {
      await Hive.deleteBoxFromDisk('projects');
      await Hive.deleteBoxFromDisk('sections');
      await Hive.deleteBoxFromDisk('chapters');
      await Hive.deleteBoxFromDisk('characters');
      await Hive.deleteBoxFromDisk('maps');
      await Hive.deleteBoxFromDisk('links');
      await Hive.deleteBoxFromDisk('history');
      await Hive.deleteBoxFromDisk('custom_traits');

      projectBox = await Hive.openBox<Project>('projects');
      sectionBox = await Hive.openBox<Section>('sections');
      chapterBox = await Hive.openBox<Chapter>('chapters');
      characterBox = await Hive.openBox<Character>('characters');
      mapBox = await Hive.openBox<MapModel>('maps');
      await Hive.openBox<Link>('links'); // 3. Open the 'links' box
      await Hive.openBox<HistoryEntry>('history');
      await Hive.openBox<SimpleTrait>('custom_traits');
    } else {
      rethrow;
    }
  }
}

// ... (Rest of the file is unchanged) ...

class LoreKeeperApp extends StatelessWidget {
  const LoreKeeperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          title: 'Lore Keeper',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
          darkTheme: ThemeData.dark(useMaterial3: true),
          themeMode: themeNotifier.themeMode,
          home: const ProjectHomeScreen(),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
        );
      },
    );
  }
}

class ProjectHomeScreen extends StatelessWidget {
  const ProjectHomeScreen({super.key});

  // ⭐️ REMOVED: The old _addProject function is gone.
  // The new creation logic is in CreateProjectDialog.

  void _openProjectEditor(BuildContext context, Project project) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProjectEditorScreen(project: project),
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, Project project) {
    showDialog(
      context: context,
      barrierDismissible: false, // Let KeyboardAwareDialog handle dismissal
      builder: (BuildContext context) {
        return ProjectDetailsDialog(project: project);
      },
    );
  }

  // ⭐️ NEW: Function to display the creation dialog.
  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Let KeyboardAwareDialog handle dismissal
      builder: (BuildContext context) {
        return const CreateProjectDialog();
      },
    ).then((result) {
      if (result == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project created successfully!')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lore Keeper Projects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Application Settings',
            onPressed: () {
              showDialog(
                context: context, // The project is null for global settings
                builder: (_) => SettingsDialog(
                  moduleIndex: -1, // No module selected in global context
                  onDictionaryOpened: () {},
                ),
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: projectBox.listenable(),
        builder: (context, Box<Project> box, _) {
          final projects = box.values.toList().cast<Project>();

          if (projects.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_stories, size: 64, color: Colors.blueGrey),
                  SizedBox(height: 20),
                  Text(
                    'No Lore Keeper Projects Found',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap "+" to create your first story or world.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return Card(
                elevation: 1,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.folder_open),
                  title: Text(
                    project.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(project.description ?? 'No description.'),

                  onTap: () => _openProjectEditor(context, project),

                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blueGrey),
                    onPressed: () => _showDetailsDialog(context, project),
                  ),
                ),
              );
            },
          );
        },
      ),
      // ⭐️ MODIFIED: Calls the new creation dialog.
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
