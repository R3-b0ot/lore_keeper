# Lore Keeper Source of Truth

Nov 7, 2026 · @Abhishek

## Rules

This doc is the only source of truth for Lore Keeper. If any other file, README, spec or chat message disagrees with it, this doc wins, and a builder must be able to work from this doc alone.

1. Read this whole doc before any task. Cite requirement IDs (R-01, R-02 and so on) in commit messages and task reports.
2. Anything not written here is not a requirement. Put questions in Open decisions; do not invent answers.
3. Until Step 1 is finished, treat every other file under docs/, plus README.md, TODO.md and .agent/, as untrusted background. Never copy a requirement out of them.
4. A requirement is Done only when its acceptance check passes. Statuses are Not started, In progress, Done and Dropped.
5. Do not edit this doc silently. Propose changes in the Change log and wait for the owner to approve.
6. AGENTS.md ends up as a short pointer to this doc plus the engineering rules in Constraints, because coding tools read it automatically at the start of every session.
7. When two requirements conflict, stop, record the conflict in Open decisions and ask. Do not pick one.
8. Agent prompts (files under .opencode/agents/) point to requirement IDs and never restate requirement text, so they cannot drift from this doc.

## Constraints and decisions

Flutter is the only fixed technology. Everything else can change, but only through a decision recorded here.

### Owner decisions

| ID | Decision |
| --- | --- |
| D-01 | Flutter is fixed. Storage, state management and folder structure may be reworked by a recorded decision. |
| D-02 | Desktop first, Windows primary. Other platforms should need UI changes only, never logic changes. |
| D-03 | Offline-first with local storage. No account, no cloud requirement. |
| D-04 | The app is pre-alpha. Existing Hive data may be wiped; no migration or importer is needed for it. |
| D-05 | Map v1 stays removed (cleanup commit 4855305). The new map system is built from scratch, in the style of Inkarnate. |
| D-06 | Built-in map art is first-party and Creative Commons licensed. Users may also import their own packs. No third-party licensed art. |
| D-07 | Existing UX (project dashboard, book-opening entry, shell navigation) stays unless a requirement here changes it. |

### Product principles

- **P-01** A link stores an entity reference (id plus type), never a copied name or description.
- **P-02** Every feature works without AI. AI output is a suggestion the user reviews, and it never overwrites user data.
- **P-03** Modules never open the database directly.
- **P-04** Cross-cutting systems (search, linking, assets, history, export) are built once and shared.

### Engineering rules (current stack, until a decision replaces them)

- Never run `dart run build_runner`. It deletes the committed `.g.dart` Hive adapters. Edit adapters by hand.
- `flutter analyze` must report zero issues and `flutter test` must pass before any task is called done.
- Layering: models, then database, then services, then providers, then modules and widgets, then screens. Widgets never open Hive boxes.
- State uses Provider with ChangeNotifier. Do not add Riverpod providers; the Riverpod scope in main.dart is reserved.
- Use the debug logger, not print.
- Check a third-party package's current documentation before using its API.

## Requirements register

22 requirements across six phases. "Status" is based on reading the code on Nov 7, 2026; "To verify" means an Sep 20 audit finding that may or may not still be open.

| ID | Requirement | Phase | Status | Done when |
| --- | --- | --- | --- | --- |
| R-01 | This doc is the single source of truth; old docs are cleaned per Step 1 | 0 | Done | Every row in the Step 1 table is actioned and the exit check passes |
| R-02 | Remove dead code and stray files; fix still-open audit defects; the legacy chapters box stays open until global search (R-14) stops reading it | 1 | To verify | Analyzer reports zero issues, tests pass, the audit P0 and P1 items are each confirmed fixed or still open, and build_runner and hive_generator are removed from dev dependencies (or their presence is justified in the report) |
| R-03 | @mention authoring: autocomplete, aliases, plural and possessive matching, typo tolerance, hover preview | 2 | Partial | Each behavior has a passing test and works in the editor |
| R-04 | Scan tool that finds entity names in a manuscript and creates references; manual links are never overwritten; on or off per project | 2 | Not started | Running the scan on a sample chapter links every known name once and leaves manual links untouched |
| R-05 | Manuscript history and diff work for documents, not only chapters | 2 | Implemented, verify | A saved document appears in history and its diff opens |
| R-06 | Export: manuscript to Markdown, DOCX and PDF (EPUB later); whole project to a Markdown zip plus JSON | 2 | Not started | The export setting works and a sample project round-trips to readable files |
| R-07 | One shared word and character counter | 2 | Implemented, verify | Editor, binder and migration show the same count for the same text |
| R-08 | Generic card system: user-defined types, subtypes, templates, custom properties, nested child cards, all linked by entity reference; every card has an id, project id, type, title, content, icon, color, asset references, tags and timestamps, and specialised types add their own fields without one shared giant class | 3 | Not started | A new type can be created and filled with no new code |
| R-09 | Characters, Magic, Calendar, Timeline and Species become specialised views over the card model with no UX regression | 3 | Not started | Each module opens the same screens as today, backed by cards |
| R-10 | Locations, Items, Cultures, Languages, Philosophies, Religions, Systems, Research and Arcs ship as card types with templates; placeholder tabs removed | 3 | Not started | No tab shows "Coming soon" |
| R-11 | Version history and undo on every card | 3 | Not started | Any card can be restored to an earlier snapshot |
| R-12 | Graph view over the reference engine with type filters, focus and edge-type toggles; replaces the Lore Map stub | 4 | Not started | Selecting a card shows its connections and opens it |
| R-13 | Relationship types, including family-tree style | 4 | Partial | Family, organisation and custom relation sets can be drawn |
| R-14 | Global search with a command palette (Ctrl+K) across all entity types | 4 | Partial | One shortcut finds any card, manuscript document or map, and search no longer reads the legacy chapters box |
| R-15 | New map maker: stamps, textures, brushes, layers, pan and zoom | 5 | Not started | A user can paint a world map from the built-in art alone |
| R-16 | Map pins and zones link to cards by entity reference and show the card's current name, icon and color; a pin or zone can open another map | 5 | Not started | Renaming a card updates every pin that points to it |
| R-17 | Built-in Creative Commons art sets plus user-imported packs, with license info stored per asset | 5 | Not started | Every shipped asset has a recorded license |
| R-18 | Whole-project backup and restore in a readable format | 4 | Not started | A backup restores to an identical project |
| R-19 | Import from Markdown, Obsidian and Word | 4 | Not started | A sample Obsidian folder imports as cards with links intact |
| R-20 | Timelines: multi-card events, lanes, eras tied to calendar systems | 4 | Partial | An event can reference several cards and sit in a named era |
| R-21 | Project asset library shared by cards and maps: images, icons and imported packs, with usage tracking | 3 | Not started | One asset is used on a card and on a map, and deleting it warns about both uses |
| R-22 | Project agents in .opencode/agents/: each reads this doc first, has narrow write permissions, and passes a permission test and a capability test before it is trusted; read-only agents come first | 1 | Not started | Every agent's test results are recorded in docs/reports/agent-tests.md and the owner has approved them |

### Out of scope

Status Dropped, with the reason: real-time collaboration, cloud accounts and sync, hosted wikis and custom domains, a public API, RPG and 5e campaign tools, achievements, 3D book covers and voice memos. Each needs a backend or serves a different audience than a solo author. Revisit only by a recorded decision.

Deferred, not dropped: the calendar temporal engine from the old master plan. R-20 stays as written until Phase 4 planning, and builders must not revive the engine from the archive.

## Build order

A phase starts only when the previous gate passes and the owner has seen its report. Every gate also requires zero analyzer issues, passing tests, and each listed requirement marked Done with its acceptance check shown.

1. **Phase 0, docs cleanup (R-01).** Step 1 below. Gate: the exit check passes and docs/SOURCE_OF_TRUTH.md is the only authoritative document in the repo.
2. **Phase 1, code cleanup (R-02, R-22).** Remove the .bak file and one-off scripts, re-check each Sep 20 audit finding against current code, fix what is still open. Gate: a short report marking each finding fixed, still open or no longer applicable, and the read-only agents of R-22 pass their tests.
3. **Phase 2, manuscript (R-03 to R-07).** Clean setup of the manuscript module: mention upgrades, scan tool, history, one word counter, export. Gate: a sample project exports to Markdown, DOCX and PDF with every chapter in order.
4. **Phase 3, card foundation (R-08 to R-11, R-21).** Proposed, pending owner approval (see Open decisions). Gate: Locations works end to end as a card type and Characters opens the same screens as before.
5. **Phase 4, connectivity and data safety (R-12 to R-14, R-18 to R-20).** Gate: graph view, Ctrl+K search, backup and restore, and at least one import source all work.
6. **Phase 5, maps (R-15 to R-17).** The largest piece, built last. Gate: a world map painted from built-in art, with a pin that links to a Locations card.

### Rules for every phase

- Begin with a read-only report: what exists, what this doc requires, and the gap. Change no code until the owner approves it.
- Commit messages cite requirement IDs.
- On any conflict between requirements, stop and ask (Rule 7).

## Step 1: docs cleanup

Of 24 items in the repo, 6 should be deleted, 8 merged then archived, 4 archived, 4 kept and 2 rewritten. The verdicts below are a first pass from headings and openings; the builder must read each file fully and correct the table where the full read disagrees.

### Procedure

1. Create branch `docs-cleanup` and tag the current main `archive/pre-docs-cleanup`.
2. The owner exports this doc to `docs/SOURCE_OF_TRUTH.md`. The builder never edits that file.
3. For each row below, read the whole file, list its claims, and mark each as matches, conflicts, new requirement or obsolete.
4. For Merge rows, write the extracted claims as proposed edits in the Change log. Do not put them in code or straight into this doc.
5. Apply the verdict. Delete means `git rm`. Archive means `git mv` into `docs/archive/2026-11/` with the first line "ARCHIVED, NOT AUTHORITATIVE. See docs/SOURCE_OF_TRUTH.md." Keep-subordinate means move to `docs/specs/` with the first line "Subordinate to docs/SOURCE_OF_TRUTH.md; that doc wins on conflict." Where a folder's files start with YAML frontmatter, put an ARCHIVED.md in the folder instead.
6. Rewrite README.md (under 60 lines: what it is, how to run it, a link to this doc). Reduce AGENTS.md to "read docs/SOURCE_OF_TRUTH.md first" plus the engineering rules from Constraints.
7. Add `docs/README.md` listing only the source of truth, reports (docs/reports/), `docs/specs/` and `docs/archive/`.
8. Exit check: search outside `docs/archive/` for "Riverpod", "build_runner", "Clean Architecture" and "Map v1". Every hit must agree with this doc. The analyzer and tests still pass, and no file outside the archive claims authority over this doc. In each moved spec, the only body edit allowed is replacing the section 0 "canonical" status text with the subordinate statement.
9. Report each file's final action, the proposed edits, and anything unexpected.

### Verdicts

| File or folder | Size | What it holds | Conflict with this doc | Verdict |
| --- | --- | --- | --- | --- |
| README.md | 161 lines | Overview, setup, usage | Placeholder clone URL and license text | Rewrite, short, link to this doc |
| AGENTS.md | 277 lines | Engineering rules and persona instructions | Mostly consistent; the rules now live under Constraints | Shrink to a pointer plus the engineering rules |
| TODO.md | 44 lines | Theme-token to-do from earlier theme work | Theme engine is not in the register | Archive |
| .clinerules/PROJECT_CONTEXT.md | 56 lines | States Riverpod, names an old branch, says do not rewrite the architecture, lists an old priority | Conflicts with D-01, D-04 and the engineering rules | Delete |
| .clinerules/flutter-architecture.md | 51 lines | Persona prompt; orders running build_runner and strict three-layer Clean Architecture | build_runner deletes the Hive adapters; layering conflicts with Constraints | Delete |
| .agent/ | 198 files, about 30,000 lines of markdown | A generic agent kit (its own index lists 20 agents, 36 skills, 11 workflows for web, Next.js, SEO, games, Python and Rust); GEMINI.md is marked always-on and tells tools to load these first | Competes with this doc for authority; almost none of it applies to a Flutter desktop app | Archive to docs/archive/2026-11/agent-kit/; the project agents (R-22) replace it later |
| testsprite_tests/ | 5 files plus a PDF | A test plan for a web app called Worldbuilder Studio, mentioning procedural map generation; an unrelated business-card PDF; config.json holds what looks like a live API key | Describes the removed Map v1 and the wrong platform | Delete; never copy its contents anywhere (the key auto-expires, so nothing needs to wait) |
| scripts/refactor_timeline.py | 75 lines | One-off refactor script with a hard-coded E:\\ path | None | Delete |
| lib/widgets/project_editor/overview_module.dart.bak | n/a | Stray backup of a source file | None | Delete |
| tools/ (2 .cmd files) | 9 lines | Local analyze and test helpers with a hard-coded E:\\src\\flutter path | None | Keep; make the path configurable later |
| .github/workflows/ci.yaml | 25 lines | CI runs analyze and test | None | Keep |
| docs/CLEANUP_REPORT.md | 228 lines | Record of the Sep 20 cleanup, including the Map v1 removal | None; accurate history | Archive |
| docs/audit/ | 10 files | Sep 20 read-only audit; the cleanup fixed part of it | Recommends wiring an old map editor that no longer exists | Merge open findings into R-02, R-05, R-07, then Archive |
| docs/audit2/ | 10 files, including a 2,316-line cycle log | A current-state manuscript audit written after docs/audit/; some of its findings are already fixed at HEAD | Repeats the "Canonical / Normative" claim; merging it verbatim would reopen fixed defects | Re-check its open questions OQ-1 to OQ-10 at HEAD, merge the still-open ones into R-02 and R-03 to R-07, then Archive the whole folder |
| docs/architecture/00-foundation.md | 748 lines | "Foundational contract": data is authoritative, modules do not own the database, local-first, repository layer, preserve the current UI | Principles match P-01 to P-04; "Hive stays the engine" and the repository layer conflict with D-01 | Merge, then Archive |
| docs/overhaul/06-lore-keeper-master-plan.md | 1,818 lines | Aug 20 roadmap: canonical entity model, universal linking layer, calendar and timeline priority | Source material for R-08, R-12 and R-20; its stack and order are out of date | Mine for the Phase 3 card spec, then Archive |
| docs/overhaul/07-calendar-timeline-todo.md | 128 lines | Calendar and timeline to-do | Feeds R-20 | Merge into R-20, then Archive |
| docs/overhaul/ other 7 files (00 to 05, 06-implementation-phases) | 33 to 147 lines each | Navigation, dashboard, book opening, theme engine, module roadmap, phases | Phases and Dracula theme work conflict with Build order; navigation and dashboard are covered by D-07 | Archive; theme engine waits on Open decision 2 |
| docs/modules/08-maps.md | 95 lines | Says maps are "spatial lenses", not a cartography product; phase 1 is image upload | Contradicts D-05 and R-15 | Delete; replaced by R-15 to R-17 |
| docs/modules/09-lore-map.md | 83 lines | Graph of linked entities | Matches R-12 | Merge, then Archive |
| docs/modules/11-secondary-worldbuilding.md | 143 lines | Species, Cultures, Magic, Items and others as entity types in one shared workspace | Matches R-08 and R-10 | Merge, then Archive |
| docs/modules/ other 12 files (00 guide, 01, 02, 03, 04, 05, 06, 07, 10, 12, 13, 14) | 54 to 112 lines each | Module contracts, reference apps, models, behaviour | Mostly consistent; 12-chronicles is an endgame feature outside the register | Merge into the matching R-IDs when that phase starts, then Archive; Archive 12-chronicles only |
| docs/LORE_KEEPER_MANUSCRIPT_MASTER_SPEC.md | 1,751 lines | Self-declared canonical manuscript spec, Windows desktop first | Claims authority that belongs to this doc | Keep as a subordinate spec; reconcile at the start of Phase 2 |
| docs/Lore_Keeper_Species_Module_Complete_Specification.md | 2,157 lines | Species module spec, AI kept independent of the UI | Consistent with P-02; the module is already built | Keep as a subordinate spec |

## Open decisions

Builders must wait for the owner's answer on any item that blocks their phase; the suggested answer is advice, not permission.

| # | Question | Suggested answer | Blocks |
| --- | --- | --- | --- |
| 1 | **Resolved:** the key in testsprite_tests/tmp/config.json: does it still need revoking? | Owner answer, Nov 8: no action needed because the key auto-expires; the folder can be deleted now | Nothing |
| 2 | Is the community theme engine (Dracula pack, token files, JSON themes) still wanted? | Not before maps; archive its docs and keep the current minimal pack | Archiving docs/overhaul/03 |
| 3 | Are the two long specs (manuscript, species) subordinate to this doc, or folded into it? | Subordinate, reconciled when their phase starts | Phase 0 step 5, Phase 2 |
| 4 | Build the card foundation (Phase 3) before maps? | Yes: maps, graph and the placeholder tabs all depend on it | Phase 3 |
| 5 | Stay on Provider, or move to Riverpod (the scope is already wrapped in main.dart)? | Stay on Provider | Phase 3 |
| 6 | Stay on Hive for the card system, or choose a store better suited to linked data? | Stay on Hive until a concrete need appears | Phase 3 |
| 7 | What happens to the .agent folder? | Archive it under docs/archive/ until the project agents (R-22) are trusted | Phase 0 |
| 8 | Which license does the repo use? README has a placeholder | Owner: decide later; the README says "License: to be decided" | Phase 0 README rewrite |
| 9 | Should Continue writing reopen the last document opened from any entry point? Today the stored key is not updated when a document is opened from the Index page, so resume can miss it | Yes: update it on every document open | Phase 2 |

## Change log

To change a requirement, decision or rule, add a row with status Proposed. Only the owner changes it to Approved and edits the text above. After each approved change, re-export this doc to `docs/SOURCE_OF_TRUTH.md`.

| Date | Change | Proposed by | Status |
| --- | --- | --- | --- |
| Nov 7, 2026 | Doc created from the vvd comparison, a scan of the repo's docs and the owner's stated decisions | Claude | Pending owner review |
| Nov 8, 2026 | Added the docs/audit2 row; changed the .agent verdict to Archive; new exit-check wording; R-21, R-22 and rule 8; docs/reports/ in the docs index; recorded owner answers on the key, license and .agent | Claude | Applied, pending owner review |
| Nov 8, 2026 | Applied the Stage B proposals: R-02, R-08 and R-14 wording, a note deferring the temporal engine, the ARCHIVED.md allowance in Step 1, and Open decision 9. Manuscript spec questions OQ-2 to OQ-9 are deferred to the Phase 2 kickoff and not copied here | Claude | Applied, pending owner review |
| Nov 9, 2026 | R-01 Done: docs-cleanup merged to main after the 38 manuscript-rebuild commits (MS-001 to MS-029) were merged separately; analyzer clean and 531 tests passing before the second merge. R-05 and R-07 set to Implemented, verify because that manuscript work covers history and diff (MS-006 to MS-008) and the shared word and character counters (MS-009, MS-010); each still needs its Done-when check run. R-02's audit findings must be re-checked against this merged main, since that work fixed several of them | Claude | Applied, pending owner review |
