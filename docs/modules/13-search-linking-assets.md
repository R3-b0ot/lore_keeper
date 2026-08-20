# Shared Search, Linking & Asset Systems

These are cross-module capabilities and should be implemented once, then consumed everywhere.

## Global Search

Search across:

- entity title;
- rich content;
- tags;
- properties;
- entity type;
- linked entities.

Results must show type, title, useful context and relationship metadata.

## Command Palette

Shortcut: `Ctrl+K` / `Cmd+K`.

Commands:

- navigate;
- search;
- create entity;
- create scene;
- create event;
- create relationship;
- open recent;
- focus mode;
- switch view;
- calendar/timeline actions.

Search and commands should share one indexing/navigation layer.

## Entity Linking

Rich text and metadata can reference entities through a quick picker. Typed references should use canonical `EntityRef` records.

Suggested interaction:

```text
@ → search entities → select → insert link
```

Clicking a link opens a preview first; explicit action opens the full workspace.

## Backlinks

Each entity exposes inbound references grouped by source type:

```text
Referenced by
├── Manuscripts
├── Scenes
├── Events
├── Characters
├── Locations
└── Other entities
```

## Assets

Project-level Asset records contain file references and metadata. Entities reference assets rather than duplicating files.

Assets support:

- image;
- document;
- map;
- concept art;
- reference material.

## Acceptance Criteria

A user can search the entire project, create/open anything from the command palette, link entities from rich text, inspect backlinks, and reuse one asset across multiple entities without duplicated canonical records.
