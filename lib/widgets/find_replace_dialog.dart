import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../services/manuscript_find_replace.dart';

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

  /// Index of the selected match in the current find session, or -1 when
  /// nothing is selected (MS-013). The match list itself is recomputed from
  /// the live document on every step, so only the position is kept.
  int _selectedIndex = -1;

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
    _stepNavigation((session) => session.next());
  }

  void _performPrevious() {
    _stepNavigation((session) => session.previous());
  }

  /// Advances the find session and selects whatever it lands on (MS-013).
  ///
  /// The session is recomputed from the live document on every step, because
  /// the document is mutable and a stale match list would point at offsets
  /// that no longer mean what they meant when they were found.
  void _stepNavigation(FindSession Function(FindSession) step) {
    if (_findController.text.isEmpty) return;
    final session = step(
      FindSession(
        text: widget.controller.document.toPlainText(),
        query: _findController.text,
        caseSensitive: _caseSensitive,
        // Continue from where we already are, so repeated Find presses walk
        // forward instead of snapping back to the first match.
        currentIndex: _selectedIndex,
      ),
    );
    setState(() {
      _selectedIndex = session.currentIndex;
    });
    final match = session.current;
    if (match == null) return;
    widget.controller.updateSelection(
      TextSelection(baseOffset: match.offset, extentOffset: match.end),
      ChangeSource.local,
    );
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
        // The document just changed under the match list, so the selected
        // match no longer exists. Drop the selection rather than leave a
        // count claiming a position that is not there.
        setState(() => _selectedIndex = -1);
      }
    }
  }

  void _replaceAll() {
    final findText = _findController.text;
    final replaceText = _replaceController.text;
    if (findText.isEmpty) return;

    // MS-012. The matches are computed once against the current text and then
    // applied **highest offset first**. Previously this looped
    // `searchText.indexOf(pattern, startIndex)` over a plain-text snapshot
    // captured before any edit, so as soon as the replacement was a different
    // length from the query the coordinates stopped referring to the document
    // that was actually being edited. `"a cat and a dog"` with `"a"`->`"bbb"`
    // produced `"bbbbbbbbbabbb and a dog"`, and the shorter-replacement and
    // empty-replacement cases did not merely corrupt the text - the latter
    // never advanced `startIndex` at all, so Replace All with an empty
    // replacement spun forever and hung the app.
    //
    // Walking the plan backwards means every range still sits at its original
    // offset when it is applied, so the outcome does not depend on the
    // relative lengths of the query and the replacement. An empty replacement
    // is just a zero-length insert at the right place.
    final plan = const FindReplaceEngine().replaceAllPlan(
      widget.controller.document.toPlainText(),
      findText,
      caseSensitive: _caseSensitive,
    );

    for (final match in plan) {
      _replaceRange(match.offset, match.length, replaceText);
    }
    // The whole match list is stale now; see _performReplace.
    setState(() => _selectedIndex = -1);
  }

  /// The find session as it currently stands, for the count display.
  FindSession get _session => FindSession(
        text: widget.controller.document.toPlainText(),
        query: _findController.text,
        caseSensitive: _caseSensitive,
        currentIndex: _selectedIndex,
      );

  @override
  Widget build(BuildContext context) {
    final countLabel = _session.countLabel;
    return AlertDialog(
      title: const Text('Find and Replace'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _findController,
              focusNode: _findFocusNode,
              decoration: InputDecoration(
                labelText: 'Find',
                hintText: 'Enter text to find',
                helperText: countLabel.isEmpty ? null : countLabel,
              ),
              onChanged: (_) => setState(() {
                // A new query invalidates the old match list, so nothing is
                // selected until the user navigates again.
                _selectedIndex = -1;
              }),
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
              onPressed: _performPrevious,
              child: const Text('Previous'),
            ),
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
