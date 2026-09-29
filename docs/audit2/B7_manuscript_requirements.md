# B7 — Manuscript Rebuild Requirements

> All requirements derived exclusively from evidence in passes A1–B6.  
> Sources cited by spec statement (S-xx), defect (D-xx), or B-pass reference.

---

## 1. Scope

This document specifies requirements for a clean rebuild of the Manuscript module in Lore Keeper. "Rebuild" means replacing or substantially rewriting the files listed in B2 while keeping the rest of the application — shell, providers for non-manuscript entities, reference engine, AI layer, database manager, and all non-manuscript tests — green.

The rebuild targets the following files as primary change surface:

- `lib/modules/manuscript_module.dart`
- `lib/widgets/manuscript_*.dart` (binder, corkboard, outliner, collections, inspector, list_pane)
- `lib/widgets/find_replace_dialog.dart`
- `lib/widgets/history_panel.dart`
- `lib/widgets/chapter_diff_view_dialog.dart`
- `lib/widgets/index_page_widget.dart`
- `lib/services/manuscript_reference_service.dart`
- `lib/services/history_service.dart` (targeted changes only)
- `lib/screens/project_editor_screen.dart` (targeted changes only — history panel wiring, column keys)

---

## 2. Explicit Non-Goals

The following are out of scope for this rebuild:

- Replacing Hive with a different database (the rebuild uses the existing `DatabaseManager` and box schema)
- Removing or migrating the legacy `Chapter`/`Section` boxes (they remain open; V2→V3 migration is complete)
- Changing `ManuscriptDocument`, `ManuscriptCollection`, `EntityRef`, `ReferenceEngine`, `ReferenceIntegrityService`, `ReferenceNameResolver`, `EntityNameMatcher`, or `ManuscriptBinderService` public APIs (B4)
- Adding new entity types to the reference system (Location, Item, Org, Faction)
- Implementing Markdown/filesystem interchange (S-51, deferred)
- Implementing the AI ContextBuilder (S-55, deferred)
- Implementing `SpecificFunctionsBar` (S-08, deferred)
- Replacing `flutter_quill` with a different editor
- Changing the `EntityNameMatcher` confidence scores (B6 §8 — tests assert on them)

---

## 3. Requirements

### Architecture / Topology

**MS-001** MUST — Single four-column layout  
The runtime widget tree for the Manuscript view must contain exactly: 1 `ModuleSidebar`, 1 `ManuscriptListPane`, 1 `ManuscriptEditor`, 1 `ManuscriptInspector`. No additional Binder, navigation tree, or Manuscript workspace may appear anywhere in the tree.  
Source: S-07, S-09, S-66  
Acceptance: `manuscript_topology_test.dart` must assert `findsOneWidget` for each of the four canonical keys. Currently `kManuscriptListPaneKey` and `kManuscriptEditorKey` are verified; `kManuscriptInspectorKey` and the Column 1 / shell keys must be added.

**MS-002** MUST — Widget keys for topology testability  
The following `Key` constants must be present and applied to their respective widgets: `Key('manuscript-list-pane')` on `ManuscriptListPane`, `Key('manuscript-editor')` on `ManuscriptEditor`, `Key('manuscript-inspector')` on `ManuscriptInspector`.  
Source: S-22, B6 §1  
Acceptance: Each key `findsOneWidget` in a topology test.

**MS-003** MUST — Single shared provider, no silent re-instantiation  
`ManuscriptListPane`, `ManuscriptBinder`, `ManuscriptCorkboard`, `ManuscriptOutliner`, `ManuscriptCollections`, `ManuscriptEditor`, and `ManuscriptInspector` must all receive the same `ManuscriptBinderProvider` instance constructed by `ProjectEditorScreen`. No child widget may call `ManuscriptBinderProvider(...)` itself in a live Project Editor session.  
Source: S-19, B2 observations  
Acceptance: Unit test confirms `provider.hashCode` is identical across all column widgets.

**MS-004** MUST — Single shared ReferenceEngine  
The `ReferenceEngine` created by `ProjectEditorScreen` must be the only engine instance passed to `ManuscriptReferenceService`. `ManuscriptEditorState` must not create a fallback engine when `widget.sharedReferenceEngine` is provided.  
Source: S-20, D8a  
Acceptance: In a topology test, assert that `ManuscriptReferenceService` and `ManuscriptInspector` both hold a reference to the same engine object (same `identityHashCode`).

**MS-005** MUST — Logic layers must not import `BuildContext` or widget packages  
`ManuscriptBinderService`, `ManuscriptCollectionsService`, `ManuscriptReferenceService`, `HistoryService`, `ReferenceNameResolver`, and `ReferenceIntegrityService` must contain zero `import 'package:flutter/material.dart'` or similar widget-layer imports.  
Source: Prompt constraint (mobile support must require UI changes only)  
Acceptance: `flutter analyze` with a custom lint rule, or grep for `import 'package:flutter/` in the above files returning 0 hits.

---

### History (fixing D1)

**MS-006** MUST — History panel shows ManuscriptDocument revisions  
`ProjectEditorScreen._buildHistoryPanel()` for `_moduleIndex == 1` must pass `targetType: 'ManuscriptDocument'` and `targetKey: _selectedManuscriptDocumentId` to `HistoryPanel`, not `targetType: 'Chapter'` with the legacy chapter key.  
Source: D1, B5  
Acceptance: Test that seeding a `HistoryEntry(targetType: 'ManuscriptDocument', targetKey: 'chapter_1')` and opening `HistoryPanel(targetType: 'ManuscriptDocument', targetKey: 'chapter_1')` shows that entry in the list. Currently fails.

**MS-007** MUST — ManuscriptDocument diff and revert  
`HistoryPanel` must handle `targetType: 'ManuscriptDocument'`: display a diff between the stored JSON snapshot and the current `ManuscriptDocument.richTextJson`, and provide a Revert action that writes the historical `richTextJson` back to the document via `ManuscriptBinderProvider.revertContentTo`.  
`revertContentTo` is the undoable revert path: it snapshots the pre-revert content through `HistoryService` before overwriting, treats a revert to the content already loaded as a no-op, and then signals the open editor to reload the canonical document (`revertSignal` → `ManuscriptEditor._applyExternalRevert`). Bare `ManuscriptBinderProvider.updateContent` is the *content write* path (MS-008) and is **not** sufficient for a revert, because it overwrites without recording what it replaced and leaves the open editor showing stale prose.  
Source: D1, S-32  
Acceptance: Test that reverting a `ManuscriptDocument` history entry updates `ManuscriptDocument.richTextJson` to the historical value, does NOT read from the legacy `chapters` box, and leaves a pre-revert `HistoryEntry` so the revert itself can be undone. Further test that the open editor's `QuillController` displays the reverted content and that a debounce armed before the revert is cancelled rather than writing the pre-revert buffer back.

**MS-008** SHOULD — History autosave guards against identical content  
`ManuscriptEditor._saveContent` must not write a new `HistoryEntry` if `richTextJson` has not changed since the last save.  
Source: D7  
Acceptance: Unit test that saves the same content twice asserts `historyBox.length == 1` (not 2).

---

### Word / Character Counts (fixing D2)

**MS-009** MUST — Single canonical word-count implementation  
Word count must be computed from Quill `toPlainText().trim().split(RegExp(r'\s+'))` in all contexts: live editor status bar, `ManuscriptBinderService.updateContent`, and the V2→V3 migration `_countWords`. The JSON-regex implementation in `ManuscriptBinderService._countWords` must be replaced.  
Source: D2, B4 §1  
Acceptance: Test that a document with content `"Hello world"` (Delta `[{"insert":"Hello world\n"}]`) yields `wordCount == 2` after calling `updateContent`. Currently fails.

**MS-010** MUST — Single canonical character-count implementation  
Character count must equal `toPlainText().length` (plain-text characters, not JSON string length) in all persistence paths.  
Source: D2, B4 §1  
Acceptance: Same fixture as MS-009; assert `characterCount == 11` (or the plain-text length). Currently fails.

---

### Find & Replace (fixing D3)

**MS-011** MUST — Replace preserves `ref:` link attributes and all other formatting  
`FindReplaceDialog._performReplace` and `_replaceAll` must use `replaceText` with a `TextSelection` that preserves attributes on the replaced span (not `null`), or reconstruct the attributes after replacement.  
Source: D3, B4 §16  
Acceptance: Test (failing sketch in B5 D3): after replacing a word adjacent to a `ref:` span, the `ref:` span retains its `link` attribute.

**MS-012** MUST — Replace All uses live document coordinates  
`_replaceAll` must iterate replacements in **descending offset order** (highest offset first) so that earlier replacements do not shift the coordinates of later ones, or track cumulative offset delta.  
Source: D3  
Acceptance: Test with `findText = "a"`, `replaceText = "bbb"` applied to `"a cat and a dog"` produces `"bbb cbbbt bbbnd bbb dog"` — no shifted characters. Currently fails with offset drift.

**MS-013** SHOULD — Find supports Next/Previous navigation  
Find should advance to the next occurrence on repeated Find calls, with wrap-around at end of document. Result count should be displayed.  
Source: S-48  
Acceptance: Test that calling Find twice on `"the cat the dog"` with query `"the"` selects offset 0 then offset 8.

---

### ReferenceIndex Integrity (fixing D3/D4)

**MS-014** MUST — `rebuildIndex` must not clear non-manuscript engine entries  
`ManuscriptReferenceService.rebuildIndex()` must replace only the manuscript-sourced entries in the engine, not call `engine.clear()`. Suggested approach: `engine.removeWhere((e) => e.source.entityType == EntityType.manuscriptDocument)` before re-adding.  
Source: D4, B4 §13  
Acceptance: Failing test in B5 D4 — engine entry from another source survives a `rebuildIndex()` call.

**MS-015** MUST — Single `ManuscriptReferenceService` instance per module session  
`ManuscriptModuleState` and `ManuscriptEditorState` must not each create an independent `ManuscriptReferenceService`. The service must be created once (in `ManuscriptModuleState`) and passed down to `ManuscriptEditor`.  
Source: D8a  
Acceptance: Static analysis (no second instantiation of `ManuscriptReferenceService` inside `ManuscriptEditorState`).

---

### Stale Reference Handling (fixing D5)

**MS-016** SHOULD — Unsupported entity types must not be purged as stale  
`ReferenceNameResolver.entityExists` must return a three-valued result for the entity-type cases it cannot resolve: `true` (exists), `false` (known-deleted), `unknown` (no canonical source). Entries whose target resolves to `unknown` must not be purged by `purgeStaleEntries`.  
Source: D5  
Acceptance: Test that a `ref:Location:uuid` entry survives a `purgeStaleEntries()` call. Currently fails because `entityExists` returns `false` for `Location`.

Note: This requires either a tri-state `entityExists` function or a separate `entityIsDefinitelyGone(EntityRef)` predicate. The existing `bool entityExists(EntityRef)` signature on `ReferenceIntegrityService` must not be changed in a way that breaks current callers; prefer adding a new predicate.

---

### Document Operations (fixing D6, D8c)

**MS-017** MUST — Document deletion shows explicit confirmation for non-empty documents  
When the user triggers Delete on a document that has children, a dialog must present the options: "Delete with all children", "Promote children to parent level", or "Cancel". The chosen action must be clear before any data changes.  
Source: D8c, S-56  
Acceptance: Test that deleting a document with children without confirming makes zero changes to the Hive box.

**MS-018** SHOULD — Duplicate document operation  
`ManuscriptBinderService` and `ManuscriptBinderProvider` must expose a `duplicateDocument(String sourceId)` method that creates a deep copy of the document (including `richTextJson`) with a new UUID-based id and `title = "<original> (copy)"`. The duplicate is placed as a sibling immediately after the original.  
Source: S-18, B3 (PARTIAL for hierarchy operations)  
Acceptance: Test that `duplicateDocument('scene_abc')` produces a new document with a different `id`, same `richTextJson`, `title` ending in `(copy)`, same `parentId`, and `orderIndex == original.orderIndex + 1`.

---

### Legacy Dependencies (fixing D8b, D8d)

**MS-019** MUST — `IndexPageWidget` reads from `ManuscriptBinderProvider`, not legacy `ChapterListProvider`  
The front-matter Index page must list `ManuscriptDocument` entries of type `chapter` and `scene` from `ManuscriptBinderProvider.getDocumentsByType()`, not legacy `Chapter` objects from `ChapterListProvider`.  
Source: D8b  
Acceptance: Test that after creating a `ManuscriptDocument` of type `chapter`, it appears in `IndexPageWidget`'s list without requiring an entry in the legacy `chapters` box.

**MS-020** MUST — The `ManuscriptDocument` diff/revert path must not open Hive boxes directly  
The diff/revert dialog for manuscripts must receive the current `ManuscriptDocument` data via parameter (not by reading from `Hive.box<Chapter>('chapters')` directly). Revert must write via `ManuscriptBinderProvider.updateContent`, not via `chapter.save()`.  
`ChapterDiffViewDialog` (`lib/widgets/chapter_diff_view_dialog.dart`) is legacy: it is intentionally left untouched and continues to serve pre-manuscript `Chapter` snapshots only. This requirement governs the manuscript path — `ManuscriptDocumentDiffViewDialog` (`lib/widgets/manuscript_diff_view_dialog.dart`) and `HistoryPanel` (`lib/widgets/history_panel.dart`) — which must never open `Hive.box<Chapter>`, deserialize a snapshot with `chapterFromJson`, or depend on `lib/models/chapter.dart`.  
Source: D8d, B2 (rule violation)  
Acceptance: Static guard (commit `4bb80aa`; `test/widgets/manuscript_history_test.dart`, "no manuscript history widget opens Hive.box<Chapter> (MS-020)") — after stripping comments, `manuscript_diff_view_dialog.dart` and `history_panel.dart` must contain no `Hive.box<Chapter>`, no `chapterFromJson`, and no `models/chapter.dart` import. Comments are stripped because the manuscript dialog's doc comment legitimately names `Hive.box<Chapter>` to explain that it never opens it. Revert test confirms `manuscriptDocuments` box is updated.

---

### Data Model Requirements

**MS-021** MUST — No new dependency on legacy `Chapter`/`Section` boxes in manuscript UI  
New manuscript UI code must not introduce imports of `lib/models/chapter.dart` or `lib/models/section.dart` or read from `Hive.box<Chapter>` directly. Existing legacy consumers (`GlobalSearchDelegate`, `ChapterListProvider`) are unchanged.  
Source: B2 observations, B3 (legacy-dependent column)  
Acceptance: Grep for `import.*chapter.dart` and `Hive.box<Chapter>` in all new/changed manuscript widget files returns 0 hits.

**MS-022** MUST — Stable document IDs through all operations  
Rename, move, reorder, status change, and metadata update must not change `ManuscriptDocument.id`.  
Source: S-17  
Acceptance: Test that `updateTitle`, `moveDocument`, `reorderDocument`, `updateStatus` all leave `doc.id` unchanged. Already passing for service layer; must remain passing after rebuild.

**MS-023** MUST — Circular hierarchy impossible through normal UI  
`moveDocument` must reject a move that would make a document its own ancestor. The `_wouldCreateCycle` check in `ManuscriptBinderService` must be preserved.  
Source: S-57, S-18  
Acceptance: Test that moving a Part under one of its own children throws `StateError`. Already passing; must remain passing.

**MS-024** MUST — Project isolation for all reference queries  
Every `ReferenceEngine` query, `ReferenceNameResolver.resolveById`, and `ManuscriptReferenceService` operation must include `projectId` in filtering. A reference from Project A must never resolve against an entity in Project B.  
Source: S-44  
Acceptance: Existing `reference_name_resolver_test.dart` cross-project tests must remain green.

**MS-025** SHOULD — `tagIds` rendered in at least one view  
`ManuscriptDocument.tagIds` must be displayed in the Inspector and/or Corkboard card. The field is already persisted; it needs only a display path.  
Source: D8e, S-26 (Corkboard "tags")  
Acceptance: Test that a document with `tagIds = ['fantasy', 'action']` shows those tags in the Inspector widget.

---

### Statistics

**MS-026** SHOULD — Character count shown live in editor status bar  
The status bar must display `Chars: N` alongside `Words: N`, using `toPlainText().length`.  
Source: S-35, D2  
Acceptance: Test that the status bar widget contains a text matching `RegExp(r'Chars: \d+')` while a document is loaded.

**MS-027** SHOULD — Branch word count visible in Binder  
The Binder node for a container document (Part, Chapter) must show the sum of `wordCount` across all descendants, via `ManuscriptBinderProvider.getBranchWordCount`.  
Source: S-49  
Acceptance: Test that a Part containing two scenes with `wordCount = 100` each shows `200` in the Binder row.

---

### Search / Navigation

**MS-028** SHOULD — Inspector backlink navigation is wired end-to-end  
Tapping a backlink in `ManuscriptInspector` must call `onDocumentSelected` which must reach `ProjectEditorScreen._onManuscriptDocumentSelected`, updating both `_selectedManuscriptDocumentId` and the `ManuscriptListPane` selection.  
Source: S-25, B3 (S-25 YES but Inspector→shell path verified by inspection only)  
Acceptance: Widget test that taps a backlink tile and asserts `ManuscriptListPane` shows the target document selected.

---

## 4. Defect-Derived Requirements (each has a failing test today)

| ID | Defect | Requirement | Failing test sketch |
|---|---|---|---|
| MS-006 | D1 | HistoryPanel shows ManuscriptDocument history | `HistoryPanel(targetType:'ManuscriptDocument', targetKey:'chapter_1')` finds entry |
| MS-007 | D1 | Revert via ManuscriptBinderProvider, not Chapter box | Revert updates `manuscriptDocuments[id].richTextJson` |
| MS-009 | D2 | Word count = plain-text split | `updateContent` → `doc.wordCount == 2` for "Hello world" |
| MS-010 | D2 | Char count = plain-text length | `updateContent` → `doc.characterCount == 11` for "Hello world" |
| MS-011 | D3 | Replace preserves ref: link | Replace adjacent to mention preserves `link` attribute |
| MS-012 | D3 | Replace All uses descending offset | "a cat and a dog" → "bbb cat and bbb dog" no drift |
| MS-014 | D4 | rebuildIndex does not clear alien entries | Non-manuscript engine entry survives rebuild |
| MS-016 | D5 | Location refs not purged | `ref:Location:x` entry survives `purgeStaleEntries()` |

---

## 5. Constraints

1. **Flutter only.** No web backend, no native code changes.
2. **Desktop primary; mobile must require UI changes only.** All service, provider, and data classes must be free of `BuildContext`, `Widget`, or Flutter rendering imports. Tests must be runnable as plain Dart unit tests where the class under test is a service.
3. **Mentions stay as Quill link attributes over real text.** `ref:TypeLabel:id` encoded as Quill `LinkAttribute` is the canonical wire format. Do not replace with embed objects or custom Delta ops.
4. **Existing reference engine tests must keep passing or be consciously ported.** Any change to `ReferenceEngine`, `ReferenceIndex`, `EntityRef`, `EntityNameMatcher`, or `ManuscriptBinderService` public API requires explicit signoff and test-update.
5. **Do not run `dart run build_runner`.** Hand-written `.g.dart` adapters are committed. If `ManuscriptDocument` gains new fields, update `manuscript_document.g.dart` manually.
6. **`flutter analyze` must return 0 issues** after every incremental change before the next change is made.
7. **All 377 existing tests must remain green** throughout the rebuild. Any failing test introduced by a change must be fixed before continuing.

---

## 6. Open Questions

| # | Question | Recommended default |
|---|---|---|
| OQ-1 | Should the legacy `chapters` box be kept open indefinitely? `GlobalSearchDelegate` and `OverviewModule` still read from it. | Keep open. Replace their reads only when those modules are explicitly rebuilt. |
| OQ-2 | Should `ReferenceNameResolver.entityExists` return a tri-state for MS-016, or is it acceptable to leave Location/Item/Org refs as "always unresolved but never purged"? | Add `bool entityIsDefinitelyGone(EntityRef)` as a second predicate; use it in `purgeStaleEntries` alongside the existing `entityExists`. Avoids breaking the existing bool-based API. |
| OQ-3 | Should history granularity be increased beyond 10 entries, or should the debounce be raised to reduce snapshot frequency? | Raise `_autosaveDelay` to 5 s and add the content-change guard (MS-008) before increasing the limit. |
| OQ-4 | `ManuscriptDocument.tagIds` exists but there is no tag management UI. Should tags be editable in the Inspector or in a dedicated dialog? | Inspector inline chips with add/remove. Defer full tag management screen. |
| OQ-5 | Calendar date fields (HiveFields 22–24) store raw year/dayOfYear. The Inspector shows raw integers. Should the rebuild add a formatted display using `CalendarSystem` chronology, or defer? | Defer formatted display until the Calendar module exposes a formatting API. Show "Day N of Year Y (System K)" as a placeholder. |
| OQ-6 | `EntityType.mapData` and `EntityType.mapLayer` remain in `EntityType.all`, which means `ReferenceEngine.rebuildIndex` (full-rebuild variant) iterates them. Should they be removed from `all` now or kept until the Map module is rebuilt? | Keep until Map module is rebuilt; removing them from `all` risks breaking the entity_ref test. |
| OQ-7 | The spec's zero baseline cites "300/300 tests". The current baseline is 377. Should the requirements doc update the baseline number? | Yes — the operative baseline is the current green count (377). Document it as such. |
| OQ-8 | A revert does not flush the editor's unsaved buffer first, so text typed but not yet autosaved can be lost without being snapshotted. | Warn the user and let them cancel if the buffer has unsaved changes. Deferred. |

---

## 7. Risk List

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| `rebuildIndex` fix (MS-014) breaks reference autocomplete or backlink tests | Medium | High | Run `reference_autocomplete_test.dart` and `manuscript_reference_service_test.dart` after every change to `rebuildIndex` |
| History fix (MS-006/007) accidentally reads `ManuscriptDocument` with the legacy `Chapter` deserializer | Low | High | Add an explicit type assertion in the revert path; never cast `historyEntry.data` to `Chapter` for `targetType == 'ManuscriptDocument'` |
| Find & Replace fix (MS-011/012) changes Quill controller mutation semantics, breaking autocomplete insert | Medium | Medium | Run `reference_autocomplete_test.dart` (1,119 lines) after any `replaceText` call-site change |
| Changing `_countWords` in `ManuscriptBinderService` (MS-009) alters word counts for all existing documents on next save | Certain | Low | Counts diverge silently today anyway; first save after upgrade will correct them. Document in migration notes. |
| `MS-015` (single ManuscriptReferenceService) requires threading the service through `ManuscriptEditor` constructor; adds a parameter to a 1,300-line file | Low | Low | Extract `ManuscriptEditor` into its own file simultaneously to keep diff readable |
| `MS-019` (IndexPageWidget reads ManuscriptBinderProvider) may not show legacy chapters that were never migrated | Low | Medium | Only affects projects that were never opened after V2→V3 migration; acceptable edge case |
| `MS-016` (tri-state entityExists) requires adding a new predicate to `ReferenceIntegrityService`; could be missed by callers | Low | Low | Add predicate behind an optional parameter with a safe default (`unknown` entities not purged) |
