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

  /// Replaces `[start, start + length)` with [replacement], preserving the
  /// attributes that were actually on the replaced span (MS-011).
  ///
  /// `QuillController.replaceText` alone is not enough, and for a reason the
  /// B5 trace had backwards: the fourth argument of `replaceText` is a
  /// `TextSelection?`, not an attribute set, so passing `null` does not strip
  /// formatting. What actually happens is the opposite - Quill's insert rule
  /// inherits the attributes of the character at the *start* index, so the
  /// replacement silently takes on whatever formatting happened to begin there.
  /// For a match wholly inside a mention that is the desired result. For a
  /// match that straddles a formatting boundary it is a data-corruption bug:
  /// replacing "ll wa" across a mention boundary extended the `ref:` link onto
  /// the new text, adding a reference the author never wrote.
  ///
  /// So the attribute set is made explicit instead of inherited:
  ///
  /// 1. Capture the attributes that apply across the *whole* matched range.
  ///    `Document.collectStyle` reports the intersection, so a mixed range
  ///    captures nothing and a uniform run captures its full set.
  /// 2. Perform the replacement.
  /// 3. Make the replacement's attribute set exactly what was captured -
  ///    clearing anything the insert heuristic leaked in, and re-applying what
  ///    is missing.
  ///
  /// Block-scope attributes (header, list, blockquote) are deliberately not
  /// carried: they belong to whole lines, and applying one to a sub-range
  /// would be invalid. An edit inside a heading is still a heading.
  void _replaceRange(int start, int length, String replacement) {
    if (length < 0 || start < 0) return;

    final captured = <String, Attribute>{};
    if (length > 0) {
      for (final entry
          in widget.controller.document.collectStyle(start, length).attributes
              .entries) {
        if (entry.value.scope == AttributeScope.inline) {
          captured[entry.key] = entry.value;
        }
      }
    }

    widget.controller.replaceText(start, length, replacement, null);

    // A pure deletion has no new range to fix up.
    if (replacement.isEmpty) return;
    final landed = widget.controller.document
        .collectStyle(start, replacement.length)
        .attributes;

    // Drop what the insert heuristic invented.
    for (final key in landed.keys.toList()) {
      if (!captured.containsKey(key)) {
        widget.controller.formatText(
          start,
          replacement.length,
          Attribute.clone(landed[key]!, null),
        );
      }
    }
    // Re-assert what was genuinely there. This is a no-op when the insert
    // already did the right thing, and the repair when it did not.
    for (final attribute in captured.values) {
      widget.controller.formatText(start, replacement.length, attribute);
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
        _replaceRange(
          selection.start,
          selection.end - selection.start,
          replaceText,
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
      _replaceRange(index, findText.length, replaceText);

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
        OverflowBar(
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            TextButton(onPressed: _performFind, child: const Text('Find')),
            TextButton(
              onPressed: _performReplace,
              child: const Text('Replace'),
            ),
            FilledButton(
              onPressed: _replaceAll,
              child: const Text('Replace All'),
            ),
          ],
        ),
      ],
    );
  }
}
