# Lore Keeper Module Implementation Guide

These documents are the **functional contracts** for vibe-coding each module. Implement the behavior described here rather than improvising a new product model per screen.

## Shared Rules

Every module must:

1. Use the existing project shell and design tokens.
2. Be local-first and project-scoped.
3. Separate domain logic from widgets/providers.
4. Reuse the shared inspector, entity cards, search, tags and link picker.
5. Treat relationships and references as first-class data.
6. Support keyboard navigation and desktop-first workflows.
7. Never silently destroy or reinterpret linked data.
8. Prefer contextual drawers/inspectors over full-screen forms.
9. Persist changes immediately or through explicit save transactions; never rely on widget lifetime.
10. Provide empty, loading, error and validation states.

## Standard Module Anatomy

```text
Module
├── Header / toolbar
├── Primary workspace
├── Optional secondary navigation
├── Contextual inspector
├── Search / filter
└── Create / quick-action flow
```

## Vibe-Coding Contract

When implementing a module:

- inspect existing models/providers before adding new ones;
- preserve existing persisted data unless a migration is explicitly defined;
- create domain models/services before complex UI logic;
- keep reusable UI in shared widgets;
- add tests for domain behavior and important user flows;
- do not introduce mock functionality that looks complete but does not persist;
- do not create duplicate versions of existing entities merely to satisfy a view.

## Module Dependencies

```text
Foundation
  ├── Project / Shell
  ├── Entity / Linking
  ├── Search / Command Palette
  └── Design System
          │
          ├── Characters
          ├── Locations
          ├── Calendar ──→ Timeline ──→ Chronicles
          ├── Manuscripts ──→ Scenes ──→ Arcs
          ├── Maps ──→ Locations
          └── Lore Map ←── everything
```

## Implementation Order

1. Foundation / shared shell
2. Calendar
3. Timeline
4. Entity linking
5. Characters
6. Locations
7. Manuscripts
8. Arcs
9. Maps
10. Lore Map
11. Secondary worldbuilding entities
12. Chronicles

Each module document defines **what it should do**, **how the user interacts with it**, **what data it owns**, **what it connects to**, and **what is explicitly out of scope**.
