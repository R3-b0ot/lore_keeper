# Lore Keeper UI Overhaul — Vibe Coder Guide

> **Audience:** Humans and agents implementing the UI overhaul.  
> **Status:** Planning / active  
> **Source of truth for product direction:** this folder + Figma Make export (`Overhaul Lore Keeper App`)

## Documents in this folder

| File | Purpose |
|------|---------|
| [00-README.md](./00-README.md) | This index |
| [01-vision-and-principles.md](./01-vision-and-principles.md) | Goals, references, non-goals |
| [02-navigation-and-modules.md](./02-navigation-and-modules.md) | Shell nav, Overview, Manuscripts, Characters, World Building |
| [03-theme-engine.md](./03-theme-engine.md) | Dual ThemePacks, Dracula/Alucard spec, community themes |
| [04-dashboard-and-book-opening.md](./04-dashboard-and-book-opening.md) | Dashboard reimagining + book-like project entry |
| [05-module-roadmap.md](./05-module-roadmap.md) | Enhanced module functionality and planned features |
| [06-implementation-phases.md](./06-implementation-phases.md) | Ordered work for vibe coding sessions |

## Quick decisions (locked)

1. **Top-level nav (project shell):** Overview · Manuscripts · Characters · World Building · Lore Map (optional/connectivity).
2. **World Building** absorbs Magic, Timeline, Calendar, Species, Locations, Languages, Items, Cultures, etc. as tabs or sub-sections.
3. **Theme packs are dual** (dark + light). First official dual pack: **Dracula Classic + Alucard Classic** (official Dracula Theme Spec).
4. **Fonts + colors exposed** for future community themes (VS Code–style marketplace later).
5. **Book-like opening** from Dashboard into a project is required UX — do not remove.
6. **UI reads tokens only** — no hard-coded palette in widgets.

## How to use these docs

- Start a session by reading `06-implementation-phases.md` for the current phase.
- When changing nav or modules, update `02-navigation-and-modules.md`.
- When touching theme, follow `03-theme-engine.md` and the Dracula Spec section there.
- Keep product decisions in these files so agents do not invent conflicting structure.
