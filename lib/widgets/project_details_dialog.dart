// lib/widgets/project_details_dialog.dart (COMPLETE FILE)

import 'package:flutter/material.dart';
import 'package:lore_keeper/models/project.dart';
import 'package:lore_keeper/widgets/keyboard_aware_dialog.dart';
import 'package:lore_keeper/widgets/genre_selection_dialog.dart';

class ProjectDetailsDialog extends StatefulWidget {
  final Project project;

  const ProjectDetailsDialog({super.key, required this.project});

  @override
  State<ProjectDetailsDialog> createState() => _ProjectDetailsDialogState();
}

class _ProjectDetailsDialogState extends State<ProjectDetailsDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _bookTitleController;
  late TextEditingController _authorsController;

  late String _selectedGenre;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.project.title);
    _descriptionController = TextEditingController(
      text: widget.project.description,
    );
    _bookTitleController = TextEditingController(
      text: widget.project.bookTitle,
    );
    _authorsController = TextEditingController(text: widget.project.authors);
    _selectedGenre = widget.project.genre?.isNotEmpty == true
        ? widget.project.genre!
        : 'Fiction';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _bookTitleController.dispose();
    _authorsController.dispose();
    super.dispose();
  }

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

  void _saveChanges() {
    if (_formKey.currentState!.validate()) {
      widget.project.title = _titleController.text.trim();
      widget.project.description = _descriptionController.text.trim();
      widget.project.bookTitle = _bookTitleController.text.trim();
      widget.project.genre = _selectedGenre;
      widget.project.authors = _authorsController.text.trim();

      widget.project.save();

      Navigator.of(context).pop(true);
    }
  }

  void _deleteProject() {
    showDialog(
      context: context,
      barrierDismissible: false, // Let KeyboardAwareDialog handle dismissal
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text(
            'Are you sure you want to permanently delete "${widget.project.title}"? This cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                widget.project.delete();
                Navigator.of(context).pop();
                Navigator.of(this.context).pop(false);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardAwareDialog(
      onConfirm: _saveChanges,
      title: const Text('Edit Project Details'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: ListBody(
            children: <Widget>[
              // Project Title Field (Internal)
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Project Title (Internal)',
                ),
                onFieldSubmitted: (_) => _saveChanges(),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Project title cannot be empty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Project Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Short Description',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Book Title Field
              TextFormField(
                controller: _bookTitleController,
                decoration: const InputDecoration(
                  labelText: 'Book Title (Public)',
                ),
              ),
              const SizedBox(height: 16),

              // Genre Dropdown/Button
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

              // Authors Field
              TextFormField(
                controller: _authorsController,
                decoration: const InputDecoration(labelText: 'Authors'),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        // DELETE BUTTON
        TextButton(
          onPressed: _deleteProject,
          child: const Text(
            'Delete Project',
            style: TextStyle(color: Colors.red),
          ),
        ),

        const Spacer(),

        // CANCEL BUTTON
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),

        // SAVE BUTTON
        FilledButton(
          onPressed: _saveChanges,
          child: const Text('Save Changes'),
        ),
      ],
    );
  }
}
