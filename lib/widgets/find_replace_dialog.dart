import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class FindReplaceDialog extends StatefulWidget {
  final QuillController controller;

  const FindReplaceDialog({super.key, required this.controller});

  @override
  State<FindReplaceDialog> createState() => _FindReplaceDialogState();
}

class _FindReplaceDialogState extends State<FindReplaceDialog> {
  final TextEditingController _findController = TextEditingController();
  final TextEditingController _replaceController = TextEditingController();
  final FocusNode _findFocusNode = FocusNode();
  bool _caseSensitive = false;

  @override
  void initState() {
    super.initState();
    // Request focus for the find field when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _findFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _findController.dispose();
    _replaceController.dispose();
    _findFocusNode.dispose();
    super.dispose();
  }

  void _performFind() {
    final text = widget.controller.document.toPlainText();
    final findText = _findController.text;
    if (findText.isEmpty) return;

    final pattern = _caseSensitive ? findText : findText.toLowerCase();
    final searchText = _caseSensitive ? text : text.toLowerCase();

    final index = searchText.indexOf(pattern);
    if (index != -1) {
      widget.controller.updateSelection(
        TextSelection(baseOffset: index, extentOffset: index + findText.length),
        ChangeSource.local,
      );
      // Scroll to the selection if possible
      // Note: Flutter Quill doesn't have a direct scroll to selection method,
      // but the selection update should bring it into view.
    }
  }

  void _performReplace() {
    final findText = _findController.text;
    final replaceText = _replaceController.text;
    if (findText.isEmpty) return;

    final selection = widget.controller.selection;
    if (selection.isValid && !selection.isCollapsed) {
      final text = widget.controller.document.toPlainText();
      final selectedText = text.substring(selection.start, selection.end);

      final matches = _caseSensitive
          ? selectedText == findText
          : selectedText.toLowerCase() == findText.toLowerCase();

      if (matches) {
        widget.controller.replaceText(
          selection.start,
          selection.end - selection.start,
          replaceText,
          null,
        );
        widget.controller.updateSelection(
          TextSelection.collapsed(offset: selection.start + replaceText.length),
          ChangeSource.local,
        );
      }
    }
  }

  void _replaceAll() {
    final findText = _findController.text;
    final replaceText = _replaceController.text;
    if (findText.isEmpty) return;

    final text = widget.controller.document.toPlainText();
    final pattern = _caseSensitive ? findText : findText.toLowerCase();
    final searchText = _caseSensitive ? text : text.toLowerCase();

    int startIndex = 0;
    while (true) {
      final index = searchText.indexOf(pattern, startIndex);
      if (index == -1) break;

      // Select the text to replace
      widget.controller.updateSelection(
        TextSelection(baseOffset: index, extentOffset: index + findText.length),
        ChangeSource.local,
      );

      // Replace the selected text
      widget.controller.replaceText(index, findText.length, replaceText, null);

      // Move start index forward
      startIndex = index + replaceText.length;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Find and Replace'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _findController,
              focusNode: _findFocusNode,
              decoration: const InputDecoration(
                labelText: 'Find',
                hintText: 'Enter text to find',
              ),
              onChanged: (_) => setState(() {}),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              enableInteractiveSelection: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _replaceController,
              decoration: const InputDecoration(
                labelText: 'Replace with',
                hintText: 'Enter replacement text',
              ),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              enableInteractiveSelection: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _caseSensitive,
                  onChanged: (value) =>
                      setState(() => _caseSensitive = value ?? false),
                ),
                const Text('Case sensitive'),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        TextButton(onPressed: _performFind, child: const Text('Find')),
        TextButton(onPressed: _performReplace, child: const Text('Replace')),
        FilledButton(onPressed: _replaceAll, child: const Text('Replace All')),
      ],
    );
  }
}
