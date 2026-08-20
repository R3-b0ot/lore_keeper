# Arcs Module

## Reference
Plottr, with manuscript integration from Scrivener.

## Purpose
Plan story structure visually without duplicating manuscript scenes.

## Model

```text
Arc
├── title / description
├── type
├── color
├── status
├── scenes
├── characters
├── events
└── notes
```

## Main View

Plot-board style horizontal/vertical lanes containing scene cards.

## Scene Card

Show:

- scene title;
- chapter/manuscript;
- short synopsis;
- POV;
- primary characters;
- location;
- status;
- arc membership.

## Behavior

- drag scene cards to reorder narrative sequence;
- drag between plotlines/arc lanes;
- create a scene from a card;
- open the actual manuscript scene from the card;
- filter by character, location, arc, tag, chapter and status;
- zoom/scroll across long stories.

Reordering must modify the canonical manuscript structure or scene ordering, not a duplicate Arc-only copy.

## Character Arcs

A character can participate in multiple arcs. Character arc views are filters/lenses over scenes rather than duplicate scene collections.

## Timeline Connection

Scenes can optionally have temporal placement or link to world events. Arc planning should never invent a second chronology system.

## Acceptance Criteria

A user can visually plan a story, move scenes, see subplot/character arcs, filter the board, and jump directly to the underlying manuscript scene.

## Out of Scope

- automatic story generation;
- AI plot scoring;
- separate duplicate scene database.
