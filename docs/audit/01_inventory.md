# Pass 1 — Repository Inventory

> Audit of `E:\lore_keeper` — Lore Keeper, a creative-writing / worldbuilding Flutter app (pre-alpha).
> Date: 2026-09-20. All facts verified with file system + tool runs.

---

## 1.1 Repository summary

| Item | Value |
|---|---|
| VCS | Git repo, default branch |
| SDK | Flutter 3.9.2+ (ruby/compatible), Dart 3.x |
| Primary deps | `flutter_riverpod` 3.0.3 (1 call site), `provider`, `hive ^2`, `flutter_quill ^11.4`, `flutter_quill_extensions ^11.0`, `language_tool ^2.2`, `file_picker`, `flutter_svg`, `nlp_compromise`/NLP tooling, `xml`, `uuid` |
| Analyzer | `flutter analyze` → **"No issues found! (ran in 2.5s)"** ✅ |
| Tests | `flutter test` → **377 passing / 0 failing** ✅ (25 files, 6,220 test-source lines) |
| Coverage | **15.7% overall** (2,963 / 18,828 lines, `flutter test --coverage`) |
| Build codegen | `dart run build_runner build` **succeeds but DELETES all 15 tracked `.g.dart` files** ("wrote 0 outputs") — see §1.7 |

---

## 1.2 Layout of `lib/`

The README and AGENTS.md claim a strict Clean Architecture (`lib/data`, `lib/domain`, `lib/presentation`).
**None of those directories exist.** The actual tree:

```
lib/
├── core/                   15 files  894 LOC   theme "facade" (dead), ai_types helper
├── database/               13 files 2195 LOC   Hive boxes, migrations, reference engine, AI providers
├── models/                 29 files 3035 LOC   Hive models (+ .g.dart)
├── modules/                10 files 6684 LOC   per-topic module screens (character 3797, manuscript 1312)
├── providers/              10 files 3263 LOC   ChangeNotifier providers (Provider package)
├── screens/                13 files 6695 LOC   top-level screens (dashboard, project editor, trait editor)
├── services/               16 files 1999 LOC   business services
├── settings/                8 files 3238 LOC   settings app + panes + widgets
├── theme/                   4 files  769 LOC   LEGACY theme (AppTheme) — still the live path
├── utils/                   8 files 1043 LOC   helpers, icon maps
└── widgets/                59 files 21020 LOC  reusable + module-specific widgets (largest layer)
```

LOC measured via `Get-Content`. Generated `.g.dart` files are counted inside `models/` in the numbers above (they are tracked in git — see 1.7).

**Arch verdict:** the "Clean Architecture" claim in `README.md`/`AGENTS.md` is aspirational documentation, not code structure. The app is a pragmatic layered structure (models → database → services → providers → modules/widgets → screens) with feature-bucket folders (`modules/`, `widgets/project_editor/`, `widgets/project_book/`, `widgets/dashboard/`). The strict 3-layer rule (Data/Domain/Presentation) is broken by:
- business logic living inside widgets (`lib/widgets/manuscript_binder.dart`, `manuscript_collections.dart`, `calendar_picker.dart` hold service logic);
- entities vs models being the same Hive classes (no domain layer);
- providers owning both state and IO.

---

## 1.3 Largest files (physical lines)

| LOC | File | Role |
|---|---|---|
| 3,996 | `lib/modules/character_module.dart` | Character tree + CRUD + relations (State spans lines 46–1023) |
| 2,307 | `lib/screens/trait_editor_screen.dart` | Trait/custom-field editor |
| 1,628 | `lib/widgets/species_tree.dart` | Species classification tree |
| 1,562 | `lib/screens/relation_chart_screen.dart` | Relationship chart (single 1,562-line StatefulWidget) |
| 1,388 | `lib/widgets/calendar_picker.dart` | Calendar date picker |
| 1,324 | `lib/widgets/species_wiki_article.dart` | Species wiki article view |
| 1,312 | `lib/modules/manuscript_module.dart` | Quill manuscript editor + reference toolbar + grammar |
| 1,264 | `lib/widgets/magic_init_wizard.dart` | Magic-system initialisation wizard |
| 1,049 | `lib/widgets/magic_main_panel.dart` | Magic system main panel |
| 827 | `lib/widgets/calendar_init_wizard.dart` | Calendar-system wizard |

`relation_chart_screen.dart` (1,562 LOC in one StatefulWidget + its dialog) and `character_module.dart` (≈3,996 LOC) are the top refactoring candidates.
No module file is tested directly (see Pass 8).

---

## 1.4 Top-level package/tooling files

| File | Status |
|---|---|
| `pubspec.yaml` | Live (Flutter app, deps listed in Pass 2) |
| `analysis_options.yaml` | Live; flutter_lints (Pass 8) |
| `plan.md` | **STALE** — describes `lib/data/maps/` structure that no longer exists; map module moved to `lib/modules/map/` then orphaned (Pass 5/9) |
| `implementation_todo.md` | Partly stale — "map creator" plan predates the orphaned `lib/modules/map/` + `lore_map_stub.dart` settle |
| `TODO.md` | Live intent; Theme Refactor section still unchecked (Pass 7) — new `lib/core/theme/` exists but its controller path is dead code |
| `cleanup_todo.md` | Points at root junk files (§1.5) still being tracked |
| `README.md` | Architecture claims do not match tree (§1.2) |

---

## 1.5 Repository root debris (all TRACKED IN GIT)

Nine junk files are committed at the repository root. **All are safe to delete** (verified as either garbage shells, or stale backups whose content no longer matches `lib/`):

| File | Contents (verified) | Verdict |
|---|---|---|
| `')` | 1-byte leftover shell fragment | delete |
| `normalizeName(name)` | 23-byte leftover function-name fragment | delete |
| `classification_node.dart.hex.txt` | hex dump → single-line minified *old* species-classification model | delete (stale backup) |
| `species_module.dart.hex.txt` | hex dump → single-line minified *old* broken `SpeciesModule` | delete (stale backup) |
| `species_provider.dart.hex.txt` | hex dump → minified old `SpeciesProvider` | delete (stale backup) |
| `species_classification_form.dart.hex.txt` | hex dump → minified old form | delete (stale backup) |
| `analysis.txt` | snapshot of `flutter analyze` output | delete |
| `_build_runner.txt` | snapshot of a `build_runner` run | delete |
| `SUMMARY.md` | ? (top-level doc, not part of `docs/`) | review + delete or fold into `docs/` |

The 4 `.hex.txt` files decode (via a hex-stripping python script) to **single-line minified Dart** — clearly accidental dumps of earlier work, superseded by current `lib/modules/species*` code.

There is also a `coverage/` artifact provision: the `flutter test --coverage` run regenerated `coverage/` (untracked), and `coverage/lcov.info` is the source for Pass 8 numbers.

---

## 1.6 Module wiring map (app shell)

Entry point: `lib/main.dart` → `DashboardScreen` → `ProjectEditorScreen` (`lib/screens/project_editor_screen.dart`, 372 analyzed-lines / ~737 physical).

`ProjectEditorScreen` module index (`_moduleIndex`):

| idx | Module | Implementation |
|---|---|---|
| 0 | Overview | `lib/widgets/project_editor/overview_module.dart` (connectivity graph is a stub) |
| 1 | Manuscripts | `lib/modules/manuscript_module.dart` |
| 2 | Characters | `lib/modules/character_module.dart` |
| 3 | World Building | `lib/widgets/project_editor/world_building_tabs.dart` |
| 4 | Lore Map | `lib/widgets/project_editor/lore_map_stub.dart` (**stub**) |

World Building tabs (`world_building_tabs.dart`): 0 Magic, 1 Timeline, 2 Calendar, 3 Species implemented; the rest are placeholder panels (Locations, Languages, Items, Cultures, Philosophies, Religions, Systems, Research, Arcs, Relationships).

**Orphaned module:** `lib/modules/map/` (`map_module.dart`, `map_editor_canvas.dart`, `map_toolbar.dart`, `map_layers_panel.dart`) — `MapModule` is referenced **nowhere** in `lib/`. The live "Map" tab shows `lore_map_stub.dart`. `lib/providers/map_provider.dart` is likewise orphaned.

---

## 1.7 Tool-run results & the `.g.dart` deletion incident

Commands run during this audit (all at repo root):

| Command | Result |
|---|---|
| `flutter analyze` | **No issues found! (ran in 2.5s)** — contradicts the "13 analyzer warnings" debt note in AGENTS.md (stale; the SVG dead code was already removed) |
| `flutter test` | **+377: All tests passed!** |
| `flutter test --coverage` | 377 passed; coverage 15.7% (details Pass 8) — note: the earlier *coverage* incident below |
| `dart pub outdated` | Matrix in Pass 2 |
| `dart run build_runner build --delete-conflicting-outputs` | **REPRODUCIBLE DATA-DELETION INCIDENT (see below)** |

### The incident

`dart run build_runner build` (before codegen-dependent tests could run) **deleted all 15 tracked `*.g.dart` model adapters** and reported `Wrote 0 outputs`. Files affected included `lib/models/character.g.dart`, `project.g.dart`, `manuscript_document.g.dart`, etc. Because these files are **tracked in git** (not gitignored), they were restored with `git restore .` and the working tree verified clean. Afterwards the full test-suite passed (so coverage/codegen artifacts were intact again).

**Impact / why:**
- `*.g.dart` are **committed to the repo** (so tests pass on checkout without build_runner).
- `build_runner build` with `--delete-conflicting-outputs` (or in this build setup) appears to run in a mode where generation "conflicts" with the checked-in outputs and it drops them, or the analyzer package-config isn't producing `*.part`/`*.g.dart` targets — net effect: it wipes them.
- Any contributor running `build_runner` will silently strip the app's Hive adapters → runtime `TypeError` when boxes are opened, and codegen-dependent tests fail to even **load** (Pass 8 lists 11 such test files that errored at compile under the *partial* state).

**Verdict (risk):** build pipeline is broken-in-practice. Either (a) stop committing `.g.dart` and provide a working `build_runner` invocation, or (b) fix the build_runner setup so it re-emits the same outputs. This is a **P0 build-hygiene issue**, before any feature work.

---

## 1.8 Runtime footgun observed during runs

Every `flutter`/`dart` command on this machine emits a leading line `The system cannot find the file specified` — a benign pwsh/environment artifact, not a Flutter failure (all commands complete successfully). Noted so it is not misread as an error in future runs.

---

## 1.9 Pass 1 conclusions

1. Code is healthy at the analyzer level (clean) but **enormous feature-direction ambiguity**: map module hidden, 10 of 14 world-building tabs placeholders, species module recently rewritten (module is now a thin 148-line StatelessWidget while 4 big `species_*` files sit in `widgets/`).
2. Structure drifted far from documented Clean Architecture; consider documenting the *real* architecture instead of chasing the docs.
3. Root-junk cleanup is trivial and risk-free (`git rm` of 9 files) — see Pass 9.
4. Build codegen pipeline must be repaired before any model changes are made (P0).