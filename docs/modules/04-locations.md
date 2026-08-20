# Locations Module

## Reference
Campfire + LegendKeeper.

## Purpose
Represent places as flexible hierarchical entities that can appear in maps, manuscripts and history.

## Hierarchy

```text
World
└── Continent
    └── Country
        └── Region
            └── City
                └── Building
                    └── Room
```

Hierarchy is optional; a location can exist independently.

## Location Workspace

- Overview / description
- Images/assets
- Parent/children
- Inhabitants
- Organizations
- Events
- Maps
- Travel/connections
- Tags/properties
- Notes

## Main View

Use a compact tree/list plus searchable cards where useful. The hierarchy should be easy to browse without forcing a tree-only interface.

## Behavior

- create location quickly;
- drag to change parent where valid;
- prevent circular parentage;
- preserve links when moving a location;
- archive rather than silently delete linked locations;
- show backlinks and related entities.

## Map Integration

A location can have one or more map pins. Pin records reference the location rather than embedding location data.

## Timeline Integration

Show events occurring at the location and allow opening them in Timeline.

## Manuscript Integration

Show scenes linked to the location.

## Acceptance Criteria

A user can build a world hierarchy, move places safely, connect inhabitants/events/maps/scenes, search locations and inspect the complete network around a place.

## Out of Scope

- procedural world generation;
- full GIS;
- automatic geography simulation.
