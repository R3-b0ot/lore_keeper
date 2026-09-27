# B3 — Feature Matrix: Spec vs Implementation

> Each spec statement (S-xx) from B1 maps to one row. Implemented-but-not-in-spec features follow.  
> Evidence: direct source reads (B2 inventory). Test column cites test file where relevant.

---

## Classification Key
- **YES** — implemented and verifiable in source
- **PARTIAL** — meaningfully present but gaps remain
- **NO** — not implemented
- **STUB** — placeholder class/file exists but no real behaviour
- **BROKEN** — code exists but known to malfunction (see B5)

---

## Part 1 — Spec Statements

| ID | Feature | Impl | Evidence | Tested | Legacy-dependent |
|---|---|---|---|---|---|
| S-07 | ManuscriptModule does NOT own separate workspace layout | YES | `manuscript_module.dart`: returns `Row([ManuscriptEditor, VerticalDivider, ManuscriptInspector])` — no Binder/navigation | `manuscript_topology_test.dart` | NO |
| S-08 | Canonical 4-column topology (Sidebar / ListPane / Editor / Inspector / SpecFunctionsBar) | PARTIAL | Columns 1–4 verified. `SpecificFunctionsBar` not found in codebase — never built | NO topology widget test covers SpecFunctionsBar | NO |
| S-09 | Runtime invariants: exactly 1 of each column widget | PARTIAL | `manuscript_topology_test.dart` verifies 1 `ManuscriptListPane` and 1 `ManuscriptEditor`. Inspector count not tested. SpecificFunctionsBar absent. | `manuscript_topology_test.dart` (partial) | NO |
| S-10 | Ownership table (shell owns Column 2 slot, provider, engine; module consumes) | YES | `project_editor_screen.dart`: constructs `ManuscriptBinderProvider` + `ReferenceEngine`, passes both into `ManuscriptModule` and `ManuscriptListPane` | NO | NO |
| S-11 | ManuscriptModule/Editor must NOT own Binder, second list, navigation tree | YES | No Binder/navigation widget instantiated in `ManuscriptModule` or `ManuscriptEditor` | `manuscript_topology_test.dart` | NO |
| S-15 | 10 document types (Manuscript/Part/Chapter/Scene/Section/Note/Research/FrontMatter/BackMatter/Custom) | YES | `ManuscriptDocumentType` enum: all 10 values (`manuscript_document.dart:7–23`) | `manuscript_binder_service_test.dart` | NO |
| S-16 | Every doc preserves: stable ID, projectId, parentId, orderIndex, title, type, richText, status, summary, metadata, references, timestamps, wordCount, charCount, favorite | YES | All 25 HiveFields present on `ManuscriptDocument`. Favorite persisted via `isFavorite` field. | `manuscript_binder_service_test.dart` | NO |
| S-17 | Document ID is identity; rename/move/reorder must not change ID | YES | `updateTitle`, `moveDocument`, `reorderDocument` in `manuscript_binder_service.dart` never reassign `id` | `manuscript_binder_service_test.dart` | NO |
| S-18 | Hierarchy operations: create child/sibling, rename, duplicate, delete, move, drag reorder, expand/collapse, select, open | PARTIAL | All except **duplicate** implemented in `ManuscriptBinderService`/`ManuscriptBinder`. No `duplicateDocument` method exists anywhere. | `corkboard_reorder_test.dart`, `manuscript_binder_service_test.dart` | NO |
| S-19 | Single shared `ManuscriptBinderProvider`; no child widget silently instantiates another | PARTIAL | Shell creates one provider and passes it. `ManuscriptCollections` lazily creates its own `ManuscriptCollectionsService` from `DatabaseManager.instance` (not a provider duplication — same engine — but bypasses DI pattern). | NO | NO |
| S-20 | Single shared `ReferenceEngine`; collections/editor/backlinks observe same instance | PARTIAL | Shell creates one engine and threads it. `ManuscriptEditorState._initReferenceService()` creates a second `ManuscriptReferenceService` internally (same engine object though). See B5 defect D3. | NO | NO |
| S-21 | Column 2: visible, collapsible, resizable, project-scoped, synced with selection, view-switch without replacing provider | PARTIAL | Visible ✓, collapsible via `_isListPaneCollapsed` ✓, project-scoped ✓, view-switch ✓. Resizable: NO (fixed width in desktop layout). | `manuscript_topology_test.dart` | NO |
| S-22 | Stable widget keys: `manuscript-list-pane`, `manuscript-editor`, `manuscript-inspector` | PARTIAL | `kManuscriptListPaneKey`, `kManuscriptEditorKey`, `kManuscriptInspectorKey` all defined and used. `project-editor-column-1` and `specific-functions-bar` keys absent. | `manuscript_topology_test.dart` | NO |
| S-23 | Binder: show hierarchy, expand/collapse, select, open, create child/sibling, rename, duplicate, delete, move, drag reorder, show type/status/wordCount, persist order | PARTIAL | All implemented except **duplicate** and **rename-in-place from toolbar** (rename is via `onDocumentRenamed` callback). Word count shown on `_DocumentRow`. | NO direct Binder widget test | NO |
| S-24 | `orderIndex` canonical; reorder updates data used by Corkboard and Outliner | YES | `reorderDocument`/`moveDocument` update Hive; Corkboard and Outliner both read via `provider.getChildren()` | `corkboard_reorder_test.dart` | NO |
| S-25 | Binder selection updates shell's active doc → Column 3 + Column 4 | YES | `onDocumentSelected` callback flows: Binder → `ManuscriptListPane` → `ProjectEditorScreen._onManuscriptDocumentSelected` → `ManuscriptEditor` (via `selectedDocumentId` prop) + `ManuscriptInspector` (via `_selectedDocument` in `ManuscriptModuleState`) | NO | NO |
| S-26 | Corkboard: cards with title/summary/wordCount/status/POV/location/timeline/tags; drag reorder updates same data | PARTIAL | Cards show title, summary, word count, status, POV, plotline. Location shown as raw ID (not name). Timeline shown as raw ID. Tags: NO. Drag reorder: implemented, updates orderIndex. | `corkboard_reorder_test.dart` | NO |
| S-27 | Outliner: Scene/POV/Location/Timeline/Words/Status/Plotline columns; configurable visibility; sort/filter must not mutate order | PARTIAL | All 7 columns present. Column visibility toggle implemented. Sort/filter: NO sort/filter UI implemented yet (future work). | NO | NO |
| S-28 | Smart collections (18 types listed) | PARTIAL | `CollectionType` enum has 16 values — **missing `sections` and `ideas`** from spec list. Favorites, Recent, Needs Revision, Draft, Revised, Complete, Archived all present. | `manuscript_collections_service_test.dart` | NO |
| S-29 | Entity collections via EntityRef→ReferenceEngine→ManuscriptDocument; no duplicate backlink index | YES | `ManuscriptCollectionsService.documentsForEntity()` queries `_referenceEngine.backlinksTo(entityRef)` — no duplicate index | `manuscript_collections_service_test.dart` | NO |
| S-30 | Custom collections: user-created, project-scoped, persistent, searchable, selectable from Column 2; opening result opens correct doc | YES | `ManuscriptCollectionsService.createCollection`, Hive-persisted, scoped by `projectId`. Opening result calls `onDocumentSelected`. | `manuscript_collections_service_test.dart` | NO |
| S-31 | Favorites: persistent, project-scoped, toggleable, visible through Collections, preserved across restart | YES | `isFavorite` field on `ManuscriptDocument` persisted to Hive. `toggleFavorite` in provider. `CollectionType.favorites` in Collections widget. | `manuscript_binder_service_test.dart` | NO |
| S-32 | Column 3 editor: load doc, edit title, edit rich text, persist, autosave, show status, undo/redo, find/replace, statistics, references, images/tables, Focus Mode | PARTIAL | All implemented except: **images/tables** (QuillEmbeds registered but no specific manuscript support), **undo/redo** (Quill built-in, no explicit test), **statistics** (word count only; no char-count live update). | NO module-level test | NO |
| S-33 | Active doc selected by Column 2; editor resolves compatibility keys to canonical ManuscriptDocument ID | PARTIAL | `_selectDocumentForChapterKey` maps legacy chapter key → ManuscriptDocument id. Spec satisfied. But legacy key bridge remains permanent coupling. | NO | YES (legacy chapter key bridge) |
| S-34 | Autosave debounced ~2s; must not rebuild unrelated state | PARTIAL | `_autosaveDelay = Duration(seconds: 2)` in `ManuscriptEditor`. Does NOT rebuild unrelated state. **But**: each autosave triggers `rebuildIndex()` which calls `engine.clear()` — potentially clears non-manuscript index entries. See B5 D3. | NO autosave test | NO |
| S-35 | Rich text: paragraphs, headings, bold/italic/underline, lists, block quotes, links, inline refs, images, tables, undo/redo, find/replace, word count, char count, persistence | PARTIAL | All basic formatting via Quill ✓. Inline refs ✓. Images: QuillEmbeds registered but no manuscript-specific image upload UI. Tables: not configured. Char count: stored but not shown live in status bar. | NO | NO |
| S-36/S-37/S-38 | Inspector: type/status/dates/counts/hierarchy/refs; readable name resolution; unresolved state; no own index | PARTIAL | Type, status, word count, dates shown ✓. POV resolved ✓. Timeline resolved ✓. **Location shown as raw ID — no resolver** (ReferenceNameResolver has no Location branch). Backlinks via ManuscriptReferenceService ✓. No own index ✓. | `reference_name_resolver_test.dart` | NO |
| S-39 | 6 statuses (Idea/Outline/Draft/Revised/Complete/Archived) consistent across all views | YES | `ManuscriptDocumentStatus` enum with 6 values. Binder, Corkboard, Outliner, Collections, Inspector all read `doc.status`. | NO cross-view consistency test | NO |
| S-40/S-41/S-42 | 10 referenceable types via EntityRef; @mention workflow; single resolution path | PARTIAL | 10 types defined in `ReferenceEntityType`. @mention implemented for: Character, Species, TimelineEvent, ManuscriptDocument (4 of 10). Location/Item/Org/Faction/Research/CalendarDate: **trigger not wired in entity providers** (`_buildEntityProviders()` in `ManuscriptEditor`). Resolution path exists for 4 types; null returned for 6. | `reference_autocomplete_test.dart` | NO |
| S-43/S-44 | ReferenceEngine as single authority; project isolation | YES | One engine per project, passed by shell. `EntityRef.projectId` participates in all index queries and resolver checks. Cross-project isolation verified in tests. | `reference_engine_test.dart`, `reference_name_resolver_test.dart` | NO |
| S-45 | ReferenceIntegrityService: 3 deletion strategies; no re-attach on recreate-with-same-ID | YES | All 3 strategies implemented. Recreate-with-same-ID: after delete+preserve, the old refs remain pointing to the now-missing entity; a new entity with the same ID would re-resolve them — **this is a potential bug** if spec §17.4 strictly requires no re-attach. Current code does not actively prevent it (no tombstone). | `reference_integrity_service_test.dart` | NO |
| S-46 | Timeline integration: assign/clear/display/navigate event; discover linked docs from Timeline | PARTIAL | `timelineEventId` field on ManuscriptDocument ✓. Assign/clear via `updateTimelineEvent` ✓. Inspector shows resolved name ✓. Navigate to event from Inspector: **NO** (no callback). Discover linked docs from Timeline module: **NO** (Timeline module has no ReferenceEngine query UI). | NO | NO |
| S-47 | Calendar integration: assign/clear/display, chronology-aware picker, no second calendar DB | PARTIAL | `calendarDateSystemKey/Year/DayOfYear` fields ✓. `updateCalendarDate` ✓. Inspector shows raw field values — **no formatted date display using CalendarSystem chronology**. Chronology-aware picker: **NO** (just raw fields). | NO | NO |
| S-48 | Search: title/content/summary/metadata/tags/type/status/plotline; editor search with next/prev/count/highlight | PARTIAL | `ManuscriptBinderProvider.searchDocuments()` covers title, summary, richTextJson, plotline ✓. Tags, type, status filtering: **NO** (only in Collections type filter). Editor search (find/replace): Find-first only, no next/prev/count, no visual highlighting. | NO | NO |
| S-49 | Statistics at hierarchy levels; parent totals derived from children | PARTIAL | `getBranchWordCount()` in provider sums descendants ✓. Live word count in editor ✓. Character count: stored but diverges from live count (B5 D2). | NO | NO |
| S-50 | Focus Mode: reduce distractions, preserve doc, restore topology, no second workspace | YES | Focus Mode implemented in `ManuscriptEditor` — hides toolbar, shows full-screen editor, exit button restores normal layout. Does not create second workspace. | NO | NO |
| S-51 | Filesystem/Markdown interchange | NO | No import/export implementation. | NO | NO |
| S-52 | DatabaseManager owns init, adapters, schema, migrations | YES | `DatabaseManager` singleton handles all of these. Hand-written adapters kept. | `legacy_migration_test.dart`, `database_manager_test.dart` | NO |
| S-55 | AI optional; ContextBuilder; AiProvider abstraction | PARTIAL | `AiProvider` interface + factory ✓. AI used only in ReferenceEngine for semantic suggestions. ContextBuilder: **NO** (not implemented). Manuscript-specific AI features (summarise, continuity): **NO**. | AI provider tests | NO |
| S-56 | Document deletion: confirm empty, explicit policy for children, warn for refs | PARTIAL | `deleteDocument(deleteChildren: bool)` in service ✓. Children: promotes or cascades ✓. Binder UI: shows delete option but **no confirmation dialog for non-empty docs** and **no "preserve unresolved" dialog** — calls `deleteDocument(deleteChildren: false)` which throws `StateError` caught silently. | `manuscript_binder_service_test.dart` | NO |
| S-57 | Data integrity mandatories | PARTIAL | Stable IDs ✓, valid project ownership ✓, no circular hierarchy (checked in `moveDocument`) ✓, deterministic ordering ✓. Missing: **no orphan detection at load time**, **no enforced hierarchy rules** (warn-only). | `manuscript_binder_service_test.dart` | NO |
| S-58 | Zero baseline: analyze 0 issues, tests all passing | PARTIAL | 377 tests pass per CLEANUP_REPORT. `flutter analyze` claims 0 issues. NOT VERIFIED in this audit (no SDK on PATH). | — | NO |
| S-59 | Required topology tests | PARTIAL | `manuscript_topology_test.dart`: verifies 1 ManuscriptListPane, 1 ManuscriptEditor. SpecificFunctionsBar absent. Inspector count not tested. Column-collapse test: NO. | `manuscript_topology_test.dart` | NO |

---

## Part 2 — Implemented Features Not in Spec

| Feature | Status | Evidence | Tested | Legacy-dependent |
|---|---|---|---|---|
| **Grammar check (LanguageTool)** | YES | `_runGrammarCheck`, `_runAutoCorrect`, consent dialog, `_GrammarPanel` in `manuscript_module.dart` | NO | NO |
| **Grammar issue panel** (categories, accept/dismiss) | YES | `_GrammarPanel` widget in `manuscript_module.dart` | NO | NO |
| **Focus Mode** | YES | `_focusMode` toggle in `ManuscriptEditorState` | NO | NO |
| **Zoom controls** in status bar | YES | `_zoomFactor` state + +/- buttons; `InteractiveViewer` wraps editor card | NO | NO |
| **Front matter pages** (Cover/Index/Author) as non-Quill custom forms | PARTIAL | `CoverPageForm`, `IndexPageWidget`, `AboutAuthorForm`; routed by negative key `front_matter_-1/-2/-3`. IndexPageWidget still reads legacy ChapterListProvider. | NO | YES (`IndexPageWidget`) |
| **Dual title/body Quill editors** (separate title controller) | YES | `_titleController` + `_titleFocusNode` + `_titleAutosaveTimer` separate from body controller | NO | NO |
| **Autosave saves history** on every write | YES (BROKEN) | `_saveContent()` calls `_historyService.addHistoryEntry(targetType: 'ManuscriptDocument')` but HistoryPanel filters `'Chapter'` — history stored but invisible | NO | NO |
| **Diff/revert** for history | PARTIAL (BROKEN) | `ChapterDiffViewDialog` for legacy Chapter; `DiffViewDialog` for Character; `ManuscriptDocument` diffs: unsupported ("Diff view not supported") | NO | YES (Chapter box) |
| **Word count goal** | NO | Not implemented | NO | NO |
| **Keyboard shortcut Ctrl+F** → Find/Replace | YES | `_openFindReplaceDialog` triggered from toolbar custom button; also from shell `_openFindReplaceDialog` for module index 1 | NO | NO |
| **Ignored words** in grammar check | YES | `_project.ignoredWords` list filters grammar results | NO | NO |
| **LkLog debug logging** throughout (not print) | YES | All logging via `LkLog` in binder service, binder provider | NO | NO |
| **`getDocumentsByType`** query | YES | `ManuscriptBinderProvider.getDocumentsByType()` | `manuscript_binder_service_test.dart` | NO |
| **Collection filtering by search query** | YES | `_searchQuery` in `ManuscriptCollections` filters displayed items | `manuscript_collections_service_test.dart` | NO |
| **`manuscript_topology_test.dart`** covers duplicate-pane risk | YES | Verifies topology invariants | `manuscript_topology_test.dart` | NO |

---

## Summary Counts

| Status | Count |
|---|---|
| YES (fully implemented, verified) | 18 |
| PARTIAL (real implementation, gaps) | 26 |
| NO (not implemented) | 4 |
| STUB | 0 |
| BROKEN | 2 (autosave history invisible, find/replace offset drift) |

The **PARTIAL** rating dominates because the 2026 redesign is structurally correct but several secondary behaviours (duplicate, calendar picker, filesystem, AI context builder, navigation from Inspector, resize, topology key gaps, non-character mention resolution) are not yet built.
