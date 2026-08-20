# Chronicles Module

## Priority
P2 / endgame feature. Build only after Calendar, Timeline, Maps and Entity Linking are stable.

## Reference
World Anvil Chronicles is the primary conceptual reference: historical events connected to time and interactive geography.

## Purpose
A Chronicle is a **historical narrative lens** combining:

> Time + Event + Location + Characters + Factions + Map State + Story Context

It is not a second event database.

## Core Model

```text
Chronicle
├── title
├── description
├── timeline/filter configuration
├── map configuration
└── event sequence / view settings
```

Events remain canonical Timeline entities.

## Main Layout

```text
┌───────────────────────────────────────────────────────┐
│ Chronicle toolbar / filters                            │
├──────────────────────────────┬────────────────────────┤
│ Timeline                     │ Map                    │
│                              │                        │
│ Event A ────────────────●────┤ Location A             │
│ Event B ───────────────●─────┤ Location B             │
│ Event C ───────────●─────────┤ Location C             │
├──────────────────────────────┴────────────────────────┤
│ Selected event / contextual inspector                 │
└───────────────────────────────────────────────────────┘
```

## Scrubbing

Moving through time updates the visible map state and event context.

The first implementation may simply filter events and highlight locations. Later versions can apply historical map state snapshots.

## Event Context

For the selected event show:

- date/range;
- narrative;
- characters;
- factions;
- location;
- linked scene/manuscript;
- related events.

## Historical Map States

Future map objects may define temporal validity:

```text
Border A
valid: Year 100–140

Border B
valid: Year 140–210
```

Chronicle playback selects objects valid at the current temporal coordinate.

## Filters

- character;
- faction;
- location;
- arc;
- event type;
- tag;
- era;
- date range.

## Acceptance Criteria

A user can choose a period, see what happened, who was involved, where it happened, and navigate the relevant map context while preserving the canonical Timeline and Map data.

## Out of Scope for V1

- full simulation of geopolitical change;
- automatic terrain evolution;
- duplicate Chronicle-specific events;
- real-time collaboration.
