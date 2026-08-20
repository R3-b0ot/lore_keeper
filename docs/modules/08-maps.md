# Maps Module

## Reference
Inkarnate for map interaction and visual polish; LegendKeeper/Campfire for linked worldbuilding.

## Purpose
Maps are spatial lenses over Lore Keeper entities, not a standalone cartography product.

## Phase 1

- import/upload map image;
- pan/zoom;
- pin entities;
- pin icon/color;
- pin labels;
- layers;
- annotations;
- nested maps;
- map metadata.

## Phase 2

- regions;
- paths/routes;
- shapes;
- measurement;
- grouped layers;
- visibility rules;
- map snapshots.

## Phase 3

- historical map states;
- timeline-linked map state;
- Chronicle playback.

## Layout

```text
Toolbar
├── Select
├── Pan
├── Pin
├── Region
├── Path
├── Measure
└── Layers

Canvas

Inspector
└── Selected map object/entity
```

## Pin Model

A pin contains position + presentation + `EntityRef`. It must not copy the entity's description/name as canonical data.

Possible linked types:

- Location;
- Character;
- Organization;
- Event;
- Item;
- custom entity.

## Interaction

- pan/zoom smoothly;
- click pin to inspect entity;
- double-click entity to open its workspace;
- drag pin to reposition;
- multi-select map objects;
- toggle layers;
- fit map to viewport;
- search map entities.

## Nested Maps

A location may link to a more detailed map. Navigation should preserve breadcrumb context.

## Chronicle Readiness

Map objects must have stable IDs and support optional temporal validity so historical states can be introduced later without redesigning the pin model.

## Acceptance Criteria

A user can upload a map, navigate it fluidly, place linked pins, organize layers, open world entities directly from the map, and nest maps.

## Out of Scope

- competing with Inkarnate's complete map generation/editor suite;
- procedural terrain generation in the first version;
- GIS coordinate systems unless explicitly required later.
