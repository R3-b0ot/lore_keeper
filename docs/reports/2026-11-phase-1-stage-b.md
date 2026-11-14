# Phase 1 Stage B report (R-02 cleanup + R-22 agent kit wave 1)

Nov 14, 2026 - branch `phase-1` (base `ebaa117`, code HEAD `40543c0`) - builder: opencode

`docs/SOURCE_OF_TRUTH.md` was not edited. `docs/specs/AGENTS_PLAN.md` was not edited. Stage A's report (`docs/reports/2026-11-phase-1-plan.md`) is the plan this stage followed; where it conflicts with `AGENTS_PLAN.md`, the Stage A report wins.

## Commits

| Commit | Date | Requirement | Subject |
| --- | --- | --- | --- |
| `ef3ccf2` | 2026-11-09 | R-02 | Remove `build_runner` and correct adapter comments |
| `0230c99` | 2026-11-09 | R-02 | Remove unused `json_serializable` and `mockito` |
| `5bbeb07` | 2026-11-09 | R-22 | Add wave 1 auditor and reviewer agents |
| `40543c0` | 2026-11-14 | R-22 | Address reviewer findings and broaden secret ignore |

Each commit was followed by `flutter analyze` (zero issues) and `flutter test` (531 passed). The final tree is green.

## R-02 - dependency and comment cleanup

| Change | Evidence |
| --- | --- |
| `build_runner: ^2.4.13` removed from `dev_dependencies` | `pubspec.yaml` and `pubspec.lock` diffs in `ef3ccf2` are removals only. |
| `hive_generator` was already absent | No entry existed at `ebaa117`; R-02's "removed or justified" is satisfied without a code change. |
| `json_serializable: ^6.8.0` and `mockito: ^5.4.4` removed | Zero hits in `lib/` and `test/`; owner approved removal in the Stage B instruction. `0230c99` removes 2 pubspec lines and 88 lock lines, no insertions. |
| Stale codegen comments rewritten | `lib/models/manuscript_collection.g.dart` and `lib/database/database_metadata.dart` now say the adapters are committed and hand-maintained and that `build_runner` must not be run. Every `typeId` and `@HiveField` is unchanged. |
| All 14 committed adapters kept | `git ls-files '*.g.dart'` = 14 (12 in `lib/models/`, plus `lib/screens/trait_editor_screen.g.dart` and `lib/services/trait_service.g.dart`). No `.g.dart` file changed in Stage B. |

R-02's Done-when names only audit P0/P1. P2-P5 remain status-only and deferred; OQ-1 stays open by design; OQ-3/OQ-5/OQ-8/OQ-9/OQ-10 remain deferred per the SoT. No Stage B code change reopened a closed audit item.

## R-22 - agent kit wave 1

### Shipped files

| File | State |
| --- | --- |
| `.opencode/agents/lk-auditor.md` | Read-only subagent. V1 `permission:` map. Edit, web, task, skill, question, external-directory denied. Bash defaults deny; read-only git allowed. |
| `.opencode/agents/lk-reviewer.md` | Independent reviewer subagent. Same shape, plus `flutter analyze`, `flutter test`, `flutter --version`. |
| `.gitignore` | Local-secrets block: `.env`, `.env.*`, `*.env`, `*.env.*`, `*.envrc`, case variants, with `!**/.env.example`. |
| `docs/reports/agent-tests.md` | R-22 test record: configuration, tests 0-7, residual limits, owner approval pending. |

### Permission model

Both agents use the V1 `permission:` map, which is the shape OpenCode 1.19.5 actually honours. The V2 ordered `permissions:` list in `docs/specs/AGENTS_PLAN.md` is silently ignored by this binary.

- Read: allow by default; deny `*.env`, `*.env.*`, `**/.env`, `**/.env.*`, `.env/**`, `.env.*/**`, `**/.env/**`, `**/.env.*/**`, `*.envrc`, `**/.envrc`; allow `*.env.example` and `**/.env.example`.
- Bash: deny by default; allow read-only git, and for the reviewer the three Flutter commands. After the git allows, deny output redirection, `--no-index`, patch/log dumps, and `.env` forms (`git diff*.env*`).
- The over-broad `git diff*-- .env*` deny was removed in `40543c0`; it did not fix the dotfile case and was redundant with `git diff*.env*`.

### Tests

| Test | Result |
| --- | --- |
| 0 - discovery | Both agents load; custom agents are subagents, so tests used a primary prompt or a temporary primary-mode copy. |
| 1 - edit deny | Pass: no write-capable tool; probe file absent. |
| 2 - bash allow/deny | Pass: read-only git and Flutter allowed; `build_runner`, `git commit`, `--output`, `--no-index`, `Remove-Item` denied. |
| 3 - auditor capability | Pass: reviewed `ebaa117`, reported 120 unique / 144 raw `Color(` lines in `genre_glow.dart`, no provable P0/P1 violation; file byte-identical after. |
| 4 - secret reads | Pass for tested paths: `.env` variants, nested `.env/`, `.envrc` denied; `.env.example` allowed. |
| 5 - reviewer planted flaws | Pass: `REQUEST_CHANGES` on `6aff325`; all planted flaws found; analyze failed, tests `+528 -3`. |
| 6 - reviewer clean control | Pass: final review on `865e5f7` returned `APPROVE`; four LOW/NIT findings addressed in `40543c0`. |
| 7 - grep secret path | Pass for ignored paths: `.gitignore` now hides the tested `.env`/`.envrc` forms from `grep`; tracked secret-like files remain a residual. |

The temporary primary-mode harness copy was deleted after the test run and is not part of the committed tree. The test-only control branch was dropped; `docs/reports/agent-tests.md` is the recorded test.

### Residual limitations

- `git diff <range> -- <dotfile>` is still denied. The permission matcher's glob does not match a command ending in a dot path (`-- .gitignore`, `-- .editorconfig`, `-- .metadata`). `git diff <range>` without a path is allowed and shows the same change, so review coverage is not lost. Adding an allow rule did not change this; no ineffective rule is shipped.
- Generic git read commands can print a tracked secret-like file. No secret-like file is tracked at this revision, and `.gitignore` blocks the tested forms.
- The `grep` tool has no path-pattern permission map in these agents. `.gitignore` is the guard for ignored secret-like files.
- A global allow for `C:\Users\jaina\.local\share\opencode\tool-output\*` overrides the agent-level `external_directory: deny` for that path. Accepted for wave 1; do not rely on `external_directory: deny` to block tool-output reads.
- `default_agent` is deferred to wave 2; a missing default falls back to `build`.

## `build_runner` classification

Search scope: the whole working tree outside `docs/archive/`, `.git/`, `build/`, `.dart_tool/`, and `ephemeral/`. Every hit is classified below.

| Category | Hits | Conclusion |
| --- | --- | --- |
| Prohibition / policy text agreeing with the SoT | `AGENTS.md:7`, `README.md:25`, `docs/SOURCE_OF_TRUTH.md:43`, `.opencode/agents/lk-auditor.md:55`, `.opencode/agents/lk-reviewer.md:58`, `lib/database/database_metadata.dart:86,142,228`, `lib/models/manuscript_collection.g.dart:8`, `docs/reports/agent-tests.md:29` | Correct: states that `build_runner` must not be run. |
| Historical / status / decision records | `docs/SOURCE_OF_TRUTH.md:57,115,126`, `docs/reports/2026-11-docs-cleanup.md:52,99`, `docs/reports/2026-11-phase-1-plan.md` (plan and audit status), `docs/specs/AGENTS_PLAN.md` (subordinate agent plan) | Correct: records the requirement, the exit check, the deleted `.clinerules` conflict, or the Stage A plan. |
| Executable references | None | `pubspec.yaml`, `pubspec.lock`, `.github/workflows/ci.yaml`, and `tools/` contain no `build_runner` or `hive_generator`. No script or CI step runs it. |

`docs/archive/` still contains historical mentions; the SoT exit check explicitly excludes the archive. Nothing outside the archive invokes code generation.

## Verification at Stage B HEAD

- `flutter analyze`: **No issues found!** (133.1 s).
- `flutter test`: **All 531 tests passed** (`00:33 +531`).
- `git ls-files '*.g.dart'`: **14** tracked adapters, unchanged.
- `pubspec.yaml`: no `build_runner`, no `hive_generator`, no `json_serializable`, no `mockito`.
- Generated plugin registrants were reverted before each commit; no generated file is in the Stage B diff.
- `docs/SOURCE_OF_TRUTH.md` and `docs/specs/AGENTS_PLAN.md`: unmodified.

## Files changed in Stage B

| File | Change |
| --- | --- |
| `pubspec.yaml`, `pubspec.lock` | Removed `build_runner`, `json_serializable`, `mockito`; removals only. |
| `lib/models/manuscript_collection.g.dart` | Comment only; adapter logic and `typeId` unchanged. |
| `lib/database/database_metadata.dart` | Three comments only; adapter logic unchanged. |
| `.opencode/agents/lk-auditor.md`, `.opencode/agents/lk-reviewer.md` | New wave 1 agents; read hardening and narrowed git denies. |
| `.gitignore` | Local-secrets block. |
| `docs/reports/agent-tests.md` | New R-22 test record. |
| `docs/reports/2026-11-phase-1-plan.md`, `docs/reports/2026-11-phase-1-stage-b.md` | Stage A plan and this report. |

## Open items for the owner

1. **R-22 owner approval.** The reviewer verdict is `APPROVE`; `docs/reports/agent-tests.md` marks owner approval pending. R-22 is not Done until the owner approves.
2. **P2-P5 deferral.** Stage A asked the owner to confirm P2-P5 stay status-only. No Stage B change reopened them.
3. **Tracked secret-like file residual.** If a secret-like file is ever force-added, generic git read commands can print it. The current tree has none.
4. **Global tool-output allow.** The global `tool-output` allow overrides agent `external_directory: deny`; revisit in wave 2 if strict isolation is required.

## Proposed Change log entries (not applied)

- **R-02:** `build_runner`, `json_serializable`, and `mockito` removed; `hive_generator` was already absent; the 14 committed `.g.dart` adapters are kept and hand-maintained; P2-P5 remain status-only and deferred.
- **R-22:** V1 `permission:` map shipped for both agents; `.env`/`.envrc` read denies and `.gitignore` coverage added; reviewer clean control returned `APPROVE`; residual dotfile-path and tracked-secret limits recorded; owner approval pending.
- **OQ-7:** baseline note remains 531 passing tests; this stage did not change it.

## Final actions

| Action | Result |
| --- | --- |
| Applied Stage A's ordered fix list | Done |
| `flutter analyze` | No issues found |
| `flutter test` | 531 passed |
| Committed R-02 and R-22 changes | 4 commits, `ef3ccf2`..`40543c0` |
| Ran agent permission, capability, planted-flaw, and grep tests | Pass; recorded in `docs/reports/agent-tests.md` |
| Edited `docs/SOURCE_OF_TRUTH.md` or `docs/specs/AGENTS_PLAN.md` | No |
| Pushed | No |
| Wrote this report | `docs/reports/2026-11-phase-1-stage-b.md` |

Stage B stops here. Nothing is pushed. Waiting for owner review and R-22 approval before merge.
