# Pass 5 — Module Deep-Dive

> Focus: `lib/modules/` + the heavy feature widgets they delegate to. Coverage figures from `flutter test --coverage`.

---

## 5.1 Overlay: the module is a shell over fat widgets

`lib/modules/` holds 10 files but most "module behavior" lives in sibling widgets:

| Module | File (LOC) | Real implementation lives in |
|---|---|---|
| Magic | `magic_module.dart` (16, thin) | `widgets/magic_main_panel.dart` (1049), `magic_init_wizard.dart` (705+), `magic_list_pane.dart` (187), provider `magic_tree_provider.dart` (824) |
| Calendar | `calendar_module.dart` (16) | `widgets/calendar_picker.dart` (1388), `calendar_init_wizard.dart` (827), `calendar_main_panel.dart` (185), `calendar_list_pane.dart` (186), provider `calendar_tree_provider.dart` (986) |
| Timeline | `timeline_module.dart` (315) | `widgets/timeline_list_pane.dart` (178), provider `timeline_event_provider.dart` (217) |
| Species | `species_module.dart` (148, thin StatelessWindow) | `widgets/species_tree.dart` (1628), `species_wiki_article.dart` (1324), `species_details_edit_dialog.dart` (125), provider `species_provider.dart` (233) |
| Character | `character_module.dart` (**3797**) | mostly self-contained + `screens/trait_editor_screen.dart` (2211), `character_list_pane.dart` (94), `relation_chart_screen.dart` (1562) |
| Manuscript | `manuscript_module.dart` (1312) | 2026 rewrite — Quill editor orchestration (Pass 6) |
| Map | `map/` (`map_module.dart` + 3) | **ORPHANED** — a full map creator exists but is never wired; UI shows `lore_map_stub.dart` |

**Consistency finding:** the 3 "new-world" modules (Magic/Calendar/Species) all follow the **thin-module → fat-provider + fat-panel** pattern and are visually consistent; the **Character module is the anomaly** — one 3,996-line StatefulWidget still holds CRUD, tree, dialogs, relationships.

## 5.2 Character module (`character_module.dart`, 3,996 physical lines)

- Single `_CharacterModuleState` spans **lines 46–1023** (~25%): tree building, selection, deletion, renaming + ~600 lines of helper/dialog code below.
- Wired at `project_editor_screen.dart:592-601`; keeps a **`GlobalKey<_CharacterModuleState>`** (`_characterModuleKey`) so the shell can select/revert characters across module boundaries.
- `_handleRevert` (`:431-434`) restores a character from the history snapshot.
- Delegates editing to `screens/trait_editor_screen.dart` (2,211 lines) and relationship graph to `screens/relation_chart_screen.dart` (1,562 lines — a single StatefulWidget + dialog, correctly disposing animation/transform controllers at `:84-89`).
- **Tests: 0.2% coverage** (3/1,765 analyzed lines) — the least-tested large file in the app, and the module with the most user-facing CRUD.

## 5.3 World-building modules (Magic / Calendar / Timeline / Species)

All are Provider-driven; the four share a **shared `ReferenceEngine`** injected by the shell.

**Magic** — `magic_tree_provider.dart` (824): systems/nodes CRUD + selection; `magic_init_wizard.dart` (705+): guided creation. Coverage 0.5%/0.4% (init wizard 1/284 tested).

**Calendar** — `calendar_tree_provider.dart` (986, largest provider): systems, per-system nodes, attributes, `selectedSystem`; `calendar_picker.dart` (1388): calendar-aware date picker. Coverage 0% (tree provider 0/481) and picker 0/444.

**Timeline** — `timeline_module.dart` (315): tiered event timeline with calendar-system filter (shell wires `calendarTreeProvider.selectedSystem → timelineProvider.setSelectedSystemKey`, `project_editor_screen.dart:220-227`). Coverage 0%.

**Species** — the module was recently **rewritten as a thin 148-line StatelessWidget** (`species_module.dart`) delegating to `species_wiki_article.dart` (1324) + `species_tree.dart` (1628). The tree is Large custom painting; article is 5/439 covered (1.1%). The 4 root `.hex.txt` backups (Pass 1) are stale copies of the *old* species implementation — safe to delete.

## 5.4 Map module (orphaned)

`lib/modules/map/` contains a genuinely substantial map editor:
`map_editor_canvas.dart` (custom painting, layers), `map_layers_panel.dart`, `map_toolbar.dart`, plus `providers/map_provider.dart` (230).
**Nothing in `lib/` imports `MapModule`** — the Lore Map slot renders `lore_map_stub.dart`. `plan.md`+`implementation_todo.md` describe map work that partially predates this folder. Verdict: the map system is either (a) about-to-be-wired or (b) abandoned-but-untriaged; either way it must be wired to the `Module` slot or removed (Pass 9 decision item).

## 5.5 Pass 5 conclusions

1. **Character module is the top technical-debt hotspot**: 3,996-line StatefulWidget, 0.2% coverage; scheduled hit for the theory of "extract + test" (Pass 9 P1).
2. Magic/Calendar share a fat-provider template with near-identical provider code (824 vs 986 lines) — strong duplicate-copy smell; consolidate (Pass 9 P2).
3. Species module rewritten thin; its 4 stale `*.hex.txt` backups in the repo root should be deleted.
4. Map system is orphaned; needs an explicit product decision.
5. Only `manuscript_module` (39.6%), `manuscript_service`, and surrounding editor widgets have real coverage — a clear "Manuscript is the cared-for gem; everything else is scaffolding" signal.