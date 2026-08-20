# Calendar Module

## Priority
P0. Calendar is the authoritative authoring system for fictional calendar rules.

## Reference
World Anvil for custom calendars; Campfire/LegendKeeper for approachable editing.

## Core Rule
The editable tree is the authoring representation. A validated `CalendarDefinition` is compiled from it. Timeline events must reference a calendar version so later edits cannot silently change historical meaning.

## Workspace

```text
Calendar Selector
        ↓
Calendar Overview
├── Calendar Structure
├── Eras
├── Months
├── Week / Days
├── Seasons
├── Holidays
└── Rules / Validation
```

## Calendar Definition

Must support:

- name;
- year length/rules;
- months and lengths;
- weekdays/week structure;
- weekend definitions;
- leap rules;
- eras and boundaries;
- seasons and date ranges;
- holidays/festivals;
- epoch/anchor;
- version.

## Editing

The existing wizard remains the onboarding path, but the main calendar editor must support incremental editing afterward.

Changes require validation before commit.

## Validation

Detect:

- month lengths not matching configured year rules;
- invalid leap rules;
- duplicate/invalid month names where prohibited;
- invalid era boundaries;
- season ranges that overlap incorrectly;
- impossible dates;
- dependent timeline events affected by changes.

## Versioning

If events depend on the active definition, create a new version instead of mutating the historical definition in place.

```text
Calendar v1 → existing events
Calendar v2 → new events / migrated events
```

## Date Operations

The domain engine must provide validation, date arithmetic, day-of-year, week, season, era and formatting calculations. Widgets must not implement date math.

## Timeline Integration

Calendar supplies date interpretation. Timeline supplies event visualization. Neither should duplicate the other's domain logic.

## Acceptance Criteria

A user can define an unusual fictional calendar, validate it, edit it safely after events exist, understand affected events, and use the resulting dates reliably in Timeline.

## Out of Scope

- real-world timezone handling;
- astronomical simulation beyond explicit calendar rules;
- replacing the calendar tree with an uneditable generated model.
