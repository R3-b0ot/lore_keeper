# B6 — Preserve List

> What a clean rebuild must keep. Every item is sourced from direct code reads.  
> A tester can walk the checklist section by section to confirm the rebuild has not regressed.

---

## 1. Screen Layout and Topology

The four-column desktop layout is a P0 invariant. Any rebuild must produce exactly this runtime structure:

| Column | Widget | Key | Collapsible? |
|---|---|---|---|
| 1 | `ModuleSidebar` (project module tabs) | `project-editor-column-1` (missing today — must add) | No |
| 2 | `ManuscriptListPane` | `Key('manuscript-list-pane')` | Yes — `_isListPaneCollapsed` toggle button in shell |
| 3 | `ManuscriptEditor` | `Key('manuscript-editor')` | No |
| 4 | `ManuscriptInspector` | `Key('manuscript-inspector')` | No (fixed 300 px width) |
| Right | `SpecificFunctionsBar` | `specific-functions-bar` (not yet built) | N/A |

Column 2 collapse: clicking the divider/toggle in the desktop layout sets `_isListPaneCollapsed = true`, hiding the list pane. The editor expands to fill the space. Collapsing must not create a second list pane.

Column 4 width: currently fixed at `SizedBox(width: 300)` in `ManuscriptModule.build()`.

---

## 2. Column 2 — ManuscriptListPane

### View switcher
Four icon-only buttons in the header bar:
- `LucideIcons.listTree` → Binder (default)
- `LucideIcons.layoutGrid` → Corkboard
- `LucideIcons.list` → Outliner
- `LucideIcons.folderSearch` → Collections

Switching view does NOT reset the selected document, does NOT re-initialize the provider.

### Binder
- [ ] Hierarchical tree, indented by depth
- [ ] Each node shows: type icon + colour, title, word count (for leaf nodes), status indicator (archived = italic)
- [ ] Expand/collapse chevron per node (persisted via `isExpanded` HiveField)
- [ ] Click to select (highlights in `primaryContainer`)
- [ ] Double-click or right-click → context menu
- [ ] Context menu items: Add Child, Add Sibling, Rename, Delete, Move (drag or explicit)
- [ ] Drag reorder via `ReorderableListView` within a parent's children
- [ ] Add Part button and Add Chapter button in the Binder toolbar
- [ ] Add-document dialog with type dropdown (all types except `manuscript`)
- [ ] Inline rename field on selected node
- [ ] Delete removes document; children are promoted to parent level (no cascade by default)
- [ ] Manuscript root node always visible at top; cannot be deleted or reordered

### Corkboard
- [ ] Card grid layout
- [ ] Each card shows: title, summary (truncated), word count, status chip, POV (label)
- [ ] Drag reorder (updates `orderIndex` via provider)
- [ ] Click card → selects document (updates editor + inspector)
- [ ] Container document selector at top (defaults to selected doc or manuscript root)

### Outliner
- [ ] Table with rows for each child document
- [ ] Columns: Title, POV, Location, Timeline, Words, Status, Plotline
- [ ] Column visibility toggle (eye icon per column)
- [ ] Row click → selects document
- [ ] Container document selector at top

### Collections
- [ ] Left rail: 16 smart collection type buttons (`CollectionType` enum)
- [ ] Entity collection section (Characters, Species, Locations, etc.)
- [ ] Custom collections section with create/rename/delete
- [ ] Search field filters displayed documents
- [ ] Clicking a document result calls `onDocumentSelected`
- [ ] Favorites accessible as `CollectionType.favorites`

---

## 3. Column 3 — ManuscriptEditor

### Toolbar
- [ ] Switches between title toolbar and main toolbar based on which editor is focused
- [ ] Title toolbar: Bold, Italic, Underline, StrikeThrough (simplified)
- [ ] Main toolbar (600 px wide, horizontally scrollable): Bold, Italic, Underline, StrikeThrough, Alignment, Headers, Blockquote, Undo, Redo, Find/Replace button, Focus Mode button
- [ ] Front-matter pages (`front_matter_-1/-2/-3`) suppress the toolbar entirely

### Document loading
- [ ] Loading spinner shown while `_isLoading = true`
- [ ] On document select: saves old document first, then loads new content
- [ ] Front-matter key `front_matter_-1` → `CoverPageForm` widget
- [ ] Front-matter key `front_matter_-2` → `IndexPageWidget` widget
- [ ] Front-matter key `front_matter_-3` → `AboutAuthorForm` widget
- [ ] All other keys → Quill editor

### Quill editor
- [ ] Two separate Quill editors: title editor (top) + body editor
- [ ] Title displayed as H1 style
- [ ] Body placeholder text: `'Write your story...'`
- [ ] `customLinkPrefixes: ['ref:']` — makes `ref:` URIs clickable
- [ ] `onLaunchUrl` → `_onReferenceLaunch` → parses `ref:Type:id` → calls `onReferenceNavigate`
- [ ] Embed builders: `FlutterQuillEmbeds.editorBuilders()` (images/video)
- [ ] `InteractiveViewer` wraps editor card (pan disabled, scale disabled)
- [ ] `Scrollbar` with `_scrollController`

### Autosave
- [ ] Body text: debounced 2 s after last keystroke (`_autosaveDelay`)
- [ ] Title text: separate 2 s debounce (`_titleAutosaveTimer`)
- [ ] Saving indicator: "Saving..." text in status bar while `_isSaving = true`
- [ ] Saves to `ManuscriptBinderProvider.updateContent` + `updateTitle`
- [ ] Chapter-switch: saves old content synchronously before loading new

### Status bar (bottom)
- [ ] Left: word count (`Words: N`)
- [ ] Left: Grammar button (shows "Checking…" / "Grammar" / "Issues: N") with triangle/check icon
- [ ] Left: Auto-correct wand button
- [ ] Right: "Saving..." label when saving
- [ ] Right: Zoom percentage (`Zoom: N%`)
- [ ] Right: Minus/plus zoom buttons (range 50%–200% in 10% steps)

### Focus Mode
- [ ] Entered via Focus Mode toolbar button (maximize icon)
- [ ] Shows: title label in top bar + maximize/exit button
- [ ] Full-screen editor with `maxWidth: 900` constraint
- [ ] Mini status bar at bottom (word count, zoom %)
- [ ] Exit button restores normal four-column layout
- [ ] Does NOT create a second workspace; editor state is preserved

### Grammar check
- [ ] Consent dialog shown before first LanguageTool network call
- [ ] Grammar panel slides in from right (7:3 editor:panel ratio, or column below 820 px)
- [ ] Panel: category filter chips (All + per-category) + issue cards
- [ ] Issue card: category label, message, context snippet, Accept / Dismiss buttons
- [ ] Accept: replaces text at stored offset, removes issue from list
- [ ] Dismiss: removes issue from list without editing
- [ ] Close button collapses grammar panel
- [ ] Auto-correct: applies all replacements in descending offset order to avoid drift
- [ ] Ignored words from `project.ignoredWords` are filtered out

### Find & Replace dialog
- [ ] Opened from toolbar button or keyboard shortcut (Ctrl+F equivalent via shell)
- [ ] Fields: Find, Replace With, Case Sensitive checkbox
- [ ] Find button: jumps to first occurrence (from start; no wrap; no next)
- [ ] Replace button: replaces current selection if it matches
- [ ] Replace All button: replaces all occurrences
- [ ] Keyboard: Tab between fields, Enter on Replace All
- [ ] Focus requests on Find field on open

---

## 4. Column 4 — Inspector

- [ ] Empty state: info icon + "Select a document" + sub-caption
- [ ] Header: type icon (coloured by type) + "Inspector" label
- [ ] Scrollable body sections:

**Document section:**
- [ ] Type (label), Status (label), Words (count), Characters (count)
- [ ] Created date (formatted), Modified date (formatted)

**Scene Metadata section** (for `isLeaf` documents only):
- [ ] POV Character: resolved name or `Unresolved • <id>` if null resolver
- [ ] Location: raw `locationId` (no resolver — show raw id or "—")
- [ ] Timeline: resolved event name or `Unresolved • <id>`
- [ ] Plotline: raw string or "—"

**Characters section** (if `characterIds` non-empty):
- [ ] Bullet list of resolved character names or `Unresolved • <id>`

**References section** (outgoing `ref:` mentions):
- [ ] List of entities this document mentions
- [ ] Resolved name + entity type label
- [ ] Unresolved state for unknown types

**Backlinks section** (incoming — "Referenced by"):
- [ ] List of documents that mention this document via `ref:ManuscriptDocument:id`
- [ ] Each item is a tappable link → calls `onDocumentSelected` (updates binder + editor)

---

## 5. History Panel

- [ ] Opened via History button in shell (supported for Manuscripts module and Characters)
- [ ] 300 px panel attached to the right of the editor
- [ ] List of `HistoryEntry` filtered by `targetKey` + `targetType`
- [ ] Each entry: formatted timestamp, "Version snapshot" subtitle, Revert button
- [ ] Revert opens `ChapterDiffViewDialog` for `'Chapter'` type, `DiffViewDialog` for `'Character'`
- [ ] For `'ManuscriptDocument'` type: currently shows "Diff view not supported" (known bug D1)
- [ ] Close button dismisses panel

> Note: The entire history feature for ManuscriptDocument is currently non-functional (D1). The rebuild must fix this. The checklist above describes the intended preserved UX, not current behaviour.

---

## 6. Every Visible Control, Menu, Shortcut, and Interaction

| Control | Location | Action |
|---|---|---|
| Module sidebar tab "Manuscripts" | Column 1 | Switches to manuscript module (index 1) |
| List pane collapse toggle | Desktop layout header | `_isListPaneCollapsed` toggle |
| View switcher buttons (4) | ManuscriptListPane header | Switch between Binder/Corkboard/Outliner/Collections |
| Binder tree expand/collapse | Each `_BinderNode` chevron | Toggles `isExpanded`, persisted |
| Binder node click | `_BinderNode` tap | Selects document → editor + inspector update |
| Binder context menu | Right-click / long-press on node | Add Child, Add Sibling, Rename, Delete, Move |
| Binder "Add Part" button | Binder toolbar | Creates Part child of manuscript root |
| Binder "Add Chapter" button | Binder toolbar | Creates Chapter child |
| Binder drag handle | `ReorderableListView` drag | Reorders siblings, persists `orderIndex` |
| Corkboard card click | `ManuscriptCorkboard` | Selects document |
| Corkboard drag | `ReorderableListView` | Reorders children |
| Outliner row click | `ManuscriptOutliner` | Selects document |
| Outliner column visibility toggle | Column header | Shows/hides columns |
| Collections type button | Left rail | Filters document list |
| Collections search field | `_searchController` | Filters by text |
| Collections custom collection create | + button | Creates named custom collection |
| Collections document tile tap | `onDocumentSelected` | Opens document in editor |
| Title editor focus | `_titleFocusNode` | Switches toolbar to title toolbar |
| Body editor focus | `_focusNode` | Switches toolbar to main toolbar |
| Bold / Italic / Underline / etc. | Quill toolbar | Applies formatting to selection |
| Header style dropdown | Quill toolbar | Applies H1–H6 |
| Undo / Redo | Quill toolbar | Quill built-in |
| Find button (toolbar) | `QuillToolbarCustomButton` | Opens `FindReplaceDialog` |
| Focus Mode button (toolbar) | `QuillToolbarCustomButton` | Enters focus mode |
| Focus Mode exit button | Top bar maximize icon | Restores normal layout |
| Zoom − button | Status bar | `_zoomFactor -= 0.1` (min 0.5) |
| Zoom + button | Status bar | `_zoomFactor += 0.1` (max 2.0) |
| Grammar button | Status bar | Opens grammar panel, triggers check |
| Auto-correct wand | Status bar | Applies all replacements automatically |
| Grammar category chip | Grammar panel | Filters issues by category |
| Grammar Accept button | Issue card | Applies replacement |
| Grammar Dismiss button | Issue card | Dismisses issue |
| Grammar Close button | Panel header | Collapses grammar panel |
| Consent dialog Continue | First grammar trigger | Enables external proofing |
| Consent dialog Cancel | First grammar trigger | Aborts check |
| Find field | FindReplaceDialog | Searches on Find click |
| Replace With field | FindReplaceDialog | Replacement text |
| Case Sensitive checkbox | FindReplaceDialog | Toggles case matching |
| Find button | FindReplaceDialog | Finds first occurrence |
| Replace button | FindReplaceDialog | Replaces current selection |
| Replace All button | FindReplaceDialog | Replaces all occurrences |
| @ key in body editor | Autocomplete trigger | Opens mention overlay |
| Autocomplete overlay ↑/↓ | Keyboard | Navigates candidates |
| Autocomplete overlay Enter | Keyboard | Inserts selected reference |
| Autocomplete overlay Escape | Keyboard | Dismisses overlay |
| `ref:` link click in editor | `onLaunchUrl` | Navigates to referenced entity |
| Inspector backlink tap | `onDocumentSelected` callback | Selects document in binder + editor |
| History button | Shell AppBar / desktop layout | Toggles history panel |
| History Revert button | History panel entry | Opens diff/revert dialog |

---

## 7. Mention/Autocomplete Behaviour

### Trigger rules (must preserve exactly)
- Triggers on `@` character when immediately preceded by whitespace or at document start
- Does NOT trigger mid-word
- Dismisses on Escape, on whitespace-only query, or when no matches remain

### Candidate sources (current — 4 of 10 types)
- Characters (from `CharacterListProvider`, including aliases and iteration names)
- Species (from `SpeciesProvider`, leaf nodes with stable `id`)
- Timeline Events (from `TimelineEventProvider`)
- Manuscript Documents (from `ManuscriptBinderProvider.allDocuments`)

### Ranking (must preserve — tests assert on confidence values)
- exactName: 1.0
- exactAlias: 0.9
- prefixName: 0.7
- prefixAlias: 0.6
- substringName: 0.3
- substringAlias: 0.2
- Max 20 candidates returned; overlay shows max 8 rows

### Keyboard navigation
- ↑/↓ moves selection (wraps at ends)
- Enter inserts selected candidate
- Escape dismisses without inserting

### Insert behaviour
- Inserts the entity's display name as plain text
- Applies `LinkAttribute('ref:TypeLabel:id')` to the inserted span
- Removes the `@` prefix + partial query typed so far
- Does not strip surrounding formatting

### Overlay positioning
- Positioned at fixed `left: 16, bottom: 16` of the editor stack
- Does not scroll with caret

---

## 8. Tests Safe to Port to a New Storage Layer

Tests that encode desired behaviour and are safe to carry forward verbatim (or with fixture-only changes) to a new storage implementation:

### Protect: Reference Pipeline Correctness
| Test file | Lines | What it protects |
|---|---|---|
| `test/services/manuscript_reference_service_test.dart` | 93 | Delta scanning for `ref:` links; `rebuildIndex` correctness |
| `test/services/reference_integrity_service_test.dart` | 233 | All 3 deletion strategies; stale-entry purge; recreate-with-same-ID |
| `test/services/reference_name_resolver_test.dart` | 342 | Name resolution by type; cross-project isolation; `entityExists` semantics for unimplemented types |
| `test/services/az_reference_pipeline_diagnostic_test.dart` | 296 | End-to-end: insert mention → rebuild index → backlink visible |
| `test/database/reference_engine_test.dart` | 315 | Engine add/clear/query; `mapData` type in `EntityType.all` |
| `test/database/entity_ref_test.dart` | 109 | EntityRef equality; `EntityType.all` contents |

### Protect: Mention Autocomplete Behaviour
| Test file | Lines | What it protects |
|---|---|---|
| `test/widgets/reference_autocomplete_test.dart` | 1,119 | Trigger detection; confidence scores (must not change); keyboard nav; insert; dismiss |
| `test/services/entity_name_matcher_test.dart` | 404 | Scoring rules; alias folding; edge cases |

### Protect: Binder / Collections Data Layer
| Test file | Lines | What it protects |
|---|---|---|
| `test/services/manuscript_binder_service_test.dart` | 170 | CRUD; hierarchy; move; delete-with-children; stable IDs |
| `test/services/manuscript_collections_service_test.dart` | 162 | Smart/entity/custom collections; favorites; no duplicate index |
| `test/services/corkboard_reorder_test.dart` | 177 | Drag-reorder updates `orderIndex`; Corkboard and Outliner see same order |

### Protect: Storage Schema
| Test file | Lines | What it protects |
|---|---|---|
| `test/database/legacy_migration_test.dart` | 407 | V2→V3 migration: `ManuscriptDocument` created from legacy `Chapter`/`Section`; IDs match expected format |
| `test/database/database_manager_test.dart` | 218 | Box names; adapter registration; schema version |

### Protect: Topology Invariants
| Test file | Lines | What it protects |
|---|---|---|
| `test/widgets/manuscript_topology_test.dart` | 428 | Exactly 1 `ManuscriptListPane`; exactly 1 `ManuscriptEditor` in widget tree |

### Tests that are NOT safe to port unchanged
| Test file | Why |
|---|---|
| `test/widgets/reference_autocomplete_test.dart` | Depends on exact `QuillController` + `ReferenceAutocompleteController` internals; must be re-verified if either class is rewritten |
| Any test that seeds legacy `Chapter`/`Section` data | Depends on the legacy Hive boxes remaining open |
| `az_reference_pipeline_diagnostic_test.dart` | Makes a real LanguageTool-style AI call; environment-dependent |
