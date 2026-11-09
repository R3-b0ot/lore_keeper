# B1 — Master Spec Digest

> Source: `docs/LORE_KEEPER_MANUSCRIPT_MASTER_SPEC.md`  
> Commit that introduced this version: `18c4472` ("docs: replace Manuscript master spec with canonical UI topology")  
> Status: **Canonical / Normative** per §0. Replaces all earlier Manuscript specs.  
> Method: full read of all 42 sections. Each statement below is quoted or closely paraphrased with section reference.

---

## Numbered Statements

**S-01 (§0)** This document is the single canonical specification for the Manuscript Module. It replaces all earlier Manuscript Module specifications, migration notes, and informal descriptions when they conflict.

**S-02 (§0)** The repository is the source of truth for what currently exists; this spec is the source of truth for intended architecture and behavior. Implementation must not silently reconcile the two by inventing architecture.

**S-03 (§0.1)** Core principles: Preserve working architecture before adding features. Prefer extension and parameterization over replacement. Do not create parallel systems for functionality already owned by an existing service.

**S-04 (§0.1)** `EntityRef` is the canonical cross-module reference value. `ReferenceEngine` is the canonical relationship/index mechanism. `ReferenceIntegrityService` is the canonical deletion-integrity coordinator. `DatabaseManager` is the canonical database/bootstrap owner.

**S-05 (§0.1)** AI is optional and must never be required for core Manuscript functionality.

**S-06 (§0.1)** The desktop Project Editor topology defined in §1 is **non-negotiable**.

**S-07 (§1.1)** The Manuscript Module does NOT own a separate workspace layout. It is a content module hosted by the existing Project Editor shell. There is exactly **one** desktop Project Editor layout and exactly **one** visible Manuscript navigation/list region. That region is **Column 2: `ManuscriptListPane`**. The Binder is a view inside `ManuscriptListPane`, not a second panel owned by `ManuscriptModule`.

**S-08 (§1.2)** Canonical desktop topology:
```
PROJECT EDITOR
├── Column 1: ModuleSidebar
├── Column 2: ManuscriptListPane (Binder / Corkboard / Outliner / Collections)
├── Column 3: ManuscriptEditor
├── Column 4: Inspector
└── Right Edge: SpecificFunctionsBar
```

**S-09 (§1.3)** Absolute runtime invariants: `COUNT(visible ModuleSidebar) == 1`, `COUNT(visible ManuscriptListPane) == 1`, `COUNT(visible ManuscriptEditor) == 1`, `COUNT(visible Inspector) == 1`, `COUNT(visible Binder/List/Tree) == 1`.

**S-10 (§1.4)** Ownership table: Global module navigation → `ProjectEditorScreen`/`ModuleSidebar`. Column 2 layout slot → `ProjectEditorScreen`. Binder/Corkboard/Outliner/Collections presentation → `ManuscriptListPane`. Shared manuscript state → `ManuscriptBinderProvider`. Active document editing → `ManuscriptEditor`. Document metadata/reference inspection → `Inspector`. Global tools/history → `SpecificFunctionsBar`/shell. Cross-module relationship/index → `ReferenceEngine`. Reference deletion integrity → `ReferenceIntegrityService`.

**S-11 (§1.5)** Explicit prohibition inside `ManuscriptModule`/`ManuscriptEditor`: must NOT own or render a `ManuscriptBinder`, a second Binder, a manuscript file tree, a chapter/document navigation tree, a second Corkboard/Outliner/Collections, a private manuscript navigation sidebar, or an alternate left-panel view switcher. Legacy `_LeftPanelMode` controlling a second visible navigation surface must be removed.

**S-12 (§2.1)** Column layout: Col 1 = `ModuleSidebar` (global project/module nav); Col 2 = `ManuscriptListPane` (navigation and alternate list views); Col 3 = `ManuscriptEditor` (active doc content editing); Col 4 = `Inspector` (active doc metadata, hierarchy, references); Right edge = `SpecificFunctionsBar` (shared tools and utilities).

**S-13 (§2.2)** Shell (`ProjectEditorScreen`) owns: module selection, desktop/mobile layout selection, the shared `ManuscriptBinderProvider`, the shared `ReferenceEngine`, shell-level navigation, the Column 2 widget slot, the Column 3/4 Manuscript content slot, and global tool controls. The shell passes shared manuscript state into Manuscript components rather than allowing each component to instantiate independent providers.

**S-14 (§2.4)** Before any Manuscript UI implementation or redesign, a **runtime topology audit** of 8 steps is required (trace shell layout, trace each column, trace every Binder/List/Tree instantiation, confirm exactly one visible Manuscript navigation surface). A static source review is insufficient.

**S-15 (§3.1)** Canonical document types: Manuscript, Part, Chapter, Scene, Section, Note, Research, Front Matter, Back Matter, Custom (10 total).

**S-16 (§3.2)** Every Manuscript document must preserve: stable document ID, project ID, parent document ID, deterministic order index, title, document type, rich-text content, status, summary, metadata, references, timestamps, word count, character count, favorite state. Fields already present in the canonical repository model must not be discarded.

**S-17 (§3.3)** The document ID is identity. Rename, move, reorder, editing, status changes, and metadata changes must not change the document ID. A move must preserve ID, project ownership, content, references, metadata, and timestamps (unless intentionally updating them).

**S-18 (§3.4)** The Binder/data layer must support: create child, create sibling, rename, duplicate, delete, move, drag reorder, expand/collapse state, select, open. Circular parent/child relationships must be impossible through normal operations.

**S-19 (§4.1)** The shell owns **one** `ManuscriptBinderProvider` for the active project, shared by: `ManuscriptListPane`, Binder, Corkboard, Outliner, Collections, `ManuscriptEditor`, and Inspector-related manuscript state. No child widget may silently instantiate another provider for the same project.

**S-20 (§4.2)** The shell should create the shared `ReferenceEngine` and thread it through relevant providers/services. Collections, editor references, entity deletion integrity, and backlinks must observe the **same** engine instance. A component may create a standalone engine only for explicitly isolated/testing scenarios — not silently in normal Project Editor runtime.

**S-21 (§5.1)** Column 2 must be: visible in normal desktop layout, collapsible through the shell's existing list-pane control, resizable where supported, project-scoped, synchronized with active document selection, capable of switching view without replacing the underlying provider.

**S-22 (§5.2)** Stable widget keys are mandatory for testability: `project-editor-column-1`, `manuscript-list-pane`, `manuscript-editor`, `manuscript-inspector`, `specific-functions-bar`.

**S-23 (§6.1)** Binder required behaviors: show hierarchy, expand/collapse, select, open, create child, create sibling, rename, duplicate, delete, move, drag reorder, show document type, show status, show word count where appropriate, persist order changes.

**S-24 (§6.2)** `orderIndex` is the canonical persisted ordering value. Reordering must update the same underlying data used by Corkboard and Outliner.

**S-25 (§6.3)** Selecting a document in Binder must update the shell's active manuscript document and therefore update Column 3 editor and Column 4 Inspector. The editor must not maintain an independent navigation selection that can diverge from Column 2.

**S-26 (§7)** Corkboard is a Column 2 view. Cards should expose: title, summary, word count, status, POV, location, timeline, tags. Drag reorder must update the same hierarchy/order data used by Binder. Corkboard must not maintain a parallel ordering system.

**S-27 (§8)** Outliner columns: Scene, POV, Location, Timeline, Words, Status, Plotline where available. Column visibility should be configurable where implemented. Sorting/filtering must not mutate canonical hierarchy order unless explicitly requested as a reorder operation.

**S-28 (§9.1)** Smart collections baseline: All Documents, Manuscript, Parts, Chapters, Scenes, Sections, Notes, Research, Front Matter, Back Matter, Custom, Favorites, Needs Revision, Recent, Draft, Revised, Complete, Archived. No smart collection may create duplicate storage of manuscript relationships.

**S-29 (§9.2)** Entity collection categories: Characters, Species, Locations, Organizations, Factions, Timeline Events. Must resolve through `EntityRef → ReferenceEngine → ManuscriptDocuments`. No collection-specific relationship database or backlink index may be created.

**S-30 (§9.3)** Custom collections must be: user-created, project-scoped, persistent, searchable/filterable, selectable from Column 2. Selecting a result must open the correct Manuscript document in Column 3.

**S-31 (§10)** Favorites are document state, not a separate relationship system. Must be: persistent, project-scoped, toggleable, visible through Collections, preserved across restart.

**S-32 (§11.1)** Column 3 editor responsibilities: load active document, edit title, edit rich text, persist content, autosave, show editing status, maintain undo/redo, expose find/replace, calculate statistics, support references, support images/tables where implemented, support Focus Mode where implemented.

**S-33 (§11.2)** The active document is selected by Column 2 and stored in shared shell state. The editor may resolve compatibility keys (e.g. legacy chapter identifiers) but must ultimately resolve to a canonical `ManuscriptDocument` ID.

**S-34 (§11.3)** Autosave must be debounced. Current target: approximately two seconds. Autosave must not rebuild unrelated project/module state on every keystroke.

**S-35 (§12)** Rich text: paragraphs, headings, bold, italic, underline, lists, block quotes, links, inline entity references, images, tables, undo/redo, find/replace, word count, character count, persistence. Existing Quill extensions and working implementations must be reused rather than replaced without a concrete reason.

**S-36 (§13.1/13.2)** Inspector must show where applicable: title, document type, status, word count, character count, created/modified date, favorite state, hierarchy, references, tags; for scenes: POV character, location, time/calendar date, plotline, characters, status, purpose, tags, timeline event.

**S-37 (§13.3)** Reference IDs must be resolved to readable names whenever a canonical source exists. If an entity is missing, belongs to another project, or has no canonical source, the UI must use an explicit unresolved state (e.g. `Unresolved • <id>`) rather than pretending the raw ID is valid.

**S-38 (§13.4)** Inspector must not create its own relationship/index system or independent entity cache that becomes a second source of truth.

**S-39 (§14)** Canonical document statuses: Idea, Outline, Draft, Revised, Complete, Archived. Status must be represented consistently across Binder, Corkboard, Outliner, Collections, Inspector, and filtering/search. Status changes must not alter document identity.

**S-40 (§15.1/15.2)** Cross-module references use `EntityRef`. Referenceable types: Character, Location, Item, Organization, Species, Faction, Timeline Event, Manuscript Document, Research, Calendar Date. Do not invent a model merely to make a reference type appear implemented; if a type has no canonical data source, its behavior must be explicitly documented as unsupported/deferred.

**S-41 (§15.3)** Inline references (`@mention` workflow): must be project-scoped, use canonical entity sources, create the canonical reference representation, preserve stable IDs, use the existing reference architecture, never create a second relationship index.

**S-42 (§15.4)** A single resolution path shared between Inspector, deletion-integrity existence checks, reference display, and autocomplete metadata. Must distinguish: valid entity / missing entity / wrong-project entity / unsupported/no-source entity.

**S-43 (§16)** `ReferenceEngine` is the single relationship/index authority. Must support: Manuscript→Entity references, Entity→Manuscript backlinks, deterministic indexing, project-scoped queries, cross-project isolation, source/target/stale-entry cleanup, purge, unresolved references. Prohibited alternatives: collection-specific relationship indexes, module-specific backlink databases, Inspector reference databases, autocomplete reference databases, duplicate reverse maps.

**S-44 (§16.2)** A reference belonging to Project A must never resolve against an entity in Project B even if target IDs happen to match. Project ID must participate in all relevant reference resolution and index queries.

**S-45 (§17)** `ReferenceIntegrityService` is the single deletion-integrity coordinator. Three strategies: Cancel (no changes), Delete & Preserve Unresolved (entity deleted, references remain as unresolved, stale engine entries purged), Delete & Remove References (entity deleted, inbound references removed, engine entries cleaned). Deleting an entity and later creating one with the same ID must never cause old references to re-attach.

**S-46 (§18)** Timeline integration where supported: assign/search/select/clear timeline event; display readable name; navigate to event; discover linked manuscript documents from Timeline. Timeline remains the owner of Timeline Event data. Manuscript must not create a duplicate Timeline database.

**S-47 (§19/20)** Calendar integration: assign/clear/display calendar date, chronology-aware picker, reuse existing CalendarSystem/Chronology. No second CalendarDate entity database. Bidirectional discovery must use existing ReferenceEngine.

**S-48 (§21)** Search should cover: title, body/content, summary, metadata, tags, linked entities, document type, status, plotline. Results must open the correct canonical document ID. Editor search: search, next, previous, result count, exact match positioning, visual highlighting — on the active document without creating a second manuscript state system.

**S-49 (§22)** Statistics at appropriate hierarchy levels (Scene, Chapter, Part, Manuscript): word count, character count. Parent totals should be derived from canonical child data rather than manually maintained duplicate totals wherever practical.

**S-50 (§23)** Focus Mode: reduce distractions, preserve active document, preserve editor content, restore normal topology safely. Must not instantiate another Manuscript workspace. If hiding columns, hide/collapse them rather than create alternate replacements.

**S-51 (§24)** Filesystem/Markdown interchange (planned): import, export, YAML frontmatter, stable IDs, conflict detection, conflict resolution, deletion/rename/move behavior. File path is a location, not identity.

**S-52 (§25)** `DatabaseManager` owns: database initialization, adapter registration, schema ownership, project ownership, migrations. Existing hand-written Hive adapters must be preserved unless there is a concrete architectural reason to change them. Do not introduce `build_runner` merely to regenerate adapters.

**S-53 (§26)** Migration policy: migration work is not an independent priority unless a current schema change requires it. Do not revive obsolete migration paths unnecessarily.

**S-54 (§27)** Performance work must be evidence-driven. Target: efficient active-document loading, debounced autosave, no unrelated rebuilds while typing, efficient reference indexing, scalable Binder behavior.

**S-55 (§28)** AI architecture: optional, `Manuscript Context → ContextBuilder → AiProvider → Local/LM Studio/OS/Remote`. Core must function completely without AI. Do not hard-code a specific model into core Manuscript architecture.

**S-56 (§30)** Document deletion: empty document — confirm then remove; document with children — explicit policy (promote, cascade delete, or cancel); document with references — warn and clean through canonical ReferenceEngine/integrity architecture. Use `ReferenceIntegrityService` rather than module-specific cleanup logic.

**S-57 (§31)** Data integrity mandatories: stable IDs, valid project ownership, valid parent relationships, no circular hierarchy, deterministic ordering, move preserves ID/content, safe deletion, reference cleanup, project-scoped lookup, no stale-reference inheritance, no duplicate relationship/index, no hidden second Binder, no hidden second Manuscript List Pane, no alternate Manuscript workspace inside the module.

**S-58 (§32.1)** Zero baseline: `flutter analyze → 0 issues`, `flutter test → 300/300 passing` (spec-stated baseline; current repo has 377 tests and this is the latest verified green checkpoint), `flutter build windows --debug → SUCCESS`. Any new error introduced by a cycle is a regression.

**S-59 (§32.2)** Required topology tests must eventually verify: exactly one `ManuscriptListPane`, exactly one `ManuscriptEditor`, exactly one Inspector, no Binder/List/Tree rendered under the editor content path, Column 2 switches between views without duplicates, collapsing Column 2 does not create an alternate list pane.

**S-60 (§33)** Every implementation cycle follows: Phase 0 (repo audit) → Phase 1 (runtime topology audit) → Phase 2 (baseline verification) → Phase 3 (tests first) → Phase 4 (implementation) → Phase 5 (format + analyze) → Phase 6 (full verification) → Phase 7 (architectural regression audit) → Phase 8 (completion report). Do not automatically begin the next cycle.

**S-61 (§34)** Every audited requirement must be classified as exactly one of: IMPLEMENTED / PARTIAL / MISSING / BROKEN / BLOCKED / DEFERRED. Do not label a feature IMPLEMENTED merely because a class or placeholder exists.

**S-62 (§37)** Priority model: P0 = architectural/data-integrity blockers (duplicate workspace, broken project isolation, corrupted references, identity loss, build/analyzer/test regression — block feature cycles); P1 = core Manuscript capability gaps; P2 = UX and scale; P3 = advanced/future capability.

**S-63 (§38)** Roadmap: Cycle 0 (reference/integrity completion, done), Cycle 1 (Filesystem/Markdown), Cycle 2 (ReferenceEngine scale), Cycle 3 (UI reliability/topology tests), Cycle 4 (UX/scale/tools), Cycle 5 (AI architecture). Each cycle's gates must be green before the next begins.

**S-64 (§39)** Prohibited implementation patterns (18 named): rendering a second Binder; putting a Binder inside `ManuscriptEditor`; creating a second relationship database; creating a second authoritative reference index; replacing stable IDs during move/rename/reorder; using file paths as document identity; introducing `build_runner` solely for convenience; suppressing analyzer warnings; skipping or weakening tests; treating a previous audit as proof current runtime behavior is correct.

**S-65 (§40)** Definition of Done: 44-item checklist covering Architecture (9 items), State (4), Hierarchy (13), Editor (13), Inspector (6), References (8), Collections (6), Timeline/Calendar (4), Testing (5), Gates (3), Reporting (2).

**S-66 (§41)** Final architectural statement: Manuscript Module is NOT a standalone three-panel application embedded inside the Project Editor. The four logical areas are Column 1 (Sidebar), Column 2 (ManuscriptListPane with Binder/Corkboard/Outliner/Collections), Column 3 (ManuscriptEditor), Column 4 (Inspector). There must never be a second Binder, second List Pane, or second Manuscript workspace. This topology is a P0 architectural invariant and must be checked at runtime.

**S-67 (§42)** Change control: a proposed architectural change must identify the conflicting existing rule, explain why it is insufficient, describe the new ownership/topology, identify affected modules and persistence/reference implications, identify required tests, and explicitly state whether the four-column contract changes. No implementation prompt may override the spec with informal language such as "three-part Manuscript workspace" or "left Binder panel."

---

## Other Manuscript-Related Docs in Repo

| File | Notes |
|---|---|
| `docs/CLEANUP_REPORT.md` | References lifecycle fix and topology requirements; consistent with spec |
| `docs/audit/06_editor.md` | Pre-cleanup audit of manuscript implementation; some claims now outdated (lifecycle fixes landed in 0877940) |
| `docs/audit/04_state_shell.md` | Pre-cleanup shell audit; column topology described; consistent with spec |
| `docs/audit/00_summary.md` | Pre-cleanup summary; references "P1-4 fix" for history targetType mismatch |
| `README.md` | Describes ManuscriptModule as owning "grammar debouncing, word count, and the @mention reference toolbar" — understates split into ManuscriptModule/ManuscriptEditor/ManuscriptInspector |
| `AGENTS.md` | Correctly references four-column topology; module list over-claims which are in `lib/modules/` |
| `TODO.md` | Contains open tokenization and theme pack items; no manuscript-specific tasks listed |
| `docs/modules/` | Older module specs (pre-spec-replacement); NOT authoritative per §0 |

## Contradictions Between Sources

| Contradiction | Spec says | Other source says |
|---|---|---|
| History targetType | Spec §32.2 requires tests for topology only (no targetType claim) | `audit/06_editor.md` documents `'ManuscriptDocument'` vs `'Chapter'` mismatch as confirmed bug |
| Zero baseline test count | Spec §32.1 states "300/300 passing" | Current repo: 377 tests (post-Cycle 0 additions); spec baseline is stale |
| Controller lifecycle | Spec §1.4 / §2.2 assigns controller ownership to ManuscriptEditor | Prior audit (pre-cleanup) identified shell as leaking it; cleanup fixed this; spec and current code now agree |
| `ManuscriptService` (legacy) | Not mentioned in spec | Still exists in `lib/services/manuscript_service.dart` serving legacy Chapter box |
