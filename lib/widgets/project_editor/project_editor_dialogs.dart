import 'package:flutter/material.dart';
import 'package:lore_keeper/theme/app_colors.dart';
import 'package:lore_keeper/models/project.dart';
import 'package:lore_keeper/providers/chapter_list_provider.dart';
import 'package:lore_keeper/providers/character_list_provider.dart';
import 'package:lore_keeper/widgets/chapter_title_dialog.dart';
import 'package:lore_keeper/widgets/settings_dialog.dart';

/// Presents the settings dialog for the project editor.
Future<void> showProjectSettingsDialog(
  BuildContext context, {
  required Project project,
  required int moduleIndex,
  required ChapterListProvider chapterProvider,
  required CharacterListProvider characterProvider,
  required VoidCallback onDictionaryOpened,
}) {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return SettingsDialog(
        project: project,
        moduleIndex: moduleIndex,
        chapterProvider: chapterProvider,
        characterProvider: characterProvider,
        onDictionaryOpened: onDictionaryOpened,
      );
    },
  );
}

/// Prompts for a new character name and returns it if confirmed.
Future<String?> showCreateCharacterDialog(BuildContext context) async {
  final nameController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final result = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        title: const Text('Create New Character'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Character Name'),
            validator: (value) =>
                (value?.trim().isEmpty ?? true) ? 'Name cannot be empty' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(nameController.text.trim());
              }
            },
            child: const Text('Create'),
          ),
        ],
      );
    },
  );

  nameController.dispose();
  return result;
}

/// Prompts to edit a character name or delete it.
Future<Map<String, dynamic>?> showEditCharacterDialog(
  BuildContext context, {
  required String initialName,
}) async {
  final nameDialogController = TextEditingController(text: initialName);
  final formKey = GlobalKey<FormState>();

  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        title: const Text('Edit Character'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameDialogController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Character Name'),
            validator: (value) =>
                (value?.trim().isEmpty ?? true) ? 'Name cannot be empty' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop({'action': 'delete'}),
            child: Text(
              'Delete Character',
              style: TextStyle(color: AppColors.getError(context)),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop({
                  'action': 'confirm',
                  'name': nameDialogController.text.trim(),
                });
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      );
    },
  );

  nameDialogController.dispose();
  return result;
}

/// Opens the chapter title dialog for chapter creation or renaming.
Future<String?> showChapterTitleDialog(
  BuildContext context, {
  String? initialTitle,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) =>
        ChapterTitleDialog(initialTitle: initialTitle ?? ''),
  );
}
