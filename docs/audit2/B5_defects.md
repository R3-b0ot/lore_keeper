# B5 — Known Defects Re-verified

> Each defect re-verified against CURRENT code (HEAD `a7ed2f3`).  
> Status: **CONFIRMED** / **FIXED** / **NOT REPRODUCIBLE**  
> Where possible a failing-test sketch is provided.

---

## D1 — Manuscript history invisible (targetType mismatch)

**Original claim:** Docs save with `targetType: 'ManuscriptDocument'` + document id; the history panel reads `targetType: 'Chapter'` + legacy chapter key → revisions recorded but never shown.

**Status: CONFIRMED**

Evidence:

`manuscript_module.dart` — `_saveContent()`:
```dart
await _historyService.addHistoryEntry(
  targetKey: _selectedDocument!.id,          // e.g. "chapter_3"
  targetType: 'ManuscriptDocument',
  objectToSave: _selectedDocument!,
  projectId: widget.projectId,
);
```
`project_editor_screen.dart` — `_buildHistoryPanel()` (lines ~484–498):
```dart
return HistoryPanel(
  targetKey: targetKey,    // int or "front_matter_-N"  ← legacy chapter key
  targetType: 'Chapter',   // ← hard-coded 'Chapter'
  ...
);
```
`history_panel.dart` filters: `e.targetKey == widget.targetKey && e.targetType == widget.targetType`.

With `targetType: 'Chapter'` and an int `targetKey`, the panel finds zero entries that were saved under `targetType: 'ManuscriptDocument'` with a string `targetKey`. History is stored but the panel shows "No history found."

Additionally, `ChapterDiffViewDialog` reads `Hive.box<Chapter>('chapters').get(historyEntry.targetKey)`. Even if the targetType were corrected to `'Chapter'`, reverting a `ManuscriptDocument` history entry would deserialise it as a `Chapter` object — a type mismatch that would either crash or silently produce wrong data.

**Failing-test sketch:**
```dart
test('ManuscriptDocument history entries are visible in HistoryPanel', () {
  // Seed: add a HistoryEntry with targetType 'ManuscriptDocument',
  //       targetKey 'chapter_1'
  // Assert: HistoryPanel(targetType: 'ManuscriptDocument',
  //           targetKey: 'chapter_1') shows that entry
  // Currently fails because shell passes targetType: 'Chapter'
});
```

---

## D2 — Three divergent word/character counters

**Original claim:** Three different word-count implementations with divergent semantics.

**Status: CONFIRMED**

Evidence (verified in current code):

1. **Editor (live, plain-text)** — `manuscript_module.dart._updateWordCount()`:
   ```dart
   plainText.split(RegExp(r'\s+')).length
   ```
   and `_updateDocumentWordCount()`:
   ```dart
   _selectedDocument!.characterCount = _controller.document.toPlainText().length;
   ```

2. **Service (on save, JSON-regex)** — `manuscript_binder_service.dart._countWords()` / `updateContent()`:
   ```dart
   doc.wordCount = _countWords(richTextJson);        // JSON-regex word split
   doc.characterCount = richTextJson.length;          // JSON string length
   ```

3. **Migration** — `database_manager.dart` V2→V3 `_countWords()`:  
   Identical to (2) — JSON-regex on raw Delta JSON.

Result: `doc.wordCount` written by the service on each autosave is based on the raw JSON string (includes `{"ops":[{"insert":"` boilerplate), producing an inflated count. `doc.characterCount` is the JSON string length, not the plain-text character count. The Inspector and Outliner read the persisted fields; only the status-bar word count (live) is accurate.

**Failing-test sketch:**
```dart
test('word count on ManuscriptDocument matches plain-text count', () {
  final doc = ManuscriptDocument()
    ..richTextJson = '{"ops":[{"insert":"Hello world\\n"}]}';
  final service = ManuscriptBinderService(...);
  await service.updateContent(doc.id, doc.richTextJson!);
  expect(doc.wordCount, equals(2));        // Currently fails: JSON-regex returns > 2
  expect(doc.characterCount, equals(11)); // Currently fails: returns JSON string length
});
```

---

## D3 — Find & Replace strips ref: attributes and drifts offsets in replace-all

**Original claim:** `_performReplace` strips `ref:` link attribute; `_replaceAll` iterates snapshot of original plain text while mutating live document → offset drift when replacement length ≠ find length.

**Status: CONFIRMED**

Evidence — `find_replace_dialog.dart._replaceAll()`:
```dart
final text = widget.controller.document.toPlainText();  // snapshot
// ...
while (true) {
  final index = searchText.indexOf(pattern, startIndex);
  // ...
  widget.controller.replaceText(index, findText.length, replaceText, null);
  // ↑ 'null' clears all attributes on the replaced span
  startIndex = index + replaceText.length;
  // ↑ advances in the ORIGINAL plain-text coordinate space
  //   but replaceText mutated the document — offsets drift when
  //   replaceText.length != findText.length
}
```

`replaceText(..., null)` in flutter_quill replaces the span and applies `null` as the `TextSelection` — this causes the Delta to insert plain text with no attributes, stripping any `ref:` link, bold, italic, or other formatting on the replaced run.

`_performReplace()` has the same attribute-loss problem via the same `replaceText(..., null)` call.

**Failing-test sketch:**
```dart
test('Replace All preserves ref: attributes on non-matching spans', () {
  final controller = QuillController.basic();
  // Insert "Hello @Aiden world" with ref: link on "Aiden"
  controller.document = Document.fromDelta(Delta()
    ..insert('Hello ')
    ..insert('Aiden', {'link': 'ref:Character:42'})
    ..insert(' world\n'));
  final dialog = FindReplaceDialogState()
    .._controller = controller
    .._findController = TextEditingController(text: 'world')
    .._replaceController = TextEditingController(text: 'universe');
  dialog._replaceAll();
  // Check that the 'Aiden' span still has {'link': 'ref:Character:42'}
  final ops = controller.document.toDelta().toList();
  expect(ops[1].attributes?['link'], equals('ref:Character:42')); // fails today
});
```

---

## D4 — ReferenceIndex rebuild clears entries from non-manuscript sources

**Original claim:** `rebuildIndex` calls `engine.clear()` then rebuilds only manuscript-source entries — any index work contributed by non-manuscript modules is wiped on the next autosave.

**Status: CONFIRMED**

Evidence — `manuscript_reference_service.dart.rebuildIndex()`:
```dart
Future<void> rebuildIndex() async {
  final entries = extractAllReferences();
  _referenceEngine.clear();            // ← clears ALL entries in shared engine
  for (final entry in entries) {
    _referenceEngine.addEntry(entry);  // ← adds only manuscript entries
  }
}
```

This is called on every autosave (`manuscript_module.dart:629`). Any references indexed by `CharacterListProvider.deleteCharacter` (which calls `purgeStale` after deletion) or `TimelineEventProvider`/`SpeciesProvider` will be wiped 2 seconds after the next keystroke. In the current codebase only `ManuscriptReferenceService` populates the engine, so no data is lost today. But if any other module were to add entries to the shared engine, they would be silently deleted.

**Risk rating:** Low-impact now; high-impact once additional entity types are wired into the reference system.

**Failing-test sketch:**
```dart
test('rebuildIndex does not clear entries from other sources', () {
  final engine = ReferenceEngine();
  // Add a character-deletion entry (simulates CharacterListProvider)
  engine.addEntry(ReferenceIndexEntry(
    source: EntityRef(id: '99', entityType: 'Character', projectId: '1'),
    target: EntityRef(id: 'chapter_1', entityType: 'ManuscriptDocument', projectId: '1'),
    kind: 'mentions', computedAt: DateTime.now(),
  ));
  final service = ManuscriptReferenceService(
    projectId: 1, referenceEngine: engine, documentBox: emptyBox);
  await service.rebuildIndex();
  // Engine should still contain the character entry
  expect(engine.length, greaterThan(0)); // Currently fails: engine.clear() removed it
});
```

---

## D5 — Mentions of non-character entities unresolved and purged as stale

**Original claim:** `reference_name_resolver.dart` resolves only Character, Species, TimelineEvent, ManuscriptDocument; Location/Item/Org/Faction return `null` and `entityExists=false` → such mentions are "Unresolved" in Inspector and purged as stale even when valid.

**Status: CONFIRMED**

Evidence — `reference_name_resolver.dart.entityExists()`:
```dart
default:
  return false;   // Location, Item, Organization, Faction, Research, Calendar → false
```

And `resolveById()`:
```dart
default:
  return null;    // same types → null → Inspector shows "Unresolved • <id>"
```

`ReferenceNameResolver.purgeStale()` → `ReferenceIntegrityService.purgeStaleEntries()` removes entries where `!entityExists(source) || !entityExists(target)`. If a manuscript document contains a `ref:Location:uuid` mention, `entityExists` returns `false` for the location target → the entry is removed from the engine on the next purge cycle, even though the mention is intentionally there.

In practice today the `@mention` autocomplete does not offer Location/Item/Org/Faction candidates (`_buildEntityProviders()` in `ManuscriptEditor` only wires 4 types), so users cannot currently create such mentions through normal UI. But if they were created programmatically or by migration, they would be silently purged.

**Failing-test sketch:**
```dart
test('Location references are not purged as stale', () {
  final engine = ReferenceEngine();
  engine.addEntry(ReferenceIndexEntry(
    source: EntityRef(id: 'scene_abc', entityType: 'ManuscriptDocument', projectId: '1'),
    target: EntityRef(id: 'loc-uuid', entityType: 'Location', projectId: '1'),
    kind: 'mentions', computedAt: DateTime.now(),
  ));
  final resolver = ReferenceNameResolver.fromDatabase(1);
  resolver.purgeStale(engine);
  // Location entry should survive because entityExists is undefined (not false)
  expect(engine.length, equals(1)); // Currently fails: returns false → purged
});
```

---

## D6 — Hierarchy validation is warn-only

**Original claim:** `_validateTypeHierarchy` in `ManuscriptBinderService` logs a warning but does not throw, allowing invalid parent/child relationships to be created.

**Status: CONFIRMED**

Evidence — `manuscript_binder_service.dart._validateTypeHierarchy()`:
```dart
if (!allowed.contains(childType)) {
  LkLog.warning('ManuscriptBinder', 'Unusual hierarchy: $parentType -> $childType');
  // Allow but warn - don't throw to maintain flexibility
}
```

A user can therefore place a `manuscript` node as a child of a `scene`, or a `part` inside a `note`, and no error is raised. `moveDocument` calls `_validateTypeHierarchy` too with the same warn-only behaviour. This is by intentional design comment ("maintain flexibility") but violates spec §3.4 which requires circular relationships to be impossible through normal operations. Circular hierarchy IS prevented (`_wouldCreateCycle`) — the issue is that non-circular but semantically invalid hierarchies are silently accepted.

**Note:** Not the same as the circular-hierarchy protection, which is correctly enforced.

---

## D7 — Autosave writes a history snapshot every ~2s

**Original claim:** Every autosave snapshots the whole document into the `history` box, limited to `historyLimit` (default 10). With 2s debounce, a 10-minute writing session produces 300 potential saves pruned to 10 — excessive Hive I/O and loss of the earliest granular history.

**Status: CONFIRMED**

Evidence — `manuscript_module.dart._saveContent()`:
```dart
await _historyService.addHistoryEntry(
  targetKey: _selectedDocument!.id,
  targetType: 'ManuscriptDocument',
  objectToSave: _selectedDocument!,
  projectId: widget.projectId,
);
```
This is inside the autosave path, which fires after every `_autosaveDelay = Duration(seconds: 2)` of inactivity. `HistoryService.addHistoryEntry` writes a new `HistoryEntry` to Hive on every call, then prunes to `historyLimit`. There is no content-change guard — identical content is snapshotted repeatedly.

Note: Because D1 is also confirmed, these snapshots are invisible to the user anyway. Both bugs must be fixed together to make history functional.

---

## D8 — Additional defects found during this audit

### D8a — `ManuscriptReferenceService` instantiated twice in the same module tree

**Evidence:** `_ManuscriptModuleState._initReferenceService()` creates one instance (`_referenceService`). `_ManuscriptEditorState._initReferenceService()` creates a second instance (also named `_referenceService`). Both call `rebuildIndex()` on the shared engine independently. Each `rebuildIndex()` calls `engine.clear()` then repopulates. With the two services initialising asynchronously, the second `rebuildIndex()` clobbers whatever the first built. In steady-state autosave, the editor's service wins because it fires on every save. The module-level service only fires once at init.

**Severity:** Medium — causes a brief window of empty index after module init; steady-state is correct.

### D8b — `IndexPageWidget` reads legacy `ChapterListProvider` instead of `ManuscriptBinderProvider`

**Evidence:** `index_page_widget.dart` accepts a `ChapterListProvider` and lists `chapterProvider.chapters`. This is the front-matter Index page (a non-Quill widget for `front_matter_-2`). It lists legacy `Chapter` objects, not `ManuscriptDocument` entries. Any chapter created via the new binder system will NOT appear on the Index page unless it also exists in the legacy `chapters` box.

**Severity:** High for front-matter correctness. All new documents live in `manuscript_documents` box only.

### D8c — `deleteDocument` in Binder UI does not show confirmation for documents with children

**Evidence:** `manuscript_binder.dart._DocumentContextMenu` calls `provider.deleteDocument(documentId)` — the no-argument form which maps to `deleteChildren: false`. `ManuscriptBinderService.deleteDocument(deleteChildren: false)` promotes children but if children exist it calls `moveDocument` per child. No dialog warns the user. If a chapter has scenes, they are silently re-parented to the manuscript root. The spec (§30.2) requires "an explicit policy such as promote children, cascade delete, or cancel" to be "clear to the user."

**Severity:** Medium — data is not lost, but the behaviour is invisible to the user.

### D8d — `chapter_diff_view_dialog.dart` opens `Hive.box<Chapter>('chapters')` directly in widget

**Evidence:** `chapter_diff_view_dialog.dart:24`: `final chapterBox = Hive.box<Chapter>('chapters');`  
This violates the project rule "no direct `Hive.openBox()` calls in widgets." The box is always open so no runtime crash results, but if the `chapters` box were ever removed or renamed this dialog would throw. Furthermore, revert writes `chapter.save()` back to the legacy `chapters` box — it does NOT update the corresponding `ManuscriptDocument` in the new box.

**Severity:** Medium — rule violation + partial revert (restores legacy box but not ManuscriptDocument).

### D8e — `tagIds` field is stored but never rendered

**Evidence:** `ManuscriptDocument.tagIds` (HiveField 14) is populated in `createDocument` and `updateMetadata`, but no widget reads it for display. Not shown in Binder, Corkboard, Outliner, Inspector, or Collections. The spec (§7 Corkboard) lists "tags" as a card field. 

**Severity:** Low — data is saved, just not surfaced.
