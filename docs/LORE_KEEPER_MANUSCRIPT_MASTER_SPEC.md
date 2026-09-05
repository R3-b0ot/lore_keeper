# LORE KEEPER — MANUSCRIPT MODULE MASTER SPECIFICATION

**Document status:** Canonical / Normative  
**Scope:** Manuscript Module and its Project Editor integration  
**Platform:** Flutter / Dart / Windows desktop first  
**Last re-baselined:** 2026-09-05

---

## 0. PURPOSE AND AUTHORITY

This document is the **single canonical specification** for the Lore Keeper Manuscript Module.

It replaces all earlier Manuscript Module specifications, migration notes, implementation prompts, and informal descriptions of the Manuscript workspace. Earlier documents may contain useful historical context, but they are **not implementation authority** when they conflict with this document.

The repository is the source of truth for what currently exists. This document is the source of truth for what the architecture and behavior are intended to be.

Every implementation cycle must therefore answer two separate questions:

1. **What does the repository currently do?**
2. **What does this specification require?**

An implementation must not silently reconcile the two by inventing architecture. A gap must be identified explicitly and then implemented deliberately.

### 0.1 Core principles

- Preserve working architecture before adding features.
- Prefer extension and parameterization over replacement.
- Do not create parallel systems for functionality already owned by an existing service.
- Project ownership is mandatory for all project data and references.
- Stable IDs are identity; titles and names are presentation data.
- `EntityRef` is the canonical cross-module reference value.
- `ReferenceEngine` is the canonical relationship/index mechanism.
- `ReferenceIntegrityService` is the canonical deletion-integrity coordinator.
- `DatabaseManager` is the canonical database/bootstrap owner.
- AI is optional and must never be required for core Manuscript functionality.
- The desktop Project Editor topology defined in this document is non-negotiable.

---

# 1. ABSOLUTE UI TOPOLOGY — NON-NEGOTIABLE

This section exists specifically to prevent the historical duplicate-Binder/duplicate-list-pane defect.

## 1.1 The Manuscript Module does NOT own a separate workspace layout

The Manuscript Module is a **content module hosted by the existing Project Editor shell**.

It must not construct a second Manuscript workspace inside itself.

There is exactly **one** desktop Project Editor layout.

There is exactly **one** visible Manuscript navigation/list region.

That region is **Column 2: `ManuscriptListPane`**.

The Binder is a **view inside `ManuscriptListPane`**. It is not a second panel owned by `ManuscriptModule`.

## 1.2 Canonical desktop topology

```text
PROJECT EDITOR
│
├── Column 1
│   └── ModuleSidebar
│
├── Column 2
│   └── ManuscriptListPane
│       ├── Binder
│       ├── Corkboard
│       ├── Outliner
│       └── Collections
│
├── Column 3
│   └── ManuscriptEditor
│
├── Column 4
│   └── Inspector
│
└── Right Edge
    └── SpecificFunctionsBar
```

The runtime must **not** produce this:

```text
PROJECT EDITOR
│
├── ModuleSidebar
├── Binder                 ← INVALID DUPLICATE
├── ManuscriptListPane
│   └── Binder             ← VALID
├── ManuscriptEditor
└── Inspector
```

It must also not produce this:

```text
PROJECT EDITOR
│
├── ModuleSidebar
├── ManuscriptListPane
├── ManuscriptModule
│   ├── Binder             ← INVALID
│   ├── Editor
│   └── Inspector
└── SpecificFunctionsBar
```

## 1.3 Absolute runtime invariants

For the normal desktop Manuscript view:

```text
COUNT(visible ModuleSidebar)       == 1
COUNT(visible ManuscriptListPane)  == 1
COUNT(visible ManuscriptEditor)    == 1
COUNT(visible Inspector)            == 1
COUNT(visible Binder/List/Tree)     == 1
```

The final condition means that a Binder, Corkboard, Outliner, or Collections navigation surface may occupy Column 2, but the Manuscript Module must never render an additional navigation/list/tree surface elsewhere.

Responsive layouts may collapse or temporarily overlay Column 2, but they must not create a second simultaneous instance.

## 1.4 Ownership rules

| Responsibility | Owner |
|---|---|
| Global module navigation | `ProjectEditorScreen` / `ModuleSidebar` |
| Column 2 layout slot | `ProjectEditorScreen` |
| Binder/Corkboard/Outliner/Collections presentation | `ManuscriptListPane` |
| Shared manuscript state | `ManuscriptBinderProvider` |
| Active document editing | `ManuscriptEditor` |
| Document metadata/reference inspection | `Inspector` inside Manuscript content area |
| Global tools/history | `SpecificFunctionsBar` / shell |
| Cross-module relationship/index | `ReferenceEngine` |
| Reference deletion integrity | `ReferenceIntegrityService` |

## 1.5 Explicit prohibition inside `ManuscriptModule`

`ManuscriptModule` / `ManuscriptEditor` must **not** own or render:

- `ManuscriptBinder`
- `ManuscriptListPane`
- a second Binder
- a manuscript file tree
- a chapter/document navigation tree
- a second Corkboard
- a second Outliner
- a second Collections pane
- a private manuscript navigation sidebar
- an alternate left-panel view switcher

Legacy state such as `_LeftPanelMode`, when it controls a second visible Binder/Corkboard/Outliner/Collections surface, is architectural debt and must be removed as part of topology correction.

Compatibility logic for old chapter keys may remain where required by the repository, but compatibility logic must not create a second visible navigation surface.

---

# 2. PROJECT EDITOR CONTRACT

## 2.1 Columns

| Position | Canonical widget | Responsibility |
|---|---|---|
| Column 1 | `ModuleSidebar` | Global project/module navigation |
| Column 2 | `ManuscriptListPane` | Manuscript navigation and alternate list views |
| Column 3 | `ManuscriptEditor` | Active document content editing |
| Column 4 | `Inspector` | Active document metadata, hierarchy and references |
| Right edge | `SpecificFunctionsBar` | Shared tools and utilities |

The shell may implement these using nested layout widgets, but the **logical ownership must remain exactly as defined above**.

## 2.2 Shell responsibilities

`ProjectEditorScreen` owns:

- module selection
- desktop/mobile layout selection
- the shared Manuscript Binder provider
- the shared Manuscript `ReferenceEngine`
- shell-level navigation
- the Column 2 widget slot
- the Column 3/4 Manuscript content slot
- global tool controls

The shell must pass the shared manuscript state into the Manuscript components rather than allowing each component to instantiate independent providers.

## 2.3 Manuscript module responsibilities

The Manuscript module consumes shell-owned state and provides:

- editor behavior
- document metadata/Inspector behavior
- manuscript-specific editing services
- reference UI
- document statistics
- manuscript-specific commands

It does not replace the shell's layout.

## 2.4 Runtime topology audit

Before any Manuscript UI implementation or redesign:

1. Inspect `project_editor_screen.dart`.
2. Inspect the desktop layout implementation.
3. Inspect the mobile/responsive layout implementation.
4. Trace the `secondColumn`/Column 2 widget.
5. Trace the `moduleContent`/Column 3+4 widget.
6. Trace every Binder/List/Tree widget instantiated by those paths.
7. Confirm there is exactly one visible Manuscript navigation surface.
8. Only then modify code.

A static source review is insufficient. The resulting widget tree must be checked against the runtime topology.

---

# 3. MANUSCRIPT DOCUMENT MODEL

## 3.1 Conceptual document types

The canonical Manuscript hierarchy supports these document types:

1. Manuscript
2. Part
3. Chapter
4. Scene
5. Section
6. Note
7. Research
8. Front Matter
9. Back Matter
10. Custom

The exact enum names and storage representation must follow the current repository model.

## 3.2 Required identity/data concepts

Every Manuscript document must preserve, where applicable:

- stable document ID
- project ID
- parent document ID
- deterministic order index
- title
- document type
- rich-text content
- status
- summary
- metadata
- references
- timestamps
- word count
- character count
- favorite state

Additional fields already present in the canonical repository model must not be discarded merely because they are not listed above.

## 3.3 Identity rule

The document ID is identity.

Rename, move, reorder, editing, status changes, and metadata changes must not change the document ID.

A document move must preserve:

- ID
- project ownership
- content
- references
- metadata
- timestamps unless the operation intentionally updates them

## 3.4 Hierarchy operations

The Binder/data layer must support:

- create child
- create sibling
- rename
- duplicate
- delete
- move
- drag reorder
- expand/collapse state
- select
- open

Circular parent/child relationships must be impossible through normal operations.

---

# 4. MANUSCRIPT PROVIDER AND STATE OWNERSHIP

## 4.1 Single shared provider

The shell owns one `ManuscriptBinderProvider` for the active project.

That provider is shared by:

- `ManuscriptListPane`
- Binder
- Corkboard
- Outliner
- Collections
- ManuscriptEditor
- Inspector-related manuscript state

No child widget may silently instantiate another provider for the same project.

## 4.2 Single shared ReferenceEngine

The shell should create the shared `ReferenceEngine` and thread it through the relevant providers/services.

Collections, editor references, entity deletion integrity, and backlinks must observe the same engine instance where the architecture requires a shared in-memory index.

A component may create a standalone engine only for explicitly isolated/testing scenarios or a documented standalone component mode. It must not do so silently in the normal Project Editor runtime.

---

# 5. COLUMN 2 — MANUSCRIPT LIST PANE

`ManuscriptListPane` is the canonical Column 2 host.

It exposes four views:

1. Binder
2. Corkboard
3. Outliner
4. Collections

The view switcher changes the contents of Column 2. It does not create additional columns.

All four views operate on the same `ManuscriptBinderProvider` data.

## 5.1 Column 2 requirements

- visible in normal desktop layout
- collapsible through the shell's existing list-pane control
- resizable where supported by the shell
- project-scoped
- synchronized with active document selection
- capable of switching view without replacing the underlying provider

## 5.2 Architectural testability

The major panes should have stable widget keys or equivalent test selectors so widget tests can assert the topology.

Recommended canonical keys:

```text
project-editor-column-1
manuscript-list-pane
manuscript-editor
manuscript-inspector
specific-functions-bar
```

The exact Flutter mechanism may differ, but the semantic testability requirement is mandatory.

---

# 6. BINDER

The Binder is the default Column 2 view.

It is a hierarchical tree over `ManuscriptDocument` data.

## 6.1 Required behavior

- show hierarchy
- expand/collapse
- select document
- open document
- create child
- create sibling
- rename
- duplicate
- delete
- move
- drag reorder
- show document type
- show status
- show word count where appropriate
- persist order changes

## 6.2 Ordering

Sibling ordering must be deterministic.

`orderIndex` is the canonical persisted ordering value where the model provides it.

Reordering must update the same underlying data used by Corkboard and Outliner.

## 6.3 Selection

Selecting a document in Binder must update the shell's active manuscript document and therefore update:

- Column 3 editor
- Column 4 Inspector

The editor must not maintain an independent navigation selection that can diverge from Column 2.

---

# 7. CORKBOARD

Corkboard is a Column 2 view over the same document hierarchy.

Cards should expose, where applicable:

- title
- summary
- word count
- status
- POV
- location
- timeline
- tags

Drag reorder must update the same hierarchy/order data used by Binder.

Corkboard must not maintain a parallel ordering system.

---

# 8. OUTLINER

Outliner is a structured Column 2 view over the same document data.

Baseline columns:

- Scene
- POV
- Location
- Timeline
- Words
- Status
- Plotline where available

Column visibility should be configurable where implemented.

Sorting/filtering must not mutate canonical hierarchy order unless explicitly requested as a reorder operation.

---

# 9. COLLECTIONS

Collections live in Column 2.

They are views/queries over existing Manuscript documents and relationships.

## 9.1 Smart collections

Baseline categories include:

- All Documents
- Manuscript
- Parts
- Chapters
- Scenes
- Sections
- Notes
- Research
- Front Matter
- Back Matter
- Custom
- Favorites
- Needs Revision
- Recent
- Draft
- Revised
- Complete
- Archived

The exact available UI may reflect the current model, but no smart collection may create duplicate storage of manuscript relationships.

## 9.2 Entity collections

Supported entity collection categories include:

- Characters
- Species
- Locations
- Organizations
- Factions
- Timeline Events

Entity collections resolve through:

```text
EntityRef
   ↓
ReferenceEngine
   ↓
ManuscriptDocuments
```

No collection-specific relationship database or backlink index may be created.

## 9.3 Custom collections

Custom collections must be:

- user-created
- project-scoped
- persistent
- searchable/filterable
- selectable from Column 2

Selecting a collection result must open the correct Manuscript document in Column 3.

---

# 10. FAVORITES

Favorites are document state, not a separate relationship system.

They must be:

- persistent
- project-scoped
- toggleable
- visible through Collections
- preserved across restart

Do not duplicate favorite membership in a separate relationship database when the canonical document model already owns the state.

---

# 11. COLUMN 3 — MANUSCRIPT EDITOR

Column 3 contains the active document editor.

It must not contain a second manuscript navigation panel.

## 11.1 Editor responsibilities

- load active document
- edit title
- edit rich text
- persist content
- autosave
- show editing status
- maintain undo/redo
- expose find/replace
- calculate statistics
- support references
- support images/tables where implemented
- support Focus Mode where implemented

## 11.2 Document selection

The active document is selected by Column 2 and stored in shared shell state.

The editor may resolve compatibility keys such as legacy chapter identifiers, but it must ultimately resolve to a canonical `ManuscriptDocument` ID.

## 11.3 Autosave

Autosave must be debounced.

The current target is approximately two seconds unless profiling or UX requirements justify another value.

Autosave must not rebuild unrelated project/module state on every keystroke.

---

# 12. RICH-TEXT REQUIREMENTS

The editor should support, as provided by the current Flutter Quill implementation:

- paragraphs
- headings
- bold
- italic
- underline
- lists
- block quotes
- links
- inline entity references
- images
- tables
- undo/redo
- find/replace
- word count
- character count
- persistence

Existing Quill extensions and working image/table implementations must be reused rather than replaced without a concrete reason.

---

# 13. INSPECTOR — COLUMN 4

Inspector is Column 4 of the Manuscript Project Editor.

It describes the currently selected Manuscript document.

## 13.1 General information

Where applicable:

- title
- document type
- status
- word count
- character count
- created date
- modified date
- favorite state
- hierarchy
- references
- tags

## 13.2 Scene metadata

Where applicable:

- POV character
- location
- time/calendar date
- plotline
- characters
- status
- purpose
- tags
- timeline event

## 13.3 Reference display

Reference IDs must be resolved to readable names whenever a canonical source exists.

If an entity is missing, belongs to another project, or has no canonical source, the UI must use an explicit unresolved state rather than pretending that the raw ID is a valid name.

Example semantic state:

```text
Unresolved • <id>
```

The exact visual treatment may follow the existing design system.

## 13.4 Inspector ownership

Inspector must not create its own relationship/index system or independent entity cache that becomes a second source of truth.

Name resolution should use the canonical resolution service where available.

---

# 14. DOCUMENT STATUS / WORKFLOW

Canonical statuses:

- Idea
- Outline
- Draft
- Revised
- Complete
- Archived

Status must be represented consistently across:

- Binder
- Corkboard
- Outliner
- Collections
- Inspector
- filtering/search

Status changes must not alter document identity.

---

# 15. ENTITY REFERENCE ARCHITECTURE

## 15.1 Canonical reference value

Cross-module references use `EntityRef`.

An `EntityRef` must preserve, where defined by the current model:

- stable target ID
- entity type
- project ID

## 15.2 Referenceable types

The Manuscript reference architecture recognizes:

1. Character
2. Location
3. Item
4. Organization
5. Species
6. Faction
7. Timeline Event
8. Manuscript Document
9. Research
10. Calendar Date

Not every type necessarily has a conventional Hive entity model or canonical provider.

**Do not invent a model merely to make a reference type appear implemented.**

If a type has no canonical data source, its behavior must be explicitly documented as unsupported/deferred until an authoritative source exists.

## 15.3 Inline references

The editor should support an `@mention`-style workflow for referenceable types that have a canonical project-scoped source.

Autocomplete must:

- be project-scoped
- use canonical entity sources
- create the canonical reference representation
- preserve stable IDs
- use the existing reference architecture
- never create a second relationship index

## 15.4 Entity name resolution

A single resolution path should be shared between:

- Inspector
- deletion-integrity existence checks where appropriate
- reference display
- autocomplete metadata where appropriate

The resolver must distinguish:

- valid entity
- missing entity
- wrong-project entity
- unsupported/no-source entity

---

# 16. REFERENCE ENGINE

`ReferenceEngine` is the **single relationship/index authority** for cross-module references.

It must support, as applicable:

- Manuscript → Entity references
- Entity → Manuscript backlinks
- deterministic indexing
- project-scoped queries
- cross-project isolation
- source cleanup
- target cleanup
- stale-entry cleanup
- purge
- unresolved references

## 16.1 Prohibited alternatives

Do not create:

- collection-specific relationship indexes
- module-specific backlink databases
- Inspector reference databases
- autocomplete reference databases
- duplicate reverse maps that become authoritative
- separate entity-to-manuscript relationship stores

Temporary derived collections or local UI lists are allowed only when they are clearly non-authoritative and derived from canonical data.

## 16.2 Project isolation

A reference belonging to Project A must never resolve against an entity in Project B, even if the target IDs happen to match.

Project ID must therefore participate in all relevant reference resolution and index queries.

---

# 17. REFERENCE INTEGRITY AND ENTITY DELETION

`ReferenceIntegrityService` is the single deletion-integrity coordinator.

Supported semantic actions:

1. Cancel
2. Delete & Preserve Unresolved
3. Delete & Remove References

## 17.1 Cancel

No entity or reference changes occur.

## 17.2 Delete & Preserve Unresolved

- target entity is deleted
- existing manuscript references remain as unresolved references
- stale ReferenceEngine target entries are purged
- references do not attach to a later entity recreated with the same ID

## 17.3 Delete & Remove References

- target entity is deleted
- inbound manuscript references are removed
- ReferenceEngine source/target entries are cleaned

## 17.4 Recreate-with-same-ID rule

Deleting an entity and later creating an entity with the same ID must never cause old references to become attached automatically.

## 17.5 Existing deletion flows

Only entity types with actual deletion-capable providers/models are to be wired into deletion integrity.

Do not invent deletion flows for model-absent entity types solely to satisfy this specification.

---

# 18. TIMELINE INTEGRATION

Manuscript documents may reference Timeline Events through the canonical reference system.

Required behavior where supported:

- assign Timeline Event
- search/select event
- clear/unlink event
- display readable event name
- navigate to event
- discover linked manuscript documents from Timeline
- preserve project isolation

The Timeline system remains the owner of Timeline Event data.

Manuscript must not create a duplicate Timeline database.

---

# 19. CALENDAR INTEGRATION

Manuscript documents may contain a chronology-aware calendar date.

Required behavior where supported:

- assign date
- clear date
- readable date display
- chronology-aware picker
- use the existing CalendarSystem/Chronology implementation

CalendarDate may be a value/chronology concept rather than a conventional entity model.

**Do not invent a second CalendarDate entity database.**

If CalendarDate cannot safely participate in a particular reference workflow without violating canonical architecture, document the limitation rather than fabricating a model.

---

# 20. TIMELINE/CALENDAR RELATIONSHIP MODEL

The intended architecture is:

```text
ManuscriptDocument
       ↕
    EntityRef
       ↕
ReferenceEngine
       ↕
Timeline Event / supported chronology reference
```

Bidirectional discovery must use the existing ReferenceEngine where the referenced type is represented there.

No duplicate relationship database is permitted.

---

# 21. SEARCH

## 21.1 Manuscript search

Search should cover, where supported:

- title
- body/content
- summary
- metadata
- tags
- linked entities
- document type
- status
- plotline

Search results must open the correct canonical document ID.

## 21.2 Editor search

Required behavior:

- search
- next
- previous
- result count
- exact match positioning
- visual highlighting

Search must operate on the active document without creating a second manuscript state system.

---

# 22. STATISTICS

Statistics should be available at appropriate hierarchy levels, including:

- Scene
- Chapter
- Part
- Manuscript

Metrics include:

- word count
- character count where appropriate

Parent totals should be derived from canonical child/document data rather than manually maintained duplicate totals wherever practical.

---

# 23. FOCUS MODE

Focus Mode is an editor presentation state.

It should:

- reduce distractions
- preserve the active document
- preserve editor content
- restore the normal Project Editor topology safely

Focus Mode must not instantiate another Manuscript workspace.

If the implementation temporarily hides shell columns, it must hide/collapse them rather than create alternate replacements.

---

# 24. FILESYSTEM / MARKDOWN INTERCHANGE

Filesystem support is a planned Manuscript capability and must not create a competing source of truth.

Where implemented, Markdown files may use YAML frontmatter for metadata.

Minimum identity requirements:

- stable document ID
- project ID or project-safe ownership mechanism
- parent ID where applicable
- document type
- status
- order information where required

Filesystem synchronization must define:

- import
- export
- conflict detection
- conflict resolution
- deletion behavior
- rename/move behavior
- stable identity preservation

Do not implement filesystem synchronization by replacing the canonical in-app identity model with file paths.

File path is a location, not identity.

---

# 25. DATABASE AND PERSISTENCE

`DatabaseManager` owns:

- database initialization
- adapter registration
- schema ownership
- project ownership
- migrations where applicable

Existing hand-written Hive adapters must be preserved unless there is a concrete architectural reason to change them.

Do not introduce `build_runner` merely to regenerate adapters.

## 25.1 Hive key rules

Where the current model defines a document ID as its Hive key, production and tests must use the same key semantics.

For example, if production uses:

```dart
box.put(document.id, document);
```

tests must seed the same way rather than using `add()` and compensating for changed IDs.

Tests must model production persistence semantics faithfully.

---

# 26. MIGRATION POLICY

This application is currently unreleased.

Migration work is therefore **not an independent implementation priority** unless a current schema change requires it for correctness.

Rules:

- do not add migration work merely because an old audit mentioned it
- do not revive obsolete migration paths unnecessarily
- if a new persisted schema change is introduced, analyze its impact before implementation
- never compromise current data integrity to avoid a migration decision

Migration must not be used as a reason to reintroduce obsolete architecture.

---

# 27. PERFORMANCE

Performance work must be evidence-driven.

Target behavior includes:

- efficient active-document loading
- debounced autosave
- no unrelated rebuilds while typing
- efficient reference indexing
- scalable Binder behavior
- acceptable large-project behavior

Potential future optimizations include:

- lazy Binder loading
- virtualization
- incremental ReferenceEngine updates
- search indexing

Do not implement an optimization merely because it sounds useful. Profile or identify a concrete bottleneck first.

---

# 28. AI ARCHITECTURE

AI is optional.

The core Manuscript Module must function completely without AI.

Target architecture:

```text
Manuscript Context
       ↓
ContextBuilder
       ↓
AiProvider
       ↓
Local / LM Studio / OS / Remote provider
```

Potential future capabilities:

- summarize
- explain
- continuity checking
- contradiction detection
- entity detection
- unresolved-reference detection
- timeline consistency
- relationship discovery

Do not hard-code a specific model into the core Manuscript architecture.

---

# 29. CONTEXT BUILDER

Future context assembly may include:

- active manuscript
- surrounding scenes
- chapter/part context
- Characters
- Locations
- Species
- Organizations
- Factions
- Timeline Events
- Calendar context
- Research

Context assembly must:

- respect project boundaries
- avoid leaking another project's data
- respect model context limits
- use canonical document/entity data
- avoid creating another persistence layer

---

# 30. DOCUMENT DELETION

## 30.1 Empty document

Confirm before deletion, then safely remove the document.

## 30.2 Document with children

Provide an explicit policy such as:

- promote children
- cascade delete
- cancel

The chosen behavior must be clear to the user.

## 30.3 Document with references

Warn as appropriate and clean references through the canonical ReferenceEngine/integrity architecture.

## 30.4 Entity referenced by Manuscript

Use `ReferenceIntegrityService` rather than module-specific cleanup logic.

---

# 31. DATA INTEGRITY RULES

The following are mandatory:

- stable IDs
- valid project ownership
- valid parent relationships
- no circular hierarchy
- deterministic ordering
- move preserves ID
- move preserves content
- safe deletion
- reference cleanup
- project-scoped lookup
- no stale-reference inheritance
- no duplicate relationship database
- no duplicate reference index
- no hidden second Binder
- no hidden second Manuscript List Pane
- no alternate Manuscript workspace inside the module

---

# 32. TESTING CONTRACT

Testing is part of the architecture contract.

## 32.1 Zero baseline

The current green checkpoint is:

```text
flutter analyze → 0 issues
flutter test    → 300/300 passing
flutter build windows --debug → SUCCESS
```

This is the baseline for future cycles unless a later verified green cycle establishes a new baseline.

Any new analyzer error/warning/info, test failure, or build failure introduced by a cycle is a regression and must be fixed before that cycle is considered complete.

## 32.2 Required topology tests

Widget/integration coverage must eventually verify:

- exactly one `ManuscriptListPane`
- exactly one `ManuscriptEditor`
- exactly one Inspector
- no Binder/List/Tree rendered under the editor content path
- Column 2 switches between Binder/Corkboard/Outliner/Collections without creating duplicates
- collapsing Column 2 does not create an alternate list pane

## 32.3 Required data/reference tests

Where applicable, test:

- project isolation
- stable IDs
- rename preservation
- move preservation
- reorder persistence
- deletion integrity
- unresolved references
- stale-entry cleanup
- recreate-with-same-ID protection
- autocomplete mapping
- readable-name resolution
- missing-entity fallback
- persistence/reload

## 32.4 Production-faithful fixtures

Test fixtures must model production storage semantics.

Do not add test-only workarounds for incorrect Hive registration, incorrect Hive keys, open-order behavior, or provider initialization if the real application does not require them.

When a test fails, identify whether the failure is:

1. a production defect,
2. a test fixture defect, or
3. a specification/architecture defect.

Fix the actual root cause.

---

# 33. IMPLEMENTATION CYCLE PROTOCOL

Every implementation cycle must follow this exact sequence.

## Phase 0 — Repository audit

Before editing:

- inspect the current branch/commit
- inspect relevant models
- inspect providers
- inspect services
- inspect widgets
- inspect screens
- inspect layouts
- inspect persistence
- inspect tests
- inspect ReferenceEngine
- inspect EntityRef
- inspect Timeline
- inspect Calendar
- inspect Project Editor

Do not assume an earlier audit is still accurate.

## Phase 1 — Runtime topology audit

For any UI-related work:

1. trace shell layout
2. trace Column 2
3. trace Column 3
4. trace Column 4
5. trace Binder/List/Tree instantiation
6. identify all widget owners
7. confirm no duplicate runtime surface

## Phase 2 — Baseline verification

Run:

```text
flutter analyze
flutter test
flutter build windows --debug
```

The baseline must be green before implementation begins.

## Phase 3 — Tests first

For substantive behavior:

1. identify existing test patterns
2. add or update tests
3. run targeted tests
4. implement the smallest change
5. run targeted tests again

## Phase 4 — Implementation

Rules:

- reuse working systems
- preserve public behavior unless intentionally changed
- preserve IDs
- preserve project scoping
- use canonical providers/services
- do not introduce duplicate architecture
- do not invent model-absent entities
- do not introduce build_runner for Hive

## Phase 5 — Formatting and static verification

Run formatting on changed Dart files.

Then run:

```text
flutter analyze
```

Required result: zero issues.

## Phase 6 — Full verification

Run:

```text
flutter test
flutter build windows --debug
```

All tests must pass and the build must succeed.

## Phase 7 — Architectural regression audit

Explicitly verify:

- four-column topology
- one Column 2
- one Binder/List/Tree surface
- one editor
- one Inspector
- shared provider
- shared ReferenceEngine
- no duplicate relationships
- no duplicate indexes
- project isolation

## Phase 8 — Completion report

Report:

- baseline
- files changed
- behavior added/fixed
- tests added/changed
- final analyzer result
- final test count
- final build result
- architecture verification
- remaining gaps

Do not automatically begin the next cycle.

---

# 34. AUDIT CLASSIFICATION

Every audited requirement must be classified as exactly one of:

- **IMPLEMENTED** — behavior exists and is verified
- **PARTIAL** — meaningful portion exists but requirements remain
- **MISSING** — not implemented
- **BROKEN** — intended behavior exists but currently fails
- **BLOCKED** — implementation is prevented by a real dependency/architecture constraint
- **DEFERRED** — intentionally postponed with an explicit reason

Do not label a feature IMPLEMENTED merely because a class or placeholder exists.

---

# 35. ARCHITECTURE AUDIT MATRIX

For each Manuscript audit, produce:

| Area | Required | Actual implementation | Status | Evidence | Risk |
|---|---|---|---|---|---|
| Project Editor topology | Four-column contract | | | | |
| Column 2 | One `ManuscriptListPane` | | | | |
| Binder | Column 2 only | | | | |
| Editor | Column 3 only | | | | |
| Inspector | Column 4 only | | | | |
| Provider ownership | One shared provider | | | | |
| ReferenceEngine | Single authority | | | | |
| Deletion integrity | Single coordinator | | | | |
| Persistence | Canonical storage | | | | |
| Project isolation | Mandatory | | | | |

The topology rows are **P0** if they are violated.

---

# 36. FEATURE COMPLIANCE MATRIX

Audits should include at minimum:

| Feature | Status | Evidence | Gap / Next action |
|---|---|---|---|
| Four-column Project Editor | | | |
| Manuscript List Pane | | | |
| Binder | | | |
| Corkboard | | | |
| Outliner | | | |
| Collections | | | |
| Favorites | | | |
| Manuscript Editor | | | |
| Inspector | | | |
| Rich text | | | |
| Entity references | | | |
| ReferenceEngine | | | |
| Deletion integrity | | | |
| Timeline integration | | | |
| Calendar integration | | | |
| Search | | | |
| Statistics | | | |
| Focus Mode | | | |
| Filesystem/Markdown | | | |
| Persistence | | | |
| AI readiness | | | |

---

# 37. PRIORITY MODEL

## P0 — Architectural/data-integrity blockers

Examples:

- duplicate Manuscript workspace
- duplicate Binder/List/Tree
- broken project isolation
- corrupted/stale references
- identity loss
- broken persistence
- circular hierarchy
- build/analyzer/test regression

P0 issues block feature cycles.

## P1 — Core Manuscript capability gaps

Examples:

- missing hierarchy operations
- broken editor persistence
- missing core Inspector behavior
- incomplete reference behavior
- missing core Collections behavior
- missing Timeline/Calendar integration

## P2 — UX and scale

Examples:

- widget coverage
- Binder virtualization
- incremental indexing
- improved filtering
- Focus Mode polish
- SpecificFunctionsBar completeness

## P3 — Advanced/future capability

Examples:

- advanced AI features
- sophisticated context building
- advanced filesystem synchronization
- optional integrations

---

# 38. IMPLEMENTATION ROADMAP

The roadmap is subordinate to the audit. A discovered P0/P1 issue may reorder it.

### Cycle 0 — Reference & Integrity Completion

Completed green checkpoint covering:

- reference name resolution
- deletion-integrity wiring where real deletion-capable providers exist
- inline reference/autocomplete architecture
- Inspector name resolution

Baseline after Cycle 0:

```text
300/300 tests passing
flutter analyze → 0 issues
Windows debug build → SUCCESS
```

### Cycle 1 — Filesystem / Markdown Interchange

Target:

- Markdown export
- Markdown import
- YAML frontmatter
- stable IDs
- conflict detection
- synchronization rules
- production-faithful persistence tests

Do not begin until the runtime topology is confirmed clean.

### Cycle 2 — ReferenceEngine Scale

Target, only if profiling/audit justifies it:

- incremental index updates
- autosave/index interaction
- large-project performance
- reference query efficiency

### Cycle 3 — UI Reliability

Target:

- Binder widget tests
- Corkboard widget tests
- Outliner widget tests
- Collections widget tests
- Editor/Inspector integration tests
- explicit four-column topology tests

### Cycle 4 — UX / Scale / Tools

Target:

- Binder virtualization if required
- SpecificFunctionsBar completeness
- Focus Mode refinement
- search/filter improvements

### Cycle 5 — AI Architecture and Features

Target:

- ContextBuilder
- provider integrations
- optional manuscript assistance

AI must remain decoupled from core persistence and editing.

---

# 39. PROHIBITED IMPLEMENTATION PATTERNS

The following are architectural violations:

1. Rendering a second Binder.
2. Rendering a second Manuscript List Pane.
3. Putting a Binder inside `ManuscriptEditor`.
4. Creating a second manuscript navigation tree inside `ManuscriptModule`.
5. Creating a second relationship database.
6. Creating a second authoritative reference index.
7. Creating a collection-specific backlink system.
8. Creating an Inspector-specific relationship cache that becomes authoritative.
9. Creating a second Calendar database.
10. Inventing model classes for entity types that have no canonical source merely to satisfy a list.
11. Replacing stable IDs during move/rename/reorder.
12. Using file paths as document identity.
13. Introducing build_runner solely for convenience when hand-written Hive adapters are the current contract.
14. Suppressing analyzer warnings/errors to pass a cycle gate.
15. Skipping or weakening tests to preserve a green count.
16. Adding test-only production workarounds instead of fixing incorrect fixtures.
17. Treating a previous audit as proof that current runtime behavior is correct.
18. Starting the next cycle before the current cycle's gates are green.

---

# 40. DEFINITION OF DONE

A Manuscript implementation cycle is complete only when all applicable items are true.

## Architecture

- [ ] Four-column Project Editor verified
- [ ] Column 1 is shell-owned ModuleSidebar
- [ ] Column 2 is exactly one ManuscriptListPane
- [ ] Binder/Corkboard/Outliner/Collections live in Column 2
- [ ] Column 3 is exactly one ManuscriptEditor
- [ ] Column 4 is exactly one Inspector
- [ ] SpecificFunctionsBar remains shell-owned
- [ ] No second Binder/List/Tree exists
- [ ] No nested Manuscript workspace exists

## State

- [ ] One shared ManuscriptBinderProvider
- [ ] One shared ReferenceEngine in normal Project Editor runtime
- [ ] Active document selection is synchronized
- [ ] Project isolation is preserved

## Hierarchy

- [ ] All supported document types
- [ ] Child creation
- [ ] Sibling creation
- [ ] Rename
- [ ] Duplicate
- [ ] Delete
- [ ] Move
- [ ] Drag reorder
- [ ] Stable IDs
- [ ] Deterministic ordering
- [ ] Circular hierarchy prevention

## Editor

- [ ] Rich text
- [ ] Links
- [ ] References
- [ ] Images where supported
- [ ] Tables where supported
- [ ] Undo/redo
- [ ] Search/find/replace
- [ ] Word count
- [ ] Character count
- [ ] Debounced autosave
- [ ] Persistence

## Inspector

- [ ] Metadata
- [ ] Hierarchy
- [ ] References
- [ ] Readable entity names where canonical sources exist
- [ ] Safe unresolved state
- [ ] Project-scoped resolution

## References

- [ ] EntityRef canonical
- [ ] ReferenceEngine canonical
- [ ] project-scoped
- [ ] backlinks
- [ ] stale cleanup
- [ ] deletion integrity
- [ ] recreate-with-same-ID protection
- [ ] no duplicate relationship/index

## Collections

- [ ] Smart collections
- [ ] Entity collections where sources exist
- [ ] Custom collections
- [ ] Favorites
- [ ] Correct document opening
- [ ] No duplicate relationship system

## Timeline / Calendar

- [ ] Timeline assignment where supported
- [ ] Timeline discovery
- [ ] Calendar assignment where supported
- [ ] Existing chronology reused
- [ ] No duplicate calendar system

## Testing

- [ ] Targeted tests pass
- [ ] Full test suite passes
- [ ] Topology tests cover duplicate-pane risk
- [ ] Persistence tests are production-faithful
- [ ] Cross-project tests pass

## Gates

- [ ] `flutter analyze` → 0 issues
- [ ] `flutter test` → all tests passing
- [ ] `flutter build windows --debug` → SUCCESS

## Reporting

- [ ] Exact files changed reported
- [ ] Exact test count reported
- [ ] Remaining gaps reported
- [ ] Next cycle NOT started automatically

---

# 41. FINAL ARCHITECTURAL STATEMENT

Lore Keeper's Manuscript Module is **not a standalone three-panel application embedded inside the Project Editor**.

It is a module hosted by a shared Project Editor shell.

The canonical desktop relationship is:

```text
ModuleSidebar
      │
      ▼
ManuscriptListPane
      │
      ├── Binder
      ├── Corkboard
      ├── Outliner
      └── Collections

ManuscriptListPane selection
      │
      ▼
ManuscriptEditor
      │
      ▼
Inspector
```

The four visible logical areas are therefore:

```text
COLUMN 1        COLUMN 2              COLUMN 3             COLUMN 4
────────        ─────────              ─────────             ─────────
Sidebar         ManuscriptListPane     ManuscriptEditor      Inspector
                ├─ Binder
                ├─ Corkboard
                ├─ Outliner
                └─ Collections
```

**There must never be a second Binder, second List Pane, or second Manuscript workspace.**

This topology is a P0 architectural invariant and must be checked at runtime, not merely inferred from class names or earlier audits.

---

# 42. CHANGE CONTROL

This specification may be changed only deliberately.

A proposed architectural change must:

1. identify the conflicting existing rule
2. explain why the existing rule is insufficient
3. describe the new ownership/topology
4. identify affected modules
5. identify persistence/reference implications
6. identify required tests
7. preserve project isolation
8. preserve stable identity
9. explicitly state whether the four-column contract changes

No implementation prompt may override this specification with informal language such as:

- "three-part Manuscript workspace"
- "left Binder panel"
- "Manuscript has its own sidebar"
- "Binder beside the editor"

unless that language is explicitly referring to **Column 2's ManuscriptListPane**.

When such historical terminology appears in source code or older documents, it must be interpreted as legacy terminology and not as permission to create another panel.

---

# END OF CANONICAL MANUSCRIPT MODULE SPECIFICATION
