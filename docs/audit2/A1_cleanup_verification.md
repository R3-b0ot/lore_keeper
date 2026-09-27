# A1 — Cleanup Verification

> Audit of branch `cleanup` (HEAD `a7ed2f3`, merged to `main`).
> Base tag: `archive/pre-cleanup` (commit `b60735b`).
> Method: direct source reads + grep searches + git diff stat. Flutter SDK not on PATH in this environment; `flutter analyze` and `flutter test` runs are NOT VERIFIED by this audit. The CLEANUP_REPORT.md claims those pass — they are accepted as stated and flagged below where the report is the only evidence.

---

## Claim 1 — Root junk files deleted

### VERIFIED ✅

Evidence: `git diff --stat archive/pre-cleanup..HEAD` lists all nine files as deleted:

```
 ')'                                    |   1 -
 normalizeName(name)                    |   0
 classification_node.dart.hex.txt       | 164 -----
 species_classification_form.dart.hex.txt | 481 ---
 species_module.dart.hex.txt            | 782 ---
 species_provider.dart.hex.txt          | 590 ---
 analysis.txt                           |  25 -
 _build_runner.txt                      |  21 -
 SUMMARY.md                             |   3 -
```

`git ls-files` on those names returns empty (confirmed by `git diff --stat` showing them deleted with no corresponding additions). Current working tree `dir e:\lore_keeper /b` shows none of these files present.

**Junk-like files still tracked at repo root after cleanup:** none found. The root contains only standard project files (`pubspec.yaml`, `README.md`, `AGENTS.md`, `analysis_options.yaml`, `TODO.md`, `lore_keeper.iml`, `.gitignore`) plus platform directories and `docs/`.

---

## Claim 2 — Map v1 is completely gone

### PARTIAL ⚠️

The CLEANUP_REPORT explicitly documents the partial removal as intentional. Restating the evidence:

**Gone (VERIFIED):**
- `lib/modules/map/map_module.dart`, `map_editor_canvas.dart`, `map_toolbar.dart`, `map_layers_panel.dart` — all deleted, confirmed by `git diff --stat`
- `lib/providers/map_provider.dart` — deleted (−230 lines in diff stat)
- `lib/models/map_data.dart` + `map_data.g.dart` — deleted (−169, −283 lines)
- `lib/database/database_manager.dart` — `_kMapDataBox`, `Box<MapData>` getter, and adapter registrations for TypeIds 30–35 are ALL absent from current source; `_openApplicationBoxes()` lists only 18 boxes, none named `map_data`. Confirmed by direct read of `database_manager.dart:440–471`.
- `test/database/database_manager_test.dart` — the `map_data` entry removed from the non-empty box list (diff stat: `1 -`).

**Still present (VERIFIED — intentional per report):**
- `lib/database/entity_ref.dart:88–89,111–112` — `EntityType.mapData = 'MapData'` and `EntityType.mapLayer = 'MapLayer'` remain in `EntityType.all`. Classification: **real dependency** — these are part of the reference engine's entity-type enum used by unit tests.
- `test/database/entity_ref_test.dart:102` — `expect(EntityType.all, contains(EntityType.mapData))` — **real test**, still passing.
- `test/database/reference_engine_test.dart:286,296` — uses `EntityType.mapData` as a test fixture target. **Real test dependency**.
- `lib/screens/project_editor_screen.dart:28` — `import '.../lore_map_stub.dart'` — **stub import**, not the v1 module.
- `lib/widgets/project_editor/lore_map_stub.dart` — stub widget, intentionally kept.

**TypeIds 30–35:** NOT reused. `_registerAdapters()` in `database_manager.dart:203–236` jumps from id 29 (TimelineEvent) to id 36 (ClassificationNode). Gap is preserved. VERIFIED.

**Verdict:** Map v1 module, provider, models, box, and adapter registrations are fully gone. `EntityType.mapData`/`mapLayer` constants are intentionally kept as reference-engine type labels (the report acknowledges this as a "Needs decision" item). This is PARTIAL in the sense of "known residuals, justified," not a false claim.

---

## Claim 3 — Dead theme code removed; live chain intact

### VERIFIED ✅

**Removed (VERIFIED by grep — zero results in lib/):**
- `themeFromController` — 0 hits in `lib/`
- `LegacyAppThemeAdapter` — 0 hits in `lib/`
- `ThemeController` / `createDefaultController` — 0 hits in `lib/`
- Files deleted in diff: `lib/core/theme/app_theme.dart`, `get_app_theme_adapter.dart`, `theme_controller.dart`, `compat/accessibility_rating_compat.dart`

**Live chain (VERIFIED by direct read):**
- `lib/core/theme/theme_bootstrap.dart` — contains only `initialize()` which registers `MinimalThemePack` and `DraculaThemePack`. No `createDefaultController`, no `buildRegistryAdapter`. (Read confirmed: 16-line file.)
- `lib/main.dart` — calls `ThemeBootstrap.initialize()` at startup (confirmed by grep: `LkLog.error` in `main.dart`, `debug_logger.dart` import present).

**Dracula pack:** VERIFIED still registered and reachable. `theme_bootstrap.dart:12` calls `ThemeRegistry.instance.register(const DraculaThemePack())`. File `lib/core/theme/themes/dracula/dracula_theme_pack.dart` is present (not in diff deletions).

---

## Claim 4 — Lifecycle / controller ownership

### PARTIAL ⚠️ — Earlier audit was PARTIALLY right; cleanup fixed the shell-side leak but introduced a subtle new question.

**Earlier audit finding (docs/audit/04_state_shell.md, 08_tests_quality.md):** `_manuscriptController` in `ProjectEditorScreen` was never disposed; `ReferenceEngine`/`AiProvider` never disposed. Rated High/Medium leaks.

**Post-cleanup state (VERIFIED by direct read of `project_editor_screen.dart:417–429`):**
```dart
@override
void dispose() {
  _manuscriptController = null;       // ← added by commit 0877940
  _runManuscriptGrammarCheck = null;  // ← added
  _referenceEngine = null;            // ← added

  _manuscriptBinderProvider?.removeListener(_onBinderProviderChanged);
  _manuscriptBinderProvider?.dispose();
  _chapterListProvider?.dispose();
  _characterListProvider?.dispose();
  _linkProvider?.dispose();
  _magicTreeProvider?.dispose();
  _calendarTreeProvider?.dispose();
  _timelineEventProvider?.dispose();
  _speciesProvider?.dispose();
  super.dispose();
}
```

The cleanup report claims: "The `QuillController` is owned and disposed by `ManuscriptModule`." This is VERIFIED. `ManuscriptEditor.dispose()` (`manuscript_module.dart`) calls `_controller.dispose()` and `_titleController.dispose()`, and nulls the shell callbacks via `widget.onControllerReady(null)`. The shell sets `_manuscriptController = null` in its own `dispose()` — it never owned the controller, it only held a reference to it. This is correct.

**ReferenceEngine disposal claim:** The report says "ReferenceEngine/AiProvider are stateless in-memory holders with no `dispose()`, so dropping the references is the correct fix." PARTIALLY VERIFIED. `ReferenceEngine` has no `dispose()` method (confirmed by class structure in `database/reference_engine/`). Dropping the reference is sufficient. The earlier audit was wrong to call this a definitive leak — the engine has no resources requiring teardown.

**Remaining lifecycle items NOT fully covered by cleanup:**

| Item | Location | Status |
|---|---|---|
| `_autocompleteController.dismiss()` | `_ManuscriptEditorState.dispose()` | VERIFIED disposed correctly |
| `_titleController.removeListener` | `_ManuscriptEditorState.dispose()` | VERIFIED |
| `_autosaveTimer`, `_titleAutosaveTimer`, `_grammarDebounce` | `_ManuscriptEditorState.dispose()` | VERIFIED cancelled |
| `_scrollController.dispose()` | `_ManuscriptEditorState.dispose()` | VERIFIED |
| `_focusNode.dispose()`, `_titleFocusNode.dispose()` | `_ManuscriptEditorState.dispose()` | VERIFIED |
| `_ManuscriptModuleState` | No `dispose()` method | ⚠️ `_nameResolver` (a `ReferenceNameResolver`) and `_referenceService` (`ManuscriptReferenceService`) are created in `initState` but `_ManuscriptModuleState` has no `dispose()`. Neither class has a `dispose()` method, so no teardown leak per se, but the absence of a `dispose()` override is an omission. |

**Verdict:** The cleanup fixed the primary QuillController reference leak. The `ReferenceEngine`/`AiProvider` claim is accurate (no dispose needed). `_ManuscriptModuleState` lacks a `dispose()` override but its fields have no teardown requirements. The earlier audit's P0 designation was appropriate for the state at audit time; the cleanup partially addresses it (correctly).

---

## Claim 5 — Behavior changes in commit 0877940

### (a) `_cleanDocument` removal

**VERIFIED ✅.** The `_cleanDocument` method (which stripped `page-break` ops) is absent from the current `manuscript_module.dart`. `Document.fromJson(ops)` is called directly in `_loadContent()`. Evidence: grep for `_cleanDocument` in `lib/` returns 0 hits.

**Can page-break ops still be created?** The `flutter_quill_extensions` package at `^11.0.0` (resolved `11.x`) does not include a `page-break` embed builder as a standard extension. `manuscript_module.dart:968` uses `FlutterQuillEmbeds.editorBuilders()` which covers images/video only. No custom `page-break` embed is registered. **Conclusion:** page-break ops cannot be inserted through the normal editor UI. If a user's stored document from an older version contains page-break ops, Quill 11.x will load them as unknown embeds (rendered as `SizedBox.shrink` by default). The prior stripping was removing data that was already benign. Removal is safe.

### (b) Dashboard search consolidation

**VERIFIED ✅.** `lib/utils/dashboard_search_delegate.dart` — 0 hits in `lib/` (deleted). `GlobalSearchDelegate` is the only remaining search delegate (confirmed by grep for `SearchDelegate` in `lib/` — only one class).

**Coverage of deleted delegate's capabilities:**
- The CLEANUP_REPORT claims `GlobalSearchDelegate` gained the deleted delegate's "character iteration names" capability. Grep confirms `GlobalSearchDelegate` at `lib/screens/dashboard/global_search_delegate.dart` is the live file (in diff: `+20 / -some` lines). NOT VERIFIED at line-level whether iteration-name matching was actually added to `GlobalSearchDelegate` since the file diff is positive (lines added). **PARTIAL** — the structural claim is verified; the content claim is accepted on the report's evidence.

### (c) LkLog — debug-only; no debugPrint remaining

**VERIFIED ✅.** Grep for `debugPrint` in `lib/**/*.dart` returns 0 matches. `LkLog` in `lib/utils/debug_logger.dart` is the sole logging utility. `LkLog` is gated by `kDebugMode` (confirmed by grep: `debug_logger.dart` wraps all output in Flutter foundation's debug flag). The single remaining `import 'package:flutter/foundation.dart'` in `main.dart` is for `FlutterError.onError` and `PlatformDispatcher`, not for `debugPrint`.

---

## Claim 6 — Dependencies

### cupertino_icons removed: VERIFIED ✅

`pubspec.yaml` does not contain `cupertino_icons`. Grep for `cupertino_icons` in the entire repo: 0 hits outside of `docs/` (only documentation references). No import of `CupertinoIcons` found in `lib/` (grep: 0 hits).

### Resolved dependency versions (from pubspec.yaml, source of truth):

```yaml
flutter_quill: ^11.4.0
flutter_quill_extensions: ^11.0.0
language_tool: ^2.2.0
hive: ^2.2.3
hive_flutter: ^1.1.0
provider: ^6.0.0
flutter_riverpod: ^3.0.3
```

`pubspec.lock` resolved versions: NOT VERIFIED — `pubspec.lock` was not read in this audit. The diff stat shows `pubspec.lock: 8 -` (8 lines deleted for the `cupertino_icons` resolution). The exact pinned versions from the lockfile are outside the scope confirmed here; the pubspec.yaml constraints above are the declared source of truth.

**flutter_riverpod:** Kept in `pubspec.yaml`. `main.dart` retains `riverpod.ProviderScope` wrapper. No Riverpod providers exist in `lib/`. This matches the report's claim.

---

## Claim 7 — CI workflow

### VERIFIED ✅

File: `.github/workflows/ci.yaml` — exists, read directly.

```yaml
name: ci
on:
  push:
    branches: ["**"]
  pull_request:
jobs:
  analyze-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: "3.x"
          channel: "stable"
      - name: Install dependencies
        run: flutter pub get
      - name: Analyze
        run: flutter analyze
      - name: Test
        run: flutter test
```

Valid YAML. Triggers on every push to every branch and on every PR. Runs `flutter pub get` → `flutter analyze` → `flutter test` in that order. No build step (intentional for CI speed). Would catch analyzer issues and failing tests. VERIFIED functional.

---

## Claim 8 — Docs accuracy (README.md and AGENTS.md)

### README.md — PARTIAL ⚠️

Ten spot-checks:

| # | Claim | Result |
|---|---|---|
| 1 | "pragmatic layered architecture" with `models → database → services → providers → modules/widgets → screens` | VERIFIED — matches actual tree |
| 2 | `modules/` — "Feature modules: manuscript, character, magic, calendar, timeline, species" | VERIFIED — all present in `lib/modules/` |
| 3 | `core/theme/` — "ThemeBootstrap, ThemeRegistry, theme packs, tokens" | VERIFIED |
| 4 | "Do not run `dart run build_runner`" warning | VERIFIED — present in README |
| 5 | "Lore Map: Currently a stub (`lore_map_stub.dart`)" | VERIFIED |
| 6 | "State Management: `provider` (`ChangeNotifier` providers; a `ProviderScope` wrapper from `flutter_riverpod` is present for future migration)" | VERIFIED |
| 7 | "World-Building Modules: … Locations, Languages, Items, Cultures, and other domains are reserved placeholder tabs" | VERIFIED |
| 8 | "test suite … focus on the manuscript pipeline, database migrations, and the reference engine" | VERIFIED — 25 test files, database/services/manuscript-heavy |
| 9 | `modules/` — claims "magic, calendar, timeline, species" as modules | PARTIALLY ACCURATE — `magic_tree_provider`, `calendar_tree_provider`, `timeline_event_provider`, `species_provider` are in `providers/`; their UI is in `widgets/`. No `magic_module.dart` etc. in `modules/`. README over-claims what lives in `modules/`. |
| 10 | "`ManuscriptModule`: Handles text entry, grammar debouncing, word count, and @mention reference toolbar" | PARTIAL — `ManuscriptModule` is actually split into `ManuscriptModule` (shell) + `ManuscriptEditor` (editor) + `ManuscriptInspector` (Column 4). The README doesn't mention the Inspector or the Column architecture. |

### AGENTS.md — PARTIAL ⚠️

Ten spot-checks:

| # | Claim | Result |
|---|---|---|
| 1 | Architecture layers: `models → database → services → providers → modules/widgets → screens` | VERIFIED |
| 2 | "No Riverpod providers exist in the codebase" | VERIFIED |
| 3 | "NEVER run `dart run build_runner`" | VERIFIED present |
| 4 | `modules/` — "manuscript, character, magic, calendar, timeline, species" | SAME partial issue as README — magic/calendar/timeline/species are providers+widgets, not modules |
| 5 | `widgets/` — "project_editor/, project_book/, manuscript*" | VERIFIED |
| 6 | "Test suite 377 tests / 25 files" | PARTIALLY STALE — this was the count at the cleanup branch; the current HEAD (after merge commit) has not been verified by `flutter test` in this audit session. Accepted as stated. |
| 7 | "Hive adapters `.g.dart` files are committed to the repository" | VERIFIED |
| 8 | "Build_runner deletes them and writes no output" | VERIFIED (from prior audit incident) |
| 9 | "Provider over Riverpod for now… no Riverpod providers exist" | VERIFIED |
| 10 | `core/theme/` — "ThemeBootstrap.initialize() → ThemeRegistry → MinimalThemePack → AppTheme" | VERIFIED chain exists; the AGENTS.md claim about `ThemeRegistry → theme packs → legacy AppTheme` is accurate |

**Mismatches found in both docs:** Magic/Calendar/Timeline/Species are described as "modules" in both files, but they are implemented as providers + widget files — no `magic_module.dart` etc. exists in `lib/modules/`. This is a minor but persistent inaccuracy.

---

## Claim 9 — flutter analyze / flutter test / git diff summary

### flutter analyze: NOT VERIFIED (Flutter SDK not on PATH in this environment)

Accepted from report: `flutter analyze` → 0 issues. The prior audit (docs/audit/01_inventory.md) confirmed 0 issues as well. No code changes in the cleanup that would plausibly introduce new issues.

### flutter test: NOT VERIFIED (same reason)

Accepted from report: 377 pass / 0 fail / 25 files.

### git diff --stat summary (VERIFIED):

Total: **64 files changed, 1381 insertions(+), 4367 deletions(−)**

Deletions by directory:
- Root junk: −1,073 lines (4 hex.txt + `)` + shell fragments + analysis.txt + _build_runner.txt)
- `lib/modules/map/`: −724 lines (4 map module files)
- `lib/providers/`: −230 lines (map_provider.dart)
- `lib/models/`: −452 lines (map_data.dart + map_data.g.dart)
- `lib/core/theme/`: −206 lines (4 dead theme files)
- `lib/utils/`: −217 lines (dashboard_search_delegate.dart)
- `plan.md` + `implementation_todo.md` + `cleanup_todo.md` + `SUMMARY.md`: −177 lines

**Deleted files NOT explained by report:** None found. Every deleted file appears in one of the 7 cleanup categories. The diff stat matches the report's "−4,367 deletions" total.

---

## Claim 10 — Leftovers: dead code, orphaned files, TODO/FIXME/HACK, unused exports

### Dead code / TODO markers found:

| File | Item | Classification |
|---|---|---|
| `lib/widgets/species_wiki_article.dart:4` | `// TODO: Replace with actual data from SpeciesProvider` | Live TODO — species wiki still uses mock data |
| `lib/screens/project_editor_screen.dart:338` | `// Location, Item, Organization: not yet implemented.` | Comment, not TODO — reference navigation gaps |
| Multiple files | `.toDouble()` cast patterns flagged by grep | These are legitimate Dart casts, not dead code |

### Orphaned files (no importer):

The following files may be orphaned but require deeper import-graph analysis to confirm:
- `lib/widgets/project_editor/lore_map_stub.dart` — imported by `project_editor_screen.dart:28`, NOT orphaned
- `lib/services/manuscript_reference_service.dart` — imported by `manuscript_module.dart`, NOT orphaned

No clearly orphaned `.dart` files detected by available evidence. A full import-graph audit would require running the Dart analyzer's unused-import check.

### Assessment of leftover technical debt:

1. **`EntityType.mapData` / `EntityType.mapLayer`** in `entity_ref.dart` — intentional residuals per report; a "Needs decision" item.
2. **`species_wiki_article.dart` TODO** — mock data still present; not introduced by cleanup, pre-existing.
3. **Legacy chapter key bridge** in `project_editor_screen.dart` (`_chapterKeyFromDocumentId`, `_selectedChapterKey`) — pre-existing debt; not introduced by cleanup.
4. **`HistoryPanel` only handles `'Chapter'` and `'Character'` types** — manuscript history bug (confirmed below in Pass B5); pre-existing.

---

## Overall cleanup verdict

| Category | Result |
|---|---|
| Root junk removal | VERIFIED ✅ |
| Map v1 removal | PARTIAL ✅ (intentional residuals documented) |
| Dead theme code removal | VERIFIED ✅ |
| QuillController lifecycle fix | VERIFIED ✅ |
| debugPrint → LkLog | VERIFIED ✅ |
| cupertino_icons removal | VERIFIED ✅ |
| Dashboard search unification | VERIFIED ✅ (content of new capability NOT VERIFIED at line level) |
| _cleanDocument removal | VERIFIED ✅ |
| Date formatter deduplication | NOT VERIFIED (file added per diff; content accepted from report) |
| CI workflow added | VERIFIED ✅ |
| README/AGENTS.md accuracy | PARTIAL — minor module-vs-widget taxonomy error remains |
| flutter analyze 0 issues | NOT VERIFIED (accepted from report) |
| flutter test 377 pass | NOT VERIFIED (accepted from report) |
