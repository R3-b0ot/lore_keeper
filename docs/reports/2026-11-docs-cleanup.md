# Docs cleanup report (R-01, Phase 0, Step 1)

Nov 8, 2026 · branch `docs-cleanup` (tag `archive/pre-docs-cleanup` on `main`) · builder: Claude

`docs/SOURCE_OF_TRUTH.md` was not edited. Everything below is an action already taken or a proposal for the Change log, which only the owner can approve.

## Commits

| Commit | Message |
| --- | --- |
| `1324703` | R-01: add the source of truth doc |
| `4911ed2` | R-01: delete stale docs and stray files |
| `f6d87aa` | R-01: archive superseded docs |
| `6f4e737` | R-01: move the two specs under docs/specs and mark them subordinate |

## Final actions (full corrected table)

| File or folder | Action taken |
| --- | --- |
| README.md | Rewritten (28 lines): what it is, how to run, link to the doc, "License: to be decided". |
| AGENTS.md | Rewritten (15 lines): pointer to the doc plus the engineering rules from Constraints, verbatim. |
| TODO.md | Archived to `docs/archive/2026-11/TODO.md`. |
| `.clinerules/PROJECT_CONTEXT.md` | Deleted. |
| `.clinerules/flutter-architecture.md` | Deleted; empty `.clinerules/` removed. |
| `.agent/` | Archived to `docs/archive/2026-11/agent-kit/` (198 files, byte-for-byte). |
| `testsprite_tests/` | Deleted (5 tracked files); contents never printed or copied. |
| `scripts/refactor_timeline.py` | Deleted. |
| `lib/widgets/project_editor/overview_module.dart.bak` | Deleted. |
| `tools/` | Kept unchanged. |
| `.github/workflows/ci.yaml` | Kept unchanged. |
| `docs/CLEANUP_REPORT.md` | Archived to `docs/archive/2026-11/CLEANUP_REPORT.md`. |
| `docs/audit/` (10 files) | Merged as proposals below, then archived to `docs/archive/2026-11/audit/`. |
| `docs/audit2/` (10 files) | Merged as proposals below, then archived to `docs/archive/2026-11/audit2/`. |
| `docs/architecture/00-foundation.md` | Merged as proposals below, then archived. |
| `docs/overhaul/06-lore-keeper-master-plan.md` | Mined for the Phase 3 card spec below, then archived. |
| `docs/overhaul/07-calendar-timeline-todo.md` | Merged into R-20 below, then archived. |
| `docs/overhaul/` other 7 files | Archived; theme engine stays waiting on Open decision 2. |
| `docs/modules/08-maps.md` | Deleted. |
| `docs/modules/09-lore-map.md` | Merged into R-12 below, then archived. |
| `docs/modules/11-secondary-worldbuilding.md` | Merged into R-08 and R-10 below, then archived. |
| `docs/modules/` other 12 files | Archived; `12-chronicles` archive only (outside the register). |
| `docs/LORE_KEEPER_MANUSCRIPT_MASTER_SPEC.md` | Moved to `docs/specs/`, subordinate first line, §0 status text replaced. |
| `docs/Lore_Keeper_Species_Module_Complete_Specification.md` | Moved to `docs/specs/`, subordinate first line; no other body edit. |

## Proposed Change log entries (status Proposed)

### R-02 (code cleanup)

- Keep the legacy `chapters` box open; `GlobalSearchDelegate` and `OverviewModule` still read it. Replace those reads only when those modules are rebuilt (audit2 OQ-1, still open at HEAD).
- `Project.lastEditedChapterKey` is no longer updated when a document is opened from the Index page, so resume can miss it. Product question, no default proposed (audit2 OQ-10, unresolved).
- Carry over the `docs/audit/` P0 and P1 findings that Stage A confirmed still open at HEAD; drop the Sep 20 map-editor recommendation (the editor no longer exists, D-05).
- Remove `build_runner` and `hive_generator` from `dev_dependencies` or record why they stay; they are present but must never be run.

### R-03 to R-07 (manuscript)

- OQ-2: add `entityIsDefinitelyGone(EntityRef)` as a second predicate instead of changing the bool API.
- OQ-3: raise the autosave delay to 5 s and add the content-change guard before increasing history depth.
- OQ-4: edit document tags as inline chips in the Inspector; no separate tag screen yet.
- OQ-5: show a formatted placeholder date until the Calendar module exposes formatting.
- OQ-6: keep `mapData` and `mapLayer` in `EntityType.all` until the map module is rebuilt.
- OQ-7: update the test baseline to the current green count (531 at this commit).
- OQ-8: warn before a revert when the editor buffer has unsaved text.
- OQ-9: keep the current "preserve reference on in-place rename" behaviour, flagged for product review.

### R-12 (graph view)

- `docs/modules/09-lore-map.md` already matches: a graph of linked entities is the intended replacement for the Lore Map stub.

### R-08 and R-10 (card foundation and new card types)

- `docs/modules/11-secondary-worldbuilding.md` matches: Species, Cultures, Magic, Items and others are entity types in one shared workspace.
- Card spec mined from `docs/overhaul/06` (paraphrased; the source sections stay in the archive):
  - A card is an entity with id, project id, type, title, description/content, icon, color, asset references, tags, custom properties, and created/updated timestamps. Specialised domains add their own fields; one giant Hive class is not required.
  - The card face shows title, date or range where temporal, icon/color, primary linked entities, and a duration indicator. The full description is never drawn on the canvas.
  - The inspector handles title, description, temporal range, certainty/precision, calendar, linked characters, locations, factions, manuscripts/scenes, tags, visual style, assets and notes.
  - Links are stored as entity references (P-01), resolved through the shared reference engine; no per-view copy of names.
- These are proposals for the Phase 3 spec, not requirements. The manuscript spec's topology details are deliberately not copied here.

### R-20 (timelines)

- `docs/overhaul/07-calendar-timeline-todo.md` feeds R-20: multi-card events, lanes, eras tied to calendar systems. R-20 is unchanged.

### Superseded and deferred material

- `docs/overhaul/06` §15 map phasing, §23 migration and §27 are superseded by D-04, D-05 and R-15; nothing from them is proposed.
- The temporal engine in §7 to §9 is deferred with R-20 unchanged.
- `docs/architecture/00-foundation.md`: principles P-01 to P-04 match; its "Hive stays the engine" and repository-layer claims conflict with D-01, so nothing is proposed from them.

## Deviations and unexpected findings

- `.agent/` could not take a first-line marker: 93 of its files start with YAML frontmatter. A folder-level `docs/archive/2026-11/agent-kit/ARCHIVED.md` carries the exact sentence instead. This is the deliberate deviation from step 5's wording.
- The manuscript spec's closing line still reads "END OF CANONICAL MANUSCRIPT MODULE SPECIFICATION". It was left alone because step 8 allows only the §0 status edit; the subordinate first line and §0 text make the status unambiguous.
- `docs/audit2/CYCLE_LOG.md` ends at 506 tests; the suite is now 531.
- Empty source folders under `docs/` were removed after the moves.

## Exit check

- "Riverpod": hits in the doc, `AGENTS.md`, `lib/main.dart` and `pubspec.yaml` all agree — the scope is reserved and no Riverpod providers exist.
- "build_runner": hits in the doc, `AGENTS.md`, `README.md`, the specs and handwritten-adapter comments all agree; the dev dependency remains and is logged above.
- "Clean Architecture" and "Map v1": no hits outside the doc.
- No file outside `docs/archive/` claims authority over the doc; both specs now defer to it.
- `flutter analyze`: no issues found.
- `flutter test`: all 531 tests passed.
