# Lore Keeper — Foundational Architecture Contract

**Status:** Foundational specification  
**Priority:** P0  
**Applies to:** Entire application  
**Implementation rule:** This document is a contract for all future vibe-coding sessions.

---

## 1. Purpose

Lore Keeper is a local-first worldbuilding application. The application must be able to grow into a large interconnected workspace containing manuscripts, characters, locations, calendars, timelines, arcs, maps, relationships, research, assets and Chronicles without allowing individual modules to invent incompatible architecture.

This foundation establishes two boundaries:

1. **The existing UI/UX is preserved.** Architecture work must not become an excuse to redesign working screens.
2. **Presentation and persistence are replaceable systems.** UI components consume application contracts; they do not own database logic or hard-coded visual styling.

The current interface is the visual baseline. Future work improves capability, correctness, performance and maintainability while preserving the established interaction model unless a module specification explicitly authorizes a UI change.

---

## 2. Core Principles

### 2.1 Current UI is a contract

Do not redesign existing screens during foundational work.

Preserve:

- navigation structure
- current module placement
- existing interaction patterns
- established spacing and visual hierarchy
- existing workflows unless explicitly superseded by a module specification

New architecture must fit underneath the current UI.

### 2.2 Data is authoritative; UI is not

Widgets must never become the source of truth for application data.

```text
UI
 ↓
Controller / Provider
 ↓
Use Case / Application Logic
 ↓
Repository
 ↓
Persistence
```

### 2.3 Modules must not own the database

A module may define domain models and repository contracts, but widgets and UI providers must not directly manipulate Hive boxes.

Bad:

```text
TimelineModule → Hive.box('timeline_events')
```

Good:

```text
TimelineModule
 → TimelineController
 → TimelineRepository
 → HiveTimelineRepository
 → Hive
```

### 2.4 Themes must not own application logic

Themes describe presentation only. No domain rule, repository or feature decision may depend on a particular color, font or theme name.

### 2.5 Local-first remains the default

The application must remain fully useful without an internet connection. Persistence must be deterministic and resilient on the local device.

### 2.6 Prefer migration over destructive recovery

Schema changes must migrate existing data whenever reasonably possible. Never delete user data merely because a schema or adapter mismatch is encountered.

### 2.7 Everything that can connect should be connectable

Lore Keeper's defining product principle is interconnected worldbuilding. Characters, locations, factions, scenes, events, maps, manuscripts and other entities should eventually be addressable through a common reference system.

---

# 3. Application Architecture

The target architecture is:

```text
┌─────────────────────────────────────────────────────────────┐
│                         PRESENTATION                         │
│                                                             │
│  Existing Screens • Modules • Widgets • Editors • Panels   │
│                                                             │
│                    Theme Contract                          │
└──────────────────────────────┬──────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────┐
│                     APPLICATION LAYER                       │
│                                                             │
│ Controllers • Providers • Commands • Use Cases • Queries   │
└──────────────────────────────┬──────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────┐
│                        DOMAIN LAYER                          │
│                                                             │
│ Entities • Value Objects • Temporal Model • EntityRefs     │
│ Relationships • Validation Rules                            │
└──────────────────────────────┬──────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────┐
│                       REPOSITORY LAYER                       │
│                                                             │
│ Project • Character • Calendar • Timeline • Manuscript ... │
└──────────────────────────────┬──────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────┐
│                     PERSISTENCE LAYER                        │
│                                                             │
│ DatabaseManager • Hive Repositories • Migrations • Indexes│
└─────────────────────────────────────────────────────────────┘
```

The boundaries are logical first. Do not create unnecessary abstractions merely for ceremony; each boundary must solve a real coupling problem.

---

# 4. Persistence Foundation

## 4.1 Hive remains the initial storage engine

Do **not** replace Hive as part of this foundation unless a concrete limitation requires it.

The current problem is not that Hive cannot store Lore Keeper data. The problem is that persistence responsibilities are currently distributed across `main.dart`, providers and modules.

Hive becomes an implementation detail behind repositories.

## 4.2 DatabaseManager

Create a central database service responsible for:

- Hive initialization
- adapter registration
- opening required boxes
- database version detection
- migrations
- graceful shutdown/close
- diagnostics
- corruption/recovery handling

`main.dart` should initialize the database service rather than manually owning the complete database lifecycle.

## 4.3 Repository layer

Every major persisted domain should have a repository contract.

Initial targets:

```text
ProjectRepository
CharacterRepository
LocationRepository
CalendarRepository
TimelineRepository
ManuscriptRepository
ArcRepository
RelationshipRepository
MapRepository
AssetRepository
SearchRepository / IndexService
```

Repositories expose domain operations, not Hive implementation details.

Example:

```dart
abstract class TimelineRepository {
  Future<TimelineEvent?> getById(String id);
  Future<List<TimelineEvent>> listByProject(int projectId);
  Future<void> save(TimelineEvent event);
  Future<void> delete(String id);
}
```

The exact APIs should be designed when each domain is implemented.

## 4.4 Project ownership

Every project-owned entity must have an unambiguous project relationship.

Do not rely on UI filtering to establish ownership.

Where a child is structurally owned by another entity, the ownership chain must be explicit and validated.

Example:

```text
Project
 └── CalendarSystem
      └── CalendarNode
```

`CalendarNode` may derive project ownership through its calendar system, but repository queries must still enforce the project boundary.

## 4.5 No redundant box initialization

Boxes should be opened by the database layer once. Providers must obtain repositories/services instead of independently calling `Hive.openBox`.

---

# 5. Schema and Migration Foundation

## 5.1 Database version

Introduce an application database schema version independent of Hive adapter type IDs.

```text
Database schema version
        ↓
Migration runner
        ↓
Current schema
```

Hive `typeId` identifies serialization adapters. It is **not** the application's migration/version system.

## 5.2 Migrations

Migrations must be:

- ordered
- deterministic
- idempotent where practical
- testable
- logged
- non-destructive by default

Example:

```text
v1 → v2
v2 → v3
v3 → v4
```

A fresh installation may initialize directly at the current schema while an existing installation executes the required migration chain.

## 5.3 Destructive operations

Never automatically execute operations such as:

```dart
Hive.deleteBoxFromDisk(...)
```

as a generic response to schema errors.

Recovery must first attempt:

1. migration
2. compatibility handling
3. backup/recovery path
4. explicit user-approved destructive reset

---

# 6. Entity Identity

Lore Keeper needs stable identities independent of Hive box keys.

Every major entity should have a stable application-level ID.

```text
Project
Character
Location
Faction
Manuscript
Scene
Calendar
CalendarNode
TimelineEvent
Map
Arc
Relationship
Asset
```

Hive keys may be implementation details. They must not become the semantic identity used by cross-module links.

---

# 7. Entity Reference System

Create a common reference concept for cross-module connections.

Conceptually:

```text
EntityRef
├── id
├── entityType
└── projectId
```

Examples:

```text
Character → TimelineEvent
Character → Scene
Location → TimelineEvent
Location → MapPin
Faction → Relationship
Scene → Arc
Event → Chronicle
```

The exact serialized representation will be defined in the Entity Reference specification.

## 7.1 Rules

- References must remain stable when UI structure changes.
- References must be project-scoped.
- Deletion must account for incoming references.
- Broken references must be detectable.
- The UI should eventually be able to show backlinks.

This system is the foundation for Search, Lore Map and Chronicles.

---

# 8. Deletion and Archiving

Important entities should support soft deletion/archive where appropriate.

Preferred lifecycle:

```text
Active
  ↓
Archived
  ↓
Permanently Deleted
```

Before permanent deletion, the system should be able to identify dependent references.

Example:

```text
Delete Character
       ↓
References found
       ↓
14 scenes
8 timeline events
3 relationships
2 map references
       ↓
User chooses action
```

Never silently leave known orphaned references.

---

# 9. Revision and Change Tracking

Important domain objects should support:

```text
createdAt
updatedAt
revision
```

Revision numbers should increase when persisted content changes.

This is groundwork for:

- undo/history
- change detection
- migrations
- future sync
- conflict detection

Full event sourcing is **not** required.

---

# 10. Caching and Derived Data

Persisted data and calculated runtime data must be distinguished.

Example:

```text
Persisted Calendar Definition
          ↓
Calendar Temporal Definition
          ↓
Cached Chronology / Indexes
```

Derived caches may be invalidated whenever source data changes.

Do not persist derived values merely to avoid inexpensive calculations unless there is a demonstrated performance reason.

This is particularly important for Calendar and Timeline.

---

# 11. Theme Foundation

The current UI remains unchanged. The theme system becomes modular underneath it.

## 11.1 Theme goals

Themes must allow future community-created visual styles without requiring module rewrites.

Initial theme contract focuses on:

- colors
- typography / font style
- light/dark variants
- theme metadata

Later versions may expose:

- spacing
- component density
- shapes
- elevation
- icon style

Do not over-engineer these additional tokens until needed.

## 11.2 Semantic tokens

Widgets should consume semantic tokens rather than hard-coded values.

Preferred:

```dart
context.lkTheme.colors.surface
context.lkTheme.colors.primary
context.lkTheme.colors.textPrimary
context.lkTheme.typography.heading
context.lkTheme.typography.body
```

Avoid:

```dart
Color(0xFF123456)
GoogleFonts.SomeFont(...)
```

inside feature widgets.

## 11.3 ThemeDefinition

Conceptually:

```text
ThemeDefinition
├── id
├── name
├── author
├── version
├── description
├── brightness
├── colors
└── typography
```

The selected theme is a configuration choice, not a dependency of application logic.

## 11.4 Theme registry

Themes should eventually be discoverable through a registry:

```text
ThemeRegistry
├── Built-in Lore Keeper
├── Community Theme A
├── Community Theme B
└── User Theme
```

Community theme loading/import is a later feature. The architecture should not make it impossible.

## 11.5 Theme safety

A theme may change presentation but must never:

- alter data
- change domain rules
- change repository behavior
- modify calendar calculations
- change sorting semantics
- change entity identity

---

# 12. UI Preservation Rules

These rules apply to every future AI/vibe-coding session.

### Allowed

- Refactor internals without changing visible behavior.
- Replace direct Hive access with repositories.
- Route existing colors/fonts through theme tokens.
- Improve performance.
- Fix data integrity bugs.
- Add explicitly specified functionality.
- Add tests.

### Not allowed without explicit module approval

- Redesigning the module.
- Changing navigation.
- Replacing the established UI metaphor.
- Introducing a new design system unrelated to the existing one.
- Hard-coding a new visual style.
- Removing existing functionality merely because a new architecture is cleaner.

If a UI change is required by a new capability, document the reason in the module specification before implementing it.

---

# 13. Module Contract

Every module specification must define:

```text
Purpose
Data model
Repository requirements
Controllers/providers
UI surfaces
Interactions
Validation
Persistence
Entity references
Dependencies
Theme usage
Acceptance criteria
Non-goals
```

A module must consume shared infrastructure rather than create competing versions of it.

---

# 14. Calendar + Timeline Special Rule

Calendar and Timeline are the first major consumers of this foundation because their current architecture has a critical data-integrity problem.

The future design must establish:

```text
Calendar Definition
       ↓
Temporal Engine
       ↓
Universal Temporal Coordinate
       ↓
Timeline Event
```

A change to a calendar definition must never silently change the historical meaning of existing events.

Calendar versioning, temporal validation, migration and cross-calendar semantics are therefore part of the Calendar/Timeline implementation rather than optional enhancements.

---

# 15. Testing Requirements

Foundational infrastructure requires tests before large module implementation begins.

Minimum coverage areas:

### Persistence

- initialization
- repository CRUD
- project isolation
- schema migration
- adapter registration
- recovery behavior

### Identity

- stable IDs
- duplicate handling
- reference validation

### Relationships

- create reference
- remove reference
- detect broken reference
- deletion impact analysis

### Theme

- default theme loads
- theme switching
- semantic tokens resolve
- invalid theme fallback
- theme does not alter domain behavior

### Calendar/Timeline

- chronology construction
- date validation
- calendar changes
- temporal conversion
- cross-calendar behavior

---

# 16. Implementation Order

Do not begin broad module vibe-coding until the following sequence is complete:

```text
P0.1  DatabaseManager
P0.2  Repository conventions
P0.3  Schema version + migration runner
P0.4  Stable entity identity rules
P0.5  EntityRef foundation
P0.6  Theme contract
P0.7  Migrate existing infrastructure without UI redesign
P0.8  Tests + diagnostics

        ↓

P1. Calendar / Temporal Engine
P1. Timeline

        ↓

P2. Search / Linking / Backlinks
P2. Characters / Locations / Factions

        ↓

P3. Manuscripts
P3. Arcs
P3. Relationships

        ↓

P4. Maps
P4. Lore Map
P4. Chronicles
```

The exact module order may change as implementation reveals dependencies, but foundational persistence and presentation contracts must remain stable.

---

# 17. Definition of Done for the Foundation

The foundation is complete when:

- [ ] Hive initialization is centralized.
- [ ] Providers/modules no longer directly open boxes.
- [ ] Repository boundaries exist for migrated domains.
- [ ] Database schema versioning exists.
- [ ] Migration runner exists and is tested.
- [ ] Destructive automatic database recovery has been removed.
- [ ] Stable application IDs are established.
- [ ] Project ownership rules are enforced.
- [ ] EntityRef foundation exists.
- [ ] Referential integrity rules exist.
- [ ] Archive/delete behavior is defined.
- [ ] Revision metadata strategy exists.
- [ ] ThemeDefinition exists.
- [ ] Semantic color tokens exist.
- [ ] Semantic typography tokens exist.
- [ ] Existing UI consumes the theme contract without visual redesign.
- [ ] Theme switching works without module-specific code changes.
- [ ] Foundation tests pass.

---

# 18. Vibe-Coding Instruction

When implementing any future Lore Keeper module, the coding agent must treat this document and the module's own specification as authoritative.

The agent must:

1. Inspect the existing implementation before changing it.
2. Preserve the current UI unless the module specification explicitly says otherwise.
3. Reuse existing infrastructure before introducing a new abstraction.
4. Never access Hive directly from widgets.
5. Never create a second theme system.
6. Never introduce hard-coded feature-specific colors/fonts when semantic theme tokens exist.
7. Never delete persisted user data as a schema shortcut.
8. Never invent a competing entity-linking mechanism.
9. Add tests for architectural behavior it changes.
10. Keep the implementation scoped to the requested module/foundation phase.

If the existing code conflicts with this contract, the agent must identify the conflict and resolve the architecture deliberately rather than silently creating another pattern.

---

# Final Architecture Principle

**Lore Keeper should feel like the same application regardless of how its internals evolve.**

The user-facing workspace stays familiar.

The data layer becomes reliable and interconnected.

The theme layer becomes replaceable.

The modules become progressively richer without becoming isolated applications.

```text
                    SAME LORE KEEPER EXPERIENCE
                               │
              ┌────────────────┴────────────────┐
              │                                 │
        Replaceable UI Theme             Stable Domain Data
              │                                 │
      Colors + Typography                 Repositories
              │                                 │
      Community Themes                    Entity Graph
                                                │
                                      Calendar + Timeline
                                                │
                                           Chronicles
```

This is the foundation on which the remaining module specifications should be implemented.