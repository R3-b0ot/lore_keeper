# B2 — Manuscript Implementation Inventory

> All file paths verified by direct read or directory listing. LOC from `find /c /v ""`.  
> Layer assignments follow AGENTS.md architecture rules.

---

## File Inventory

### Models

| File | LOC | Purpose | Layer |
|---|---|---|---|
| `lib/models/manuscript_document.dart` | ~220 | Core entity: 10 doc types, 6 statuses, 25 HiveFields (typeId 40). `toJson`/`fromJson`. | models |
| `lib/models/manuscript_collection.dart` | ~60 | Custom collection entity (typeId 41): id, projectId, name, optional type/status filters | models |
| `lib/models/chapter.dart` | (legacy) | Legacy entity: title, richTextJson, parentProjectId, parentSectionKey, orderIndex | models (legacy) |
| `lib/models/section.dart` | (legacy) | Legacy entity: title, parentProjectId, orderIndex | models (legacy) |
| `lib/models/history_entry.dart` | ~40 | History snapshot: targetKey (dynamic), targetType (String), timestamp, data (JSON string) | models |

### Database Layer

| File | LOC | Purpose | Layer |
|---|---|---|---|
| `lib/database/database_manager.dart` | ~520 | Singleton; opens 18 boxes; registers adapters; V2→V3 migration creates ManuscriptDocument hierarchy from legacy Chapter/Section. Exposes `manuscriptDocuments`, `manuscriptCollections` getters. | database |
| `lib/database/entity_ref.dart` | 121 | `EntityRef` (id, entityType, projectId); `EntityType` string constants including `manuscriptDocument`; `EntityType.all` list | database |
| `lib/database/reference_engine/reference_engine.dart` | 138 | In-memory reference index; add/clear/removeWhere; query (referencesFrom, backlinksTo, insideContainer, search, referencedEntityTypes); AI delegation | database |
| `lib/database/reference_engine/reference_index.dart` | 69 | `ReferenceIndexEntry` (source, target, kind, containerEntity, computedAt); equality by source+target+kind+container | database |

### Services

| File | LOC | Purpose | Layer |
|---|---|---|---|
| `lib/services/manuscript_binder_service.dart` | 568 | CRUD for ManuscriptDocument hierarchy: create, read, update, reorder, move, delete (with child promotion or cascade). Hierarchy validation (warn-only). `_countWords` (JSON-regex, **DIVERGES from editor**). `ReferenceIntegrityService` wired for deletion. | services |
| `lib/services/manuscript_collections_service.dart` | 138 | Smart collections (type/status filter), entity collections (via ReferenceEngine backlinks), custom collections (Hive-persisted). Favorites via document field. | services |
| `lib/services/manuscript_reference_service.dart` | ~160 | Parses Quill Delta `link` attributes for `ref:` URIs; `rebuildIndex()` calls `engine.clear()` then re-adds; `extractAllReferences`, `getBacklinksTo`, `getReferencesFrom`, unused: `getReferencesInContainer`, `searchReferences`, `getReferencedEntityTypes` | services |
| `lib/services/manuscript_service.dart` | 182 | **Legacy** service for Chapter/Section boxes. Used only by `ChapterListProvider`. Handles front-matter chapter creation with string keys `front_matter_-1/-2/-3`. | services (legacy) |
| `lib/services/reference_attribute.dart` | 104 | `ReferenceEntityType` enum (10 types), `ReferenceTarget` (encode/decode `ref:TypeLabel:id`). Maps entity types to inline ref types. | services |
| `lib/services/reference_integrity_service.dart` | 189 | Deletion strategies (cancel/preserve/removeReferences); stale-entry detection and purge; `planDeletion`, `execute`, `removeSource`, `removeTarget`, `purgeStaleEntries`, `groupByUnresolved` | services |
| `lib/services/reference_name_resolver.dart` | 183 | Resolves EntityRef→human name for Character, Species, TimelineEvent, ManuscriptDocument. Returns `null` for Location/Item/Org/Faction. Project-scoped. `entityExists()` for integrity checks. `purgeStale()` coordinator. | services |
| `lib/services/entity_name_matcher.dart` | 259 | Ranked fuzzy name matching: exactName 1.0, exactAlias 0.9, prefix 0.7/0.6, substring 0.3/0.2; max 20 candidates. Powers @mention autocomplete. | services |
| `lib/services/entity_reference_entries.dart` | ~80 | Extension methods: `Character.toReferenceEntry()`, `ClassificationNode.toReferenceEntry()`, `TimelineEvent.toReferenceEntry()`, `ManuscriptDocument.toReferenceEntry()`. Bridges domain models to autocomplete shape. | services |

### Providers

| File | LOC | Purpose | Layer |
|---|---|---|---|
| `lib/providers/manuscript_binder_provider.dart` | 378 | `ChangeNotifier` wrapping `ManuscriptBinderService`. Exposes full CRUD API, tree queries, search, word-count totals, `toggleFavorite`, `updateCalendarDate`, `updateTimelineEvent`. Holds shared `ReferenceEngine` reference. | providers |
| `lib/providers/chapter_list_provider.dart` | 191 | **Legacy** provider for `Chapter` box. Still used by `ProjectEditorScreen`, `OverviewModule`, `GlobalSearchDelegate`, `ChapterDiffViewDialog`. | providers (legacy) |

### Modules

| File | LOC | Purpose | Layer |
|---|---|---|---|
| `lib/modules/manuscript_module.dart` | ~1,300 | Contains two public classes: **`ManuscriptModule`** (StatefulWidget — owns Column 3+4 Row; creates `ReferenceNameResolver`, initialises `ManuscriptReferenceService`, owns `_selectedDocument`, routes backlink nav to shell); **`ManuscriptEditor`** (StatefulWidget — owns `QuillController` × 2, both `FocusNode`s, all timers, autosave, grammar check, `ReferenceAutocompleteController`, content load/save). Private grammar helpers (`_GrammarIssue`, `_GrammarPanel`). | modules |

### Widgets — Column 2 / Navigation

| File | LOC | Purpose | Layer |
|---|---|---|---|
| `lib/widgets/manuscript_list_pane.dart` | 190 | Column 2 host. View switcher (Binder/Corkboard/Outliner/Collections tabs). Passes shared provider through to each view. Key: `kManuscriptListPaneKey`. | widgets |
| `lib/widgets/manuscript_binder.dart` | 786 | Hierarchical tree with `ReorderableListView`, expand/collapse, inline rename, context menu (add child/sibling, rename, duplicate, delete, move). `_BinderNode`, `_DocumentRow`, `_DocumentContextMenu`. | widgets |
| `lib/widgets/manuscript_corkboard.dart` | 939 | Card grid view; drag-reorder via `ReorderableListView`; card shows title, summary, word count, status, POV, plotline. | widgets |
| `lib/widgets/manuscript_outliner.dart` | 595 | Table view; 7 configurable columns: Title, POV, Location, Timeline, Words, Status, Plotline; column visibility toggle. | widgets |
| `lib/widgets/manuscript_collections.dart` | 788 | 16 smart `CollectionType` enum values + entity collection categories + custom collections. `_searchController` for filtering. Lazy-creates `ManuscriptCollectionsService`. | widgets |

### Widgets — Column 3 / Editor

| File | LOC | Purpose | Layer |
|---|---|---|---|
| `lib/widgets/find_replace_dialog.dart` | ~170 | Find (plain text, first occurrence), Replace (selection-match only), Replace All (snapshot + offset walk — **has offset-drift bug**). Case-sensitive toggle. | widgets |
| `lib/widgets/cover_page_form.dart` | ~150 | Custom form widget for front-matter Cover page (docId `front_matter_-1`). Edits `Project.bookTitle`, `coverImage`. No Quill. | widgets |
| `lib/widgets/index_page_widget.dart` | ~100 | Custom widget for front-matter Index page (docId `front_matter_-2`). Reads `ChapterListProvider` to list chapters. | widgets |
| `lib/widgets/about_author_form.dart` | ~120 | Custom form for front-matter About Author page (docId `front_matter_-3`). | widgets |
| `lib/widgets/reference_autocomplete_controller.dart` | 266 | `ReferenceAutocompleteController`: detects `@` trigger, queries `EntityNameMatcher`, manages overlay show/hide state, keyboard nav (up/down/enter/escape), inserts `ref:` link via `QuillController.formatText`. | widgets |
| `lib/widgets/reference_autocomplete_overlay.dart` | 235 | `ReferenceAutocompleteOverlay`: renders candidate list (max 8), hover no-op, keyboard events delegated to controller. | widgets |

### Widgets — Column 4 / Inspector

| File | LOC | Purpose | Layer |
|---|---|---|---|
| `lib/widgets/manuscript_inspector.dart` | 566 | Stateless. Displays: doc type/status, word/char counts, dates, favorite. For leaves: POV (resolved via `ReferenceNameResolver`), Location (raw id — **unresolved, no resolver**), Timeline (resolved), Plotline. Characters list (resolved). References/backlinks from `ManuscriptReferenceService`. Backlink taps call `onDocumentSelected`. Key: `kManuscriptInspectorKey`. | widgets |

### Widgets — History / Diff

| File | LOC | Purpose | Layer |
|---|---|---|---|
| `lib/widgets/history_panel.dart` | ~160 | Lists history entries filtered by `targetKey` + `targetType`. For `'Character'` shows `DiffViewDialog`; for `'Chapter'` shows `ChapterDiffViewDialog`; all else → snackbar "not supported". | widgets |
| `lib/widgets/chapter_diff_view_dialog.dart` | ~130 | Diff dialog for legacy `Chapter` objects. Reads `Hive.box<Chapter>('chapters')` directly (**rule violation: box in widget**). Shows title/orderIndex diff + text diff. Revert: writes back to Chapter box. | widgets |
| `lib/widgets/diff_view_dialog.dart` | ~150 | Diff dialog for `Character` objects. | widgets |

### Shell / Screen

| File | LOC | Purpose | Layer |
|---|---|---|---|
| `lib/screens/project_editor_screen.dart` | ~740 | Constructs and owns all providers including `ManuscriptBinderProvider`, `ReferenceEngine`. Holds `_manuscriptController` ref (not owned). Routes `_onManuscriptDocumentSelected`. Passes `selectedDocumentId` to Column 2 and Column 3. `HistoryPanel` for manuscripts uses `targetType: 'Chapter'` with legacy chapter key — **mismatch with how saves are stored**. | screens |

### AI Layer

| File | LOC | Purpose | Layer |
|---|---|---|---|
| `lib/database/ai/` (multiple) | ~400 | `AiProvider` interface + `NullAiProvider`, `LlamaDartAiProvider`, `OpenAiCompatibleAiProvider`, `DeviceAiDiscovery`, `AiProviderFactory`, `AiMetadata`. All optional; `ReferenceEngine` degrades to no-AI. | database/AI |

### Tests (Manuscript-Relevant)

| File | LOC | What It Tests |
|---|---|---|
| `test/services/manuscript_binder_service_test.dart` | 170 | CRUD, hierarchy, reorder, move, delete-with-children |
| `test/services/manuscript_collections_service_test.dart` | 162 | Smart collections, entity collections via engine, custom collections, favorites |
| `test/services/manuscript_reference_service_test.dart` | 93 | `extractReferencesFromDocument`, `rebuildIndex`, `getBacklinksTo` |
| `test/services/reference_name_resolver_test.dart` | 342 | Name resolution per entity type, cross-project isolation, entityExists, purgeStale |
| `test/services/reference_integrity_service_test.dart` | 233 | All 3 deletion strategies, stale-entry purge, recreate-with-same-ID protection |
| `test/services/corkboard_reorder_test.dart` | 177 | Drag-reorder of children via ManuscriptBinderProvider |
| `test/services/az_reference_pipeline_diagnostic_test.dart` | 296 | End-to-end reference pipeline with real AI call; diagnostic/integration |
| `test/services/entity_name_matcher_test.dart` | 404 | Scoring, ranking, aliases, edge cases |
| `test/widgets/manuscript_topology_test.dart` | 428 | Widget tests for topology (one ManuscriptListPane, one ManuscriptEditor, etc.) |
| `test/widgets/reference_autocomplete_test.dart` | 1,119 | Trigger detection, candidate ranking, keyboard nav, insert behaviour |
| `test/database/reference_engine_test.dart` | 315 | Engine add/clear/query/search |
| `test/database/entity_ref_test.dart` | 109 | EntityRef equality, EntityType.all contents |
| `test/database/legacy_migration_test.dart` | 407 | V2→V3 migration creating ManuscriptDocument from Chapter/Section data |

---

## Dependency Graph (who imports whom)

```
ProjectEditorScreen
  ├── ManuscriptBinderProvider  ←── ManuscriptBinderService
  │                                     ├── ManuscriptDocument (model)
  │                                     ├── ManuscriptCollection (model)
  │                                     ├── ReferenceIntegrityService
  │                                     └── ReferenceNameResolver
  │
  ├── ReferenceEngine  ←── ReferenceIndex
  │
  ├── ManuscriptListPane  (Column 2)
  │     ├── ManuscriptBinder       ←── ManuscriptBinderProvider, ManuscriptDocument
  │     ├── ManuscriptCorkboard    ←── ManuscriptBinderProvider, ManuscriptDocument
  │     ├── ManuscriptOutliner     ←── ManuscriptBinderProvider, ManuscriptDocument
  │     └── ManuscriptCollections  ←── ManuscriptBinderProvider, ManuscriptCollectionsService
  │                                         └── ManuscriptDocument, ReferenceEngine
  │
  ├── ManuscriptModule  (Column 3+4)
  │     ├── ManuscriptEditor
  │     │     ├── QuillController (×2)
  │     │     ├── ReferenceAutocompleteController
  │     │     │     └── EntityNameMatcher  ←── EntityReferenceEntry
  │     │     │         (candidates: Character, Species, TimelineEvent, ManuscriptDocument)
  │     │     ├── ReferenceAutocompleteOverlay
  │     │     ├── ManuscriptReferenceService  ←── ReferenceEngine, ManuscriptDocument
  │     │     ├── HistoryService
  │     │     ├── FindReplaceDialog  ←── QuillController
  │     │     └── FrontMatter widgets (CoverPageForm, IndexPageWidget, AboutAuthorForm)
  │     │           └── IndexPageWidget ←── ChapterListProvider (LEGACY dependency)
  │     └── ManuscriptInspector
  │           ├── ReferenceNameResolver
  │           └── ManuscriptReferenceService
  │
  └── HistoryPanel
        ├── ChapterDiffViewDialog  ←── Chapter box (DIRECT HIVE, rule violation)
        └── DiffViewDialog         ←── Character

ChapterListProvider  ←── ManuscriptService (LEGACY)  ←── Chapter box, Section box
GlobalSearchDelegate  ←── Chapter box (DIRECT HIVE)
OverviewModule  ←── ChapterListProvider (LEGACY for "Recent Manuscripts")
```

---

## Consumers of Manuscript Data Outside the Manuscript Feature

| Consumer | What it reads | How |
|---|---|---|
| `OverviewModule` | Legacy `Chapter` list via `ChapterListProvider` | "Recent Manuscripts" widget shows chapter titles (legacy model, not ManuscriptDocument) |
| `GlobalSearchDelegate` | Legacy `Chapter` box directly (`Hive.box<Chapter>`) | Dashboard search lists chapters |
| `IndexPageWidget` | Legacy `ChapterListProvider.chapters` | Front-matter Index page lists chapter titles |
| `ProjectEditorScreen` | `_selectedChapterKey` (legacy int key) bridged to `_selectedManuscriptDocumentId` | `_chapterKeyFromDocumentId` / `_selectDocumentForChapterKey` compatibility shim |
| `project_book.dart` | Project-level word count deliberately omitted to avoid synchronous chapter scan | Comment notes the perf risk of counting chapters |
| `DatabaseManager` | V2→V3 migration reads Chapter and Section boxes to create ManuscriptDocument hierarchy | One-time migration |

---

## Observations

1. **Two parallel navigation systems co-exist**: The new `ManuscriptDocument`/`ManuscriptBinderProvider` system is the canonical path. The legacy `Chapter`/`ChapterListProvider`/`ManuscriptService` system is still live and depended on by `OverviewModule`, `GlobalSearchDelegate`, `IndexPageWidget`, and `ProjectEditorScreen`'s legacy key bridging.

2. **`ManuscriptCollections` lazy-creates its own `ManuscriptCollectionsService`** from `DatabaseManager.instance` inside `didChangeDependencies` — this means it bypasses the shell's shared provider and directly opens database boxes. This is a mild architectural concern but not a duplicate-index violation since `ManuscriptCollectionsService` reads through the shared `ReferenceEngine` passed via the provider.

3. **`ManuscriptReferenceService` is instantiated twice**: once in `ManuscriptModuleState._initReferenceService()` and once in `ManuscriptEditorState._initReferenceService()`. Both use the same shared engine but operate independently — the rebuild-on-autosave double-clear issue is compounded by this duplication.

4. **`ChapterDiffViewDialog` opens `Hive.box<Chapter>('chapters')` directly** — violates the "no Hive.box in widgets" rule. Low risk (box is always open), but the diff/revert feature is tightly coupled to the legacy Chapter model and will break if the Chapter box is removed.
