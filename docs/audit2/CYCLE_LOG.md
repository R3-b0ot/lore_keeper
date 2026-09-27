# CYCLE_LOG — Manuscript Rebuild

Per-file journal for the staged Manuscript rebuild (spec `docs/LORE_KEEPER_MANUSCRIPT_MASTER_SPEC.md`,
requirements `docs/audit2/B7_manuscript_requirements.md`).

Legend: `+` green, `-` red/broken, `~` partial/known-issue, `!` decision/blocker.

---

## Cycle 1 — Manuscript Topology Guards (MS-001 … MS-005)

Branch: `manuscript-fixes`. Scope: prove the four canonical columns render exactly once
through the real shell and that the manuscript pipeline shares one binder + one reference engine.

### Commits

| Commit | Requirement | Summary |
| --- | --- | --- |
| `b029633` | MS-002 | Added canonical stable key `project-editor-column-1` for Column 1 (`ModuleSidebar` root). |
| `afe8b8f` | MS-001 | Runtime audit: pump the REAL `ProjectEditorScreen` and assert the four canonical columns render exactly once, Binder only in Column 2, and a seeded chapter opens. |
| `f23ccf1` | MS-003 | Identity test: Columns 2/3/4 observe ONE `ManuscriptBinderProvider` instance. |
| `90fbbeb` | MS-004 | Exposed `ManuscriptReferenceService.referenceEngine` + identity test: binder engine == inspector reference-service engine == shell engine. |
| current | MS-005 | Grep guard: the six manuscript logic services stay Flutter-free; this log. |

### Tests added (`test/widgets/manuscript_topology_test.dart`)

- `ProjectEditorScreen shell renders exactly one of each canonical column (MS-001)`
- `ProjectEditorScreen threads ONE ManuscriptBinderProvider to Columns 2/3/4 (MS-003)`
- `ProjectEditorScreen shares ONE ReferenceEngine across the manuscript pipeline (MS-004)`
- `manuscript logic services stay Flutter-free (MS-005)`

### Key findings / decisions

- **Pumping `ProjectEditorScreen` under plain FakeAsync hangs the framework**
  post-test epilogue. The shell builds its own Hive-backed providers in
  `initState`; their bootstrap completes on the real-async event loop and, when
  stranded in the FakeAsync zone, leaves the post-test `flushMicrotasks` in an
  endless churn (no `testDone` event, `--timeout` cannot interrupt). The
  supported remedy, discovered by bisect (overview vs manuscript vs
  runAsync-bootstrap probes): run the whole shell mount + bootstrap inside
  `tester.runAsync` (real event loop), render with one normal `pump`, then
  optionally unmount. Helper `_pumpProjectEditorShell` encodes this.
- **`_normalizeModuleIndex` legacy remap quirk**: `initialModuleIndex: 0` is a
  legacy deep-link index and maps to Manuscripts (1). New-range indices are
  0=Overview … 4=Lore Map. Tests reach the manuscript module via the legacy 0.
- **Hive writes must not be awaited directly inside a `testWidgets` FakeAsync
  zone** (they are real-async I/O); seed in `setUp` (real async context) or in
  `tester.runAsync`.
- **MS-003 structurally satisfied** (spec §5.2): the shell already threads one
  `ManuscriptBinderProvider` to Column 2 (`ManuscriptListPane.provider`) and to
  the module, which passes the same instance into Column 3 (`ManuscriptEditor.binderProvider`)
  and Column 4 (`ManuscriptInspector.binderProvider`). Guarded by identity test.
- **MS-004 structurally satisfied** (§11.3): every reference producer (module &
  editor `ManuscriptReferenceService`, binder, collections) builds on the one
  shell `ReferenceEngine`. The module and editor each *construct* a
  `ManuscriptReferenceService`, which is acceptable structurally but is the
  **MS-015 (Cycle 4) technical debt**: unify to a single service instance.
  Deferred by explicit decision, noted here.
- **`ManuscriptCollections`** self-creates a `ManuscriptReferenceService` with
  the same engine; that DI-bypass is a maintenance concern only, not a second
  engine — no fix required this cycle.
- **MS-005 already clean**: the six logic services carry zero
  `package:flutter/` imports; the grep-guard test pins it.
- Pre-existing analyzer infos (9, `use_null_aware_elements` in
  `database/ai/device_ai/*`, `services/entity_reference_entries.dart`,
  `settings/widgets/settings_widgets.dart`) are untouched; all changed files are
  analyzer-clean and the Dart analyzer reports no warnings/errors.

### Health

| Check | Baseline | Cycle 1 end |
| --- | --- | --- |
| `flutter analyze` | 0 errors / 0 warnings (9 pre-existing infos) | unchanged |
| `flutter test` | 377 | **380** |
| Tooling rules | no build_runner, no dep adds, no public-API changes to off-limits types | honored (`ManuscriptReferenceService.referenceEngine` is explicitly allowed) |

---

## Cycle 2 — (not started)

Planned succession: MS-006 … MS-010 (see B7). Stops after Cycle 1 complete.