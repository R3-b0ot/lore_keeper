// lib/widgets/create_project_dialog.dart (COMPLETE FILE)

import 'package:flutter/material.dart';
import 'package:lore_keeper/models/project.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lore_keeper/models/project.dart';
import 'package:lore_keeper/widgets/keyboard_aware_dialog.dart';
import 'package:lore_keeper/widgets/genre_selection_dialog.dart'; // ⭐️ NEW IMPORT

class CreateProjectDialog extends StatefulWidget {
  const CreateProjectDialog({super.key});

  @override
  State<CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<CreateProjectDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  // ⭐️ NEW CONTROLLERS ⭐️
  late TextEditingController _bookTitleController;
  late TextEditingController _authorsController;

  // State for the selected genre
  String _selectedGenre = 'Fiction';

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    // ⭐️ Initialize new controllers ⭐️
    _bookTitleController = TextEditingController();
    _authorsController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _bookTitleController.dispose();
    _authorsController.dispose();
    super.dispose();
  }

  // ⭐️ NEW: Function to open the Genre selection dialog ⭐️
  void _selectGenre() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => GenreSelectionDialog(initialGenre: _selectedGenre),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedGenre = result;
      });
    }
  }

  void _createProject() async {
    if (_formKey.currentState!.validate()) {
      final newProject = Project(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        bookTitle: _bookTitleController.text.trim(),
        genre: _selectedGenre,
        authors: _authorsController.text.trim(),
        createdAt: DateTime.now(),
      );

      // Save the new project to the global Hive box
      final projectBox = Hive.box<Project>('projects');
      await projectBox.add(newProject);

      // Close the dialog and confirm creation
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardAwareDialog(
      onConfirm: _createProject,
      title: const Text('Create New Project'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: ListBody(
            children: <Widget>[
              // Project Title Field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Project Title (Internal)',
                ),
                onFieldSubmitted: (_) => _createProject(),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Project title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Project Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Short Description (Optional)',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // ⭐️ NEW FIELD: Book Title ⭐️
              TextFormField(
                controller: _bookTitleController,
                decoration: const InputDecoration(
                  labelText: 'Book Title (Public)',
                ),
              ),
              const SizedBox(height: 16),

              // ⭐️ MODIFIED: Genre Dropdown/Button ⭐️
              InkWell(
                onTap: _selectGenre,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Genre',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  child: Text(
                    _selectedGenre,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ⭐️ NEW FIELD: Authors ⭐️
              TextFormField(
                controller: _authorsController,
                decoration: const InputDecoration(labelText: 'Authors'),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _createProject, child: const Text('Create')),
      ],
    );
  }
}
