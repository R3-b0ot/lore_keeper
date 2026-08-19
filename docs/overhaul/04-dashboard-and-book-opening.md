# Dashboard and Book Opening

## Dashboard (multi-project)

The Dashboard is **not** the in-project Overview. It is the library of projects.

### Must keep

- Ability to **create** and **open** projects.  
- **Book-like opening** transition when the user enters a project UI (existing custom experience).  
- Sense of “your shelf / your works” — not a generic empty Material scaffold.

### Reimagine (structure)

Move away from an oversized hero-only narrative toward a clearer hierarchy while staying on-brand:

1. **Header / identity** — app brand + optional global actions (settings, theme).  
2. **Primary actions** — New Project, Browse / Open.  
3. **Recent projects** — cards or row with cover, title, last edited, progress.  
4. **Full project list** — searchable table or grid for larger libraries.  
5. **Optional** — pinned projects, stats across all works (later).

Use **theme tokens** for all surfaces (so Dracula/Alucard and future packs apply). Avoid hard-coded purple gradients; if a gradient remains, it should come from pack extensions or neutral elevation.

### Book-like opening (required)

When the user chooses a project:

1. Dashboard initiates the existing (or refined) **book / cover opening** animation or transition.  
2. Destination is the **project shell** with **Overview** as the default section (not a random module).  
3. Transition must feel intentional — “opening the book” — not a bare `Navigator.push` only.

Implementation notes for vibe coders:

- Locate current book-opening / cover / project-book widgets under `lib/widgets/project_book/` and dashboard flow.  
- Preserve the ritual; polish timing/assets if needed; wire destination to Overview.  
- Do not remove this path when simplifying the Dashboard layout.

## Overview (in-project module)

New top-level section after open:

- Project title, genre/author, last edited.  
- Stats: words, character count, locations, timeline events (whatever data exists).  
- Recent manuscripts / recent activity.  
- Quick navigate to Manuscripts, Characters, World Building, Lore Map.  
- Optional: word-count progress toward target.

Overview is the calm “desk” inside the book; Dashboard is the “shelf.”

## Relationship diagram

```text
Dashboard (shelf)
    │  book-like opening
    ▼
Project shell
    ├── Overview          ← default landing
    ├── Manuscripts
    ├── Characters
    ├── World Building
    └── Lore Map
```
