# Lore Keeper — Master Architecture, Product & UX Plan

**Status:** Proposed implementation roadmap  
**Date:** 2026-08-20  
**Repository:** `R3-b0ot/lore_keeper`  
**Primary stack:** Flutter / Dart / Hive / ChangeNotifier  
**Scope:** Application architecture, information architecture, data model, Calendar + Timeline foundation, module evolution, UX system, connectivity, Maps, Manuscripts, Characters, Arcs and future Chronicles

---

## 0. Executive Decision

Lore Keeper should not be rebuilt as a collection of independent modules. It should evolve into a **local-first, interconnected worldbuilding workspace** where every important piece of lore can participate in multiple contexts without forcing the user into rigid forms.

The product direction is:

> **Campfire's breadth + LegendKeeper's simplicity/connectivity + Scrivener's writing workflow + Plottr's story planning + Aeon Timeline's temporal canvas + Inkarnate's map interaction + Obsidian's linking philosophy + World Anvil Chronicles' space/time history model.**

These products are references, not templates to copy. Lore Keeper should take the strongest interaction patterns from each and build a coherent desktop-first experience around its own identity.

The existing repository already points in this direction. The overhaul documentation explicitly consolidates the project shell into **Overview, Manuscripts, Characters, World Building and Lore Map**, with the former long list of modules moved into World Building. The roadmap also calls for interconnected timelines, custom calendars, Scrivener-like manuscript structure, entity linking, maps and a later Chronicles-style experience. The plan below turns that intent into an implementation order and architectural contract. 

---

# 1. Current Repository Baseline

## 1.1 Repository state

The repository is a public Dart/Flutter project on `main`. The current repository metadata reports Dart as the primary language, an active `main` branch, an existing issue/PR workflow, and recent activity on 2026-08-20.

The repository already contains an overhaul documentation layer under `docs/overhaul/`, plus an `.agent/` system containing specialist agents, skills and workflows. The existing agent architecture includes dedicated planning, frontend, backend, database, testing, performance, debugging and code-archaeology roles. This should be treated as development infrastructure rather than product architecture.

## 1.2 Existing product direction

`docs/overhaul/02-navigation-and-modules.md` establishes the intended application shell:

- Dashboard remains the multi-project library/project picker.
- Overview becomes the project home after opening a project.
- Top-level navigation is reduced to:
  - Overview
  - Manuscripts
  - Characters
  - World Building
  - Lore Map
- World Building becomes the home for Calendar, Timeline, Maps, Locations, Magic, Species and future domains.
- Global search is intended to behave like a command palette (`Ctrl+K` / `Cmd+K`).
- A collapsible inspector is intended to be heavily used for entities.
- The shell should remain short and focused instead of exposing every domain as a permanent navigation item.

This direction should be preserved.

## 1.3 Existing roadmap direction

`docs/overhaul/05-module-roadmap.md` already identifies:

- Scrivener references for Manuscripts.
- Lore Forge / Campfire / LegendKeeper references for Characters.
- Aeon Timeline / LegendKeeper / World Anvil references for Timeline.
- Plottr references for Arcs.
- Obsidian / LegendKeeper philosophy for Lore Map.
- Inkarnate / LegendKeeper references for Maps.
- Global search, quick linking, backlinks and tags as cross-cutting capabilities.
- Chronicles as a later feature combining maps and timelines.

This document does **not** replace that roadmap. It turns it into a dependency-aware execution plan.

---

# 2. Product North Star

## 2.1 The core mental model

Lore Keeper should answer four questions immediately:

1. **What am I creating?** — entity, manuscript, scene, event, place, relationship, map, etc.
2. **Where does it belong?** — project, hierarchy, collection, timeline, map, manuscript.
3. **What is it connected to?** — characters, locations, factions, events, scenes, documents.
4. **When and where does it happen?** — temporal and spatial context.

The user should rarely need to duplicate information merely because they are viewing it from another module.

## 2.2 Product principles

### Principle A — Connections are first-class

Every major entity should be linkable to other entities.

### Principle B — Structure should be flexible

Do not force every entity through a giant form. Optional sections, properties, tags, links and rich content should carry the burden.

### Principle C — Context should follow the user

An entity inspector, reference sidebar, backlinks panel or quick preview should let the user inspect related lore without losing their current workspace.

### Principle D — The canvas is a tool, not the product

Timelines, maps, relationship graphs and corkboards are lenses over the same underlying data.

### Principle E — Local-first is non-negotiable

The existing Hive/local architecture should remain the default persistence model. The product must work without a server dependency.

### Principle F — Visual richness without visual noise

Use strong hierarchy, cards, subtle surfaces, compact metadata and restrained chrome. Avoid dashboard-style UI overload.

### Principle G — Canonical data, multiple views

A Character is one entity. Its card grid, inspector, manuscript references, relationship graph and timeline appearances are views of the same entity.

---

# 3. Reference Product Matrix

| Reference | Borrow | Do not copy blindly |
|---|---|---|
| Campfire | Modular worldbuilding, interconnected modules, flexible panels, focus mode, cross-reference workflow | Large module count and potentially form-heavy workflows |
| Inkarnate | Map canvas, drawing tools, asset-first map workflow, visual polish | Full cartography/editor scope in early Lore Keeper releases |
| Lore Forge | Simple entity UI, concept art, tags/search, scenes, lightweight writing context | Its exact schema or visual styling |
| World Anvil | Feature depth, custom calendars, timelines, Chronicles, multi-scale world history | Feature density and article-centric UX as the default |
| Scrivener | Binder, structured manuscript, corkboard, outliner, inspector, reference workflow | Complex publishing-oriented UI everywhere |
| Plottr | Scene cards, plotlines, filters, drag/drop, visual story structure | Treating all events as narrative scenes |
| Aeon Timeline | Timeline canvas, zoom, inspector, grouping, minimap/context bar, uncertain dates | Generic project-management semantics |
| Obsidian | Backlinks, properties, search, command palette, graph philosophy | Turning Lore Keeper into a general note-taking app |
| LegendKeeper | Flexible wiki, nested pages, auto-linking, maps, timelines, offline model, simple worldbuilding shell | MMO/wiki-like information density |

## 3.1 Reference hierarchy

When two references conflict, use this priority:

1. **Lore Keeper's domain model and local-first constraints**
2. **LegendKeeper** for overall shell and connectivity
3. **Campfire** for module breadth and flexible worldbuilding
4. **Scrivener** for Manuscript interaction
5. **Aeon Timeline** for temporal interaction
6. **Plottr** for narrative planning
7. **Inkarnate** for Map interaction
8. **World Anvil** for advanced feature depth and Chronicles
9. **Obsidian** for connectivity philosophy
10. **Lore Forge** for lightweight entity UX and asset handling

---

# 4. Target Application Architecture

## 4.1 Target stack

Keep Flutter/Dart. Do not migrate frameworks as part of this overhaul.

Target logical layers:

```text
Presentation
  ├── Shell
  ├── Module Views
  ├── Inspectors
  ├── Canvases
  └── Editors

Application
  ├── Commands
  ├── Use Cases
  ├── Selection / Navigation State
  ├── Search
  └── Linking

Domain
  ├── Entities
  ├── Value Objects
  ├── Temporal Engine
  ├── Relationship Graph
  ├── Validation
  └── Derived Views

Persistence
  ├── Hive repositories
  ├── adapters
  ├── migrations
  └── indexes / caches
```

The current codebase does not need a wholesale rewrite to reach this structure. Introduce boundaries incrementally around the most fragile domains first.

## 4.2 Provider rule

Providers should own **application state**, not domain mathematics.

Avoid putting date conversion, map geometry, relationship traversal or complex filtering logic directly into ChangeNotifier classes.

Preferred pattern:

```text
Provider
   ↓
Application service / use case
   ↓
Domain service
   ↓
Repository / model
```

## 4.3 Repository rule

A Hive box is persistence infrastructure, not the domain model.

The application should not rely on arbitrary widgets reopening Hive boxes or directly interpreting serialized attributes.

---

# 5. Canonical Entity Model

Lore Keeper needs an explicit concept of an **Entity** even if the existing Hive models remain separate internally.

Conceptually:

```text
Entity
├── id
├── projectId
├── type
├── title
├── description/content
├── icon
├── color
├── image/asset references
├── tags
├── properties
├── createdAt
└── updatedAt
```

Specialized domains then add their own fields:

```text
Character
Location
Faction / Organization
Species
Culture
Magic System
Item
Language
Religion
Philosophy
Research Item
Manuscript
Scene
Arc
Calendar
Timeline Event
Map
Relationship
```

This does **not** mean converting every model into one giant Hive class. It means establishing a common linking vocabulary.

---

# 6. Universal Linking Layer

## 6.1 Entity reference

Introduce a lightweight reference type conceptually equivalent to:

```dart
EntityRef {
  String entityId;
  String entityType;
}
```

Use this instead of adding increasingly specific ID arrays everywhere.

Examples:

```text
Event → Character
Event → Location
Event → Faction
Scene → Character
Scene → Location
Scene → Event
Character → Location
Character → Organization
Manuscript → Character
MapPin → Location
MapPin → Character
```

Existing IDs can be migrated gradually.

## 6.2 Relationship model

Relationships should eventually become first-class objects:

```text
Relationship
├── id
├── projectId
├── fromEntity
├── toEntity
├── type
├── label
├── directionality
├── strength / metadata
├── validFrom
├── validTo
└── notes
```

This allows a relationship itself to have history.

Example:

```text
Character A
    │
    └── rival of ──→ Character B
        valid: Year 340–344
```

This is important for timeline-aware worldbuilding.

---

# 7. Calendar + Timeline: Architectural Priority #1

This is the most important architectural work before advanced Calendar/Timeline features are added.

## 7.1 Current problem

The current system stores TimelineEvent dates as:

```text
absoluteYear
absoluteDayOfYear
calendarSystemKey
```

The CalendarNode tree stores the actual calendar structure. `CalendarChronology` reconstructs numerical meaning at runtime.

This means an event's date is effectively an interpretation rather than a stable domain value.

The audit identified the resulting risks:

- editing month lengths silently changes event meaning;
- deleting calendars leaves orphaned events;
- changing eras changes historical labels retroactively;
- invalid day-of-year values are possible;
- cross-calendar ordering has no chronological meaning;
- there is no universal time axis;
- durations are stored but not visually represented;
- uncertain dates and ranges are unsupported.

## 7.2 Target temporal architecture

```text
Calendar Tree
      ↓ compile
Calendar Definition
      ↓
Temporal Engine
      ↓
Calendar Date ←→ Universal Temporal Coordinate
      ↓
Temporal Range
      ↓
Timeline Event
```

## 7.3 CalendarDefinition

Create a computational calendar definition separate from the editable tree.

Conceptual fields:

```text
CalendarDefinition
├── systemId
├── version
├── name
├── yearStructure
├── months
├── weekdays
├── weekStructure
├── eras
├── leapRule
├── seasons
├── epoch
└── validation metadata
```

The CalendarNode tree remains the **authoring source**. A compiler turns it into a validated definition.

## 7.4 CalendarDate

Replace direct event dependence on `absoluteDayOfYear` with a real date value object.

```text
CalendarDate
├── calendarSystemId
├── calendarVersion
├── year
├── month
├── day
└── optional era context
```

The engine can derive day-of-year, week number, season and era.

## 7.5 Universal Temporal Coordinate

Introduce a universal internal coordinate such as:

```text
TemporalCoordinate
└── absoluteDay / absoluteTick
```

A calendar date converts to this coordinate through its epoch and calendar rules.

This enables:

- cross-calendar comparison;
- multiple calendars in one world;
- calendar conversion;
- global timeline ordering;
- parallel timelines;
- event overlap detection;
- future Chronicles.

## 7.6 TemporalRange

Timeline events should support:

```text
TemporalRange
├── start
├── end
├── precision
├── certainty
└── display policy
```

Supported precision should include at minimum:

- exact day;
- month;
- year;
- decade/century-like coarse periods;
- approximate;
- before/after;
- range.

## 7.7 Duration

Duration should be a domain value rather than an unused integer:

```text
TemporalDuration
├── days
└── optional higher-level display units
```

The timeline renderer must use it to draw event spans.

## 7.8 Calendar versioning

A calendar definition must be versioned once dependent events exist.

```text
Calendar System
├── Definition v1
├── Definition v2
└── Definition v3
```

An existing event must retain the calendar definition that gave its date meaning, unless the user explicitly migrates it.

## 7.9 Calendar mutation workflow

When changing a calendar with dependent events:

```text
Edit Calendar
      ↓
Compile proposed definition
      ↓
Compare with active definition
      ↓
Find affected events
      ↓
Show impact preview
      ↓
Preserve / migrate / review
      ↓
Commit new calendar version
```

Example warning:

> 12 events are affected because changing Month 2 from 30 to 32 days changes the month/day interpretation of later dates.

## 7.10 Calendar deletion

Never silently delete a calendar referenced by timeline events.

Preferred options:

- archive calendar;
- migrate events to another calendar;
- duplicate/migrate calendar definition;
- explicitly delete dependent events.

---

# 8. Temporal Engine API

The domain service should eventually provide APIs similar to:

```text
validate(date)
validateCalendar(definition)
dateToDay(date)
dayToDate(calendar, coordinate)
addDays(date, days)
difference(a, b)
compare(a, b)
monthAtDayOfYear(day)
dayOfMonthAtDayOfYear(day)
weekOfYear(date)
eraAtDate(date)
seasonAtDate(date)
format(date)
parse(text)
convert(date, targetCalendar)
```

No UI widget should implement these calculations.

## 8.1 Testing requirements

The temporal engine requires exhaustive unit tests for:

- ordinary years;
- leap years;
- leap days;
- month boundaries;
- year boundaries;
- era boundaries;
- negative/ancient years if supported;
- custom epochs;
- multiple calendars;
- conversion round trips;
- duration arithmetic;
- invalid dates;
- calendar version changes.

---

# 9. Timeline 2.0

Reference mechanics: Aeon Timeline, Plottr and World Anvil Chronicles.

Aeon Timeline's model of an interactive canvas plus inspector, context bar, bookmarks, grouping, drag/drop and uncertain dates is particularly appropriate. Plottr adds useful narrative filtering through characters, places, tags and plotlines. World Anvil demonstrates the value of custom calendars and multi-scale history.

## 9.1 Timeline views

The Timeline module should provide multiple views over the same event dataset:

### Chronicle

Readable historical sequence.

### Canvas

Zoomable temporal canvas with events, groups and lanes.

### Gantt / Range

Duration-focused bars for wars, reigns, journeys and periods.

### Calendar

Day/month/year planning view for detailed events.

### List

Dense searchable event list.

## 9.2 Event card

Minimum visible fields:

- event title;
- date/range;
- icon/color;
- linked location;
- primary linked characters;
- duration indicator where relevant.

Do not put the entire event description on the canvas.

## 9.3 Event inspector

The right inspector should handle:

- title;
- description/lore;
- temporal range;
- certainty/precision;
- calendar;
- linked characters;
- linked locations;
- linked factions;
- linked manuscripts/scenes;
- tags;
- visual style;
- assets;
- notes.

## 9.4 Grouping

Allow grouping by:

- era;
- faction;
- character;
- location;
- arc;
- timeline;
- custom group.

Aeon Timeline's flexible grouping model is a strong reference here.

## 9.5 Minimap / context bar

The Timeline should have a compact navigator showing the current viewport within the full chronology.

## 9.6 Zoom

Use semantic zoom rather than simply shrinking widgets.

```text
World / Millennium
      ↓
Era / Century
      ↓
Decade / Year
      ↓
Month
      ↓
Week
      ↓
Day
```

At each scale, show the information appropriate to that scale.

---

# 10. Chronicles — Major Future Feature

World Anvil's Chronicles is the clearest reference for a future Lore Keeper experience because it combines **where + when**. Its current implementation connects timeline events to interactive map markers and can show how geography changes over history.

Lore Keeper should eventually build its own version:

```text
                 CHRONICLE

Timeline ────────────────────────────────▶
   │
   ├── Event A ── Character(s) ── Location
   │                   │              │
   │                   │              ▼
   │                   │          Map State
   │                   │
   ├── Event B ── Faction ─────── Location
   │
   └── Event C ── Scene ────────── Location
```

## 10.1 Chronicle event

A Chronicle event is more than a TimelineEvent.

It is a historical occurrence with:

- time;
- place;
- characters;
- factions;
- narrative context;
- source/manuscript references;
- map representation;
- optional state changes.

## 10.2 Map-aware chronology

Future map states could represent:

- borders;
- settlements;
- political control;
- renamed places;
- destroyed/created locations;
- migration;
- terrain changes;
- roads/trade routes.

This should be explicitly phased later because it depends on stable Calendar/Timeline and Map foundations.

---

# 11. Manuscripts 2.0

Reference: Scrivener, Campfire, Lore Forge and Plottr.

The Manuscript module should be a structured writing environment rather than a document editor with a sidebar.

## 11.1 Binder model

```text
Manuscript
├── Part I
│   ├── Chapter 1
│   │   ├── Scene 1
│   │   └── Scene 2
│   └── Chapter 2
├── Part II
└── Research / Notes
```

The structure should be persisted independently of the editor surface.

## 11.2 Views

- Binder
- Editor
- Corkboard
- Outliner
- Collections
- Search
- Reference inspector

## 11.3 Scene metadata

A scene should be linkable to:

- characters;
- locations;
- timeline events;
- arc/plotline;
- POV;
- tags;
- status;
- notes;
- temporal position.

## 11.4 Side reference

Borrow heavily from Scrivener and Campfire's cross-reference workflow.

The writer should be able to pin:

- Character;
- Location;
- Event;
- Research item;
- Image;
- another scene.

The reference panel should update without navigating away from the manuscript.

## 11.5 Distraction-free mode

Hide shell chrome while preserving a fast escape/command shortcut.

---

# 12. Characters 2.0

Reference: Campfire, Lore Forge, LegendKeeper.

## 12.1 Default presentation

Use a card grid with:

- portrait/concept art;
- name;
- short role/descriptor;
- tags;
- status/completion indicator.

Selecting a card opens the entity inspector rather than a separate full-screen form wherever possible.

## 12.2 Character workspace

Suggested sections:

- Overview
- Identity
- Appearance
- Personality
- History
- Relationships
- Appearances
- Timeline
- Locations
- Manuscripts / Scenes
- Assets
- Notes

Sections should be collapsible and optional.

## 12.3 Relationships

A relationship should be directly navigable to the relationship graph and to the related entity.

## 12.4 Timeline integration

Characters should expose:

> “Show this character on timeline”

with events automatically filtered to relevant linked events.

---

# 13. World Building Consolidation

World Building remains a container for domains, not a giant generic editor.

Recommended internal navigation:

```text
World Building
├── Overview
├── Characters-adjacent entities
├── Timeline
├── Calendar
├── Locations
├── Maps
├── Magic
├── Species
├── Cultures
├── Languages
├── Organizations
├── Items
├── Religions
├── Philosophies
├── Research
├── Arcs
└── Relationships
```

The exact tab set should remain configurable as modules mature, but the top-level shell should stay short.

---

# 14. Locations

Reference: Campfire and LegendKeeper.

Locations should be hierarchical:

```text
World
└── Continent
    └── Country
        └── Region
            └── City
                └── Building
                    └── Room
```

But the hierarchy must not be mandatory.

A location should support:

- rich description;
- images/assets;
- parent location;
- child locations;
- inhabitants;
- organizations;
- events;
- map pins;
- travel links;
- tags;
- notes.

---

# 15. Map Module

Reference: Inkarnate for creation quality; Campfire and LegendKeeper for linking.

The repository's previous map architecture was intentionally removed/identified as a cleanup candidate. Do not simply restore the old implementation. Reintroduce Maps as a **new generation module** with a narrower, better-defined responsibility.

## 15.1 Phase 1 map scope

- import/upload map image;
- pan/zoom;
- pins;
- custom pin icons/colors;
- link pin to Location/Character/Event/etc.;
- nested maps;
- layers/visibility;
- annotations;
- map metadata.

## 15.2 Phase 2

- regions;
- paths;
- routes;
- shapes;
- measurement;
- layer groups;
- map state snapshots.

## 15.3 Phase 3

- Chronicle map states;
- historical map changes;
- timeline-linked map visibility.

Do not attempt to compete with Inkarnate as a complete map-generation product in the first implementation. Lore Keeper's differentiator is **connected worldbuilding**, not brush technology.

---

# 16. Arcs / Plot Module

Reference: Plottr.

The Arc system should connect narrative structure to actual Manuscript scenes and world events.

## 16.1 Core model

```text
Arc
├── name
├── description
├── color
├── type
├── scenes
├── characters
├── events
└── status
```

## 16.2 Visual model

```text
             MAIN ARC
────────────────────────────────────────
 Scene 1     Scene 4        Scene 9

     SUBPLOT A
─────── Scene 2 ─── Scene 6 ────────────

     CHARACTER ARC
──────── Scene 3 ───── Scene 7 ─────────
```

Plottr's scene cards, plotlines and filters are the strongest interaction reference.

## 16.3 Filters

Filter by:

- character;
- location;
- arc;
- manuscript;
- tag;
- status;
- event;
- chapter.

---

# 17. Lore Map

Reference philosophy: Obsidian + LegendKeeper.

Lore Map is a **lens**, not the default home screen.

## 17.1 Nodes

Potential node types:

- Character
- Location
- Organization
- Species
- Culture
- Magic
- Item
- Event
- Manuscript
- Scene
- Arc
- Calendar
- Research

## 17.2 Edges

Examples:

- related-to
- appears-in
- located-in
- member-of
- rules
- practices
- founded-by
- created-by
- participated-in
- occurs-at
- caused-by
- follows
- precedes

## 17.3 Backlinks

Every entity should be able to answer:

> “What else references this?”

Obsidian's backlinks model is a good interaction reference, while LegendKeeper demonstrates how links can remain embedded in a worldbuilding-first workflow.

---

# 18. Search + Command Palette

This should become one of the highest-value cross-cutting features.

## 18.1 Global search

Search across:

- title;
- content;
- tags;
- properties;
- entity type;
- linked entities.

## 18.2 Command palette

`Ctrl+K` / `Cmd+K` should support:

- navigate to module;
- open entity;
- create entity;
- create scene;
- create event;
- create relationship;
- search project;
- toggle focus mode;
- switch theme/view;
- recent items.

## 18.3 Quick linking

While editing rich text:

```text
@Character Name
@Location Name
@Event Name
```

should resolve to an entity reference.

Avoid forcing the user to leave the editor to create the link.

---

# 19. Asset Library

Reference: Campfire, Lore Forge and LegendKeeper.

Create a project-level asset abstraction:

```text
Asset
├── id
├── projectId
├── file reference
├── type
├── title
├── tags
├── metadata
└── linked entities
```

Assets should be reusable across:

- Characters;
- Locations;
- Manuscripts;
- Maps;
- Events;
- Organizations;
- moodboards.

Avoid duplicating the same image for every entity.

---

# 20. UI Design System

The previous Figma/overhaul work established the direction toward a clean, content-first design. The next iteration should formalize that system rather than repeatedly styling individual modules.

## 20.1 Shell

```text
┌───────────────────────────────────────────────────────────┐
│ Brand / Project / Search / Actions                        │
├────────────┬──────────────────────────────┬───────────────┤
│ Navigation │ Main workspace               │ Inspector     │
│            │                              │               │
│ Overview   │                              │ Contextual    │
│ Manuscripts│                              │ properties    │
│ Characters │                              │ links         │
│ World      │                              │ references    │
│ Lore Map   │                              │               │
└────────────┴──────────────────────────────┴───────────────┘
```

## 20.2 Shared workspace patterns

Standardize these components:

- Entity card
- List row
- Inspector
- Property section
- Tag chip
- Link chip
- Breadcrumb
- Search field
- Command palette
- Filter bar
- Empty state
- Inline editor
- Modal/drawer
- Canvas toolbar
- Context navigator
- History panel

## 20.3 Surface hierarchy

Use a restrained hierarchy:

```text
Application background
  → workspace surface
    → panel surface
      → elevated/selected surface
```

Avoid excessive borders and card nesting.

## 20.4 Density

Lore Keeper is a professional creative tool, not a marketing dashboard.

Prefer:

- compact metadata;
- strong typography hierarchy;
- generous writing space;
- minimal decorative chrome;
- contextual controls.

---

# 21. Responsive Strategy

Desktop is the primary target for deep authoring.

Tablet/mobile should focus on:

- reading;
- quick capture;
- editing simple entity data;
- reviewing timeline;
- browsing maps;
- manuscript writing.

Do not force desktop canvases into tiny screens.

The existing project shell should remain responsive, but each module should declare its mobile strategy.

---

# 22. Persistence and Data Integrity

## 22.1 Hive

Keep Hive as the initial local persistence layer.

## 22.2 Box initialization

Open shared boxes once at application/bootstrap level and inject repositories/services into providers.

Avoid repeated `Hive.openBox()` calls across providers even if Hive safely returns the same instance.

## 22.3 Project ownership

Project ownership must be explicit in every top-level persisted entity.

Nested objects can inherit ownership through a parent, but cross-project references must be rejected.

## 22.4 Referential integrity

Before deleting any entity:

1. discover inbound references;
2. show the user what will be affected;
3. migrate, remove or preserve references according to domain rules;
4. only then delete.

## 22.5 Soft deletion

Prefer an archive/soft-delete state for high-value entities such as:

- Calendars;
- Characters;
- Locations;
- Timeline Events;
- Manuscripts.

Permanent deletion can be an explicit second step.

---

# 23. Migration Strategy

Never combine a large data-model migration with a visual overhaul in one opaque change.

Use:

```text
Migration N
    ↓
Read old model
    ↓
Validate
    ↓
Create new model
    ↓
Verify counts/references
    ↓
Mark migration complete
```

## 23.1 Calendar migration

Current:

```text
absoluteYear
absoluteDayOfYear
calendarSystemKey
```

Target:

```text
calendarSystemId
calendarVersion
CalendarDate / TemporalRange
```

Keep a compatibility path until all existing events have been migrated.

## 23.2 ID migration

Existing specialized ID arrays should remain readable while the universal `EntityRef` system is introduced.

Do not break all existing modules simultaneously.

---

# 24. Performance Plan

## 24.1 Derived data caching

`CalendarChronology.fromProvider()` must not be rebuilt on every widget build.

Introduce a cache keyed by:

```text
calendarSystemId + calendarVersion
```

Invalidate only when the calendar definition changes.

## 24.2 Timeline rendering

Do not instantiate expensive date calculations for every event on every frame.

Precompute a view model:

```text
TimelineEventViewModel
├── temporalCoordinate
├── displayDate
├── displayRange
├── lane
├── visible links
└── layout metrics
```

Cache by event revision + viewport/zoom state where appropriate.

## 24.3 Large projects

Plan for:

- thousands of entities;
- thousands of timeline events;
- large manuscripts;
- large map images.

Use pagination/virtualization where possible.

---

# 25. Testing Strategy

## 25.1 Domain tests

Highest priority:

- Calendar engine;
- temporal conversions;
- relationship graph;
- entity linking;
- validation;
- migrations.

## 25.2 Provider tests

Verify:

- project scoping;
- selection synchronization;
- filtering;
- deletion behavior;
- change notifications.

## 25.3 Widget tests

Verify:

- inspectors;
- event editing;
- card grids;
- navigation;
- calendar wizard;
- timeline interactions.

## 25.4 Integration tests

Critical flows:

```text
Create Project
 → Create Character
 → Create Location
 → Create Calendar
 → Create Event
 → Link Character + Location
 → Create Scene
 → Link Scene to Event
 → View on Timeline
 → View on Map
 → Open Character and inspect backlinks
```

## 25.5 Migration tests

Every persisted schema change requires:

- old fixture;
- migration;
- new fixture assertion;
- reference integrity assertion.

---

# 26. Development Phases

## Phase 0 — Baseline Lock

**Goal:** establish a known-good starting point.

Tasks:

- freeze current `main` behavior;
- run analyzer;
- run all tests;
- document current Hive adapters/type IDs;
- capture existing UI screenshots;
- identify unfinished/dead modules;
- create migration test fixtures;
- verify current project creation/opening flows.

**Exit:** reproducible baseline.

---

## Phase 1 — Architecture Foundation

**Goal:** establish domain boundaries without changing the visible product significantly.

Tasks:

- shared repository layer;
- shared entity reference model;
- centralized Hive initialization;
- application command/use-case boundaries;
- shared selection/navigation state;
- validation utilities;
- domain error/result model;
- shared inspector/link components.

**Exit:** modules can consume shared domain/application services instead of embedding business logic in widgets/providers.

---

## Phase 2 — Temporal Foundation

**Goal:** fix Calendar + Timeline before adding advanced features.

Tasks:

- CalendarDefinition;
- CalendarCompiler;
- CalendarDate;
- TemporalCoordinate;
- TemporalDuration;
- TemporalRange;
- leap rule abstraction;
- date arithmetic;
- validation;
- calendar versioning;
- event migration;
- chronology caching.

**Exit:** changing a calendar cannot silently corrupt existing event meaning.

---

## Phase 3 — Timeline 2.0

**Goal:** turn Timeline into a real temporal workspace.

Tasks:

- canvas rewrite around universal coordinate;
- semantic zoom;
- event ranges;
- uncertain dates;
- inspector;
- grouping/lane model;
- minimap/context bar;
- calendar view;
- list view;
- event linking;
- search/filter.

**Exit:** timeline can handle exact, fuzzy, ranged and cross-calendar events.

---

## Phase 4 — Entity Connectivity

**Goal:** make the application feel like one system.

Tasks:

- EntityRef;
- universal link picker;
- backlinks;
- relationship model;
- link chips;
- entity preview;
- global search;
- command palette;
- quick linking.

**Exit:** users can navigate the world through relationships instead of manually switching modules.

---

## Phase 5 — Manuscripts 2.0

**Goal:** make writing the strongest primary workflow.

Tasks:

- binder hierarchy;
- scenes;
- corkboard;
- outliner;
- scene metadata;
- pinned references;
- character/location/event links;
- collections;
- focus mode.

**Exit:** a complete manuscript can be planned and written without leaving Lore Keeper.

---

## Phase 6 — Characters + Locations + Entities

**Goal:** unify entity management.

Tasks:

- card grids;
- inspector;
- flexible sections;
- assets;
- tags;
- backlinks;
- appearances;
- relationships;
- location hierarchy;
- map integration hooks.

**Exit:** Characters and Locations feel like first-class interconnected entities rather than isolated CRUD modules.

---

## Phase 7 — Arcs + Story Planning

**Goal:** connect narrative structure to actual manuscript and world data.

Tasks:

- arcs;
- plotlines;
- scene cards;
- character arcs;
- filters;
- drag/drop planning;
- manuscript synchronization.

**Exit:** moving a scene in planning updates the manuscript structure without duplicate data.

---

## Phase 8 — Maps 2.0

**Goal:** introduce a focused, linked map workspace.

Tasks:

- image map;
- pins;
- nested maps;
- linked entities;
- layers;
- annotations;
- regions/paths;
- asset handling.

**Exit:** a location can be discovered from a map and opened as a full entity.

---

## Phase 9 — Chronicles

**Goal:** merge time + space + narrative.

Tasks:

- Chronicle model;
- timeline/map split view;
- event focus;
- map state snapshots;
- historical map states;
- parallel timelines;
- event-to-scene links;
- character/faction filters.

**Exit:** a user can scrub through history and understand what happened, when, where and who was involved.

---

## Phase 10 — Advanced Worldbuilding

Potential modules/features:

- cultures;
- languages;
- religions;
- philosophies;
- magic systems;
- organizations/factions;
- items;
- technology;
- research;
- family trees;
- diplomacy;
- boards/whiteboards;
- secrets;
- publication/export.

These should be built on the common entity/linking infrastructure rather than creating isolated systems.

---

# 27. What NOT To Build Yet

Do not spend the next development cycle on:

- decorative dashboard widgets;
- elaborate theme galleries;
- multiplayer;
- cloud sync;
- full Inkarnate-style map generation;
- full Obsidian plugin ecosystem;
- complex AI generation;
- giant mandatory entity forms;
- separate navigation items for every domain;
- map-history simulation before temporal foundations are stable.

The current product needs **structural correctness and interconnected workflows** more than additional feature count.

---

# 28. Priority Matrix

| Area | Priority | Reason |
|---|---:|---|
| Temporal foundation | P0 | Existing data can silently change meaning |
| Entity linking | P0 | Core product differentiator |
| Calendar integrity/versioning | P0 | Prevents historical corruption |
| Timeline 2.0 | P0 | Major existing module with architectural debt |
| Global search | P1 | Required once entity count grows |
| Manuscript structure | P1 | Core writer workflow |
| Characters/Locations inspector | P1 | Core entity workflow |
| Relationships | P1 | Connectivity backbone |
| Arcs | P1 | Narrative planning |
| Maps | P1/P2 | Strong visual feature but depends on linking |
| Chronicles | P2 | High-value endgame feature |
| Advanced modules | P2/P3 | Build after shared foundations |
| Collaboration | P3 | Conflicts with local-first architecture and adds major complexity |

---

# 29. Definition of Done for the Overhaul

The overhaul is successful when:

### Architecture

- modules do not implement their own linking systems;
- providers do not contain complex domain mathematics;
- Hive initialization is centralized;
- migrations are explicit;
- derived calculations are cached.

### Calendar

- custom calendars support real date arithmetic;
- leap rules are supported;
- dates validate;
- calendar versions preserve historical meaning;
- events cannot become silently invalid.

### Timeline

- exact, fuzzy and ranged events are supported;
- duration is rendered;
- events can link to characters, locations, factions and scenes;
- multiple calendars can share a universal chronological axis;
- timeline has canvas/list/calendar/chronicle-style views.

### Manuscript

- structured binder;
- scenes;
- corkboard/outliner;
- contextual references;
- entity linking;
- focus mode.

### Connectivity

- global search;
- command palette;
- backlinks;
- quick linking;
- relationship graph;
- entity previews.

### Maps

- interactive image maps;
- linked pins;
- nested maps;
- location integration.

### Chronicles

- event + time + location + characters/factions;
- timeline/map synchronization;
- historical map states as a future-ready abstraction.

---

# 30. Recommended Immediate Execution Order

If implementation begins immediately, do **not** start by redesigning every screen.

Execute this order:

```text
1. Baseline + test lock
        ↓
2. Temporal domain foundation
        ↓
3. Calendar migration/versioning
        ↓
4. Timeline engine rewrite
        ↓
5. Shared EntityRef + linking
        ↓
6. Global search / command palette
        ↓
7. Shared inspector + entity workspace
        ↓
8. Manuscript binder/scenes
        ↓
9. Characters + Locations
        ↓
10. Arcs / Plottr-style planning
        ↓
11. Map 2.0
        ↓
12. Chronicles
```

UI redesign should happen **alongside each architectural phase**, using the shared design system, rather than as one giant visual rewrite at the end.

---

# 31. Reference Notes

The following sources informed the product direction:

- Campfire — modular worldbuilding, interconnected writing tools, characters, maps, relationships and customizable panels.
- Inkarnate — map editing, line/shape tools, assets and high-resolution map workflow.
- Lore Forge — lightweight writing/worldbuilding UI, scenes, characters, locations, relationships, tags and concept art.
- World Anvil — advanced worldbuilding breadth, custom calendars, timelines and Chronicles.
- Scrivener — binder, structured manuscript, corkboard, outliner and contextual writing workflow.
- Plottr — scene cards, plotlines, character arcs, filters and visual story planning.
- Aeon Timeline — interactive timeline, grouping, inspector, zoom, minimap/context navigation, uncertain dates and duration.
- Obsidian — backlinks, graph/connectivity philosophy and command-driven navigation.
- LegendKeeper — flexible wiki, nested pages, links, maps, timelines, offline operation and low-friction worldbuilding.

See the implementation repository's existing overhaul documents for the established shell and module roadmap.

---

# 32. Final Product Positioning

Lore Keeper should not try to become:

> “Campfire but free.”

or:

> “Obsidian for writers.”

or:

> “A simplified World Anvil.”

Its strongest identity is:

> **A local-first creative workspace where a writer can build a world, write the story, and see the relationship between people, places, events and history without maintaining separate databases.**

The most important long-term interaction is therefore:

```text
                    LORE KEEPER
                         │
          ┌──────────────┼──────────────┐
          │              │              │
       MANUSCRIPT     WORLD          HISTORY
          │              │              │
       Scenes        Entities       Timeline
          │              │              │
          └───────┬──────┴──────┬───────┘
                  │             │
               LINKS         CALENDAR
                  │             │
                  └──────┬──────┘
                         │
                      CHRONICLE
                         │
                  TIME + SPACE + LORE
```

That is the architecture the rest of the product should converge toward.
