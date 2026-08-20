# Secondary Worldbuilding Modules

This contract applies to Species, Cultures, Magic, Organizations/Factions, Items, Languages, Religions, Philosophies and Research.

## Product Rule
These are **entity types**, not separate applications. They should reuse the same entity workspace, inspector, linking, tags, assets, search and backlinks infrastructure.

## Common Workspace

```text
Header
├── Name / icon / image
├── Type / tags
└── Quick links

Content
├── Overview
├── Rich description
├── Properties
├── Relationships
├── Timeline
├── Locations
├── Manuscripts / Scenes
├── Assets
└── Notes
```

Sections vary by entity type but remain optional.

## Organizations / Factions

Support:

- members;
- leadership;
- parent organization;
- allies/enemies;
- territories;
- ideology;
- events;
- assets;
- history.

## Species

Support:

- taxonomy/classification;
- traits;
- lifespan;
- population/context;
- cultures;
- locations;
- characters;
- history;
- assets.

## Cultures

Support:

- values;
- customs;
- language;
- religion;
- locations;
- organizations;
- characters;
- historical development.

## Magic Systems

Support:

- rules;
- sources;
- limitations;
- users;
- artifacts;
- schools/types;
- historical events;
- related cultures.

Do not hardcode one RPG magic schema.

## Items

Support:

- description;
- creator;
- owner/current holder;
- origin;
- location;
- properties;
- events;
- images;
- history.

## Languages

Support:

- classification;
- speakers;
- regions;
- writing systems;
- related cultures;
- historical stages.

## Religions / Philosophies

Support:

- beliefs;
- practices;
- founders;
- followers;
- institutions;
- texts;
- locations;
- historical changes.

## Research

Research is a source/knowledge entity. Support:

- title;
- source type;
- URL/file reference;
- notes;
- tags;
- linked entities;
- citations;
- status.

## Acceptance Criteria

A user can create any secondary worldbuilding entity quickly, add rich information progressively, connect it to other lore, attach assets/sources, and discover it through search/backlinks/graph.

## Out of Scope

Do not build a unique CRUD architecture for every type. New types should mostly be configuration + specialized fields over the shared entity foundation.
