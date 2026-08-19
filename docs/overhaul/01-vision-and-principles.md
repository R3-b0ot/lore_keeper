# Vision and Principles

## Product

Lore Keeper is an offline-first creative writing and world-building app (Flutter). Authors manage manuscripts, characters, and deep lore in one place with strong linking between entities.

## Overhaul goals

1. **Simplify the shell** without dumbing down capability.
2. **Modern, calm UI** inspired by LegendKeeper, Lore Forge, Scrivener, Campfire, and the Figma Make prototype — content over chrome.
3. **Theme engine path** so community dual themes (colors + fonts) can load later, similar in spirit to VS Code themes.
4. **Keep proven UX:** Dashboard project home, book-like entry into a project, Manuscripts, Characters, rich world modules.
5. **Increase module depth** using best patterns from reference apps (not a clone of any single one).

## Reference apps (use for patterns, not copies)

| App | Borrow |
|-----|--------|
| **LegendKeeper** | Unified shell, elements + tabs, calm dark UI, maps/timelines/boards as views |
| **Lore Forge** | Simple entity UI, writing-focused, unobtrusive chrome, assets on entities |
| **Campfire** | Module taxonomy for world-building domains |
| **Scrivener** | Manuscript as structured project (binder / corkboard / outliner mindset) |
| **Plottr** | Arcs, scene cards, plotlines |
| **Aeon Timeline** | Timeline canvas mechanics |
| **World Anvil Chronicles** | Event = time + place + people + factions (visual history) |
| **Obsidian** | Connectivity philosophy (links, backlinks, tags, search) — not full PKM UI |
| **Inkarnate** | Map module interaction quality |
| **Figma Make prototype** | Concrete layout: sidebar, Overview, Manuscripts, Characters, World tabs, Lore Map |

## Principles

- **Tokens over hex in widgets** — ThemePack supplies colors/fonts; UI consumes `ThemeData` / extensions.
- **Dual packs only** — every theme defines dark *and* light.
- **Dracula fidelity** — the Dracula pack follows the official Dracula Theme Spec (Classic + Alucard).
- **Book entry stays** — opening a project from the Dashboard retains a deliberate “opening the book” transition into the project UI.
- **Overview is first-class** — project home inside the shell (stats, recent work, navigate), distinct from the multi-project Dashboard.
- **World Building is the catch-all** — non-manuscript, non-character domains live under one top-level area with internal tabs/sections.
- **Plan ahead** — module roadmap documents enhanced features even if implementation is phased.

## Non-goals (this overhaul)

- Turning Lore Keeper into a pure wiki or pure PKM tool.
- Cloud-first collaboration as a prerequisite (offline-first remains).
- Shipping a full community theme marketplace in phase 1 (only the *hooks* and pack format).
- Removing Manuscripts or Characters as top-level destinations.
