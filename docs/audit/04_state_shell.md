# Pass 4 — State Management & App Shell

> Sources: `lib/main.dart`, `lib/screens/project_editor_screen.dart`, `lib/providers/*` (10 files), `lib/widgets/project_editor/*`. Verified directly.

---

## 4.1 State-management stack: Provider (with a Riverpod hat)

- **Primary: `provider` package.** All 10 files in `lib/providers/` are `ChangeNotifier` subclasses; injection via `MultiProvider`/`ChangeNotifierProvider` in `main.dart`.
- **`flutter_riverpod` appears exactly once**: `main.dart:4` (`as riverpod`) wraps `MultiProvider` in `riverpod.ProviderScope` (`main.dart:58-60`). No Riverpod provider is used anywhere else in `lib/`. It is a vestigial wrapper.
- Per-AGENTS.md the directive is "consolidate on Provider" — the Riverpod scope is dead weight that should be removed (Pass 2).

## 4.2 Provider inventory

| Provider | LOC | Owns / state | Notes |
|---|---|---|---|
| `ThemeNotifier` (`theme_provider.dart`) | 102 | theme pack (minimal/dracula), mode, AA/AAA | Live chain; reads `Hive.box('settings')` directly (`:51`) |
| `ChapterListProvider` | 191 | chapters of a project, word count, reorder | Legacy chapter box |
| `CharacterListProvider` | 180 | character tree + referenceEngine purge integration | Purges stale references (`character_list_provider.dart:145-152`) |
| `LinkProvider` | 84 | relationship links | |
| `MagicTreeProvider` | 824 | magic systems tree, nodes | God-object-sized provider |
| `CalendarTreeProvider` | 986 | calendar systems, nodes, attributes, selection | **Largest provider; duplication with MagicTree pattern** |
| `TimelineEventProvider` | 217 | timeline events + selectedSystemKey | Wires to reference engine |
| `SpeciesProvider` | 233 | species tree (classification nodes) | |
| `ManuscriptBinderProvider` | 378 | manuscript document tree, collections, active doc | Highest-in-layer test coverage (35.9%) |
| `MapProvider` | 230 | map data | **ORPHANED** — no consumer (map module is stubbed; see 4.3) |

**Dependency-injection pattern:** providers are constructed in `ProjectEditorScreen.initState` (`project_editor_screen.dart:159-217`) with a **shared `ReferenceEngine`** passed by constructor (`:167-179`) — good seam: character, timeline, species, manuscript providers all share one index. This is the one part of the state layer that is genuinely well-designed.

## 4.3 App shell / project editor

- Entry: `DashboardScreen` (screens/dashboard) → `ProjectEditorScreen` via `Navigator.push`.
- 5 module slots (`_moduleItems`): Overview(0), Manuscripts(1), Characters(2), World Building(3), Lore Map(4).
- **Deep-link normalization** `_normalizeModuleIndex` (`:230-263`) maps legacy indices 0–15 (the old flat module list) to the new 0–4. All 16 old worldbuilding modules collapse to slot 3.
- Shared selection state: `_selectedChapterKey`, `_selectedCharacterKey`, `_selectedManuscriptDocumentId` — legacy chapter key ↔ new document id bridged in `_chapterKeyFromDocumentId` (`:372-378`) — a permanent two-key bookkeeping tax.
- **Reference navigation** `_onReferenceNavigate` (`:322-339`): only `TypeLabel == 'Character'` navigates (jump to module 2 + select). Location/Items/Orgs: "not yet implemented" (`:338`). Timeline/Species mentions resolve to nothing.

## 4.4 Layouts

- Desktop: `project_editor_desktop_layout.dart` (84 analyzed lines) — 3-column (sidebar, list pane, editor).
- Mobile: `project_editor_mobile_layout.dart` (55) — stacked/tabbed.
- `module_sidebar.dart` (87), `project_editor_module_resolver.dart`, `project_editor_module_resolution.dart`, `project_editor_actions.dart`, `project_editor_dialogs.dart` (73), `chapter_selection_dialog.dart`, `character_selection_dialog.dart`, `specific_functions_bar.dart` — the shell is small and decomposed well.
- The whole shell (`project_editor_screen.dart`, 372 analyzed LOC) is **0% covered** by tests and disposes 8 providers + a `QuillController` **but not `_manuscriptController`** (leak, see Pass 6/8).

## 4.5 Command palette / quick navigation

- **None.** No command-palette (`Ctrl+K`), no module-to-module jump UI beyond the sidebar tabs. The only cross-module jump is the reference click-through (`:331-336`). This is a product gap the roadmap may want (Pass 9).

## 4.6 World Building container

`world_building_tabs.dart` (213): 2 implemented columns, 1 tab strip of 14 `_WorldTab`s (index 0–13): Magic, Timelines, Calendars, Species implemented (switch at `:139-159`); **10 placeholder tabs** ("Coming soon — will be implemented in Phase 4", `:204`). TabController is properly disposed (`:91-95`).
- **14 tabs vs 4 modules**: the placeholder tabs (Locations, Languages, Items, Cultures, Philosophies, Religions, Systems, Research, Arcs, Relationships) are UI-only promises. The reference system labels (`location`, `item`, `organization`) are exactly these unimplemented domains — hence non-navigable mentions.

## 4.7 State-layer quality assessment

| Aspect | Verdict |
|---|---|
| Consistent Provider/ChangeNotifier pattern | ✅ single coherent idiom (Riverpod scope is vestigial) |
| Shared reference engine DI | ✅ excellent seam |
| God-object providers | ⚠️ `CalendarTreeProvider` 986 LOC, `MagicTreeProvider` 824 — closely parallel, likely copy-paste from one another (feature parity drift risk) |
| Provider robustness | ⚠️ no formal unit tests on 8/10 providers (Pass 8) |
| App-shell testing | ❌ `project_editor_screen.dart` 0% covered; module-resolution index mapping (16→5) untested |
| Leak discipline | ❌ `_manuscriptController` undisposed; `ReferenceEngine` + built `AiProvider` never disposed |

## 4.8 Pass 4 conclusions

1. State layer is idiomatic Provider; remove the dead Riverpod wrapper.
2. Calendar/Magic providers are siblings-by-copy — a refactor to one generic "tree provider" would halve the state layer (Pass 9 priority 2).
3. The shell leaks a QuillController and the shared AI/ReferenceEngine resources.
4. World Building is a 3.5/14 implemented area with 10 promised tabs — the largest functional gap masked by the tab strip.