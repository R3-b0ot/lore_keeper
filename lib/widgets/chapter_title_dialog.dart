// lib/widgets/chapter_title_dialog.dart

import 'package:flutter/material.dart';
import 'package:lore_keeper/widgets/keyboard_aware_dialog.dart';

/// A dialog for entering or editing a chapter title.
class ChapterTitleDialog extends StatefulWidget {
  final String initialTitle;

  const ChapterTitleDialog({super.key, this.initialTitle = ''});

  @override
  State<ChapterTitleDialog> createState() => _ChapterTitleDialogState();
}

class _ChapterTitleDialogState extends State<ChapterTitleDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardAwareDialog(
      onConfirm: _submit,
      title: Text(
        widget.initialTitle.isEmpty ? 'New Chapter' : 'Rename Chapter',
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Chapter Title'),
          validator: (value) =>
              (value?.trim().isEmpty ?? true) ? 'Title cannot be empty' : null,
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
