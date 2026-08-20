# Relationships Module

## Purpose
Make relationships first-class, reusable, inspectable and optionally time-aware.

## Model

```text
Relationship
├── id
├── projectId
├── fromEntity
├── toEntity
├── type
├── label
├── direction
├── notes
├── metadata
├── validFrom
└── validTo
```

## Behavior

- choose two entities;
- choose or create relationship type;
- optionally set direction;
- add notes/properties;
- optionally define temporal validity;
- save one relationship record;
- expose it from both entities.

Do not store independent duplicated relationship records on each endpoint.

## Relationship Types

Support flexible user-defined types while providing useful defaults:

- parent/child;
- sibling;
- spouse/partner;
- friend;
- rival;
- enemy;
- member-of;
- rules;
- located-in;
- created-by;
- allied-with;
- associated-with.

## Views

- relationship list;
- entity relationship section;
- graph view;
- timeline-aware relationship view later.

## Timeline

A relationship may change over history. Temporal validity is optional and should use the shared Temporal Engine.

## Acceptance Criteria

Creating a relationship from either entity creates one canonical record, visible from both sides, searchable, graphable and optionally time-aware.

## Out of Scope

- hardcoded relationship schemas per entity type;
- duplicated bidirectional records.
