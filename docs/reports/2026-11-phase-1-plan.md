# Phase 1 Stage A plan (R-02 cleanup + R-22 agent kit wave 1)

Nov 9, 2026 - branch `phase-1` (HEAD `ebaa117`) - builder: opencode

`docs/SOURCE_OF_TRUTH.md` was not edited. Stage A is read-only: no code, config, test, or agent file was changed. Everything below is either a finding at HEAD or a proposal for Stage B.

## Verification at HEAD

- `flutter analyze`: **No issues found!** (97.6 s).
- `flutter test`: **All 531 tests passed** (`00:24 +531`).
- `git status --short --branch`: only `## phase-1`; working tree clean.
- `git ls-files '*.g.dart'`: **14** tracked adapters (12 in `lib/models/`, plus `lib/screens/trait_editor_screen.g.dart` and `lib/services/trait_service.g.dart`). The Sep 20 audit counted 15; one orphan adapter is no longer tracked.

## R-02 scope

R-02's Done-when is narrower than the Phase 1 gate: "Analyzer reports zero issues, tests pass, the audit P0 and P1 items are each confirmed fixed or still open, and `build_runner` and `hive_generator` are removed from dev dependencies (or their presence is justified in the report)." The SoT also says "Manuscript spec questions OQ-2 to OQ-9 are deferred to the Phase 2 kickoff and not copied here."

This report therefore marks every audit finding, but the Stage B fix list is limited to R-02's P0/P1 scope plus the dependency cleanup. P2-P5 are status only.

## Audit findings at HEAD

### P0

| ID | Finding | Status at HEAD | Evidence / action |
| --- | --- | --- | --- |
| P0-1 | Codegen build pipeline is a landmine | **Still open** | `build_runner: ^2.4.13` remains at `pubspec.yaml:76`; `hive_generator` is already absent from `pubspec.yaml`. All 14 `.g.dart` adapters are committed and hand-maintained. Stale comments remain at `lib/models/manuscript_collection.g.dart:7` and `lib/database/database_metadata.dart:85-87,142-144,229-231`. Stage B: remove `build_runner`; update the comments; keep the 14 adapters. |
| P0-2 | 9 tracked root-junk files | **Fixed** | R-01 removed the `.bak` file, one-off scripts, `.agent/`, `.clinerules/`, and the stray root files. Re-check at HEAD found none. No action. |
| P0-3 | Three resource leaks in the app shell | **Fixed** | `lib/screens/project_editor_screen.dart:421` `dispose()` nulls `_manuscriptController` at 426 and `_referenceEngine` at 428, and disposes the five module providers at 431-436. `AiProvider` is built inline at 170-179 (`buildAiProviderFromSettings`), not stored, so there is nothing to dispose. `QuillController` is owned and disposed by `ManuscriptEditor`. No action. |

### P1

| ID | Finding | Status at HEAD | Evidence / action |
| --- | --- | --- | --- |
| P1-4 | Manuscript history invisible | **Fixed** | `project_editor_screen.dart:698-702` uses `targetType: 'ManuscriptDocument'` and `:710-713` uses `'Character'`; `history_panel.dart:186` filters those, and routes at 71/82/84. No action. |
| P1-5 | Three divergent word/char counters | **Fixed** | Single implementation `lib/utils/manuscript_text_stats.dart`, used by `database_manager.dart:414,417`, `manuscript_module.dart:692-695`, `manuscript_binder_service.dart:182,183,243,244`, and `manuscript_diff_view_dialog.dart:117`. No action. |
| P1-6 | Find & Replace strips attributes and drifts offsets | **Fixed** | `find_replace_dialog.dart:95-120` preserves attributes and reapplies inline scope after `replaceText`; `:183-204` replaces all from the highest offset down. No action. |

### P2

| ID | Finding | Status at HEAD | Evidence / action |
| --- | --- | --- | --- |
| P2-7 | Ten placeholder World-Building tabs | **Still open - deferred to R-10 (Phase 3)** | Placeholders remain at `project_editor_screen.dart:825`, `species_tree.dart:82`, `overview_module.dart:343`, `world_building_tabs.dart:204`. R-10 owns removal/replacement. |
| P2-8 | Map editor is orphaned | **No longer applicable** | `lib/modules/map/` does not exist at HEAD; only `lib/widgets/project_editor/lore_map_stub.dart:4,40` remains. D-05 removed the old editor. R-10/R-12 own the Lore Map slot. |
| P2-9 | Two fat tree providers | **Still open** | `lib/providers/calendar_tree_provider.dart` 986 lines; `lib/providers/magic_tree_provider.dart` 824 lines. Refactor is not an R-02 P0/P1 item. |
| P2-10 | Oversized modules | **Still open** | `character_module.dart` 3,997 lines; `relation_chart_screen.dart` 1,710 lines; `manuscript_module.dart` 1,633 lines. Refactor is not an R-02 P0/P1 item. |

### P3

| ID | Finding | Status at HEAD | Evidence / action |
| --- | --- | --- | --- |
| P3-11 | Half-dead theme refactor; Dracula unreachable | **Fixed** | `lib/core/theme/app_theme.dart` is absent and `ThemeController`/`themeFromController` have zero callers. The live class is `ThemeNotifier`. `lib/core/theme/theme_bootstrap.dart:12,13` registers `MinimalThemePack` and `DraculaThemePack`; the theme-pack dropdown in `settings_global_panes.dart` reads `themeNotifier.themePack` around 76/88 and calls `setThemePack` around 104/119, so Dracula is selectable. The audit's second option (delete the dead facade, keep the legacy path) is the one taken: `lib/theme/app_theme.dart` still backs `minimal_theme_dark.dart:4,12` and `minimal_theme_light.dart:4,11`; `AppTheme.draculaTheme` at `lib/theme/app_theme.dart:412` is unused. No Stage B action. |
| P3-12 | AA/AAA claim is unmeasured | **Still open** | No contrast/accessibility test exists in `test/`. Not an R-02 P0/P1 item. |
| P3-13 | Hard-coded colors in `project_book/*` | **Still open** | `genre_glow.dart` has 120 unique lines with `Color(0x` (144 occurrences); `project_book_view.dart` has 11; `project_book_demo_screen.dart` has 39. Not an R-02 P0/P1 item. |

### P4

| ID | Finding | Status at HEAD | Evidence / action |
| --- | --- | --- | --- |
| P4-14 | Remove `cupertino_icons` and vestigial `ProviderScope` | **Partially fixed / no action on ProviderScope** | `cupertino_icons` is absent from `pubspec.yaml` and has zero imports. `lib/main.dart:4,58` still wraps the app in `riverpod.ProviderScope`; the SoT explicitly reserves that scope, so the audit recommendation conflicts with the SoT and the SoT wins. |
| P4-15 | Planned dependency upgrades | **Still open** | Versions unchanged: `flutter_quill_extensions: ^11.0.0` (`pubspec.yaml:41`), `file_picker: ^8.0.0` (`:61`), `xml: ^6.5.0` (`:63`). Not an R-02 P0/P1 item. |
| P4-16 | Replace 21 `debugPrint` calls; tighten lints | **Partially fixed** | Zero `print`/`debugPrint` hits in `lib/` and `test/`. `analysis_options.yaml` still includes only `flutter_lints/flutter.yaml`; `avoid_dynamic_calls` and `public_member_api_docs` are not enabled. Enabling `public_member_api_docs` would fail analyze on existing code, so it is not an R-02 change. |

### P5

| ID | Finding | Status at HEAD | Evidence / action |
| --- | --- | --- | --- |
| P5-17 | Coverage roadmap toward ~50% | **Still open** | No coverage measurement or gate. 531 tests exist, but the audit's layer targets are not measured. Not an R-02 P0/P1 item. |
| P5-18 | CI gate | **Fixed** | `.github/workflows/ci.yaml` runs `flutter pub get`, `flutter analyze`, `flutter test` on push and pull request. No `build_runner`. Pre-commit is not configured; CI is the gate. |

## Audit2 findings at HEAD

| ID | Finding | Status at HEAD | Evidence |
| --- | --- | --- | --- |
| D1 | Manuscript history invisible (`targetType` mismatch) | **Fixed** | Same as P1-4. |
| D2 | Three divergent word/character counters | **Fixed** | Same as P1-5. |
| D3 | Find & Replace strips `ref:` and drifts offsets | **Fixed** | Same as P1-6. |
| D4 | `ReferenceIndex` rebuild clears non-manuscript entries | **Fixed** | `manuscript_reference_service.dart:135 rebuildIndex` and `:186 rebuildIndexFor` use `_referenceEngine.removeWhere` at 137/189; the only `engine.clear()` left is `reference_integrity_service.dart:201` inside `purgeAll()`, which is deliberate. |
| D5 | Non-character entity mentions purged as stale | **Fixed** | `reference_name_resolver.dart:124 entityExists`, `:150 _nodeExists`, `:173 entityIsDefinitelyGone`; the latter is the second predicate added for MS-016. |
| D6 | Hierarchy validation is warn-only | **Fixed** | `manuscript_binder_service.dart:566 _validateTypeHierarchy`, throws at 602-603, called from 146/150 and 405/406. |
| D7 | Autosave writes history every ~2 s | **Partial - deferred (OQ-3)** | Content-change guard `_lastSavedContent` exists around `manuscript_module.dart:794`; `_autosaveDelay` is still 2 s at `:310`. SoT defers OQ-2 to OQ-9 to Phase 2. |
| D8a | `ManuscriptReferenceService` instantiated twice | **Fixed** | One service is threaded through the module tree; `manuscript_topology_test.dart` covers MS-015. |
| D8b | `IndexPageWidget` reads legacy `ChapterListProvider` | **Fixed** | `index_page_widget.dart` is binder-only; `manuscript_topology_test.dart` covers MS-003. |
| D8c | Binder delete has no confirmation for non-empty docs | **Fixed** | `manuscript_binder.dart:519 _confirmDelete`, dialog at 524, `_deleteDocument(deleteChildren:)` at 542-560; corkboard uses the same path at `:354`. |
| D8d | `chapter_diff_view_dialog.dart` opens `Hive.box<Chapter>` directly | **Fixed for manuscript** | New `manuscript_diff_view_dialog.dart`; `history_panel.dart:82-87` keeps the legacy dialog only for `'Chapter'`. |
| D8e | `tagIds` stored but never rendered | **Fixed** | `manuscript_inspector.dart:229` renders tag chips; model/provider/service support is at `manuscript_document.dart:94,173,207`, `manuscript_binder_provider.dart:103,118,247,259`, `manuscript_binder_service.dart:141,177,296,309,494`. |

## OQ status

| OQ | Status | Evidence / note |
| --- | --- | --- |
| OQ-1 | **Open by design** | `overview_module.dart:17,27,66,74` and `global_search_delegate.dart:91,106,117-119` still read the legacy chapters box. R-02 says the box stays open until R-14 stops those reads. Do not remove it in Phase 1. |
| OQ-2 | Resolved | `entityIsDefinitelyGone(EntityRef)` is the second predicate; `entityExists` remains a bool. |
| OQ-3 | Open - deferred | `_autosaveDelay` is 2 s at `manuscript_module.dart:310`; guard exists around 794. SoT defers OQ-2 to OQ-9. |
| OQ-4 | Resolved | Inline tag chips in the Inspector at `manuscript_inspector.dart:229`. |
| OQ-5 | Open - deferred | Formatted placeholder date still waits on the Calendar module; no Phase 1 change. |
| OQ-6 | Resolved | `mapData`/`mapLayer` stay in `EntityType.all` until the map module is rebuilt. |
| OQ-7 | Open | Spec §32.1 baseline is stale; current green baseline is 531 tests at this commit. |
| OQ-8 | Open - deferred | Revert path `manuscript_module.dart:549-550,652,667` discards unsaved buffer without a warning. |
| OQ-9 | Open - deferred | Rename goes through `manuscript_binder_service.dart:226 updateTitle`; `manuscript_reference_service.dart:179-180` documents that the extractor does not index titles. |
| OQ-10 | Open | `Project.lastEditedChapterKey` is set only by `chapter_list_provider.dart:99,186`, read at `project_editor_screen.dart:195`, and nulled at `:315`; opening a document from the Index page does not update it. Product question for Phase 2. |

## Ordered fix list for Stage B

1. **Remove `build_runner`.** Delete `build_runner: ^2.4.13` from `pubspec.yaml:76`. Do not add `hive_generator`; it is already absent, so R-02's wording is satisfied by the report. Do not run `dart run build_runner` at any point.
2. **Update the stale codegen comments.** Change `lib/models/manuscript_collection.g.dart:7` and `lib/database/database_metadata.dart:85-87,142-144,229-231` from "Normally produced by build_runner + hive_generator ... version conflict" to a statement that the adapters are committed and hand-maintained and that `build_runner` must not be run. Keep every `@HiveField` number unchanged.
3. **Leave the already-fixed code alone.** P0-2, P0-3, P1-4, P1-5, P1-6, and audit2 D1-D6/D8a-D8e need no Stage B code change. Do not reopen them.
4. **Defer P2-P5 and OQ-3/OQ-5/OQ-8/OQ-9/OQ-10.** They are outside R-02's P0/P1 Done-when. OQ-1 stays open by design; OQ-7 is a baseline note; P4-14's `ProviderScope` stays because the SoT reserves it.
5. **Decide the unused dev dependencies.** `json_serializable: ^6.8.0` (`pubspec.yaml:77`) and `mockito: ^5.4.4` (`:78`) have zero hits in `lib/` and `test/`. R-02 names only `build_runner`, so ask the owner whether to remove them in the same change. Recommended: remove both if no follow-up codegen/mocking is planned.

### Proving checks for the Stage B dependency change

- `flutter analyze` reports zero issues.
- `flutter test` reports 531 passed.
- `git ls-files '*.g.dart'` still reports 14 files; `git diff` shows no `.g.dart` changes.
- `pubspec.yaml` contains no `build_runner` and no `hive_generator`.
- The only remaining `build_runner` text is in the updated explanatory comments; no command, script, or CI step runs it.

## R-22 wave 1 - agent kit

### Installed format evidence

- `opencode --version` -> **1.19.5**.
- `probe-v2.md` used the V2 ordered `permissions:` list (`{action, resource, effect}`). `opencode agent list` showed no edit/bash rules for it; the V2 list is silently ignored.
- `probe-v1.md` used the V1 `permission:` map (`edit` and `bash` with `"*": deny` plus specific allows). `opencode agent list` showed exactly those resolved rules.
- `probe-v1b.md` confirmed the keys `read`, `webfetch`, `websearch`, `task`, `skill`, `external_directory`, `question`, `doom_loop`, `bash`, and `edit`. The shell action key is **`bash`**, not `shell`.
- Global defaults appear after agent rules. A global allow for `C:\Users\jaina\.local\share\opencode\tool-output\*` overrides an agent-level `external_directory: deny` for that path; do not rely on `external_directory: deny` to block tool-output reads.
- Conclusion: write the agents with the **V1 `permission:` map**. `docs/specs/AGENTS_PLAN.md`'s V2 shape (around lines 52-56) is wrong for this binary. `default_agent` is deferred to Wave 2; pointing it at a missing agent falls back to `build`.

### `.opencode/agents/lk-auditor.md`

```markdown
---
description: Read-only auditor for Lore Keeper. Inspects diffs, proves findings with file:line, and reports against requirement IDs without editing code.
mode: subagent
permission:
  edit:
    "*": deny
    "docs/reports/**": allow
  bash:
    "*": deny
    "git log*": allow
    "git status*": allow
    "git diff*": allow
    "git show*": allow
    "git ls-files*": allow
    "git rev-parse*": allow
  read:
    "*": allow
    "**/.env": deny
    "**/.env.*": deny
    "**/*.key": deny
    "**/*.pem": deny
    "**/*.keystore": deny
    "**/*.jks": deny
    "**/secrets/**": deny
  webfetch: deny
  websearch: deny
  task: deny
  skill: deny
  external_directory: deny
  question: deny
---

# Lore Keeper auditor

You are the read-only auditor. You did not write the change and you do not fix it.

Read `docs/SOURCE_OF_TRUTH.md` first. It is the only source of truth. Cite requirement IDs (R-01, R-02, and so on) in every finding. Never restate requirement text; quote an ID and the exact sentence only when the requirement is ambiguous.

## Inputs

- The diff, commit range, or file list from the conductor.
- The acceptance check named in the task.
- The repository at the current HEAD.
- Existing reports under `docs/reports/`.

## Procedure

1. Read the requirement IDs in scope in `docs/SOURCE_OF_TRUTH.md`.
2. Inspect the change with `git status`, `git diff`, `git show`, and `git log`.
3. Check every changed file against the project rules:
   - layering: models, then database, then services, then providers, then modules/widgets, then screens
   - widgets never open Hive boxes
   - Provider + ChangeNotifier only; no new Riverpod providers
   - no `print` or `debugPrint`; use the debug logger
   - no `dart run build_runner`
   - committed `.g.dart` adapters are not regenerated, deleted, or renumbered
   - no secrets, keys, tokens, or personal data
   - behavior changes have tests; no test-only production branches
   - report and doc claims match the code
4. Report only what you can prove with `file:line` or command output.
5. If a rule is not in the source of truth, do not invent it. Record the gap as an open question.
6. If a command is denied or a file is unreadable, stop and report the block; do not work around it.

## Output

Return your report as your final message. Do not write a file unless the conductor explicitly asks for one under `docs/reports/`.

Use this shape:

- Verdict: PASS, FAIL, or BLOCKED
- Findings: severity, `file:line`, evidence, requirement ID, required fix
- Open questions: requirement ID, exact conflict, options
- Coverage: what you inspected and what you did not inspect

## Hard rules

- Never edit source, tests, `pubspec.yaml`, config, or docs outside `docs/reports/`.
- Never run `dart run build_runner`, `flutter pub add`, `flutter pub upgrade`, `git add`, `git commit`, `git push`, or network commands.
- Never read `.env*`, `*.key`, `*.pem`, `*.keystore`, `*.jks`, or `secrets/`.
- Do not ask the user questions; report the block and stop.
```

### `.opencode/agents/lk-reviewer.md`

```markdown
---
description: Independent reviewer for Lore Keeper. Verifies a builder's diff against requirement IDs, runs analyze and tests, and blocks on evidence gaps without editing code.
mode: subagent
permission:
  edit:
    "*": deny
    "docs/reports/**": allow
  bash:
    "*": deny
    "git log*": allow
    "git status*": allow
    "git diff*": allow
    "git show*": allow
    "git ls-files*": allow
    "git rev-parse*": allow
    "flutter analyze*": allow
    "flutter test*": allow
    "flutter --version": allow
  read:
    "*": allow
    "**/.env": deny
    "**/.env.*": deny
    "**/*.key": deny
    "**/*.pem": deny
    "**/*.keystore": deny
    "**/*.jks": deny
    "**/secrets/**": deny
  webfetch: deny
  websearch: deny
  task: deny
  skill: deny
  external_directory: deny
  question: deny
---

# Lore Keeper reviewer

You are the independent reviewer. You did not write the change and you do not fix it.

Read `docs/SOURCE_OF_TRUTH.md` first. It is the only source of truth. Cite requirement IDs in every finding. Never restate requirement text; quote an ID and the exact sentence only when the requirement is ambiguous.

## Inputs

- The builder's diff or commit range.
- The requirement IDs the builder claims.
- The acceptance check named in the task.
- The repository at the current HEAD.

Do not read the builder's chat or reasoning. Judge the diff and the repository.

## Procedure

1. Read the requirement IDs in scope in `docs/SOURCE_OF_TRUTH.md`.
2. Inspect the full diff with `git diff <base>...HEAD` and `git show`.
3. Verify the claimed acceptance check. If there is no check, the verdict is REQUEST CHANGES.
4. Check:
   - layering and the Hive-box boundary
   - Provider + ChangeNotifier only; no new Riverpod providers
   - no `print` or `debugPrint`; use the debug logger
   - no `dart run build_runner`; `.g.dart` adapters intact
   - no secrets or external network calls
   - tests are added or updated and actually exercise the change
   - no unrelated changes or drive-by refactors
   - report and doc claims match the diff
5. Run `flutter analyze` and `flutter test`. Both must pass; paste the tail of each.
6. Try to falsify the builder's claim. "It works" without evidence is not a review.

## Output

Return your report as your final message. Do not write a file unless the conductor explicitly asks for one under `docs/reports/`.

Use this shape:

- Verdict: APPROVE, REQUEST CHANGES, or BLOCKED
- Blocking findings: `file:line`, requirement ID, why it blocks
- Non-blocking findings
- Verification commands and results
- What you could not verify

## Hard rules

- Never edit source, tests, `pubspec.yaml`, config, or docs outside `docs/reports/`.
- Never commit, push, add, run `build_runner`, or run `flutter pub add`/`upgrade`.
- Never read `.env*`, `*.key`, `*.pem`, `*.keystore`, `*.jks`, or `secrets/`.
- If analyze or tests fail, the verdict is REQUEST CHANGES.
- Do not ask the user questions; report the block and stop.
```

### Permission test

Run once per agent in Stage B and record the results in `docs/reports/agent-tests.md` (created then, not in Stage A):

1. Denied edit: attempt to edit `lib/main.dart`; expect denial.
2. Allowed edit: attempt to write `docs/reports/agent-tests.md`; expect success.
3. Denied shell: attempt `git commit`, `rm`, and `dart run build_runner build`; expect denial.
4. Allowed shell: run `git status`, `git log -1`, `git diff`; expect success. For the reviewer, also run `flutter analyze` and `flutter test`.
5. Denied read: create a fixture `.env` and attempt to read it; expect denial.
6. Denied network/tools: attempt `webfetch`, `websearch`, `task`, `skill`, and an external-directory read; expect denial.
7. Denied question: confirm the agent cannot ask and instead reports the block.

Note: `flutter test` writes `.dart_tool` inside the repository; that tool write is unavoidable despite the edit deny. Do not treat it as a permission failure.

### Capability test

- **Auditor:** at HEAD, find and cite `build_runner` at `pubspec.yaml:76`; confirm `hive_generator` is absent; find the legacy chapter reads at `global_search_delegate.dart:91` and `overview_module.dart:17,66`; report 120 unique `Color(0x` lines in `genre_glow.dart` plus 11 in `project_book_view.dart`; report 14 tracked `.g.dart` files.
- **Reviewer:** review a planted-flaw diff that contains (1) a `print`, (2) a widget opening a Hive box, (3) a secret-looking string, (4) a `dart run build_runner` call, and (5) no test. The reviewer must flag all five as blocking. A clean diff must receive APPROVE.

## Unclear or conflicting items

1. **R-02 scope.** The Done-when names only P0/P1, but the Phase 1 gate says "re-check each Sep 20 audit finding ... fix what is still open." This report lists all findings but proposes Stage B code changes only for P0/P1 plus the dependency cleanup. Owner should confirm that P2-P5 stay deferred.
2. **Unused dev dependencies.** R-02 names `build_runner` and `hive_generator`, not `json_serializable` or `mockito`. Both have zero use. Recommended: remove all three non-`hive_generator` entries in the same change; ask if the owner wants a narrower diff.
3. **`hive_generator` is already absent.** R-02's "removed or justified" is satisfied by this report; no code change is needed for it.
4. **AGENTS_PLAN's auditor capability test is stale.** It references a leaked key file, `.clinerules`, and `docs/audit2/` paths that R-01 removed or archived. The replacement test above uses current HEAD facts.
5. **`default_agent`.** Deferred to Wave 2. Do not point it at `lk-conductor` until that file exists; a missing default falls back to `build`.
6. **D7/OQ-3.** The content-change guard is present, but the 2 s debounce remains. SoT defers OQ-2 to OQ-9, so this is not a Phase 1 fix.
7. **OQ-1.** R-02 and R-14 keep the legacy chapters box open; do not remove it in Phase 1.
8. **P4-14 `ProviderScope`.** The audit says remove it; the SoT reserves the Riverpod scope. The SoT wins. `cupertino_icons` is already gone.
9. **P3-13 count.** The audit's 131 is 120 unique lines in `genre_glow.dart` plus 11 in `project_book_view.dart`. `genre_glow.dart` has 144 occurrences because some lines contain two colors; the demo screen's 39 is separate.
10. **P4-16 lint tightening.** `avoid_dynamic_calls` and `public_member_api_docs` are not enabled. Enabling `public_member_api_docs` would fail analyze on existing code; defer or scope it.

## Proposed Change log entries (not applied)

- **R-02:** `hive_generator` was already absent; `build_runner` is removed; the 14 committed `.g.dart` adapters are kept and hand-maintained; P2-P5 findings are status only and remain deferred. Ask whether `json_serializable` and `mockito` are removed too.
- **R-22:** use the V1 `permission:` map; the V2 `permissions:` list is ignored by OpenCode 1.19.5; `default_agent` is deferred to Wave 2; the auditor capability test is replaced with current HEAD facts.
- **OQ-3, OQ-5, OQ-8, OQ-9, OQ-10:** remain open/deferred per the SoT's Phase 2 kickoff rule.
- **OQ-7:** update the baseline note to 531 passing tests at `ebaa117`.

## Final actions

| Action | Result |
| --- | --- |
| Read `docs/SOURCE_OF_TRUTH.md`, both audits, the manuscript spec, `AGENTS_PLAN.md`, `pubspec.yaml`, source, and tests | Done |
| `flutter analyze` | No issues found |
| `flutter test` | 531 passed |
| `opencode --version` / `opencode agent list` on three throwaway probes | 1.19.5; V1 map works, V2 list ignored |
| Changed code, config, tests, or agent files | None |
| Wrote this report | `docs/reports/2026-11-phase-1-plan.md` |

Stage A stops here. Stage B waits for the owner's `"approved"`.
