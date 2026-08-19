# Implementation Phases

Ordered for vibe coding. Finish or stabilize a phase before expanding scope.

## Phase 0 — Docs + Theme foundation

**Done when:** Dual ThemePack API exists; Dracula (Classic + Alucard) and Minimal registered; app selects themes only via registry; fonts/colors exposed on pack interface.

- [x] Overhaul MD docs in `docs/overhaul/`  
- [ ] `ThemeColorTokens`, `ThemeFontTokens`  
- [ ] `ThemePack` dual dark/light contract  
- [ ] `DraculaThemePack` from official spec  
- [ ] `MinimalThemePack` wraps current defaults  
- [ ] Registry registers both; bootstrap updated  
- [ ] `main.dart` / ThemeNotifier: no Dracula special-case  
- [ ] ThemeExtensions expose full tokens if needed  

## Phase 1 — Project shell navigation

**Done when:** Inside a project, top-level nav is Overview | Manuscripts | Characters | World Building (| Lore Map stub).

- [ ] Sidebar shell using theme tokens  
- [ ] Overview module (new) as default post-open landing  
- [ ] Manuscripts and Characters remain reachable top-level  
- [ ] World Building hosts former modules as tabs  
- [ ] Wire existing panes into World tabs without behavior regression  

## Phase 2 — Dashboard + book opening

**Done when:** Dashboard layout is reimagined; book-like opening still runs and lands on Overview.

- [ ] Simplify Dashboard hierarchy (actions, recent, list)  
- [ ] Token-based colors (works under Dracula/Alucard/Minimal)  
- [ ] Preserve / refine book-opening → project shell → Overview  
- [ ] Create project / browser flows still work  

## Phase 3 — Manuscripts & Characters UX

**Done when:** Both match the simplified, reference-inspired patterns and remain pack-agnostic.

- [ ] Manuscripts: list + editor chrome cleanup; link-entity affordance  
- [ ] Characters: card grid + inspector detail  
- [ ] Shared list/card/inspector components  

## Phase 4 — World Building depth (first pass)

**Done when:** Magic, Timeline, Calendar, Species, Locations usable under World with clearer UI.

- [ ] Tab shell polish  
- [ ] Magic cards / systems UI  
- [ ] Timeline list + basic canvas improvements  
- [ ] Locations + species list/detail consistency  

## Phase 5 — Connectivity

- [ ] ⌘K global search  
- [ ] Lore Map graph v1  
- [ ] Stronger linking from manuscript editor  

## Phase 6 — Theme engine (community-ready)

- [ ] Pack manifest format (JSON/folder)  
- [ ] Load external dual pack (colors + font families)  
- [ ] Document how to author a community theme  
- [ ] (Later) gallery / import UI  

## Phase 7+ — Roadmap features

- Corkboard / outliner for Manuscripts  
- Chronicles-style timeline ↔ map  
- Plottr-like arcs  
- Map pins depth (Inkarnate/LK)  

---

## Session checklist (every vibe session)

1. Read this file — which phase is active?  
2. Read the relevant doc (02 nav, 03 theme, 04 dashboard, 05 roadmap).  
3. Prefer tokens over raw colors.  
4. Do not drop book-opening or dual-pack rule.  
5. Update checkboxes in this file when a slice lands.  
6. `flutter analyze` clean before calling a slice done.
