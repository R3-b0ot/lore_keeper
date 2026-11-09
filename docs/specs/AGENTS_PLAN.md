# Lore Keeper Agents: Roster and Build Plan

Subordinate to docs/SOURCE_OF_TRUTH.md; that doc wins on conflict.

Nov 8, 2026 · @Abhishek

## Summary

Replace the current `.agent` folder with a small set of Lore Keeper-specific OpenCode agents, rather than patching its 20 generic ones. Keep their useful habits (systematic debugging, test-first loops, codebase exploration) as short notes inside the new agents.

- **Primary agents (2):** `lk-conductor` runs the phase protocol and approval gates; `lk-builder` implements one requirement at a time.
- **Subagents (6 now):** `lk-auditor`, `lk-reviewer`, `lk-tester`, `lk-data-guardian`, `lk-docs-keeper`, `lk-ux-guard`.
- **Later (1):** `lk-asset-licensor`, for the map phase.

Every agent reads docs/SOURCE_OF_TRUTH.md first and cites requirement IDs. Write limits are enforced by OpenCode permissions, not by wording in a prompt, and a separate agent reviews every change before it counts as done.

Nothing in this doc has been sent to OpenCode.

## Why the current agents fall short

The kit is a generic multi-stack toolkit, not a Lore Keeper toolset. Counts come from the `.agent` folder in my copy of the repo, which may be slightly older than your local one.

- **Wrong stack.** 20 agents cover React and Next.js, Node and Python backends, SEO, games, deployment and penetration testing. Only 3 mention Flutter, Dart or Hive at all, and none mention Hive adapters, type IDs or the build_runner trap.
- **Overlap.** The product-manager and product-owner agents cover the same ground, and the test-engineer and qa-automation-engineer agents overlap on web end-to-end testing.
- **Heavy.** Agents plus skills total about 28,000 lines of markdown. Every skill an agent loads is more context to read before it starts.
- **Competing authority.** GEMINI.md is marked always-on and sets its own priority order (itself, then agent files, then skills). Nothing refers to the Source of Truth.
- **Wrong format.** The files use `tools:` and `skills:` frontmatter. OpenCode's current docs list `tools` as a legacy field and control tools through `permissions`, so these limits may not be enforced. Check this against your installed version.
- **Loose permissions.** Most agents get Edit, Write and Bash with no limits and nothing blocks editing the committed Hive adapters.

### What happens to each old agent

| Old agent | Fate |
| --- | --- |
| explorer-agent, code-archaeologist | Become `lk-auditor` |
| orchestrator, project-planner | Become `lk-conductor` (the orchestrator's own advice to start with 2 to 3 agents stays) |
| mobile-developer | Becomes `lk-builder`, Flutter only |
| debugger | Its method becomes a short debugging protocol inside `lk-builder` |
| test-engineer, qa-automation-engineer | Become `lk-tester`; unit and widget tests only, no Playwright or Cypress |
| database-architect | Becomes `lk-data-guardian`, for Hive instead of SQL |
| documentation-writer | Becomes `lk-docs-keeper`; its "only when asked" restraint stays |
| performance-optimizer | Dropped for now; revisit when the graph or maps need it |
| product-manager, product-owner | Dropped; the Source of Truth register does their job |
| frontend, backend, game, SEO, devops, penetration-tester, security-auditor | Dropped as not applicable; a secret scan moves into `lk-reviewer` |

## Design rules

### How OpenCode defines an agent

From [OpenCode's agent docs](https://opencode.ai/docs/agents/), read Nov 8, 2026.

- One markdown file per agent at `.opencode/agents/<name>.md`. The frontmatter holds options and the body is the agent's system prompt.
- Frontmatter fields: `description` (the model uses it to pick a subagent), `mode` (`primary`, `subagent` or `all`), `model`, `permissions`, `steps` (maximum model steps), `hidden`, `color`, `disabled`.
- `permissions` is an ordered list of `action`, `resource` and `effect` (`allow`, `ask` or `deny`). The last matching rule wins, so broad rules go first. Actions include `edit`, `shell`, `subagent`, `read`, `skill`, `webfetch` and `external_directory`.
- Subagents start with fresh context. The parent's `subagent` permissions decide which ones it may launch.
- Built-in agents `build`, `plan`, `general` and `explore` exist, and reusing an ID overrides one.
- The docs call the older frontmatter (`tools`, `permission`, `maxSteps`) deprecated. Confirm which format your installed OpenCode version expects before building.

### Rules for every Lore Keeper agent

1. **Source of Truth first.** Every prompt starts by reading docs/SOURCE_OF_TRUTH.md, citing requirement IDs, and stopping to ask if something is not covered (its Rules 2 and 7).
2. **Least privilege in permissions, not in prose.** Default-deny edits and open only the paths the agent owns.
3. **One lane per path.** The builder edits `lib/` except models and database, the data guardian owns `lib/models` and `lib/database`, the tester owns `test/`, the docs keeper owns `docs/` except SOURCE_OF_TRUTH.md. Start strict and loosen only if the handoffs cause friction.
4. **Nobody grades their own work.** The reviewer sees only the diff, the Source of Truth and the acceptance check, never the builder's reasoning.
5. **Reports are files.** Each agent writes a short report under `docs/reports/` and returns a summary of about ten lines.
6. **Hard stops are denied by permission:** `dart run build_runner`, `git push`, edits to SOURCE_OF_TRUTH.md, hand edits to `.g.dart` outside the data guardian, and reading secret files.
7. **Short prompts.** About 80 lines each, only Lore Keeper facts, no generic skill libraries.
8. **Step limits.** Set `steps` so a stuck agent stops and reports instead of looping.
9. **Done means evidence.** Analyzer at zero issues, tests passing, and the requirement's "Done when" check shown.
10. **Models.** Leave them inheriting at first; pin cheaper models to the read-only agents once they have proven themselves.

## Proposed roster

Nine agents, two primary and seven subagents. Only the builder can edit application code broadly, and every other agent writes to a narrow path.

| Agent | Mode | Job | May write | May run | First used |
| --- | --- | --- | --- | --- | --- |
| `lk-conductor` | Primary | Runs a phase: reads the Source of Truth, plans, delegates, enforces report-then-approval, gathers reports | `docs/reports/` | `git status`, `git log` | Phase 1 |
| `lk-builder` | Primary | Implements one requirement at a time from an approved report; one commit series per requirement ID | `lib/` except `models/` and `database/` | `flutter analyze`, `flutter test`, `flutter format`, `git add`, `git commit` | Phase 1 |
| `lk-auditor` | Subagent | Read-only gap reports: Source of Truth against code and old docs (the Stage A job) | `docs/reports/` | Search and `git log` only | Phase 1 |
| `lk-reviewer` | Subagent | Independent review of a diff against requirement IDs, layering rules, acceptance check, and a secret scan | `docs/reports/` | `flutter analyze`, `flutter test`, `git diff` | Phase 1 |
| `lk-tester` | Subagent | Writes the tests for each acceptance check and keeps the suite green | `test/` | `flutter test` | Phase 2 |
| `lk-data-guardian` | Subagent | Hive models, hand-kept adapters, unique type IDs, box setup, schema notes | `lib/models/`, `lib/database/` | `flutter test`, a type-ID collision check | Phase 2 |
| `lk-docs-keeper` | Subagent | Archive moves, README and AGENTS pointers, Change log proposals | `docs/` except SOURCE_OF_TRUTH.md, README.md, AGENTS.md | `git mv`, `git add` | Phase 2 |
| `lk-ux-guard` | Subagent | Protects the existing UX (D-07): navigation, dashboard, book opening, widget keys, theme tokens, desktop-first layout | `docs/reports/` | `flutter test` | Phase 2 |
| `lk-asset-licensor` | Subagent, later | Confirms every shipped map asset has a Creative Commons license record (R-17) | `docs/reports/` | Search only | Phase 5 |

## Agent specs

Each spec becomes the body of one `.opencode/agents/<name>.md` file, plus the permissions from the roster table.

### lk-conductor

- **Takes:** a phase number or requirement IDs from the owner.
- **Delivers:** a plan listing each task, its agent and the gate; waits for the owner's "approved"; then a gate report showing each acceptance check's result.
- **Never:** edits code, skips the approval step, or starts more than 2 to 3 subagents at first.

### lk-builder

- **Takes:** one approved requirement ID and its audit report.
- **Delivers:** the change, a commit series citing the ID, analyzer and test output, and a list of files touched. Debugging protocol: reproduce, isolate, fix the root cause, add a test, confirm.
- **Never:** works on two requirements at once, edits models or database (asks the conductor for the data guardian), runs build_runner, pushes, or changes UX covered by D-07 without a requirement.

### lk-auditor

- **Takes:** a phase or requirement IDs.
- **Delivers:** a report with what exists in code, what the Source of Truth requires, the gap, and conflicts between docs and code, each with file and line references.
- **Never:** edits outside `docs/reports/`, takes requirements from old docs, or reports from headings without reading the file.

### lk-reviewer

- **Takes:** a diff and the requirement IDs it claims to satisfy.
- **Delivers:** pass or fail per acceptance check, rule violations in severity order (layering, adapters, print statements, hard-coded strings), and a secret-scan result.
- **Never:** sees the builder's reasoning, edits anything, or passes a change without running the analyzer and tests.

### lk-tester

- **Takes:** a requirement's "Done when" line.
- **Delivers:** tests that fail before the change and pass after it, using in-memory Hive for storage tests as the repo already does.
- **Never:** edits `lib/`, weakens or deletes a test to make it pass, or adds web end-to-end tools.

### lk-data-guardian

- **Takes:** a model or schema change request, relayed by the conductor.
- **Delivers:** the model change, the hand-written adapter update, a unique type ID, box registration, a schema note, and passing tests.
- **Never:** runs build_runner, reuses a type ID, or writes a migration unless the owner says that data must survive (D-04).

### lk-docs-keeper

- **Takes:** the Step 1 verdict table or an approved Change log entry.
- **Delivers:** file moves, archive banners, README and AGENTS rewrites, and new Change log rows marked Proposed.
- **Never:** edits SOURCE_OF_TRUTH.md, deletes a file the verdict table does not list, or copies claims from archived docs into live ones.

### lk-ux-guard

- **Takes:** any diff that touches UI.
- **Delivers:** a checklist result: navigation items unchanged, dashboard and book opening still work, existing widget keys kept, colors from theme tokens, layout sound at desktop and narrow widths, widget tests run.
- **Never:** edits files or proposes a redesign.

### lk-asset-licensor (later)

- **Takes:** a new or changed map asset pack.
- **Delivers:** a table of every asset with its source, license, author and attribution text, plus a list of assets missing a license.
- **Never:** accepts an asset without a named Creative Commons license and its source address.

## Build plan

Build in four waves, safest first. An agent is trusted only after it passes a test with a known answer, and the conductor delegates only to trusted agents. The Phase 0 docs cleanup does not need any of these; plain OpenCode can finish it.

| Wave | Agents | Test with a known answer |
| --- | --- | --- |
| 1. Read-only | `lk-auditor`, `lk-reviewer` | The auditor re-runs the docs audit and must find the known issues (the `audit2` folder, the leaked key file, the `.clinerules` conflicts). The reviewer reviews a planted-flaw diff (a print statement, a widget opening a Hive box, a secret-looking string, a build_runner call) and must catch all four. |
| 2. Gatekeeper | `lk-conductor` | Given "Phase 1", it produces a plan and stops without touching a file. Told to skip approval, it refuses. |
| 3. Writers | `lk-builder`, `lk-tester`, `lk-data-guardian` | Run them on R-07 (one shared word counter), small and contained. A task needing a new model field must route to the data guardian. build_runner and `git push` must be refused. |
| 4. Support | `lk-docs-keeper`, `lk-ux-guard`; `lk-asset-licensor` in Phase 5 | The docs keeper cannot edit SOURCE_OF_TRUTH.md. The UX guard flags a planted diff that removes a navigation item. |

### Checklist for each agent

1. Write `.opencode/agents/<name>.md`: frontmatter plus a prompt of about 80 lines. The prompt points to requirement IDs and never restates requirement text, so it cannot drift from the Source of Truth.
2. Permission test: attempt every forbidden action once. Each must be refused or ask first.
3. Run the capability test from the table above.
4. Record both results in `docs/reports/agent-tests.md`.
5. The owner approves, and only then is the agent listed as trusted in the conductor's prompt.

## Open decisions and Source of Truth changes

None of this applies until you approve it. The Source of Truth is untouched so far.

### Decisions for you

| # | Question | Suggested answer |
| --- | --- | --- |
| 1 | What happens to the old `.agent` folder? | Archive it under `docs/archive/` instead of deleting, until Wave 4 is trusted. The tag from Step 1 keeps it either way |
| 2 | Which OpenCode version is installed? The agent file format differs between the older and newer frontmatter | Run `opencode --version` and check it against the agent docs before Wave 1 |
| 3 | Where do agent reports live? | `docs/reports/`, committed, so there is a history |
| 4 | Should the builder be blocked from `models/` and `database/`? | Yes at first; loosen only if the handoffs cause friction |
| 5 | Should `lk-conductor` be the default primary agent, so every session starts behind the approval gate? | Yes |
| 6 | Which models should the agents use? | Inherit at first; pin cheaper models to the read-only agents later |

### Changes this needs in the Source of Truth

Each goes into its Change log as Proposed; you approve before the text changes.

- **New requirement R-22:** project agents live in `.opencode/agents/`, are built per this doc, and each has passed its tests recorded in `docs/reports/agent-tests.md`. Phase 1 to 2.
- **New rule:** agent prompts point to requirement IDs and never restate requirement text.
- **Open decision 7:** change from "delete the whole .agent folder" to "archive it" (this doc's decision 1).
- **Step 1, step 7:** `docs/README.md` also lists `docs/reports/`.
- **Step 1, `.agent/` row:** verdict changes from Delete to Archive.
