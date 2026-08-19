/// Controller for the @mention autocomplete overlay.
///
/// Detects `@` triggers in Quill document text, extracts the query,
/// resolves candidates via [ReferenceEngine], and manages replacement.
///
/// No Flutter widget dependencies — pure state management.
library;

import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:lore_keeper/models/character.dart';
import 'package:lore_keeper/services/reference_attribute.dart';
import 'package:lore_keeper/services/reference_engine.dart';

/// Callback type for providing characters to the controller.
typedef CharactersProvider = List<Character> Function();

/// Controller for the @mention autocomplete feature.
///
/// Manages trigger detection, query extraction, candidate resolution,
/// selection state, and replacement logic. The UI layer (overlay widget)
/// reads state from this controller and calls its methods.
class ReferenceAutocompleteController {
  final ReferenceEngine _engine;
  final QuillController _quillController;
  final CharactersProvider _charactersProvider;

  bool _isActive = false;
  String _query = '';
  int _triggerOffset = -1;
  List<ReferenceCandidate> _candidates = [];
  int _selectedIndex = 0;

  /// Callback invoked when state changes; the UI layer listens to this.
  VoidCallback? _onStateChanged;

  /// Creates a reference autocomplete controller.
  ReferenceAutocompleteController({
    required QuillController quillController,
    required CharactersProvider charactersProvider,
    ReferenceEngine? engine,
  })  : _quillController = quillController,
        _charactersProvider = charactersProvider,
        _engine = engine ?? const ReferenceEngine();

  /// Whether the autocomplete overlay is currently visible.
  bool get isActive => _isActive;

  /// The current query text (everything after `@` up to the cursor).
  String get query => _query;

  /// The plain-text offset of the `@` trigger character.
  int get triggerOffset => _triggerOffset;

  /// The resolved candidates for the current query.
  List<ReferenceCandidate> get candidates => _candidates;

  /// The currently highlighted candidate index (for keyboard navigation).
  int get selectedIndex => _selectedIndex;

  /// Register a callback for state changes.
  set onStateChanged(VoidCallback? callback) {
    _onStateChanged = callback;
  }

  /// Call on every QuillController text change.
  ///
  /// Checks if an `@` trigger is active and updates the query/candidates.
  void onTextChanged() {
    if (!_isActive) {
      _checkForTrigger();
    } else {
      _updateQuery();
    }
  }

  /// Handle raw key events from the editor's focus node.
  ///
  /// Returns `true` if the event was consumed (should not propagate).
  /// Returns `false` if the event should propagate normally.
  bool handleKeyEvent(KeyEvent event) {
    if (!_isActive) return false;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      _moveSelection(1);
      return true;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _moveSelection(-1);
      return true;
    }
    if (key == LogicalKeyboardKey.enter) {
      if (_candidates.isNotEmpty) {
        selectCandidate(_selectedIndex);
      }
      return true;
    }
    if (key == LogicalKeyboardKey.escape) {
      dismiss();
      return true;
    }
    return false;
  }

  /// Select a candidate by index, replacing the @query in the document
  /// and applying an inline reference attribute.
  void selectCandidate(int index) {
    if (index < 0 || index >= _candidates.length) return;

    final candidate = _candidates[index];
    final replacement = candidate.matchedName;

    // Find the @ trigger by scanning backward from current cursor.
    final cursor = _quillController.selection.baseOffset;
    final plainText = _quillController.document.toPlainText();
    final textBefore = plainText.substring(0, cursor);
    final atIndex = textBefore.lastIndexOf('@');
    if (atIndex == -1) {
      dismiss();
      return;
    }

    // Length to replace: from @ to current cursor position.
    final replaceLength = cursor - atIndex;

    _quillController.replaceText(
      atIndex,
      replaceLength,
      replacement,
      null,
    );

    // Apply the reference link attribute for styling + metadata.
    final target = ReferenceTarget(
      type: ReferenceEntityType.character,
      id: candidate.entry.key,
    );
    _quillController.formatText(
      atIndex,
      replacement.length,
      LinkAttribute(target.encode()),
    );

    // Position cursor right after the inserted name.
    _quillController.updateSelection(
      TextSelection.collapsed(offset: atIndex + replacement.length),
      ChangeSource.local,
    );

    dismiss();
  }

  /// Dismiss the autocomplete overlay without selecting.
  void dismiss() {
    if (!_isActive) return;
    _isActive = false;
    _query = '';
    _triggerOffset = -1;
    _candidates = [];
    _selectedIndex = 0;
    _notifyStateChanged();
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  void _checkForTrigger() {
    final cursor = _quillController.selection.baseOffset;
    if (cursor <= 0) return;

    final plainText = _quillController.document.toPlainText();
    if (cursor > plainText.length) return;

    final textBefore = plainText.substring(0, cursor);

    // Scan backward from cursor to find @.
    final atIndex = textBefore.lastIndexOf('@');
    if (atIndex == -1) return;

    // The character before @ must be whitespace or start of document
    // to avoid matching email-like patterns (e.g. user@domain).
    if (atIndex > 0 &&
        textBefore[atIndex - 1] != ' ' &&
        textBefore[atIndex - 1] != '\n' &&
        textBefore[atIndex - 1] != '\t') {
      return;
    }

    // Activate.
    _triggerOffset = atIndex;
    _query = textBefore.substring(atIndex + 1);
    _isActive = true;
    _resolveCandidates();
    _notifyStateChanged();
  }

  void _updateQuery() {
    final cursor = _quillController.selection.baseOffset;
    final plainText = _quillController.document.toPlainText();
    if (cursor > plainText.length) {
      dismiss();
      return;
    }

    final textBefore = plainText.substring(0, cursor);

    // Verify the @ trigger still exists at the expected offset.
    if (_triggerOffset >= textBefore.length ||
        textBefore[_triggerOffset] != '@') {
      dismiss();
      return;
    }

    _query = textBefore.substring(_triggerOffset + 1);
    _selectedIndex = 0;
    _resolveCandidates();
    _notifyStateChanged();
  }

  void _resolveCandidates() {
    final entries = _buildEntries();
    if (_query.trim().isEmpty) {
      final results = entries
          .map((entry) => ReferenceCandidate(
                entry: entry,
                displayName: entry.name,
                matchedName: entry.name,
                matchType: MatchType.exactName,
                confidence: 1.0,
              ))
          .toList();
      results.sort((a, b) => a.displayName.compareTo(b.displayName));
      _candidates = results.length <= _engine.maxResults
          ? results
          : results.sublist(0, _engine.maxResults);
    } else {
      _candidates = _engine.resolve(_query, entries);
    }
  }

  void _moveSelection(int delta) {
    if (_candidates.isEmpty) return;
    _selectedIndex = (_selectedIndex + delta) % _candidates.length;
    _notifyStateChanged();
  }

  List<CharacterReferenceEntry> _buildEntries() {
    final characters = _charactersProvider();
    final entries = <CharacterReferenceEntry>[];
    for (final c in characters) {
      final aliases = <String>[
        if (c.aliases != null) ...c.aliases!,
        if (c.iterations.isNotEmpty) ...[
          if (c.iterations.last.name != null) c.iterations.last.name!,
          if (c.iterations.last.aliases != null) ...c.iterations.last.aliases!,
        ],
      ];
      entries.add(CharacterReferenceEntry(
        key: c.key,
        name: c.name,
        aliases: aliases,
      ));
    }
    return entries;
  }

  void _notifyStateChanged() {
    _onStateChanged?.call();
  }
}
