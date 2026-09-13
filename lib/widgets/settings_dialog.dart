// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lore_keeper/widgets/responsive_layout.dart';
import 'package:lore_keeper/models/chapter.dart';
import 'package:lore_keeper/models/character.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';

import 'package:lore_keeper/models/project.dart';
import 'package:lore_keeper/providers/chapter_list_provider.dart';
import 'package:lore_keeper/providers/character_list_provider.dart';
import 'package:lore_keeper/settings/global_settings_controller.dart';
import 'package:lore_keeper/settings/settings_shell.dart';

/// Settings dialog entry point.
///
/// This is the top-level container that the rest of the application opens via
/// `showDialog`. It hosts the new [SettingsShell] and supplies:
/// - real project context (so project-scope settings can persist to the
///   [Project] model),
/// - a real delete-project callback (preserving the legacy deletion flow),
/// - the dictionary-manager callback.
///
/// The dialog exposes the same constructor shape as the legacy dialog so all
/// existing call sites (dashboard, project editor) keep working unchanged.
class SettingsDialog extends StatelessWidget {
  final Project? project;
  final int? moduleIndex;
  final ChapterListProvider? chapterProvider;
  final CharacterListProvider? characterProvider;
  final VoidCallback? onDictionaryOpened;

  const SettingsDialog({
    super.key,
    this.project,
    this.moduleIndex,
    this.chapterProvider,
    this.characterProvider,
    this.onDictionaryOpened,
  });

  /// Legacy deletion flow shared with the danger-zone pane.
  Future<void> _deleteProject(BuildContext context, Project project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text(
          'Are you sure you want to permanently delete "${project.title}"? '
          'This will also delete all chapters, characters, and links '
          'associated with it. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final projectId = project.key;

      // 1. Delete chapters.
      final chapterBox = Hive.box<Chapter>('chapters');
      final chapterKeysToDelete = chapterBox.values
          .where((c) => c.parentProjectId == projectId)
          .map((c) => c.key)
          .toList();
      await chapterBox.deleteAll(chapterKeysToDelete);

      // 2. Delete characters.
      final characterBox = Hive.box<Character>('characters');
      final characterKeysToDelete = characterBox.values
          .where((c) => c.parentProjectId == projectId)
          .map((c) => c.key)
          .toList();
      await characterBox.deleteAll(characterKeysToDelete);

      // 3. Delete the project itself.
      await project.delete();

      // 4. Navigate back to the home screen.
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GlobalSettingsController>(
      builder: (context, settings, _) {
        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: adaptiveDialogConstraints(
              context,
              maxWidth: 1180,
              maxHeightFactor: 0.9,
            ),
            child: SettingsShell(
              project: project,
              moduleIndex: moduleIndex,
              chapterProvider: chapterProvider,
              characterProvider: characterProvider,
              onDictionaryOpened: onDictionaryOpened,
              onDeleteProject: project != null
                  ? () => _deleteProject(context, project!)
                  : null,
            ),
          ),
        );
      },
    );
  }
}

/// Indicator used by callers that want a stable icon reference for settings
/// (kept for compatibility with legacy top-bar behaviour).
const IconData settingsIcon = LucideIcons.settings;
