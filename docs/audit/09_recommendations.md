# Pass 9 — Recommendations

> Consolidated, evidence-backed action plan prioritized by impact/effort. Every item traces to a Pass.

## P0 — Do these first (they block or poison trust)

1. **Repair the codegen build pipeline.** `dart run build_runner build` deletes all 15 tracked `.g.dart` files and writes 0 outputs; 4 adapters are hand-written because of a "pre-existing version conflict" (`database_metadata.dart:84-87,143-147,230-235`). Fix the dependency conflict, and decide: go fully generated (gitignore `.g.dart`, guarantee `build_runner` works) **or** keep committed outputs (never run bare `build_runner`, document it). Currently the build is a landmine for any `@HiveField` change. *(Sources: Pass 1 §1.7, Pass 3 §3.3/3.4, Pass 8 §8.4)*
2. **Delete the 9 tracked root-junk files** (`')`, `normalizeName(name)`, four `*.hex.txt`, `analysis.txt`, `_build_runner.txt`, `SUMMARY.md`). All verified stale/unneeded (Pass 1 §1.5). `git rm` then commit — zero risk.
3. **Fix the three resource leaks in the app shell:** dispose the undisposed `QuillController _manuscriptController` (`project_editor_screen.dart:77,579`; `dispose()` at 417-429) and the shared `ReferenceEngine`/`AiProvider` (`:166-174`). *(Pass 6 §6.7, Pass 8 §8.5)*

## P1 — Manuscript/editor correctness (high user value)

4. **Fix manuscript history visibility:** manuscript saves write `targetType: 'ManuscriptDocument'` (`manuscript_module.dart:633-638`) but the panel filters `'Chapter'` with legacy key (`project_editor_screen.dart:665-679`). Unify on document id + type; update `history_panel.dart` diff viewers to handle manuscript docs (port `ChapterDiffViewDialog` → document-based). *(Pass 6 §6.4)*
5. **Consolidate word/char counting:** three divergent implementations (editor plain-text `manuscript_module.dart:576-585`; JSON-regex+JSON-length `manuscript_binder_service.dart:246-247,551-559`; migration `database_manager.dart:437-447`). One shared plain-text counter, used everywhere; recompute stored counts. *(Pass 6 §6.2)*
6. **Fix Find & Replace** in `find_replace_dialog.dart`: stop iterating a stale plain-text snapshot (`:85-111` — offset drift), and preserve `ref:`/formatting attributes when replacing (`:56-83`). *(Pass 6 §6.5)*

## P2 — World-building & state consolidation

7. **Product decision: the 10 placeholder World-Building tabs** (Locations, Languages, Items, Cultures, Philosophies, Religions, Systems, Research, Arcs, Relationships) — either scope them into a v1 release (start with Locations/Languages, since reference entity types exist for them) or remove the tabs + placeholder text. Align reference resolution (`reference_name_resolver.dart:80-84`) and navigation (`project_editor_screen.dart:338`) with whatever ships. *(Pass 4 §4.6, Pass 6 §6.3)*
8. **Map module decision:** wire the orphaned real `lib/modules/map/` map editor into the Lore Map slot **or** remove it while stubbed. *(Pass 5 §5.4)*
9. **De-duplicate the two fat tree providers** (`calendar_tree_provider.dart` 986 vs `magic_tree_provider.dart` 824) into one generic tree/CRUD provider; identical shape, copy-paste drift risk. *(Pass 4 §4.7, Pass 5 §5.3)*
10. **Break up `character_module.dart`(3,996 lines)** + `relation_chart_screen.dart`(1,562) into extracted widgets/states, mirroring the thin-module pattern used by Magic/Calendar/Species. *(Pass 5 §5.2)*

## P3 — Theme & consistency

11. **Resolve the half-done theme refactor.** Live chain = `MinimalThemePack → legacy AppTheme`; the `ThemeController`/`themeFromController` facade is dead (`core/theme/app_theme.dart:22-31`, zero callers), Dracula unreachable. Either finish (activate controller, port AppTheme palettes → color tokens, delete legacy `lib/theme`) or delete the dead facade/adapters and keep the legacy path. *(Pass 7 §7.1)*
12. **Make the AA/AAA claim verifiable** — add a contrast test against all token pairs, or soften docs. Right now it's palette-assumed, unmeasured. *(Pass 7 §7.2)*
13. **Theme pass on `project_book/*`** (120 hard-coded `Color(0x)` in `genre_glow.dart`, 39 in demo screen, 11 in `project_book_view.dart`). *(Pass 7 §7.3)*

## P4 — Dependencies & hygiene

14. **Remove `cupertino_icons`** (0 imports) and the vestigial `riverpod.ProviderScope` in `main.dart` (0 riverpod providers; consolidate on Provider per AGENTS.md). *(Pass 2 §2.5)*
15. **Planned upgrades:** `file_picker 8→13` (major), `xml 6→7`, `flutter_quill_extensions 11.x→11.6.x` — each with a test run first. *(Pass 2)*
16. **Replace the 21 `debugPrint` calls** with `debug_logger.dart` (or delete), and consider tightening `analysis_options.yaml` (`avoid_dynamic_calls`, `public_member_api_docs`) so AGENTS.md standards stop being advisory-only. *(Pass 8 §8.1/§8.5)*

## P5 — Test coverage roadmap

17. Target: raise total coverage toward ~50% in this order (cheap wins from mapper services → big-ROI shell/widgets):
    a. `project_editor_screen` module-index normalization (15→5 mapping `:230-263`) + `_onReferenceNavigate` — pure logic, high value, currently 0% *(Pass 4 §4.3, Pass 8 §8.7)*
    b. `calendar_tree_provider`/`magic_tree_provider` CRUD (add a shared provider test harness) *(Pass 8 §8.3)*
    c. `settings` panes (1.3%) and `global_settings_controller` (0/208) *(Pass 8 §8.3)*
    d. `relation_chart_screen`/`trait_editor_screen` widget tests (0%) *(Pass 8 §8.3)*
    e. `character_module` (0.2%) at the state level *(Pass 8 §8.3)*
18. Add a pre-commit/CI gate: `flutter analyze` + `flutter test` (and treat the `.g.dart`-registration state as a prerequisite). *(Pass 1, Pass 8)*

## Non-code

19. **Docs drift:** update `README.md`/`AGENTS.md` to describe the *actual* architecture (models→database→services→providers→modules→widgets; screenshot/tree map in Pass 1 §1.2) — or commit fully to the documented Clean Architecture (large, separate work). *(Pass 1 §1.2)*
20. Replace/retire stale `plan.md`, `implementation_todo.md`, `TODO.md`, `cleanup_todo.md` with this audit set as the single source of truth for follow-ups. *(Pass 1 §1.4)*

### Sequencing suggestion
P0 (1-3) → P1 (4-6) → tests for the shell + one provider (P5-a/b) so each P1 change lands with coverage → P2 decisions → P3/P4 tidy-up → remaining P5.