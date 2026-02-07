// lib/widgets/create_project_dialog.dart (COMPLETE FILE)

import 'package:flutter/material.dart';
import 'package:lore_keeper/models/project.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:lore_keeper/widgets/genre_selection_dialog.dart';
import 'package:lore_keeper/theme/app_colors.dart';

class CreateProjectDialog extends StatefulWidget {
  const CreateProjectDialog({super.key});

  @override
  State<CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<CreateProjectDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _bookTitleController;
  late TextEditingController _authorsController;

  String _selectedGenre = 'Fiction';
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
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
        lastModified: DateTime.now(),
      );

      final projectBox = Hive.box<Project>('projects');
      await projectBox.add(newProject);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.bgPanel
        : Theme.of(context).colorScheme.surface;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 32, 32, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Begin New Lore',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: onSurfaceColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Configure your new world and manuscript settings.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: onSurfaceColor.withValues(alpha: 0.05),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 48, indent: 32, endIndent: 32),

              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildLabel('INTERNAL REFERENCE'),
                      _buildTextField(
                        controller: _titleController,
                        hint: 'Project Title (e.g. "Project Starlight")',
                        icon: Icons.inventory_2_outlined,
                        validator: (v) =>
                            v?.isEmpty == true ? 'Required' : null,
                      ),
                      const SizedBox(height: 24),

                      _buildLabel('PUBLIC BRANDING'),
                      _buildTextField(
                        controller: _bookTitleController,
                        hint: 'Official Book Title (Optional)',
                        icon: Icons.menu_book_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _authorsController,
                        hint: 'Author(s)',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 24),

                      _buildLabel('CLASSIFICATION'),
                      _buildGenreSelector(),
                      const SizedBox(height: 24),

                      _buildLabel('CONTEXT'),
                      _buildTextField(
                        controller: _descriptionController,
                        hint: 'Brief world description...',
                        icon: Icons.description_outlined,
                        maxLines: 3,
                      ),

                      const SizedBox(height: 40),

                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: FilledButton(
                              onPressed: _createProject,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 8,
                                shadowColor: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.5),
                              ),
                              child: const Text(
                                'Initialize Project',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Theme.of(
          context,
        ).colorScheme.onSurface.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildGenreSelector() {
    return InkWell(
      onTap: _selectGenre,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              Icons.category_outlined,
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(_selectedGenre, style: const TextStyle(fontSize: 14)),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
