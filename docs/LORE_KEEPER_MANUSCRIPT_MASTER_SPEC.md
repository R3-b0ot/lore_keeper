# LORE KEEPER — MANUSCRIPT MODULE MASTER SPECIFICATION

## Purpose

This is the canonical specification for the Manuscript Module. Because the current Manuscript model has changed substantially, **the current repository must be audited against this document before implementation**. Earlier implementation status must not be assumed to remain valid.

---

# 1. CORE ARCHITECTURE RULES

The Manuscript Module provides:

- Manuscript hierarchy and organization
- Rich-text writing
- Scene/chapter/part metadata
- Binder
- Corkboard
- Outliner
- Collections
- Inspector
- Entity references
- Central ReferenceEngine integration
- Timeline and Calendar integration
- Search
- Statistics
- Status/workflow
- File-system support
- Persistence and migration
- Optional AI readiness

### Non-negotiable rules

1. Do not create duplicate relationship databases.
2. Cross-module relationships use `EntityRef` and the central `ReferenceEngine`.
3. All data is project-scoped.
4. Stable IDs survive rename, move, reorder, and editing.
5. Moving a document must preserve its identity and content.
6. Ordering must be deterministic.
7. Deletion must explicitly handle inbound/outbound references.
8. The Project Editor's four-column architecture must be audited before UI changes.
9. **Column 2 is mandatory** and is the Manuscript List Pane.
10. Reuse existing working systems instead of rebuilding them.
11. AI is optional and must never be required for core functionality.
12. Persistence/schema changes require migration analysis.

---

# 2. PROJECT EDITOR — FOUR-COLUMN ARCHITECTURE

This must be audited **every time the Manuscript UI is migrated or redesigned**.

| Position | Panel | Manuscript responsibility |
|---|---|---|
| Column 1 | `ModuleSidebar` | Global module navigation |
| Column 2 | Module List Pane | Binder / Corkboard / Outliner / Collections |
| Column 3 | Content Pane | Active Manuscript Editor |
| Column 4 | Inspector | Document/scene metadata and references |
| Right edge | `SpecificFunctionsBar` | Shared History / Find / Replace / Settings |

### Column 1 — Module Sidebar

Shared navigation between project modules.

### Column 2 — Manuscript List Pane

**Mandatory.**

Contains:

- Binder
- Corkboard
- Outliner
- Collections
- relevant list/search/filter controls

The List Pane must not be omitted or merged conceptually into the editor.

### Column 3 — Content Pane

Contains:

- active manuscript document
- rich-text editor
- document search
- editing controls

### Column 4 — Inspector

Contains contextual:

- metadata
- scene information
- references
- tags
- hierarchy information
- actions

### Audit requirement

Before changing Project Editor files:

1. Inspect `project_editor_screen.dart`.
2. Inspect the desktop/layout implementation.
3. Identify the current four columns.
4. Identify how Manuscript supplies each column.
5. Record deviations.
6. Only then plan UI changes.

---

# 3. MANUSCRIPT DOCUMENT MODEL

Required conceptual hierarchy:

- Manuscript
- Part
- Chapter
- Scene
- Section
- Note
- Research
- Front Matter
- Back Matter
- Custom

Core properties:

- stable ID
- project ID
- parent ID
- order index
- title
- content
- summary
- metadata
- status
- timestamps

### Hierarchy operations

- Create child
- Create sibling
- Rename
- Duplicate
- Delete
- Move
- Drag/reorder
- Expand/collapse
- Select
- Open

Moving must preserve ID, content and metadata.

Circular hierarchy must be impossible.

---

# 4. DOCUMENT STATUS

Required:

- Idea
- Outline
- Draft
- Revised
- Complete
- Archived

Status must work consistently across:

- Binder
- Corkboard
- Outliner
- Inspector
- Collections
- filtering/search

---

# 5. RICH-TEXT EDITOR

Required capabilities:

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
- autosave
- document switching
- persistence

Autosave must be debounced and must not rebuild unrelated module state on every keystroke.

Existing Quill image/table implementations should be audited and reused if present.

---

# 6. MANUSCRIPT LIST PANE

Column 2 must expose the Manuscript views:

1. Binder
2. Corkboard
3. Outliner
4. Collections

All four operate on the same underlying manuscript data.

---

# 7. BINDER

Hierarchical tree view.

Must support:

- hierarchy
- expand/collapse
- selection
- create child
- create sibling
- rename
- duplicate
- delete
- move
- drag reorder
- deterministic ordering
- type display
- status display
- word count where appropriate

Drag/reorder must persist `orderIndex`.

---

# 8. CORKBOARD

Cards should expose:

- Title
- Summary
- Word count
- Status
- POV
- Location
- Timeline
- Tags

Drag reorder must update the same hierarchy used by Binder.

---

# 9. OUTLINER

Structured table with:

- Scene
- POV
- Location
- Timeline
- Words
- Status

Column visibility must be configurable.

---

# 10. COLLECTIONS

Collections live in **Column 2**.

## Smart Collections

Required baseline:

- All Documents
- Favorites
- Needs Revision
- Recent
- document-type views
- status views

## Entity Collections

Support:

- Characters
- Species
- Locations
- Organizations
- Factions
- Timeline Events

Entity Collections must resolve through:

`EntityRef → ReferenceEngine → ManuscriptDocuments`

**No duplicate relationship/index may be created for Collections.**

## Custom Collections

Must be:

- user-created
- persistent
- searchable/filterable

## Creation flow

`New Collection`
→ `Category`
→ `Entity Type` if applicable
→ `Search Entity`
→ `Select Entity`
→ `Create`

Collection names may default to the selected entity name.

Selecting a collection document must open the correct document in Column 3.

---

# 11. FAVORITES

Favorites must be persistent and exposed through Collections.

Audit:

- storage
- toggle
- restart persistence
- filtering
- project ownership

---

# 12. INSPECTOR

Column 4.

General metadata:

- Title
- Type
- Word count
- Character count
- Status
- Tags
- References
- hierarchy

Scene metadata:

- POV Character
- Location
- Time
- Plotline
- Characters
- Status
- Purpose
- Tags

Resolve entity IDs to readable names whenever possible.

---

# 13. ENTITY REFERENCES

Referenceable types:

- Character
- Location
- Item
- Organization
- Species
- Faction
- Timeline Event
- Manuscript Document
- Research
- Calendar Date

Inline references should support an `@mention`-style workflow where appropriate.

The central reference architecture must remain the single relationship mechanism.

---

# 14. REFERENCE ENGINE

Required:

- Manuscript → Entity references
- Entity → Manuscript backlinks
- deterministic indexing
- project-scoped queries
- cross-project isolation
- stale-entry cleanup
- source cleanup
- target cleanup
- purge
- unresolved references

A Project A reference must never resolve against Project B.

### Entity deletion

Use a shared integrity mechanism supporting:

1. Cancel
2. Delete & Preserve Unresolved
3. Delete & Remove References

Deleting/recreating an entity must never cause stale references to attach to the new entity.

Do not create per-module competing relationship/index systems.

---

# 15. TIMELINE INTEGRATION

Required:

- Scene → Timeline Event
- Timeline Event → Manuscript Documents
- bidirectional navigation
- readable event names
- Inspector integration
- project-scoped references

Timeline picker should support:

- search
- calendar/date context where available
- clear/unlink

---

# 16. CALENDAR INTEGRATION

Scenes should support a calendar date/reference.

Required:

- assign date
- clear date
- readable date display
- existing CalendarSystem/Chronology integration
- chronology-aware UI

Do not create a second calendar implementation.

---

# 17. TIMELINE/CALENDAR RELATIONSHIP

Intended architecture:

`ManuscriptDocument`
↔ `EntityRef`
↔ `ReferenceEngine`
↔ `TimelineEvent / CalendarDate`

Timeline must discover linked manuscript documents.

Manuscript must discover linked timeline events.

No duplicate relationship database.

---

# 18. SEARCH

Global Manuscript search:

- title
- body/content
- summary
- metadata
- tags
- linked entities
- type
- status

Search result must open the correct document.

### Editor search

Must support:

- search
- next
- previous
- result count
- exact match positioning
- visual highlighting

---

# 19. STATISTICS

Available at:

- Scene
- Chapter
- Part
- Manuscript

Metrics:

- word count
- character count where appropriate

Parent totals should be derived rather than manually duplicated.

---

# 20. FOCUS MODE

Editor-focused presentation.

Should:

- reduce distractions
- preserve active document
- restore normal layout safely

Audit whether current implementation is view-state or route-based. Do not unnecessarily rebuild it.

---

# 21. FILE SYSTEM

Audit Markdown/YAML support if present.

Requirements:

- stable identity
- frontmatter
- content persistence
- synchronization
- migration
- conflict handling

Do not create competing sources of truth.

---

# 22. DATABASE

`DatabaseManager` owns:

- database initialization
- schema versioning
- adapters
- project ownership
- migrations

Required document persistence:

- stable ID
- projectId
- parentId
- orderIndex
- metadata
- references
- status

Schema changes require migration analysis.

---

# 23. MIGRATION

Migration must be:

- sequential
- project-safe
- backed up where possible
- non-destructive where possible

Audit existing migrations before modifying them.

Do not invent a migration merely to solve a UI or compile problem.

---

# 24. PERFORMANCE

Target behavior:

- efficient active-document loading
- debounced autosave
- no unrelated rebuilds while typing
- efficient reference indexing
- scalable Binder
- acceptable large-project behavior

Potential optimizations may include lazy Binder loading, virtualization, incremental ReferenceEngine updates and better search indexing, but must be evidence-driven.

---

# 25. AI ARCHITECTURE

AI remains optional.

Target:

`Manuscript Context`
→ `ContextBuilder`
→ `AiProvider`
→ Local / LM Studio / OS / Remote provider

Core Manuscript must function without AI.

Potential future features:

- summarize
- explain
- continuity checking
- contradiction detection
- character/entity detection
- unresolved references
- timeline consistency
- relationship discovery

Do not hard-code a specific model.

---

# 26. CONTEXT BUILDER

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

Must respect project boundaries and model context limits.

---

# 27. DELETION

### Empty document
Safe deletion after confirmation.

### Document with children
Offer promote-children or cascade behavior.

### Document with external references
Warn and handle references safely.

### Entity referenced by Manuscript
Use the shared deletion-integrity mechanism.

---

# 28. DATA INTEGRITY

Mandatory:

- stable IDs
- valid project ownership
- valid parents
- no circular hierarchy
- deterministic ordering
- move preserves ID
- move preserves content
- safe deletion
- reference cleanup
- project-scoped lookup
- no stale-reference inheritance
- no duplicate relationship database

---

# 29. AUDIT PROCESS

## Phase 0 — Repository Audit

Inspect current:

- models
- providers
- services
- widgets
- screens
- routes
- persistence
- migrations
- ReferenceEngine
- EntityRef
- Timeline
- Calendar
- Project Editor
- tests
- generated code
- dependencies

**Do not modify code.**

## Phase 1 — Four-Column Architecture Audit

Map current implementation:

| Column | Current implementation | Expected | Status |
|---|---|---|---|

## Phase 2 — Feature Audit

For every requirement classify:

- IMPLEMENTED
- PARTIAL
- MISSING
- BROKEN
- UNKNOWN

Include evidence from actual repository files.

## Phase 3 — Data Model Audit

Verify all fields, adapters, references, IDs, project ownership and persistence.

## Phase 4 — Cross-Module Audit

Verify:

- Characters
- Species
- Locations
- Organizations
- Factions
- Timeline
- Calendar
- ReferenceEngine

## Phase 5 — Persistence Audit

Verify:

- Hive boxes
- adapters
- schema
- migrations
- file synchronization
- project isolation

## Phase 6 — Test/Build Audit

Run:

`flutter analyze`

`flutter test`

`flutter build windows --debug`

Separate baseline issues from regressions.

---

# 30. AUDIT OUTPUT

Produce:

## Executive Summary

- build status
- analyzer status
- test status
- overall health

## Architecture Map

Four-column mapping and deviations.

## Feature Compliance Matrix

| Feature | Requirement | Current implementation | Status | Evidence | Gap |
|---|---|---|---|---|---|

## Data Model Audit

| Area | Current | Required | Status | Risk |
|---|---|---|---|---|

## Cross-Module Audit

| Module | References | Backlinks | Deletion integrity | Status |
|---|---|---|---|---|

## Persistence Audit

| Area | Status | Evidence | Risk |
|---|---|---|---|

## Test Coverage

| Area | Coverage | Status | Gap |
|---|---|---|---|

## Priority Plan

- P0 — blockers/data integrity
- P1 — core missing features
- P2 — UX/polish
- P3 — future/advanced

---

# 31. IMPLEMENTATION RULE

After the audit:

1. Use the actual current repository as the source of truth.
2. Reuse working code.
3. Do not blindly recreate old implementations.
4. Preserve stable IDs.
5. Preserve project ownership.
6. Preserve the four-column architecture.
7. Preserve Column 2.
8. Use ReferenceEngine rather than creating relationship duplicates.
9. Add tests for every substantive change.
10. Verify persistence after model changes.
11. Verify cross-module behavior.
12. Verify project isolation.

---

# 32. IMPLEMENTATION ORDER

The exact order is determined by the audit.

Potential sequence:

### Cycle 0 — Recovery/Foundation
Build, model, persistence and architectural blockers.

### Cycle 1 — Core Manuscript
Hierarchy, Binder, Editor, Inspector, Corkboard, Outliner.

### Cycle 2 — Collections/Search
Smart, Entity and Custom Collections, Favorites, search.

### Cycle 3 — References
EntityRef, ReferenceEngine, deletion integrity and all supported entity types.

### Cycle 4 — Timeline/Calendar
Event picker, calendar dates, bidirectional navigation and chronology.

### Cycle 5 — AI
ContextBuilder and provider implementations.

### Cycle 6 — Performance/Polish
Profiling, lazy loading, indexing, Focus Mode and migration improvements.

The audit may reorder these.

---

# 33. DEFINITION OF DONE

## Architecture
- [ ] Four-column Project Editor verified
- [ ] Column 2 List Pane exists
- [ ] Column 3 editor exists
- [ ] Column 4 Inspector exists
- [ ] Shared sidebar/tools remain shared

## Hierarchy
- [ ] All document types
- [ ] Child/sibling creation
- [ ] Rename
- [ ] Duplicate
- [ ] Delete
- [ ] Move
- [ ] Drag reorder
- [ ] Stable IDs
- [ ] Deterministic ordering
- [ ] Circular hierarchy prevention

## Editor
- [ ] Rich formatting
- [ ] Links
- [ ] References
- [ ] Images
- [ ] Tables
- [ ] Undo/redo
- [ ] Search
- [ ] Match positioning
- [ ] Word/character counts
- [ ] Autosave
- [ ] Persistence

## Views
- [ ] Binder
- [ ] Corkboard
- [ ] Outliner
- [ ] Collections

## Collections
- [ ] Smart Collections
- [ ] Favorites
- [ ] Needs Revision
- [ ] Recent
- [ ] Entity Collections
- [ ] Custom Collections
- [ ] Persistence
- [ ] Correct document opening

## Inspector
- [ ] Document metadata
- [ ] Scene metadata
- [ ] Purpose
- [ ] References
- [ ] Readable entity names
- [ ] Tags
- [ ] Hierarchy

## References
- [ ] EntityRef
- [ ] ReferenceEngine
- [ ] Project isolation
- [ ] Backlinks
- [ ] Supported entity types
- [ ] Stale-entry cleanup
- [ ] Deletion integrity
- [ ] Unresolved references

## Timeline/Calendar
- [ ] Event picker
- [ ] Event display
- [ ] Calendar date
- [ ] Bidirectional navigation
- [ ] Chronology integration

## Persistence
- [ ] DatabaseManager ownership
- [ ] Schema versioning
- [ ] Adapters
- [ ] Project ownership
- [ ] Migrations
- [ ] File-system support
- [ ] Stable IDs

## AI
- [ ] Optional AiProvider
- [ ] ContextBuilder architecture
- [ ] No hard AI dependency
- [ ] Provider extensibility

## Verification
- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] `flutter build windows --debug`
- [ ] No newly introduced analyzer errors
- [ ] Regression tests
- [ ] Persistence tests
- [ ] Cross-module tests
- [ ] Deletion-integrity tests

---

# 34. CRITICAL RULE

**The audit is authoritative over historical implementation summaries.**

If the current repository differs from previous Manuscript versions, report the current state.

Do not silently restore old architecture.

Classify discrepancies as:

- `IMPLEMENTED`
- `PARTIAL`
- `MISSING`
- `BROKEN`
- `UNKNOWN`
- `DEVIATION`

If a requirement cannot be confirmed from the repository, report `UNKNOWN` rather than guessing.

---

# 35. COMPLETE WORKFLOW

`MASTER SPEC`
→ `REPOSITORY AUDIT`
→ `4-COLUMN ARCHITECTURE AUDIT`
→ `FEATURE AUDIT`
→ `DATA/PERSISTENCE AUDIT`
→ `CROSS-MODULE AUDIT`
→ `TEST/BUILD AUDIT`
→ `PRIORITIZED GAP REPORT`
→ `IMPLEMENTATION PLAN`
→ `IMPLEMENTATION`
→ `TESTS`
→ `ANALYZER`
→ `WINDOWS BUILD`
→ `FINAL REGRESSION AUDIT`
→ `DEFINITION OF DONE`

**Do not begin implementation until the audit is complete.**
