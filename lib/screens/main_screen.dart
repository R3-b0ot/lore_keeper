import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lore_keeper/models/project.dart';
import 'package:lore_keeper/screens/project_editor_screen.dart';
import 'package:lore_keeper/widgets/create_project_dialog.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late Box<Project> projectBox;

  @override
  void initState() {
    super.initState();
    projectBox = Hive.box<Project>('projects');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lore Keeper'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _createNewProject),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: projectBox.listenable(),
        builder: (context, Box<Project> box, _) {
          if (box.values.isEmpty) {
            return const Center(
              child: Text('No projects yet. Create your first project!'),
            );
          }

          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, index) {
              final project = box.getAt(index);
              if (project == null) return const SizedBox.shrink();

              return ListTile(
                title: Text(project.title),
                subtitle: Text(project.description ?? ''),
                onTap: () => _openProject(project),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteProject(index);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete Project'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _createNewProject() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const CreateProjectDialog(),
    );

    if (result != null && mounted) {
      final project = Project(
        title: result['title']!,
        description: result['description'],
        createdAt: DateTime.now(),
      );
      await projectBox.add(project);
    }
  }

  void _openProject(Project project) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProjectEditorScreen(project: project),
      ),
    );
  }

  void _deleteProject(int index) async {
    await projectBox.deleteAt(index);
  }
}
