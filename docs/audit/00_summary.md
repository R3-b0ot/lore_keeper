# Lore Keeper — Full Audit Summary (Passes 1–9)

> Read-only audit of the Flutter pre-alpha creative-writing app at `E:\lore_keeper`. Executed 2026-09-20.
> Per-pass detail: `docs/audit/01_inventory.md` … `docs/audit/09_recommendations.md`.

## Headline numbers

| Metric | Value |
|---|---|
| Analyzer | **Clean** (`flutter analyze`: "No issues found!") |
| Tests | **377 passing / 0 failing** (25 files, 6,220 src lines) |
| Test coverage | **15.7%** (2,963 / 18,828 lines) — world-building + screens at 0% |
| Storage | Hive, 19 boxes, `currentSchemaVersion = 3`, stepped V1→V2→V3 migrations |
| Largest file | `modules/character_module.dart` — 3,996 lines (0.2% covered) |
| Build codegen | **BROKEN in practice** — bare `build_runner` deletes all `.g.dart` files |
| Root debris | 9 junk files tracked in Git at repo root |

## What's genuinely good (the app's core strengths)

1. **The 2025–2026 manuscript/editor/reference/AI pipeline is the crown jewel.** `ManuscriptDocument` (86.7% cov), `ManuscriptBinderService` (55.9%), the attribute-based `ref:TypeLabel:id` mention engine (autocomplete controller 97.2%, engine 92.6%, overlay 93.4%, name matcher 92.6%), and the AI providers (94–100%) are well-engineered **and** well-tested. Backlinks extraction is real and works.
2. **Schema versioning + stepped migrations** (`database_manager.dart:244-264`, V2→V3 chapter→document migration at `:295-435`) — rare quality for this stage of a project.
3. **DI seam**: shell constructs a single shared `ReferenceEngine` and injects it into character/timeline/species/manuscript providers (`project_editor_screen.dart:166-216`) — clean.
4. **Analyzer clean + full suite green**: the code compiles warning-free, and 377 tests exercise the pipeline.

## What's most at risk (answers to "what should we work on")

1. **Build/codegen is a landmine (P0).** `dart run build_runner build` wiped 15 checked-in `.g.dart` files (restored via `git restore`); 4 Hive adapters are handwritten because of a dependency conflict (`database_metadata.dart:84-87`). Any model change, or any contributor running build_runner, silently breaks boxes + tests.
2. **The shell leaks engine/editor resources (P0).** Undisposed `QuillController` (`project_editor_screen.dart:77`, missing from `dispose()` at 417-429), undisposed `ReferenceEngine`+`AiProvider` (`:166-174`).
3. **Manuscript history is secretly broken (P1).** Docs save with `targetType:'ManuscriptDocument'` + document id; the history panel reads `'Chapter'` + legacy key → revisions recorded but never shown (`manuscript_module.dart:633-638` vs `project_editor_screen.dart:665-679`).
4. **Word/character counts diverge 3 ways** (plain-text vs raw-JSON regex vs JSON-length) — inconsistent numbers in UI between saves. (`manuscript_module.dart:576-585`, `manuscript_binder_service.dart:551-559`, `database_manager.dart:437-447`)
5. **Find & Replace is attribute-destructive + offset-drifting** (`find_replace_dialog.dart:56-111`) — strips `ref:` mentions during replace.
6. **World Building is 4 of 14 tabs.** Magic/Timeline/Calendar/Species exist; Locations/Languages/Items/Cultures/Philosophies/Religions/Systems/Research/Arcs/Relationships are "Coming soon" placeholders, and the reference system's own entity labels for them are non-navigable/non-resolvable (`reference_name_resolver.dart:80-84`, `project_editor_screen.dart:338`).
7. **The map editor is orphaned.** A full `lib/modules/map/` creator exists but the UI shows `lore_map_stub.dart`. Needs a wire-or-delete decision.
8. **Theme "refactor" is half-dead.** Live path = `MinimalThemePack` wrapping legacy `AppTheme`; `ThemeController`/`core/theme/app_theme.dart` facade has zero callers; Dracula pack unreachable. AA/AAA is palette-assumed, never measured.
9. **Coverage is a staircase**: everything new tested (to 68.7% in database), everything old at zero — `character_module` 0.2%, all screens 0%, providers 0-36%.

## The 3-vote "first things"

- **P0–1:** fix the build_runner/codegen situation and delete the 9 root junk files.
- **P0–3:** dispose the QuillController/engine leaks.
- **P1–4:** unify history targetKey/targetType so manuscript history is visible.

Full prioritized plan with 20 items and effort hints: `09_recommendations.md`.

## Quick-reference: pass map

| Pass | Doc | Scope |
|---|---|---|
| 1 | `01_inventory.md` | Tree, LOC, module/arch map, tool runs, codegen incident |
| 2 | `02_dependencies.md` | deps, `pub outdated`, platform surface |
| 3 | `03_data.md` | 19 boxes, schema v3, migrations, typeIds, adapters |
| 4 | `04_state_shell.md` | Provider inventory, shell routing, layouts, World-Building 3.5/14 |
| 5 | `05_modules.md` | character/magic/calendar/timeline/species/map deep-dives |
| 6 | `06_editor.md` | Quill integration, mention engine, history, find-replace, grammar |
| 7 | `07_ui_theme.md` | dual theme path, AA/AAA, hard-coded color counts |
| 8 | `08_tests_quality.md` | 377 tests, 15.7% by layer, leaks, lint |
| 9 | `09_recommendations.md` | P0–P5 numbered action plan |