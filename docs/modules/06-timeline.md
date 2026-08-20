# Timeline Module

## Priority
P0. Timeline is the visual history workspace and must consume the shared Temporal Engine.

## Reference
Aeon Timeline for canvas mechanics; Plottr for narrative filtering; World Anvil for world history.

## Event Model

An event contains:

- title;
- description/lore;
- temporal range;
- date precision;
- certainty;
- calendar + calendar version;
- duration/range;
- linked characters;
- linked locations;
- linked organizations/factions;
- linked manuscript scenes;
- linked arcs;
- tags;
- icon/color;
- assets.

## Views

1. **Canvas** — zoomable horizontal chronology.
2. **List** — dense searchable event list.
3. **Calendar** — day/month/year presentation where precision permits.
4. **Chronicle** — readable sequential history.
5. **Range/Gantt** — duration-focused visualization.

All views use the same event records.

## Canvas

Semantic zoom:

```text
World → Era → Century/Decade → Year → Month → Week → Day
```

Do not merely scale the same cards down. Change information density at each level.

## Event Rendering

Point events render as milestones. Ranged events render as spans/bars. Approximate events show uncertainty visually. Events without exact day precision must not pretend to be exact.

## Lanes / Grouping

Group by:

- era;
- character;
- location;
- faction;
- arc;
- custom group.

## Inspector

Right-side inspector handles event editing, date/range, links, tags, lore and visual properties.

## Interaction

- drag event to change date when precision allows;
- resize range to change duration;
- create by clicking/dragging on the timeline;
- multi-select for bulk changes;
- zoom with wheel/pinch;
- pan horizontally;
- keyboard shortcuts for create/search/zoom.

Every drag operation must validate the resulting temporal value before persisting.

## Filtering

Filter by calendar, character, location, faction, arc, manuscript, tag, certainty and date range.

## Minimap

A compact full-history context navigator shows the current viewport and allows rapid navigation.

## Cross-Calendar Behavior

Events use a universal temporal coordinate internally. Calendar-system key order must never determine chronology.

## Acceptance Criteria

A user can create exact, approximate and ranged events, drag them through history, zoom from eras to days, filter by world entities, inspect details and see the same event consistently in every timeline view.

## Out of Scope

- project-management task timelines;
- fake cross-calendar ordering without an epoch/coordinate;
- independent date math inside UI widgets.
