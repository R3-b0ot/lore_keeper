import 'package:flutter/material.dart';
import 'package:lore_keeper/theme/app_colors.dart';
import 'package:lore_keeper/models/project.dart';
import 'package:lore_keeper/providers/chapter_list_provider.dart';
import 'package:lore_keeper/providers/character_list_provider.dart';
import 'package:lore_keeper/widgets/chapter_title_dialog.dart';
import 'package:lore_keeper/widgets/settings_dialog.dart';

/// Describes the confirmed action from the character edit dialog.
sealed class CharacterDialogResult {
  const CharacterDialogResult();
}

/// Requests that the selected character be renamed to [name].
class ConfirmCharacterName extends CharacterDialogResult {
  final String name;

  const ConfirmCharacterName(this.name);
}

/// Requests that the selected character be deleted.
class DeleteCharacter extends CharacterDialogResult {
  const DeleteCharacter();
}

/// Protects persisted character names from empty or malformed input.
String? validateCharacterName(String? value) {
  final name = value?.trim() ?? '';
  if (name.isEmpty) return 'Name cannot be empty';
  if (name.length > 120) return 'Name is too long';
  if (RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]').hasMatch(name)) {
    return 'Name contains unsupported characters';
  }
  return null;
}

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
Future<String?> showCreateCharacterDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const _CreateCharacterDialog(),
  );
}

class _CreateCharacterDialog extends StatefulWidget {
  const _CreateCharacterDialog();

  @override
  State<_CreateCharacterDialog> createState() => _CreateCharacterDialogState();
}

class _CreateCharacterDialogState extends State<_CreateCharacterDialog> {
  late final TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(_nameController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Character'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Character Name'),
          validator: validateCharacterName,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Create')),
      ],
    );
  }
}

/// Prompts to edit a character name or delete it.
Future<CharacterDialogResult?> showEditCharacterDialog(
  BuildContext context, {
  required String initialName,
}) {
  return showDialog<CharacterDialogResult>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _EditCharacterDialog(initialName: initialName),
  );
}

class _EditCharacterDialog extends StatefulWidget {
  final String initialName;

  const _EditCharacterDialog({required this.initialName});

  @override
  State<_EditCharacterDialog> createState() => _EditCharacterDialogState();
}

class _EditCharacterDialogState extends State<_EditCharacterDialog> {
  late final TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(
        context,
      ).pop(ConfirmCharacterName(_nameController.text.trim()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Character'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Character Name'),
          validator: validateCharacterName,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(const DeleteCharacter()),
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
        FilledButton(onPressed: _confirm, child: const Text('Confirm')),
      ],
    );
  }
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
