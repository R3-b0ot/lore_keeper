# Lore Map Module

## Reference
Obsidian for connectivity philosophy; LegendKeeper for worldbuilding-first presentation.

## Purpose
Lore Map is a visual graph of the project's knowledge, not a replacement for entity pages.

## Nodes

Any linkable entity may become a node:

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

## Edges

Examples:

- related-to;
- appears-in;
- located-in;
- member-of;
- rules;
- practices;
- founded-by;
- created-by;
- participated-in;
- occurs-at;
- caused-by;
- follows/precedes.

## Main Interaction

```text
Search / Filters
      ↓
Graph Canvas
      ↓
Selected Node → Inspector
```

- pan/zoom;
- select node;
- open entity;
- expand connected nodes;
- hide/show edge types;
- filter by entity type/tag;
- focus selected entity;
- reset layout.

## Backlinks

Every entity should expose incoming references independently of graph view. Lore Map is one presentation of those references.

## Layouts

Start with automatic force/tree layouts. Later support saved layouts and manually positioned nodes.

## Performance

Do not render the entire project graph by default for very large projects. Start with selected entity + neighborhood and allow expansion.

## Acceptance Criteria

A user can start from any entity, discover related lore visually, filter the graph, inspect a node, and jump directly into the canonical entity workspace.

## Out of Scope

- general-purpose whiteboard;
- arbitrary drawing canvas;
- replacing rich-text linking.
