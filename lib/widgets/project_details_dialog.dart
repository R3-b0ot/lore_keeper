// lib/widgets/project_details_dialog.dart

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lore_keeper/models/project.dart';
import 'package:lore_keeper/widgets/genre_selection_dialog.dart';
import 'package:lore_keeper/theme/app_colors.dart';

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
      widget.project.lastModified = DateTime.now();
      widget.project.save();

      Navigator.of(context).pop(true);
    }
  }

  void _deleteProject() {
    showDialog(
      context: context,
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
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: () {
                widget.project.delete();
                Navigator.of(context).pop();
                Navigator.of(this.context).pop(false);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
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
                        LucideIcons.penLine,
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
                            'Edit Project',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: onSurfaceColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Update your manuscript and lore details.',
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
                      icon: const Icon(LucideIcons.x),
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
                        hint: 'Project Title',
                        icon: LucideIcons.package,
                        validator: (v) =>
                            v?.isEmpty == true ? 'Required' : null,
                      ),
                      const SizedBox(height: 24),

                      _buildLabel('PUBLIC BRANDING'),
                      _buildTextField(
                        controller: _bookTitleController,
                        hint: 'Official Book Title',
                        icon: LucideIcons.bookOpen,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _authorsController,
                        hint: 'Author(s)',
                        icon: LucideIcons.user,
                      ),
                      const SizedBox(height: 24),

                      _buildLabel('CLASSIFICATION'),
                      _buildGenreSelector(),
                      const SizedBox(height: 24),

                      _buildLabel('CONTEXT'),
                      _buildTextField(
                        controller: _descriptionController,
                        hint: 'Short description...',
                        icon: LucideIcons.fileText,
                        maxLines: 3,
                      ),

                      const SizedBox(height: 40),

                      // Actions
                      Row(
                        children: [
                          IconButton(
                            onPressed: _deleteProject,
                            icon: Icon(
                              LucideIcons.trash2,
                              color: AppColors.getError(context),
                            ),
                            tooltip: 'Delete Project',
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.getError(
                                context,
                              ).withValues(alpha: 0.1),
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FilledButton(
                              onPressed: _saveChanges,
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
                                'Save Changes',
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
              LucideIcons.tag,
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(_selectedGenre, style: const TextStyle(fontSize: 14)),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
