import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lore_keeper/models/project.dart';
import 'package:lore_keeper/theme/app_colors.dart';

class CoverPageForm extends StatefulWidget {
  final Project project;

  const CoverPageForm({super.key, required this.project});

  @override
  State<CoverPageForm> createState() => _CoverPageFormState();
}

class _CoverPageFormState extends State<CoverPageForm> {
  late bool _showTitle;
  late bool _showAuthor;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _showTitle = widget.project.showTitleOnCover ?? true;
    _showAuthor = widget.project.showAuthorOnCover ?? true;
    _imagePath = widget.project.coverImagePath;
  }

  void _save() {
    widget.project.showTitleOnCover = _showTitle;
    widget.project.showAuthorOnCover = _showAuthor;
    widget.project.coverImagePath = _imagePath;
    widget.project.save();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Cover settings saved')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        // Left side: Settings Form
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cover Page Settings',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Configure how your book\'s cover will look.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),

                _buildSectionHeader('Artwork'),
                _buildImagePicker(),

                const SizedBox(height: 32),
                _buildSectionHeader('Typography Visibility'),
                SwitchListTile(
                  title: const Text('Show Book Title'),
                  subtitle: const Text(
                    'Display the title over the cover artwork',
                  ),
                  value: _showTitle,
                  onChanged: (val) => setState(() => _showTitle = val),
                ),
                SwitchListTile(
                  title: const Text('Show Author Name'),
                  subtitle: const Text(
                    'Display your name over the cover artwork',
                  ),
                  value: _showAuthor,
                  onChanged: (val) => setState(() => _showAuthor = val),
                ),

                const SizedBox(height: 48),
                Center(
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(LucideIcons.save),
                    label: const Text('Save Cover Settings'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Right side: Live Preview
        Expanded(
          flex: 3,
          child: Container(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            padding: const EdgeInsets.all(48),
            child: Center(
              child: AspectRatio(
                aspectRatio: 2 / 3, // Standard book aspect ratio
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.scrim.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background Image
                      if (_imagePath != null)
                        Image.file(
                          File(_imagePath!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholder(colorScheme);
                          },
                        )
                      else
                        _buildPlaceholder(colorScheme),

                      // Overlay Content
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              colorScheme.scrim.withValues(alpha: 0.4),
                              Colors.transparent,
                              Colors.transparent,
                              colorScheme.scrim.withValues(alpha: 0.6),
                            ],
                            stops: const [0.0, 0.2, 0.7, 1.0],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (_showTitle)
                                Text(
                                  widget.project.bookTitle ??
                                      widget.project.title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    fontFamily:
                                        'Serif', // Use a classical font for covers
                                    shadows: [
                                      Shadow(
                                        blurRadius: 10,
                                        color: colorScheme.onSurface,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                const SizedBox.shrink(),

                              if (_showAuthor)
                                Text(
                                  widget.project.authors ?? 'Unknown Author',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 2,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 5,
                                        color: colorScheme.onSurface,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                const SizedBox.shrink(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.image,
            size: 48,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Upload Cover Artwork',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'High resolution portrait images (2:3 aspect ratio) work best.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  // In a real app we'd use image_picker.
                  // For this mock/demo environment, we'll allow manual path entry or just simulate selection.
                  _showImagePathDialog();
                },
                icon: const Icon(LucideIcons.imagePlus),
                label: const Text('Select Image'),
              ),
              if (_imagePath != null) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => setState(() => _imagePath = null),
                  icon: Icon(
                    LucideIcons.trash2,
                    color: AppColors.getError(context),
                  ),
                  label: Text(
                    'Remove',
                    style: TextStyle(color: AppColors.getError(context)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.book,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No artwork selected',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePathDialog() {
    final controller = TextEditingController(text: _imagePath);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Image Path'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter absolute path to image file',
            helperText: 'e.g., C:\\Users\\Name\\Pictures\\cover.jpg',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              setState(() => _imagePath = controller.text);
              Navigator.pop(context);
            },
            child: const Text('Set Image'),
          ),
        ],
      ),
    );
  }
}
