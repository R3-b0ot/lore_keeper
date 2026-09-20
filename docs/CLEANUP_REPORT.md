# Cleanup Report

Branch: `cleanup` (tag `archive/pre-cleanup` captures pre-cleanup `main` @ `b60735b`)
Date: 2026-09-20

## Summary

Seven cleanup categories, one commit each, each verified with `flutter analyze`
(0 issues) and `flutter test` (all green). Net result: **53 files changed,
+319 / −4367 LOC across 7 commits**, `flutter analyze` clean, `flutter test`
passes (377 tests / 25 files).

Total removed: **−4,048 net lines**.

| Commit | Category | Δ LOC |
|---|---|---|
| `fd15241` | 1. Root junk | +3 / −2,067 |
| `2b95da3` | 2. Stale docs | +131 / −334 |
| `4855305` | 3. Map v1 removal | −1,413 |
| `681c916` | 4. Dead theme code | +1 / −205 |
| `d613c34` | 5. cupertino_icons | −9 |
| `0877940` | 6. Small fixes | +158 / −339 |
| `10aef26` | 7. CI workflow | +26 |

---

## Category 1 — Root junk (`fd15241`)

Deleted 9 stray junk files and added rigorous ignored coverage output.

### Removed files (git-grep evidence)
```
')'                          # shell redirect typo
normalizeName(name)          # pasted signature
classification_node.dart.hex.txt
species_module.dart.hex.txt
species_provider.dart.hex.txt
species_classification_form.dart.hex.txt
analysis.txt                 # stale analyzer dump
_build_runner.txt            # stale build_runner warning dump
SUMMARY.md                   # 3-line TOC pointing at README.md (verified no valuable content)
```
All six `.hex.txt` files were exported string dumps of the four
`species_*`/`classification_node` sources (default `git add` on Windows would
export them again, but they are junk and were not referenced by anything).
`SUMMARY.md` was read fully before deletion — a 3-line navigation stub.

### `.gitignore` addition
```
coverage/
```
Prevents the `test/`-generated coverage output from ever being tracked.

---

## Category 2 — Stale documentation (`2b95da3`)

### Files deleted (`git rm plan.md implementation_todo.md cleanup_todo.md`)
- `plan.md` — described a restructuring of `lib/data/…/maps/…` paths that no
  longer exist (feature was moved and evolved).
- `implementation_todo.md` — stale map-creator enhancement checklist.
- `cleanup_todo.md` — unchecked items referencing the deleted theme-controller
  path and the map rework.

### Files rewritten from audit findings
- **README.md** — replaced Clean-Architecture boilerplate with the real
  layered structure (`models → database → services → providers → modules →
  widgets → screens`), removed bogus "13 analyzer warnings" claim, added a
  prominent **"Do not run `dart run build_runner`"** warning (it deletes the
  committed `.g.dart` Hive adapters).
- **AGENTS.md** — same corrections plus explicit "NEVER run build_runner",
  no Riverpod providers, correct architecture section.
- **TODO.md** — removed the completed ThemeController wiring steps (resolved
  by Category 4), kept the tokenization and pack steps.

---

## Category 3 — Map v1 removal (`4855305`)

### Removed (git-grep evidence)
```
lib/modules/map/map_module.dart        # orphaned: MapModule referenced nowhere else in lib/
lib/modules/map/map_editor_canvas.dart # imports map_provider + map_data
lib/modules/map/map_toolbar.dart       # imports map_provider + map_data
lib/modules/map/map_layers_panel.dart  # imports map_provider
lib/providers/map_provider.dart        # 230 LOC, Hive.box<MapData>('map_data')
lib/models/map_data.dart + .g.dart     # MapData/MapLayer/MapStamp/MapPath/MapPolygon/OffsetData + adapters
```
Consumers of the box/adapters in `database_manager.dart` were also stripped:
import, `_kMapDataBox` const, `Box<MapData>` getter, the legacy-box list
entry, adapter registration `reg(30…35)`, and the `_openBox` call.
`test/database/database_manager_test.dart` had `'map_data'` removed from a
non-empty-box-names list.

### Kept
- `lib/widgets/project_editor/lore_map_stub.dart` — the Lore Map slot stays a
  stub; only the defunct v1 implementation was removed.
- `EntityType.mapData` / `EntityType.mapLayer` constants in
  `lib/database/entity_ref.dart` — these live inside the reference engine
  (`EntityType.all` feeds the engine's rebuild loop, and is 100% unit-tested);
  per the scope rule the reference/mention engine is untouched. See
  "Needs decision".

### Hive typeId 30–35
Retired. **Not reused or renumbered** (avoids silent misread risks in existing
databases). The `map_data` box JSON, if any user device still holds one, is
simply never opened.

---

## Category 4 — Dead theme code (`681c916`)

### Removed (git-grep evidence: zero remaining references)
```
lib/core/theme/app_theme.dart                       # themeFromController facade
lib/core/theme/get_app_theme_adapter.dart           # LegacyAppThemeAdapter
lib/core/theme/theme_controller.dart                # ThemeController/ThemeRegistryAdapter
lib/core/theme/compat/accessibility_rating_compat.dart
```
`lib/core/theme/theme_controller.dart` was imported only by `theme_bootstrap.dart`
and `app_theme.dart` (the two other deleted files). `get_app_theme_adapter.dart`
was imported only by `app_theme.dart`. Zero tests reference any of this code.

### Simplified
`lib/core/theme/theme_bootstrap.dart` now contains only `initialize()`
(pack registration); removed `createDefaultController`,
`buildRegistryAdapter`, `defaultRegistryAdapter`,
`_DefaultThemeRegistryAdapter`.

### Kept (live startup chain, verified intact)
`main.dart:35 ThemeBootstrap.initialize()` → `ThemeRegistry` →
`theme_provider.dart` (`ThemeNotifier`, pack id `'minimal'`) →
`minimal_theme_pack.dart` → `minimal_theme_dark.dart` → legacy
`lib/theme/app_theme.dart` (`AppTheme.getDarkTheme`).
`flutter analyze` + `flutter test` clean (0 issues, 377 pass) proves the
chain is unaffected.

### Needs decision
- **Dracula theme pack** (`core/theme/themes/dracula/`, ~330 LOC) is kept:
  it is a fully registered, user-selectable theme with 30+ references across
  its own files. Recommend keeping; could be extracted later if the app
  commits to a single theme.

---

## Category 5 — Dependency drop (`d613c34`)

`cupertino_icons` removed from `pubspec.yaml`.

Evidence: `git grep cupertino_icons` in `lib/` and `test/` returns **zero**
hits — the app uses `lucide_icons_flutter` and Material icons, never
`CupertinoIcons`. `flutter pub get` clean, analyze/test green.
- `flutter_riverpod` **kept** (`main.dart`'s `ProviderScope` is the reserved
  migration seam; no Riverpod providers exist yet).

---

## Category 6 — Small fixes (`0877940`)

### (a) Controller/engine ownership in `project_editor_screen.dart`
`dispose()` now clears `_manuscriptController`, `_runManuscriptGrammarCheck`,
and `_referenceEngine`. The `QuillController` is owned and disposed by
`ManuscriptModule` (which already calls `onControllerReady(null)` + `dispose()`
in its own dispose); `ReferenceEngine`/`AiProvider` are stateless in-memory
holders with no `dispose()`, so dropping the references is the correct fix.

### (b) Logging — all 21 `debugPrint` → `LkLog` (`lib/utils/debug_logger.dart`)
Files updated: `trait_editor_screen.dart`, `manuscript_binder_service.dart`,
`manuscript_service.dart`, `relationship_service.dart`, `resource_manager.dart`,
`character_list_provider.dart`, `chapter_list_provider.dart`,
`character_module.dart`. Where `flutter/foundation.dart` existed solely for
`debugPrint`, the import was replaced by `debug_logger.dart`.
`git grep debugPrint(` on `lib/` now returns zero hits.

### (c) No-op dashboard Import action
Removed `onTap: () {}` from the dashboard Import `ActionCard`
(`dashboard_screen.dart:192`); `ActionCard` now renders the click cursor only
when an `onTap` handler exists, so non-clickable cards stop implying
interactivity.

### (d) Unified search delegates
Deleted `lib/utils/dashboard_search_delegate.dart` in favor of
`lib/screens/dashboard/global_search_delegate.dart` (the sectioned,
navigation-capable delegate). `dashboard_topbar.dart` now uses
`GlobalSearchDelegate`. The survivor also gained the deleted delegate's
capability: matching **character iteration names** (not just the character
name field) and falling back to the first iteration name when `name` is empty.
Evidence: `DashboardSearchDelegate`/`dashboard_search_delegate` now appear in
zero files.

### (e) Date-formatting dedupe → `lib/utils/date_formatters.dart`
Added `formatRelativeDate`, `formatDateTime`, `formatDateOnly` and replaced
four duplicated private `_formatDate` implementations (relative-date copy in
`project_list_table.dart`, `overview_module.dart`, `project_book.dart`; the
`d/M/yyyy HH:mm` formatter in `manuscript_inspector.dart`) plus the inline
date in `global_search_delegate.dart`.

### (f) Page-break stripping removed
Deleted `_cleanDocument` in `manuscript_module.dart` (it silently deleted
`page-break` ops whenever a document was reloaded from storage).
`Document.fromJson` is now called with the raw ops list. Single call site,
no test coverage, behavior-critical fix (page breaks persist across reloads).

---

## Category 7 — CI (`10aef26`)

New `.github/workflows/ci.yaml`: `flutter pub get` → `flutter analyze` →
`flutter test` on every push and pull request (stable channel). No lint
tightening was introduced.

---

## Verification

| | before | after |
|---|---|---|
| `flutter analyze` | 0 issues | **0 issues** |
| `flutter test` | 377 pass / 25 files | **377 pass / 25 files** |
| LOC (lib + docs) | — | −4,048 net |

Final runtime smoke-test plan: `flutter run -d windows` (manual step in this
environment).

## Deliverables not covered by this branch (future work)
- `MapData`/`MapLayer` entity-type constants in the reference engine
  (`EntityType.all`) — decision needed on whether to retire them once the
  future Lore Map rewrite lands.
- Dracula theme pack — see "Needs decision" above.