# Lore Keeper — Species Module
## Complete Functional Specification, Architecture & Individual User Flows

**Purpose:** This document is the implementation reference for the Lore Keeper Species Module. It consolidates the agreed module architecture, classification system, manual creation workflow, tree behavior, article behavior, data rules, validation rules, future AI compatibility, and implementation boundaries.

---

# 1. Module Objective

The Species Module manages all forms of life and life-like entities within a Lore Keeper project.

It must support:

- Real-world fauna
- Real-world flora
- Fictional fauna
- Fictional flora
- Alien life
- Extinct life
- Engineered life
- Cybernetic life
- Synthetic or artificial life
- Species with no Earth-equivalent taxonomy
- Entirely fictional evolutionary lineages

The system uses taxonomy as an organizational reference, but it must **not be dependent on Earth biology**.

The hierarchy is configurable through user-created nodes.

The module has one central principle:

> **The Classification Tree is the source of truth for taxonomic structure.**

The module has two primary areas:

```text
┌─────────────────────────────┬──────────────────────────────────────────────┐
│ LEFT PANEL                  │ RIGHT PANEL                                  │
│                             │                                              │
│ CLASSIFICATION TREE         │ WIKI-LIKE ARTICLE                            │
│                             │                                              │
│ - Navigation                │ - Reading                                    │
│ - Hierarchy                 │ - Writing                                    │
│ - Search                    │ - Lore                                       │
│ - Create                    │ - Classification summary                     │
│ - Select                    │ - Entity information                         │
│                             │                                              │
└─────────────────────────────┴──────────────────────────────────────────────┘
```

The left panel owns **classification and navigation**.

The right panel owns **content and entity information**.

There must not be a second hierarchy or duplicate navigator in the right panel.

---

# 2. Product Constraints

The implementation must follow these constraints.

## 2.1 Preserve the Existing Lore Keeper UI

Do not redesign the application.

Reuse the existing:

- Application shell
- Theme system
- Colors
- Typography
- Spacing
- Panels
- Tree patterns
- List patterns
- Buttons
- Dialogs
- Search controls
- Selection behavior
- Article/editor infrastructure where appropriate

The Species Module should feel native to Lore Keeper.

## 2.2 Keep the Theme System Independent

The Species Module must not introduce hardcoded visual styling that conflicts with the modular theme architecture.

Future community themes must automatically apply to the module through existing design tokens and theme mechanisms.

## 2.3 Keep Database Architecture Centralized

Hive initialization remains the responsibility of:

`DatabaseManager`

Do not:

- Register adapters inside widgets
- Open Hive boxes inside providers
- Restore old scattered initialization patterns
- Modify existing Hive type IDs
- Introduce destructive database recovery

Providers should consume already-open boxes.

## 2.4 Keep AI Independent From the UI

AI classification is a future capability.

The Species Module must be designed so AI can eventually produce the same draft classification structure as manual creation.

Do not implement LM Studio inference in the first Species cycle.

Do not call AI directly from widgets.

---

# 3. Classification Philosophy

Traditional Earth taxonomy is the primary conceptual reference:

```text
Category
    ↓
Lineage
    ↓
Kingdom
    ↓
Phylum
    ↓
Class
    ↓
Order
    ↓
Family
    ↓
Genus
    ↓
Species
    ↓
Subspecies (optional)
```

However, the names stored at each level are entirely user-defined.

The application does not assume:

- Eukarya
- Animalia
- Plantae
- Chordata
- Mammalia
- Homo

These are example classification values, not hardcoded data.

The user can create structures such as:

```text
FAUNA
└── Terran Life
    └── Animalia
        └── Chordata
            └── Mammalia
                └── Primates
                    └── Hominidae
                        └── Homo
                            └── Homo sapiens
                                ├── Homo sapiens cyberneticus
                                └── Homo sapiens excelsus
```

Or:

```text
FAUNA
└── Xylorian Life
    └── Lumina
        └── ...
```

Or:

```text
FAUNA
└── Synthetic Life
    └── Mechanica
        └── Synthetica
            └── Anthropomorpha
                └── Cognitiva
                    └── Archividae
                        └── In silico
                            └── Insilico sapiens
                                └── Insilico sapiens migratus
```

The application controls **hierarchical order and relationships**.

The user controls **classification names and content**.

---

# 4. Initial Project Structure

Every project must have two root nodes:

```text
FAUNA

FLORA
```

These are classification nodes with rank:

```text
category
```

No additional biological taxonomy is automatically seeded.

Do not automatically create:

```text
Terran Life
Animalia
Plantae
Eukarya
Chordata
```

The user builds the hierarchy.

## Root Creation Rules

For each project:

1. Check whether the Fauna root exists.
2. Check whether the Flora root exists.
3. Create only missing roots.
4. Never duplicate existing roots.
5. Roots belong to the current project only.

Project A:

```text
FAUNA
FLORA
```

Project B:

```text
FAUNA
FLORA
```

These are separate nodes with separate IDs.

No cross-project sharing occurs.

---

# 5. Classification Hierarchy

## 5.1 Rank Order

The initial hierarchy is:

| Level | Rank |
|---|---|
| 1 | Category |
| 2 | Lineage |
| 3 | Kingdom |
| 4 | Phylum |
| 5 | Class |
| 6 | Order |
| 7 | Family |
| 8 | Genus |
| 9 | Species |
| 10 | Subspecies |

Because `class` conflicts with Dart syntax, use an equivalent identifier such as:

```dart
classRank
```

The display label remains:

```text
Class
```

## 5.2 Valid Parent → Child Relationships

```text
Category
└── Lineage

Lineage
└── Kingdom

Kingdom
└── Phylum

Phylum
└── Class

Class
└── Order

Order
└── Family

Family
└── Genus

Genus
└── Species

Species
└── Subspecies
```

Subspecies is terminal in Cycle 1.

Invalid examples:

```text
Category
└── Genus
```

```text
Kingdom
└── Species
```

```text
Species
└── Family
```

The UI should guide valid creation paths.

The provider must enforce them.

---

# 6. Data Architecture

Do not create one model containing fields such as:

```text
lineage
kingdom
phylum
class
order
family
genus
species
```

Instead, use a generic hierarchical model.

## 6.1 Core Model

Conceptual model:

```text
ClassificationNode
```

Suggested fields:

```dart
id
projectId
parentId
rank
name
normalizedName
content
createdAt
updatedAt
```

Additional fields may be added only when required by existing application patterns.

## 6.2 Parent Relationship

Hierarchy is represented through:

```text
parentId
```

Example:

```text
Homo sapiens
parentId → Homo
```

```text
Homo
parentId → Hominidae
```

The complete classification path is reconstructed by traversing parent relationships.

## 6.3 Rank

Rank is a constrained enum or equivalent type:

```text
category
lineage
kingdom
phylum
classRank
order
family
genus
species
subspecies
```

## 6.4 Article Content

Every ClassificationNode should be capable of holding basic article content.

This avoids future migration if higher-level groups later receive full articles.

Cycle 1 UI priority:

- Species → full article experience
- Subspecies → full article experience
- Higher-level nodes → overview experience

Future:

Any classification node may become a richer wiki article.

---

# 7. Source of Truth

## 7.1 Classification

The Classification Tree is authoritative.

Do not duplicate classification fields inside the species article.

Do not store:

```text
Kingdom: Animalia
Phylum: Chordata
Class: Mammalia
```

as an independent copy that can drift away from the tree.

Instead:

```text
Selected Species
    ↓
parentId
    ↓
parent
    ↓
parent
    ↓
...
    ↓
Category
```

The breadcrumb/path is generated from the hierarchy.

## 7.2 Article

The selected ClassificationNode owns its own article/content.

Classification structure comes from parent relationships.

Article content comes from the node.

---

# 8. Uniqueness Rules

Node names are not globally unique.

This is valid:

```text
FAUNA
└── Terran Life
    └── Animalia
```

And:

```text
FLORA
└── Terran Life
    └── Animalia-like Flora
```

The same display name can exist in different branches.

The uniqueness scope is:

```text
projectId
+ parentId
+ rank
+ normalizedName
```

Conceptually:

```text
(projectId, parentId, rank, normalizedName)
```

represents a unique classification position.

## 8.1 Normalization

Matching must at minimum:

1. Trim leading whitespace.
2. Trim trailing whitespace.
3. Collapse repeated internal whitespace.
4. Convert to lowercase for comparison.

Example:

```text
Terran Life
terran life
TERRAN LIFE
  Terran    Life
```

all resolve to:

```text
terran life
```

The original user formatting can be preserved for a genuinely new node's display name.

---

# 9. Module Layout

The Species Module contains two primary panels.

```text
┌──────────────────────────────────────────────────────────────────────────┐
│ SPECIES MODULE                                                           │
├───────────────────────────────┬──────────────────────────────────────────┤
│ LEFT PANEL                    │ RIGHT PANEL                              │
│                               │                                          │
│ Species                       │ Selected Node Article                    │
│ [ Search ]          [ + New ] │                                          │
│                               │ Title                                    │
│ ▾ FAUNA                       │ Rank                                     │
│   ▾ Terran Life               │ Classification Breadcrumb                │
│     ▾ Animalia                │                                          │
│       ▾ Chordata              │ Article / Overview                       │
│         ▾ Mammalia            │                                          │
│           ▾ Primates          │                                          │
│             ▾ Hominidae       │                                          │
│               ▾ Homo          │                                          │
│                 ● sapiens     │                                          │
│                               │                                          │
│ ▸ FLORA                       │                                          │
│                               │                                          │
└───────────────────────────────┴──────────────────────────────────────────┘
```

---

# 10. LEFT PANEL

The left panel contains the entire classification tree.

## Header

Display:

```text
Species
```

Controls:

- Search
- + New

Do not create additional unnecessary left columns.

The tree must occupy the complete navigation area.

## Tree Capabilities

The tree must support:

- Expand
- Collapse
- Nested indentation
- Selected node state
- Appropriate icons
- Search
- Create
- Rename
- Delete
- Contextual actions consistent with existing Lore Keeper patterns

---

# 11. Tree Selection Flow

## Flow: Select a Node

```text
User clicks ClassificationNode
        ↓
Provider selection changes
        ↓
Selected node becomes authoritative selection
        ↓
Right panel receives selected node
        ↓
Resolve parent chain
        ↓
Build classification path
        ↓
Display node overview/article
```

There must not be competing selection state in:

- Tree widget
- Article widget
- Local dialog state
- Multiple providers

Follow existing Lore Keeper selection conventions.

---

# 12. Empty State Flow

## Flow: No Selection

```text
Species Module Opens
        ↓
No ClassificationNode selected
        ↓
Right Panel displays empty state
        ↓
"Select a species to view its article"
        ↓
Optional action:
"Create a new species"
```

The empty state must visually match existing Lore Keeper patterns.

---

# 13. Search Flow

Search belongs to the left panel.

## Search Scope

Search only the active project's classification nodes.

At minimum search:

```text
name
```

## Flow

```text
User enters query
        ↓
Normalize query
        ↓
Search current project's nodes
        ↓
Return matching nodes
        ↓
Expose matching hierarchy/navigation
        ↓
User selects result
        ↓
Tree selection changes
        ↓
Right panel updates
```

Do not build a second global search system.

Reuse existing search components and patterns where possible.

---

# 14. + New Flow

Clicking:

```text
+ New
```

opens a creation choice.

Cycle 1:

```text
Create Species
└── Create Manually
```

The architecture should allow future options:

```text
+ New
├── Create Manually
├── Ask AI                  [Future]
├── Import                  [Future]
└── Create from Template    [Future]
```

Only manual creation is implemented now.

---

# 15. Manual Creation — Complete Flow

The manual creation system is a cascading draft-path builder.

It does not immediately write to the database.

## Step 1: Select Category

The user selects:

```text
Fauna
```

or:

```text
Flora
```

The category root is selected from the current project.

## Step 2: Build Classification Path

The form presents:

```text
Category
Lineage
Kingdom
Phylum
Class
Order
Family
Genus
Species
Subspecies (optional)
```

Each field depends on the parent selected above it.

## Example

```text
Category:
Fauna

Lineage:
Terran Life

Kingdom:
Animalia

Phylum:
Chordata

Class:
Mammalia

Order:
Primates

Family:
Hominidae

Genus:
Homo

Species:
Homo sapiens

Subspecies:
Homo sapiens cyberneticus
```

---

# 16. Cascading Selector Rules

Each classification field is a searchable **select-or-create** control.

Do not implement:

```text
Dropdown
+
Separate Create Button
```

for every field.

Create a reusable component conceptually named:

```text
ClassificationSelector
```

The component receives:

- Current rank
- Parent node
- Existing valid children
- Current selection
- Draft value
- Callback for selection/proposal

## Selector Behavior

### Existing Value

```text
User types: Homo
        ↓
Existing Homo found
        ↓
Show Homo
        ↓
User selects Homo
```

### New Value

```text
User types: Xylorian
        ↓
No matching valid child
        ↓
Show:
+ Create "Xylorian"
        ↓
User selects proposal
        ↓
Store in in-memory draft only
```

No Hive mutation occurs while typing.

---

# 17. Cascading Data Flow

Each selector only displays valid children of the selected parent.

Example:

```text
Category = Fauna
        ↓
Lineage options =
children(Fauna, rank: lineage)
```

After:

```text
Lineage = Terran Life
```

then:

```text
Kingdom options =
children(Terran Life, rank: kingdom)
```

After:

```text
Kingdom = Animalia
```

then:

```text
Phylum options =
children(Animalia, rank: phylum)
```

This continues through the entire hierarchy.

---

# 18. Cascade Reset Rules

Changing a higher-level value invalidates all values below it.

## Flow: Change Lineage

Before:

```text
Fauna
Terran Life
Animalia
Chordata
Mammalia
Primates
Hominidae
Homo
Homo sapiens
```

User changes:

```text
Terran Life
```

to:

```text
Xylorian Life
```

Result:

```text
Category = Fauna
Lineage = Xylorian Life

Kingdom = cleared
Phylum = cleared
Class = cleared
Order = cleared
Family = cleared
Genus = cleared
Species = cleared
Subspecies = cleared
```

## General Rule

Changing:

```text
Rank N
```

clears:

```text
Rank N + 1
through
Subspecies
```

Examples:

Changing Kingdom clears:

- Phylum
- Class
- Order
- Family
- Genus
- Species
- Subspecies

Changing Genus clears:

- Species
- Subspecies

Changing Species clears:

- Subspecies

Mixed paths are never allowed.

---

# 19. Subspecies Flow

Subspecies is optional.

The user may:

1. Leave it empty.
2. Select an existing subspecies.
3. Propose a new subspecies.

Subspecies options are only children of the selected Species.

Example:

```text
Homo sapiens
├── Homo sapiens cyberneticus
└── Homo sapiens excelsus
```

If:

```text
Species = Homo sapiens
```

then the Subspecies selector only searches those direct children.

Subspecies is terminal in Cycle 1.

---

# 20. Draft Classification Path

The creation form builds an in-memory draft.

Conceptual structure:

```text
ClassificationDraft
```

It contains one entry for each rank:

```text
category
lineage
kingdom
phylum
class
order
family
genus
species
subspecies
```

Each entry represents either:

```text
ExistingNodeReference
```

or:

```text
ProposedNewNode
```

Example:

```text
✓ Fauna                       Existing

+ Terran Life                 New
  + Animalia                  New
    + Chordata                New
      + Mammalia              New
        + Primates            New
          + Hominidae         New
            + Homo            New
              + Homo sapiens  New
```

---

# 21. Review and Confirmation Flow

Before database mutation, resolve the draft.

## Flow

```text
User completes classification form
        ↓
Validate hierarchy
        ↓
Validate required Species value
        ↓
Resolve existing nodes
        ↓
Resolve proposed nodes
        ↓
Detect duplicates
        ↓
Build final creation plan
        ↓
Display review if consistent with current UI
        ↓
User confirms
        ↓
Persist path
        ↓
Select final node
        ↓
Open article
```

The user must not accidentally create a hierarchy merely by typing into fields.

---

# 22. Path Resolution

A provider-level operation should conceptually perform:

```text
resolvePath()
```

Responsibilities:

- Validate rank sequence
- Validate parent relationships
- Find existing nodes
- Normalize names
- Detect duplicates
- Identify proposed nodes
- Produce a resolved creation plan

The UI does not directly perform Hive writes.

---

# 23. Path Creation

A provider-level operation should conceptually perform:

```text
createClassificationPath()
```

## Required Sequence

```text
Validate complete draft
        ↓
Re-check duplicate state
        ↓
Reuse existing Category
        ↓
Reuse or create Lineage
        ↓
Reuse or create Kingdom
        ↓
Reuse or create Phylum
        ↓
Reuse or create Class
        ↓
Reuse or create Order
        ↓
Reuse or create Family
        ↓
Reuse or create Genus
        ↓
Reuse or create Species
        ↓
Optionally reuse or create Subspecies
        ↓
Return final node
        ↓
Select final node
```

Creation occurs from parent to child.

The operation must never create:

```text
Homo sapiens
```

without a valid:

```text
Homo
```

parent.

---

# 24. Duplicate Prevention

Before creating every proposed node:

```text
Find existing child where:

projectId == activeProject
parentId == currentParent
rank == expectedRank
normalizedName == proposed.normalizedName
```

If found:

```text
Reuse existing node.
```

If not found:

```text
Create node.
```

This re-check is required even after initial draft resolution to prevent accidental duplication.

---

# 25. Partial Failure Safety

The path creation operation should be controlled by the provider.

Before persistence:

- Validate the entire draft as much as possible.
- Resolve all existing nodes.
- Identify all required writes.

During persistence:

- Create nodes in parent-to-child order.
- Track created nodes.
- Do not leave selection pointing to an incomplete node.

If an error occurs:

- Surface the error.
- Do not delete Hive boxes.
- Do not use destructive recovery.

Where practical, use the existing persistence capabilities to minimize partial hierarchy corruption.

---

# 26. Right Panel — Wiki Article

The right panel is a wiki-like content view.

It is not a duplicate taxonomy form.

For a selected Species:

```text
HOMO SAPIENS

Species

Classification:

Fauna
› Terran Life
› Animalia
› Chordata
› Mammalia
› Primates
› Hominidae
› Homo
› Homo sapiens

────────────────────────────────

Overview

[Article content]

────────────────────────────────

Lore

[Article content]
```

The exact visual implementation should reuse existing Lore Keeper editor/article patterns.

---

# 27. Species Article Flow

```text
User selects Species
        ↓
Resolve selected node
        ↓
Resolve rank
        ↓
Traverse parent chain
        ↓
Build classification breadcrumb
        ↓
Load node content
        ↓
Render Species article
```

Minimum Cycle 1 content:

- Name
- Rank
- Classification summary
- Overview / Description
- Lore / article body

Do not prematurely build:

- Diet
- Lifespan
- Anatomy
- Reproduction
- Genetics
- Abilities
- Weaknesses

Those can later become article sections, templates, or structured custom fields.

---

# 28. Higher-Level Node Flow

The user can select any node.

Example:

```text
Mammalia
```

The right panel must not crash.

Display:

```text
MAMMALIA

Classification Group

Path:

Fauna › Terran Life › Animalia › Chordata › Mammalia

Children:

- Primates
- Carnivora
- ...
```

If article content exists, display it.

Higher-level nodes can have basic content now and richer content later.

---

# 29. Classification Breadcrumb Resolution

Classification must be derived dynamically.

Conceptual algorithm:

```text
current = selectedNode

while current exists:
    add current to path
    current = parent(current.parentId)

reverse path
```

Example result:

```text
Fauna
→ Terran Life
→ Animalia
→ Chordata
→ Mammalia
→ Primates
→ Hominidae
→ Homo
→ Homo sapiens
```

No duplicate taxonomy fields are stored inside the Species article.

---

# 30. Rename Flow

```text
User chooses Rename
        ↓
Enter new name
        ↓
Normalize name
        ↓
Check sibling duplicate:
(projectId + parentId + rank + normalizedName)
        ↓
If duplicate:
    Reject or reuse according to UI flow
        ↓
If valid:
    Update display name
    Update normalizedName
    Update updatedAt
        ↓
Refresh tree
        ↓
Refresh article path
```

Renaming preserves:

- ID
- Parent
- Children
- Article content

---

# 31. Delete Flow

Deletion is potentially destructive.

## Leaf Node

```text
User selects Delete
        ↓
Check children
        ↓
No children
        ↓
Confirm
        ↓
Delete node
        ↓
Clear/update selection
```

## Node With Descendants

```text
User selects Delete
        ↓
Children exist
        ↓
Display warning
        ↓
Explain affected descendants
        ↓
Require explicit confirmation
```

Do not silently delete an entire branch.

Do not delete database boxes.

The final cascade behavior should follow the safest pattern compatible with existing Lore Keeper tree modules.

---

# 32. Provider Responsibilities

Create a dedicated provider following repository conventions.

Possible naming:

```text
SpeciesProvider
```

or:

```text
ClassificationProvider
```

Choose the name that best fits the existing codebase.

Responsibilities:

- Project-scoped loading
- Root initialization
- Retrieve roots
- Retrieve children
- Search nodes
- Find nodes
- Normalize names
- Validate rank transitions
- Create nodes
- Rename nodes
- Delete nodes
- Resolve classification drafts
- Create classification paths
- Prevent duplicates
- Manage selected node if consistent with application architecture
- Notify listeners after meaningful state changes

The provider must not own:

- Dialog rendering
- Widget layout
- AI prompts
- Theme styling

---

# 33. Database Integration

The Species Module integrates with the existing database foundation.

Before implementation:

1. Inspect all existing Hive adapters.
2. Find the next safe unused Hive type ID.
3. Register the new adapter in `DatabaseManager`.
4. Open required boxes through centralized initialization.
5. Add migration only if required by the established schema/version process.

Do not change:

- Existing type IDs
- Existing adapter definitions unnecessarily
- Existing migration history

The provider should use:

```text
Hive.box()
```

for already-open boxes.

---

# 34. Project Isolation Flow

Every query must respect the active project.

## Loading

```text
Provider receives projectId
        ↓
Load nodes where:

node.projectId == projectId
```

## Search

```text
Search query
        +
projectId filter
```

## Root Initialization

```text
Ensure Fauna exists for project
Ensure Flora exists for project
```

## Creation

Every new node receives:

```text
projectId = activeProjectId
```

Data from Project A must never appear in Project B.

---

# 35. Reference Engine Compatibility

The module must not create a parallel entity-reference architecture.

Species entities should be compatible with:

```text
EntityRef
ReferenceEngine
ReferenceIndexEntry
```

Future relationships may include:

```text
Character
    → Species

Species
    → Location

Species
    → Event

Species
    → Manuscript

Species
    → Organization

Species
    → Other Species
```

Cycle 1 does not need to fully implement all cross-module references.

The architecture must simply avoid blocking them.

---

# 36. Future AI Classification

AI is not implemented in Cycle 1.

However, manual creation establishes the exact contract AI should eventually produce.

Future flow:

```text
User clicks + New
        ↓
Ask AI
        ↓
User enters:
"Humans"
        ↓
AI proposes:
Category: Fauna
Lineage: Terran Life
Kingdom: Animalia
Phylum: Chordata
Class: Mammalia
Order: Primates
Family: Hominidae
Genus: Homo
Species: Homo sapiens
        ↓
Create ClassificationDraft
        ↓
User reviews
        ↓
Existing nodes reused
        ↓
Missing nodes proposed
        ↓
User confirms
        ↓
Same createClassificationPath()
        ↓
Species created
```

Manual and AI creation must converge into the same:

```text
ClassificationDraft
```

and:

```text
createClassificationPath()
```

pipeline.

AI must never directly mutate Hive data.

The existing `AiProvider` architecture remains the integration boundary.

Future LM Studio integration belongs behind the AI provider contract.

---

# 37. Future Expansion Possibilities

These are explicitly outside Cycle 1 but should remain possible.

## Structured Species Data

Future sections:

- Appearance
- Biology
- Anatomy
- Habitat
- Diet
- Lifespan
- Reproduction
- Culture
- Abilities
- Weaknesses
- Evolution

## Custom Classification Templates

Future worlds may use different hierarchy systems.

Potential future concept:

```text
ClassificationSchema
```

which could allow:

```text
Category
Lineage
Kingdom
...
```

or custom systems.

Do not implement this abstraction unless needed now.

Cycle 1 uses the agreed hierarchy.

## AI Classification

Local AI via:

```text
AiProvider
→ LM Studio
→ Local Model
```

should eventually:

- Interpret natural-language species descriptions.
- Suggest classification.
- Search existing hierarchy.
- Reuse matching nodes.
- Propose missing nodes.
- Ask for clarification where required.

## Relationships

Future Reference Engine integration can connect:

```text
Species ↔ Character
Species ↔ Location
Species ↔ Timeline Event
Species ↔ Manuscript
Species ↔ Organization
```

---

# 38. Implementation Boundaries

Do not unnecessarily modify:

- Calendar system
- Timeline system
- Magic system
- Theme system
- ReferenceEngine core
- AI provider contracts
- Existing migrations
- Existing Hive type IDs
- Existing unrelated modules

Only modify files required for:

- New model
- Adapter registration
- Database initialization
- Provider
- Module
- Widgets
- Routing/tab integration if needed
- Tests

---

# 39. Required Tests

## Root Tests

```text
[ ] Fauna root is created.
[ ] Flora root is created.
[ ] Repeated initialization does not duplicate roots.
[ ] Roots are isolated by project.
```

## Hierarchy Tests

```text
[ ] Category → Lineage is valid.
[ ] Lineage → Kingdom is valid.
[ ] Invalid parent-child transitions are rejected.
[ ] Children belong to the correct parent.
[ ] Subspecies cannot have children in Cycle 1.
```

## Duplicate Tests

```text
[ ] Same sibling + same rank + same normalized name is reused/rejected.
[ ] Same name under a different parent is allowed.
[ ] Same name in another project is allowed.
```

## Normalization Tests

```text
[ ] Case differences resolve to the same normalized name.
[ ] Leading/trailing spaces are ignored.
[ ] Repeated whitespace is collapsed.
```

## Path Creation Tests

```text
[ ] Complete new path creates nodes in correct order.
[ ] Existing nodes are reused.
[ ] Mixed existing/new path works.
[ ] Duplicate nodes are not created.
[ ] Final Species is returned.
[ ] Optional Subspecies is handled correctly.
```

## Cascade Tests

```text
[ ] Changing Lineage clears all lower ranks.
[ ] Changing Kingdom clears lower ranks.
[ ] Changing Genus clears Species and Subspecies.
[ ] Changing Species clears Subspecies.
```

## Project Isolation Tests

```text
[ ] Project A nodes do not appear in Project B.
[ ] Search is project-scoped.
```

## Article Path Tests

```text
[ ] Species breadcrumb resolves correctly.
[ ] Higher-level breadcrumb resolves correctly.
[ ] Missing parent does not crash the UI/provider.
```

---

# 40. Acceptance Criteria

Before the Species Module cycle is considered complete:

## Module

```text
[ ] Species Module opens correctly.
[ ] Existing application UI remains visually consistent.
[ ] There is only one classification/navigation tree.
[ ] The right panel contains article/overview content.
```

## Roots

```text
[ ] Fauna exists.
[ ] Flora exists.
[ ] Roots do not duplicate after restart.
```

## Manual Creation

```text
[ ] + New opens manual creation.
[ ] User can choose Fauna or Flora.
[ ] Lineage only shows children of the selected category.
[ ] Every lower rank filters by selected parent.
[ ] Existing nodes can be searched and selected.
[ ] Missing values can be proposed.
[ ] Typing does not immediately persist nodes.
[ ] Parent changes clear dependent values.
[ ] Subspecies is optional.
```

## Persistence

```text
[ ] Existing nodes are reused.
[ ] Missing nodes are created only after confirmation.
[ ] Duplicate sibling nodes are prevented.
[ ] Nodes are project-scoped.
[ ] Hive initialization remains centralized.
```

## Article

```text
[ ] Selected Species displays its article.
[ ] Classification path is derived from the tree.
[ ] Higher-level node selection does not crash.
[ ] Empty selection has a valid empty state.
```

## Validation

```text
[ ] flutter analyze
[ ] flutter test
[ ] flutter run -d windows
```

Any pre-existing failures must be reported separately from Species Module regressions.

---

# 41. Final Architecture Summary

```text
PROJECT
│
├── SPECIES MODULE
│
├── ClassificationProvider
│
├── ClassificationNode Hive Box
│
├── ROOTS
│   ├── FAUNA
│   └── FLORA
│
├── CLASSIFICATION TREE
│   │
│   └── Category
│       └── Lineage
│           └── Kingdom
│               └── Phylum
│                   └── Class
│                       └── Order
│                           └── Family
│                               └── Genus
│                                   └── Species
│                                       └── Subspecies
│
├── LEFT PANEL
│   ├── Search
│   ├── + New
│   ├── Expand / Collapse
│   ├── Select
│   ├── Rename
│   └── Delete
│
├── MANUAL CREATION
│   │
│   ├── Category Selection
│   ├── Cascading Select-or-Create Controls
│   ├── ClassificationDraft
│   ├── Path Resolution
│   ├── Review
│   └── createClassificationPath()
│
├── RIGHT PANEL
│   ├── Node Title
│   ├── Rank
│   ├── Classification Breadcrumb
│   ├── Overview
│   └── Lore / Article Content
│
└── FUTURE
    ├── Ask AI
    ├── LM Studio
    ├── AI Classification
    ├── Structured Biology
    ├── Reference Engine Connections
    └── Rich Species Relationships
```

---

# 42. Core Implementation Principle

The entire Species Module revolves around one controlled pipeline:

```text
USER ACTION
    ↓
CLASSIFICATION DRAFT
    ↓
VALIDATE
    ↓
RESOLVE EXISTING NODES
    ↓
IDENTIFY PROPOSED NODES
    ↓
CONFIRM
    ↓
CREATE ONLY MISSING NODES
    ↓
REUSE EXISTING NODES
    ↓
RETURN FINAL SPECIES / SUBSPECIES
    ↓
SELECT NODE
    ↓
DISPLAY WIKI ARTICLE
```

This pipeline must be shared by future creation methods.

Manual creation:

```text
Manual Form
    ↓
ClassificationDraft
    ↓
Shared Creation Pipeline
```

Future AI:

```text
AI Provider
    ↓
ClassificationDraft
    ↓
Shared Creation Pipeline
```

Import:

```text
Importer
    ↓
ClassificationDraft
    ↓
Shared Creation Pipeline
```

This prevents multiple competing implementations of species creation.

---

# 43. Final Product Definition

Lore Keeper's Species Module is not simply a database of animals or plants.

It is a flexible worldbuilding classification system.

It allows the user to begin with:

```text
Fauna
```

and construct:

```text
Terran Life
→ Animalia
→ Chordata
→ Mammalia
→ Primates
→ Hominidae
→ Homo
→ Homo sapiens
```

Or begin with:

```text
Fauna
```

and construct an entirely fictional lineage:

```text
Xylorian Life
→ Lumina
→ ...
```

The system enforces the structure of the hierarchy while allowing the worldbuilder to define the life within it.

The left side is the world's classification map.

The right side is the world's encyclopedia.

The manual form constructs a proposed path.

The provider resolves and validates that path.

The database stores the hierarchy.

The tree remains the source of truth.

The article explains the selected entity.

Future AI produces the same draft structure as the human user.

That is the foundational architecture for the Lore Keeper Species Module.
