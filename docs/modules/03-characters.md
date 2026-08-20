# Characters Module

## Reference
Campfire + Lore Forge + LegendKeeper.

## Purpose
Manage people as rich, connected entities rather than static forms.

## Main View

Default: searchable card/grid view.

Each card shows:

- portrait;
- name;
- short role/descriptor;
- key tags;
- optional status.

Views: Cards, List, Timeline appearances, Relationships.

## Character Workspace

```text
Overview
Identity
Appearance
Personality
History
Relationships
Timeline
Locations
Manuscript Appearances
Assets
Notes
```

Sections are optional and collapsible.

## Behavior

- Create quickly with name + optional portrait.
- Add details progressively.
- Never require completion of a giant form.
- Autosave edits.
- Support tags and custom properties.
- Search title, content, tags and properties.
- Duplicate only as an explicit action.

## Relationships

Relationships are first-class records. A character can have typed relationships to characters, organizations, locations and other entities. Relationship metadata may include notes and temporal validity.

## Timeline

Show linked historical events and allow filtering by character. Do not create copies of events.

## Manuscripts

Show scenes where the character is referenced/linked. Clicking a scene opens it without losing the character context.

## Assets

Portraits and concept art reference project assets. Avoid storing duplicate files per character.

## Inspector

The inspector should provide quick editing for common fields and links. Deep content remains in the character workspace.

## Acceptance Criteria

A user can create a character in seconds, progressively build a rich profile, connect relationships, see timeline and manuscript appearances, attach assets, search it, and navigate to every connected item.

## Out of Scope

- automatic biography generation;
- rigid RPG/stat-sheet assumptions;
- separate relationship data duplicated inside each character.
