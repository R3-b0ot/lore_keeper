# Manuscripts Module

## Reference
Primary: Scrivener. Secondary: Campfire, Lore Forge, Plottr.

## Purpose
A structured writing environment where a manuscript is a hierarchy of documents/scenes rather than one giant editor.

## Core Model

```text
Manuscript
├── Binder nodes
│   ├── Folder / Part
│   ├── Chapter
│   └── Scene / Document
├── Collections
├── Metadata
└── References
```

A scene is independently addressable and linkable.

## Layout

```text
┌──────────────┬───────────────────────────┬──────────────┐
│ Binder       │ Editor                    │ Inspector    │
│              │                           │              │
│ Part 1       │ Scene content             │ Metadata     │
│  Chapter 1   │                           │ Characters   │
│   Scene 1    │                           │ Locations    │
│   Scene 2    │                           │ Events       │
│  Chapter 2   │                           │ Arc          │
└──────────────┴───────────────────────────┴──────────────┘
```

## Required Views

- Binder
- Editor
- Corkboard
- Outliner
- Collections
- Search
- Focus mode

## Binder Behavior

- drag/drop reorder;
- nested folders;
- collapse/expand;
- rename inline;
- duplicate only when explicitly requested;
- move scene without breaking links;
- show scene status/metadata subtly.

## Editor

The editor owns document content, not entity data. Inline entity links reference existing entities.

Support:

- headings;
- rich text;
- lists;
- quotes;
- links;
- entity mentions;
- images/assets;
- undo/redo;
- autosave.

## Scene Metadata

- title;
- status;
- POV character;
- characters;
- locations;
- timeline event(s);
- arc(s);
- tags;
- notes;
- word count;
- optional temporal position.

## Corkboard

Represent scenes as movable cards. Reordering cards changes the binder order. Cards show title, short synopsis, POV, status and key metadata.

## Inspector

Contextual, collapsible and editable. Never replace the editor unless the user intentionally enters a dedicated property editor.

## Cross-Module Connections

Scenes can link to Characters, Locations, Events, Arcs, Maps and Research. Entity pages expose manuscript appearances.

## Focus Mode

Hide navigation and nonessential chrome while preserving autosave and a keyboard escape/shortcut to return.

## Acceptance Criteria

A user can create a manuscript, build a hierarchy, write scenes, reorder them, link lore entities, inspect metadata, view scenes as cards, and return later with the exact structure/content intact.

## Out of Scope

- publishing pipeline;
- collaborative editing;
- full Scrivener file-format compatibility.
