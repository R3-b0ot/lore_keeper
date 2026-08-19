# Navigation and Modules

## Two layers of “home”

| Surface | Role |
|---------|------|
| **Dashboard** | Multi-project: list/create/open projects. Custom UI. **Book-like opening** when entering a project. |
| **Overview** (inside project) | Single-project home: stats, recent manuscripts, activity, quick links into modules. **New module** in the project shell. |

Do not collapse Dashboard into Overview. Dashboard remains the project picker / library; Overview is the first screen *after* opening a project.

## Project shell top-level navigation

Aligned with the Figma Make design. Keep the rail short.

| ID | Label | Status | Notes |
|----|-------|--------|-------|
| `overview` | Overview | **New** | Project dashboard inside the shell |
| `manuscripts` | Manuscripts | **Keep** | Structured writing (Scrivener-inspired over time) |
| `characters` | Characters | **Keep** | Entity cards + detail/inspector |
| `world` | World Building | **Consolidate** | All other lore domains as tabs/sections |
| `loremap` | Lore Map | **Plan / phase** | Connectivity graph (relationships, appears-in, etc.) |

### World Building tabs (initial set)

Push former top-level modules here (names can match existing domain models):

- Magic  
- Timelines  
- Calendars  
- Species  
- Locations  
- *(later / same area)* Languages, Items, Cultures, Philosophies, Religions, Systems, Research, Arcs, Relationships, Maps  

Maps may live under World Building *or* as a view on location entities (LegendKeeper-style tabs on an element). Prefer one clear home in the nav; avoid a second long rail.

### Explicitly *not* top-level anymore

Former long module list (Manuscript, Characters, Map, Timeline, Calendar, Languages, Magic, Research, Arcs, Relationships, Items, Species, Cultures, Philosophies, Religions, Systems) is reduced:

- Manuscripts → top-level  
- Characters → top-level  
- Everything else → World Building (or Lore Map for pure connectivity)

## Shell layout (target)

```
┌─────────────┬──────────────────────────────────────────────┐
│  Sidebar    │  Main content                                │
│  - Brand    │  (Overview | Manuscript list+editor |        │
│  - Project  │   Character grid+inspector | World tabs |    │
│  - Search   │   Lore Map)                                  │
│  - Nav      │                                              │
│  - Progress │  [optional right inspector]                  │
└─────────────┴──────────────────────────────────────────────┘
```

- Global search: ⌘K / Ctrl+K (command palette style).  
- Inspector: collapsible; used heavily on Characters and entity detail.  
- Sidebar width ~220px in prototype; use theme tokens for surfaces.

## Routing / state (guidance)

- Project editor route owns: selected top-level section, selected entity ids, World tab index.  
- Preserve deep links where they exist today (e.g. open project → specific chapter/character).  
- Overview is the default landing **inside** a project after the book-opening transition.

## UX continuity

- List + main + optional history/inspector patterns for Manuscripts can remain.  
- Character card grid + detail panel matches the Figma prototype direction.  
- World Building: horizontal or sidebar tabs for domains; each domain keeps its existing pane depth where possible, then deepens per roadmap.
